---
name: arma-bug
description: Triage and fix an Arma Reforger defect from a report, compile error, stack trace, or log — locate the cause from evidence, then delegate the fix.
argument-hint: "<bug report, error text, or \"last session\">"
disable-model-invocation: true
---

Triage this bug report as team-lead:

$ARGUMENTS

1. Establish expected versus observed behaviour from what is provided.
2. Get the evidence before theorising. When the report points at a Workbench, game, or server session, send `scout` to triage it (`logs_summarize_errors`, `logs_filter`, `FPS:` lines for lag). A compile error, stack trace, or log line is sufficient reproduction; ask for more only if the fault cannot be located without it.
3. Attribute the behaviour before changing anything: our code, vanilla, or a third-party mod (`arma-third-party-mod-audit`). Check `git log` for a recent change in the area; if the defect comes from it, fix forward in the same scope.
4. Pick the tier; most fixes are `minor`. Send root-cause analysis to `staff-engineer` only when the cause touches replication or persistence, or is not evident from the code.
5. Delegate the fix to `senior-engineer` with the evidence under `Decisions already made`, and accept on the gates.

Add the reproduction rerun as a W3 item for the user; replication defects add W4, persistence defects a dedicated-server restart.
