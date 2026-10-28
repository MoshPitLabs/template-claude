---
name: arma-feature
description: Coordinate an Arma Reforger feature from intake through acceptance — tier, brief, delegation to staff-engineer and senior-engineer, evidence-based acceptance.
argument-hint: "<feature request>"
disable-model-invocation: true
---

Coordinate this feature request as team-lead:

$ARGUMENTS

Follow `.claude/rules/team.md` and `.claude/rules/arma-enfusion.md`:

1. Pick the tier and state why. Ask only for a decision that changes the tier or the outcome.
2. Send symbol and pattern lookups that read a lot to `scout` first; put its citations in the brief.
3. Design-gated: `staff-engineer` writes the ADR, its decision goes verbatim into the brief, and `senior-engineer` runs on `opus`.
4. Delegate implementation to `senior-engineer` with the complete brief. For `standard` and `design-gated`, send the diff and the implementer's report to `staff-engineer` for review.
5. Accept on the gates; send gaps back.

Do not implement anything yourself. End with the final report from your instructions, including the W2–W4 items the user should run.
