---
description: Create an implementation plan for a requested feature using team-lead orchestration
argument-hint: <feature-request>
agent: team-lead
---
Plan `$ARGUMENTS`.

Execution requirements:
1. If no argument is provided, ask for the feature/request to plan.
2. Load TD context first using the `td` tool (`usage`, `status`; CLI fallback only if needed).
3. Check TD status first:
   - If a task is already focused and matches the planning request, use it.
   - If no suitable task is focused, create one (`td create`) and start/focus it.
   - Do not create a new task if one is already active for this work.
4. Delegate planning to `product-manager` and require:
   - problem statement,
   - scope and non-goals,
   - testable acceptance criteria,
   - task breakdown (parallel vs sequential),
   - Git worktree execution map (branch, worktree per task),
   - risks and mitigations,
   - validation checklist,
   - open technical questions (if any).
5. Ensure the plan is ready for one-task-per-worktree execution.
6. Log planning completion to TD.

Output format:
- TD task being planned
- Concise implementation plan with parallel/sequential phases
- Git worktree execution map:
  | Task ID | Branch | Worktree path | Phase |
  |---------|--------|---------------|-------|
  | td-xxx  | feature/td-<id>-<slug> | ../worktrees/td-xxx | 1 (parallel) |
- Git worktree setup commands (for manual execution):
  ```
  git worktree add ../worktrees/<task-id> -b <branch-name>
  ```
- blockers/unknowns
- Recommended next command (`/build <task-id>`)
