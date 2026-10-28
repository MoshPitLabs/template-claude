---
name: linear-start
description: Pick up a Linear issue as the work item — read it, then run the normal intake and delivery with the issue tracked.
argument-hint: "<issue identifier or URL>"
disable-model-invocation: true
---

Pick up this Linear issue as team-lead:

$ARGUMENTS

1. Load `linear-tracking` and read `.claude/local/linear.md` (create it first if missing).
2. Read the issue, its comments, images, parent, and blocking issues. If it is blocked by an open issue, or already done or canceled, say so and stop.
3. Restate the issue as expected outcome and acceptance. Ask the user only for a decision that changes the tier or the outcome.
4. Continue with the intake in your instructions. A defect follows the domain's bug workflow and anything else its feature workflow (`Workflows` in `.claude/rules/`), with the issue in `Issue:` of the brief.
5. Track the issue as `Tracking` in `.claude/rules/linear-tracking.md` says: state at first delegation, comments at review and acceptance.

End with the final report from your instructions, including the `Issue:` line.
