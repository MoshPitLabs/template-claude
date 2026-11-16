---
name: wow-review
description: Review a World of Warcraft addon change with staff-engineer for correctness, taint and combat lockdown, SavedVariables safety, flavor coverage and untrusted input.
argument-hint: "<target: branch, commit range, files, or ADR, plus the brief or goal>"
disable-model-invocation: true
context: fork
agent: staff-engineer
---

Review this target:

$ARGUMENTS

Determine the diff (`git diff`, `git show`, or the named files, including untracked files in a new repository) and the brief or goal it was written against; if no brief is given, take the goal from the arguments and the commit messages and say so. Follow the Review section of your instructions and the WoW review checklist in `.claude/rules/wow-addons.md`. Check APIs only where the change relies on newly introduced ones, for each flavor in scope.

Focus on consequential defects: taint and protected-frame changes in combat, replaced Blizzard functions, SavedVariables read too early or migrated lossily, files missing from a flavor TOC, untrusted addon-message or import data reaching code unchecked, per-frame cost, leaked globals. Inspect the verification evidence against the final source state; lint and unit tests are distinct from in-game checks. Do not broaden a focused review into unrelated refactoring.

Return `approve`, `conditional` (with exact corrections, path and line, and the observable consequence), or `reject`, plus residual risks, in your deliverable format. Do not edit anything outside your ADR paths.
