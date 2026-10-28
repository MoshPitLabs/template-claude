---
name: arma-handoff
description: Record a resumable handoff for in-progress Arma Reforger work in the issue tracker, reconciled against the repository state.
argument-hint: "<work item or context>"
disable-model-invocation: true
---

Prepare a handoff as team-lead for:

$ARGUMENTS

Reconcile every claim against evidence: `git status`, `git diff --stat`, `git log`, the latest quoted W1 and smoke results, and the built-in task list. Do not claim verification that has no evidence.

The handoff holds: objective, tier, mod and paths, completed work, remaining work, decisions (with ADR links), verified symbols, open uncertainty, checks run and their verdicts, W2–W4 items still open, and the exact next action with the agent that should take it.

Post it as the handoff step of the pack that fills `Tracking` in `.claude/rules/` (for Linear, a comment on the work item). Never write it into a repository file. Without a tracker pack, return it to the user only.

Return the same content to the user as a short resume block, with the tracker link.
