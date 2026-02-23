# Agent Team Workflow

This workflow uses role-based OpenCode agents, TD task tracking, and git worktrees.

## Team Roles

- `team-lead` (primary orchestrator)
- `product-manager` (scope and acceptance criteria)
- `staff-engineer` (implementation and code review)
- `validator` (criteria and test validation)

## TD-First Rules

1. Start session context: `td usage --new-session`
2. Start or focus a task: `td start <TASK-ID>`
3. Implement/validate/review
4. Log progress: `td log "..."`
5. Handoff before exit: `td handoff <TASK-ID> --done ... --remaining ... --decision ... --uncertain ...`

The local plugin `.opencode/plugins/td-enforcer.ts` blocks file edits when no active TD task exists.

## Security Guardrails

- `.opencode/plugins/security.ts` blocks reads/edits/searches over sensitive files such as `.env`, key material, and credential files.
- It also blocks destructive `rm -rf` command patterns.

## Git Worktrees

Recommended execution model:
1. Create git worktree per TD task via git worktree commands.
2. Start or focus the TD task in the worktree.
3. Run implementation and validation in isolated worktrees.
4. Complete merge workflow and cleanup.

---

## TD One-Task-Per-Worktree Execution Playbook

### Overview

This playbook enforces **one task per worktree** using TD task tracking and git worktree isolation. Each task executes in its own git worktree with dedicated branch and directory.

**Core Principles:**
- **Isolation**: One task = one worktree = one branch = one workspace
- **Traceability**: All file changes auto-tracked to focused TD task
- **Parallelism**: Multiple tasks execute concurrently in separate worktrees
- **Clean Handoffs**: Explicit done/remaining/decision/uncertain context at task boundaries

---

### Epic-to-Child Task Decomposition

#### When to Decompose

Decompose epics into child tasks when:
- Epic spans multiple domains (frontend + backend + infra)
- Epic requires >8 hours of focused work
- Epic has natural dependency boundaries (API → UI → tests)
- Epic involves multiple reviewers or approval gates

#### Decomposition Strategy

**1. Identify Natural Boundaries**
```
Epic: "Implement user authentication system"
├─ Task 1: Design auth API schema and endpoints
├─ Task 2: Implement JWT token service
├─ Task 3: Build login/logout UI components
├─ Task 4: Add integration tests for auth flow
└─ Task 5: Update security documentation
```

**2. Define Dependencies**
- **Sequential**: Task 2 depends on Task 1 (API schema → implementation)
- **Parallel**: Task 3 and Task 4 can run concurrently after Task 2
- **Blocking**: Task 5 waits for all implementation tasks

**3. Create Child Tasks**
```bash
# Create epic
td create "Implement user authentication system" \
  --type epic \
  --priority P1 \
  --labels auth,security

# Create child tasks with parent linkage
td create "Design auth API schema and endpoints" \
  --type task \
  --parent td-abc123 \
  --priority P1 \
  --labels auth,api,design

td create "Implement JWT token service" \
  --type task \
  --parent td-abc123 \
  --priority P1 \
  --labels auth,backend \
  --depends-on td-def456  # Depends on schema task
```

**4. Size Guidelines**
- **Epic**: 3-10 child tasks, 1-4 weeks total
- **Task**: 2-8 hours focused work, single domain
- **Subtask**: <2 hours, single file or component

---

### One-Task-Per-Worktree Execution

#### Branch and Worktree Naming Conventions

Git worktree branches follow this structure:
```
<branch-type>/<task-id>-<brief-slug>
```

**Branch Types:**
- `feature/` - New functionality (e.g., `feature/td-abc123-user-auth`)
- `bugfix/` - Bug fixes (e.g., `bugfix/td-def456-login-error`)
- `refactor/` - Code refactoring (e.g., `refactor/td-ghi789-api-cleanup`)
- `docs/` - Documentation updates (e.g., `docs/td-jkl012-api-guide`)
- `test/` - Test additions (e.g., `test/td-mno345-auth-coverage`)
- `hotfix/` - Emergency production fixes (e.g., `hotfix/td-pqr678-security-patch`)

**Examples:**
```bash
# Feature task worktree
git worktree add -b feature/td-abc123-jwt-service ../worktrees/feature-td-abc123-jwt-service

# Bugfix task worktree
git worktree add -b bugfix/td-def456-token-expiry ../worktrees/bugfix-td-def456-token-expiry

# Refactor task worktree
git worktree add -b refactor/td-ghi789-auth-middleware ../worktrees/refactor-td-ghi789-auth-middleware
```

#### Workspace Setup Flow

**1. Create Git Worktree**
```bash
# Create worktree with new branch
git worktree add -b feature/td-abc123-jwt-service ../worktrees/feature-td-abc123-jwt-service

# Navigate to worktree
cd ../worktrees/feature-td-abc123-jwt-service/
```

**2. Start TD Task in Worktree**
```bash
# Start TD task
td start td-abc123

# Verify context
td status
# Output: focus: td-abc123, branch: feature/td-abc123-jwt-service
```

**3. Implement in Isolation**
```bash
# All file edits tracked to td-abc123 by td-enforcer plugin
# Plugin enforces task focus before writes

# Example implementation
vim src/auth/jwt-service.ts
# → Plugin links file to td-abc123 (if enabled)
# → Manual logging recommended for key changes
```

**4. Validate and Review**
```bash
# Run tests in workspace
npm test

# Log validation results
td log "All JWT service tests passing (12/12)"

# Submit for review
td review td-abc123
```

**5. Merge and Cleanup**
```bash
# Return to main worktree
cd ../../template-opencode/

# Merge worktree branch
git merge feature/td-abc123-jwt-service

# Remove worktree
git worktree remove ../worktrees/feature-td-abc123-jwt-service

# Delete merged branch (optional)
git branch -d feature/td-abc123-jwt-service

# Mark task done
td done td-abc123
```

---

### Task Dependencies and Blocker Propagation

#### Dependency Types

**1. Sequential Dependencies**
```
Task A → Task B → Task C
```
- Task B cannot start until Task A completes
- Use `--depends-on` flag when creating tasks

**2. Parallel Dependencies**
```
Task A → Task B
      ↘ Task C
```
- Task B and Task C can run concurrently after Task A
- Execute in separate git worktrees

**3. Convergent Dependencies**
```
Task A ↘
        → Task C
Task B ↗
```
- Task C waits for both Task A and Task B
- Use multiple `--depends-on` flags

#### Blocker Propagation

**When Task is Blocked:**
```bash
# Mark task as blocked with reason
td block td-abc123 --reason "Waiting for API schema approval"

# Blocker propagates to dependent tasks
td status
# Output:
# blocked: [td-abc123] "Waiting for API schema approval"
#          [td-def456] "Blocked by td-abc123"
#          [td-ghi789] "Blocked by td-abc123"
```

**Unblocking Flow:**
```bash
# Resolve blocker
td unblock td-abc123 "API schema approved"

# Dependent tasks auto-unblock
td status
# Output:
# ready_to_start: [td-def456, td-ghi789]
```

**Blocker Handoff:**
```bash
# Handoff blocked task with context
td handoff td-abc123 \
  --done "Implemented 80% of JWT service" \
  --remaining "Add refresh token logic" \
  --decision "Using RS256 for signing" \
  --uncertain "Blocked: Need product decision on token expiry duration (1h vs 24h)"
```

---

### Task Handoff and Review Flow

#### Handoff Context (MANDATORY)

Every task handoff MUST capture:
- **done**: Concrete accomplishments
- **remaining**: Outstanding work
- **decision**: Key architectural/implementation choices
- **uncertain**: Open questions, blockers, areas needing clarification

**Example Handoff:**
```bash
td handoff td-abc123 \
  --done "Implemented JWT service with RS256 signing, token generation, and validation. Added unit tests (12/12 passing). Updated API documentation." \
  --remaining "Add refresh token endpoint, implement token revocation list, add integration tests with auth middleware" \
  --decision "Using RS256 (asymmetric) instead of HS256 to support distributed validation. Storing public keys in environment variables. Token expiry set to 1 hour with refresh flow." \
  --uncertain "Should we support multiple JWT issuers for SSO integration? Need security review on key rotation strategy. Performance impact of RSA validation at scale unknown."
```

#### Review Workflow

**1. Submit for Review**
```bash
# Implementation complete
td review td-abc123

# Task transitions: in_progress → in_review
```

**2. Reviewer Assignment**
```bash
# Reviewer checks reviewable tasks
td status
# Output:
# in_review.reviewable_by_you: [td-abc123]

# Reviewer focuses on task
td focus td-abc123
```

**3. Review Execution**
```bash
# Navigate to task worktree (if it still exists)
cd ../worktrees/feature-td-abc123-jwt-service/ 2>/dev/null || cd .

# Review code changes
git diff main...feature/td-abc123-jwt-service

# Run validation
npm test
npm run lint

# Log review findings
td log "Code review: Approved with minor suggestions (see PR comments)"
```

**4. Review Outcomes**

**Approved:**
```bash
# Approve and merge
td approve td-abc123
git merge feature/td-abc123-jwt-service
git worktree remove ../worktrees/feature-td-abc123-jwt-service 2>/dev/null || true
td done td-abc123
```

**Request Changes:**
```bash
# Reject and return to implementer with feedback
td reject td-abc123 --reason "Add error handling for expired tokens, increase test coverage for edge cases"

# Task transitions: in_review → in_progress
# Implementer can resume work
```

**Blocked:**
```bash
# Block if external dependency discovered
td block td-abc123 --reason "Requires security team approval for key management strategy"
```

---

### Practical End-to-End Example

#### Scenario: Implement User Profile Feature

**Epic Decomposition:**
```bash
# Create epic
td create "User profile management" \
  --type epic \
  --priority P1 \
  --labels feature,user-profile

# Epic ID: td-epic-001

# Create child tasks
td create "Design profile API schema" \
  --type task \
  --parent td-epic-001 \
  --priority P1 \
  --labels api,design

# Task ID: td-task-101

td create "Implement profile CRUD endpoints" \
  --type task \
  --parent td-epic-001 \
  --priority P1 \
  --labels api,backend \
  --depends-on td-task-101

# Task ID: td-task-102

td create "Build profile UI components" \
  --type task \
  --parent td-epic-001 \
  --priority P1 \
  --labels frontend,ui \
  --depends-on td-task-102

# Task ID: td-task-103
```

**Task 1: Design Profile API Schema (td-task-101)**

```bash
# Create worktree
git worktree add -b feature/td-task-101-profile-schema ../worktrees/feature-td-task-101-profile-schema

# Navigate to worktree
cd ../worktrees/feature-td-task-101-profile-schema/

# Start TD task
td start td-task-101

# Implement schema
vim docs/api/profile-schema.md

# Log progress
td log "Defined profile schema with fields: id, username, email, avatar_url, bio, created_at, updated_at"

# Submit for review
td review td-task-101

# Handoff
td handoff td-task-101 \
  --done "Completed profile API schema design with validation rules" \
  --remaining "None - ready for review" \
  --decision "Using UUID for profile IDs, email as unique identifier" \
  --uncertain "Should bio field have character limit? Suggest 500 chars."

# Return to main worktree
cd ../../template-opencode/
```

**Task 2: Implement Profile CRUD Endpoints (td-task-102)**

```bash
# Wait for td-task-101 approval
td status
# Output: ready_to_start: [td-task-102]

# Create worktree
git worktree add -b feature/td-task-102-profile-crud ../worktrees/feature-td-task-102-profile-crud

# Navigate to worktree
cd ../worktrees/feature-td-task-102-profile-crud/

# Start TD task
td start td-task-102

# Implement endpoints
vim src/api/profile-controller.ts
vim src/api/profile-service.ts
vim src/api/profile-repository.ts

# Run tests
npm test

# Log progress
td log "Implemented GET, POST, PUT, DELETE endpoints. All tests passing (24/24)."

# Submit for review
td review td-task-102

# Handoff
td handoff td-task-102 \
  --done "Implemented full CRUD API for user profiles with validation, error handling, and unit tests" \
  --remaining "None - ready for review" \
  --decision "Using repository pattern for data access, JWT middleware for auth" \
  --uncertain "Performance testing needed for large user base (>100k profiles)"

# Return to main worktree
cd ../../template-opencode/
```

**Task 3: Build Profile UI Components (td-task-103)**

```bash
# Wait for td-task-102 approval
td status
# Output: ready_to_start: [td-task-103]

# Create worktree
git worktree add -b feature/td-task-103-profile-ui ../worktrees/feature-td-task-103-profile-ui

# Navigate to worktree
cd ../worktrees/feature-td-task-103-profile-ui/

# Start TD task
td start td-task-103

# Implement UI components
vim src/components/ProfileCard.tsx
vim src/components/ProfileForm.tsx
vim src/hooks/useProfile.ts

# Run tests
npm test

# Log progress
td log "Built ProfileCard and ProfileForm components with form validation and error states"

# Submit for review
td review td-task-103

# Handoff
td handoff td-task-103 \
  --done "Implemented profile UI components with responsive design, form validation, and loading states" \
  --remaining "None - ready for review" \
  --decision "Using React Hook Form for validation, Tailwind for styling" \
  --uncertain "Accessibility audit needed - should we add ARIA labels?"

# Return to main worktree
cd ../../template-opencode/
```

**Epic Completion:**

```bash
# All child tasks approved and merged
td status td-epic-001
# Output: 
# children: [td-task-101: done, td-task-102: done, td-task-103: done]

# Mark epic complete
td done td-epic-001

# Cleanup all worktrees (if not already removed)
git worktree remove ../worktrees/feature-td-task-101-profile-schema 2>/dev/null || true
git worktree remove ../worktrees/feature-td-task-102-profile-crud 2>/dev/null || true
git worktree remove ../worktrees/feature-td-task-103-profile-ui 2>/dev/null || true
```

---

### Best Practices

**1. Workspace Hygiene**
- Create worktree immediately when starting task
- Never work on multiple tasks in same worktree
- Remove worktree after merge (prevents stale worktrees)

**2. Dependency Management**
- Declare dependencies upfront during task creation
- Use `td status` to check ready_to_start queue
- Block tasks early if external dependencies discovered

**3. Handoff Quality**
- Provide concrete `done` accomplishments (not vague "made progress")
- List specific `remaining` work items (enables next session to start immediately)
- Document `decision` rationale (prevents re-litigation of choices)
- Explicitly state `uncertain` areas (surfaces blockers and questions)

**4. Review Efficiency**
- Keep tasks small (2-8 hours) for faster review cycles
- Submit for review when implementation complete (don't wait for perfection)
- Respond to review feedback in same worktree (preserves context)

**5. Parallel Execution**
- Identify parallel tasks during decomposition
- Use separate git worktrees for concurrent work
- Coordinate merge order to avoid conflicts

---

### Troubleshooting

**Problem: Task blocked but no blocker message**
```bash
td status
# Output: blocked: [td-abc123] ""

# Solution: Add explicit blocker context
td block td-abc123 --reason "Waiting for design approval from product team"
```

**Problem: Worktree branch conflicts with main**
```bash
# In worktree
git merge main
# Conflict detected

# Solution: Resolve conflicts in worktree before review
git mergetool
git commit
td log "Resolved merge conflicts with main branch"
```

**Problem: Multiple tasks modifying same file**
```bash
# Task A and Task B both edit src/config.ts

# Solution: Serialize tasks or refactor to avoid overlap
td block td-task-B --reason "Waiting for td-task-A to complete (both modify src/config.ts)"
```

**Problem: Forgot to handoff before session end**
```bash
# Next session - check last task state
td status
# Output: focus: td-abc123 (no handoff context)

# Solution: Reconstruct context from git history
git log --oneline -10
td log "Session interrupted - resuming work on JWT service implementation"
```

## Slash Commands

- `/plan <feature-request>`
- `/build <feature-request | td-task-id | plan-summary>`

The team-lead command flow is intentionally minimal:
- Use `/plan` when you want a build-ready plan and acceptance criteria.
- Use `/build` when you want end-to-end orchestration with minimal manual steps.
