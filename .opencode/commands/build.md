---
description: Build a feature end-to-end by orchestrating product-manager, staff-engineer, and validator
argument-hint: <feature-request | td-task-id | plan-summary>
agent: team-lead
---
Build `$ARGUMENTS` using full team orchestration.

Execution protocol:
1. Load TD context using the `td` tool (`usage`, `status`; CLI fallback only if needed).
2. Resolve scope source:
   - if argument is a TD task id, use that task context,
   - otherwise treat argument as feature request and create/start a TD task if needed.
3. If no accepted plan exists, delegate to `product-manager` for a compact build-ready plan.
4. **Assess parallelization opportunity:**
   - Can work be split into 2-3 independent units with clear boundaries?
   - Are acceptance criteria separable per unit?
   - Are there cross-unit dependencies that require sequencing?
5. **Choose execution mode:**
   - **Sequential (default)**: Single `staff-engineer` → `validator` flow
   - **Parallel (3x3 bounded)**: Up to 3 implementation lanes + 3 validation lanes
     - Use when: independent features, separable modules, isolated bug fixes
     - Avoid when: shared state mutations, tight coupling, unclear boundaries
6. **Implementation phase:**
   - Sequential: Delegate to single `staff-engineer`
   - Parallel: Delegate to up to 3 `staff-engineer` lanes concurrently
     - Each lane gets clear scope subset and acceptance criteria
     - Track each lane via separate TD task or sub-task
     - Monitor for lane-local vs global blockers
7. **Validation phase:**
   - Sequential: Delegate to single `validator`
   - Parallel: Delegate to up to 3 `validator` lanes concurrently
     - Each lane validates corresponding implementation lane output
     - Aggregate evidence across all lanes
8. **Review phase (always sequential):**
   - Delegate to single `staff-engineer` for code review across all implementation lanes
   - Consolidate findings across all changed files
9. **Enforce go/no-go gate:**
   - All lanes: acceptance criteria validated
   - All lanes: no unresolved high-severity review findings
   - All lanes: validation evidence captured
10. **Ensure TD records are updated:**
    - Log major milestones per lane
    - Link changed files to task(s)
    - Capture handoff context with lane status
    - Submit task(s) for review when complete

Operating rules:
- Keep one task per worktree unless user overrides.
- Stop on blockers and report exact unblock actions.
- Do not ask user to manually invoke role commands unless blocked by missing context.

Output format:
- TD task(s) and current state
- Execution mode used (sequential or parallel 3x3)
- **Per-lane status** (if parallel):
  - Lane identifier and scope
  - Status: in-progress, blocked (local/global), complete
  - Changed files per lane
  - Blocker details if applicable
- **Aggregated implementation summary:**
  - Combined work across all lanes
  - Cross-lane dependencies resolved
- **Aggregated validation verdict:**
  - Evidence from all validator lanes
  - Acceptance criteria coverage across lanes
- **Consolidated review findings:**
  - Severity-ranked findings across all implementation lanes
  - Per-lane breakdown if helpful for triage
- Changed files (all lanes combined)
- Next step (merge, follow-up fix, or unblock action)
