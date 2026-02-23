---
name: git-worktree-flow
description: Execute one-task-per-worktree delivery with predictable branch, merge, and cleanup hygiene
license: MIT
compatibility: claude-code
metadata:
  audience: engineering
  workflow: git
---
## What I do
- Define one-task-per-worktree execution.
- Reduce branch conflicts through isolation.
- Provide cleanup and merge hygiene.

## Naming policy

- Branches: `feature/td-<id>-<slug>`, `bugfix/td-<id>-<slug>`, `chore/td-<id>-<slug>`.
- Worktrees: `<repo>-td-<id>-<slug>` or equivalent team convention.
- Keep naming stable between TD task, branch, and workspace when possible.

## Recommended conventions
- Branch naming: `feature/td-<id>-<slug>`, `bugfix/td-<id>-<slug>`, `chore/td-<id>-<slug>`.
- Workspace naming should match branch intent.
- Keep each worktree scoped to a single TD task.

## Manual git worktree flow
1. `git fetch origin`
2. `git worktree add ../<workspace> -b <branch> origin/main`
3. Run agent work in that worktree.
4. Validate, review, push, open PR.
5. After merge: `git worktree remove ../<workspace>` and prune stale refs.

## Conflict and recovery runbook

- If branch diverges: rebase or merge `origin/main` early, not at the end.
- If merge conflicts appear late: pause merge, run validator again after resolution.
- If workspace is abandoned: log in TD, then clean up local worktree/branch.

## Guardrails
- Do not mix unrelated tasks in one worktree.
- Do not merge without validator + staff-engineer review outcomes.
- Do not delete worktree before TD handoff and review state are captured.
