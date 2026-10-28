---
name: hytale-review
description: Review a Hytale change with staff-engineer for correctness, world-thread safety, feature isolation, persistence and compatibility.
argument-hint: "<target: branch, commit range, files, or ADR, plus the brief or goal>"
disable-model-invocation: true
context: fork
agent: staff-engineer
---

Review this target:

$ARGUMENTS

Determine the diff (`git diff`, `git show`, or the named files, including untracked files in a new repository) and the brief or goal it was written against; if no brief is given, take the goal from the arguments and the commit messages and say so. Follow the Review section of your instructions and the Hytale review checklist. Check API signatures only where the change relies on newly introduced ones.

Focus on consequential defects: invalid references or thread access, ordering and cancellation, double restoration of resources, XP or rewards, incomplete cleanup, unsafe migrations, unbounded generation. Inspect the verification evidence against the final source state; compilation and unit tests are distinct from server startup and client gameplay checks. Do not broaden a focused review into unrelated refactoring.

Return `approve`, `conditional` (with exact corrections, path and line, and the observable consequence), or `reject`, plus residual risks, in your deliverable format. Do not edit anything outside your ADR paths.
