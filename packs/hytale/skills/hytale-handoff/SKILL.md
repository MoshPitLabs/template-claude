---
name: hytale-handoff
description: Record a resumable handoff for in-progress Hytale work in the issue tracker, reconciled against the repository state.
argument-hint: "<work item or context>"
disable-model-invocation: true
---

Prepare a handoff as team-lead for:

$ARGUMENTS

Reconcile every claim against evidence: `git status`, `git diff --stat`, `git log`, the latest quoted verification result, and the built-in task list. Do not claim verification that has no evidence.

The handoff holds: objective, tier, paths, completed work, remaining work, decisions (with ADR links), changed modules, schemas and assets, the pinned server build, verified symbols, open uncertainty, checks run and their verdicts, runtime behavior not yet verified, and the exact next action with the agent that should take it. Name any blocker with its supporting evidence.

Post it as the handoff step of the pack that fills `Tracking` in `.claude/rules/` (for Linear, a comment on the work item). Never write it into a repository file, and never copy credentials or raw player data into tracker content. Without a tracker pack, return it to the user only and say it was not saved externally.

Return the same content to the user as a short resume block, with the tracker link.
