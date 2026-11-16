---
name: wow-handoff
description: Record a resumable handoff for in-progress World of Warcraft addon work in the issue tracker, reconciled against the repository state.
argument-hint: "<work item or context>"
disable-model-invocation: true
---

Prepare a handoff as team-lead for:

$ARGUMENTS

Reconcile every claim against evidence: `git status`, `git diff --stat`, `git log`, the latest quoted verification result, and the built-in task list. Do not claim verification that has no evidence.

The handoff holds: objective, tier, paths, completed work, remaining work, decisions (with ADR links), changed files and TOCs, flavors and pinned Interface numbers, SavedVariables and message-format changes, verified symbols (with flavor), open uncertainty, checks run and their verdicts, in-game behavior not yet verified, and the exact next action with the agent that should take it. Name any blocker with its supporting evidence.

Post it as the handoff step of the pack that fills `Tracking` in `.claude/rules/` (for Linear, a comment on the work item). Never write it into a repository file, and never copy release tokens, account names or SavedVariables contents into tracker content. Without a tracker pack, return it to the user only and say it was not saved externally.

Return the same content to the user as a short resume block, with the tracker link.
