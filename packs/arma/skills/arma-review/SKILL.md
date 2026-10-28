---
name: arma-review
description: Review an Arma Reforger design or implementation diff against its brief with staff-engineer — scope, overrides, inheritance, GUIDs, authority/proxy, persistence, performance.
argument-hint: "<target: branch, commit range, files, or ADR, plus the brief or goal>"
disable-model-invocation: true
context: fork
agent: staff-engineer
---

Review this target:

$ARGUMENTS

Determine the diff (`git diff`, `git show`, or the named files) and the brief or goal it was written against; if no brief is given, take the goal from the arguments and the commit messages and say so. Follow the Review section of your instructions. Spot-check only newly introduced engine symbols.

Return `approve`, `conditional` (with exact corrections), or `reject`, plus residual risks, in your deliverable format. Do not edit anything outside your ADR paths.
