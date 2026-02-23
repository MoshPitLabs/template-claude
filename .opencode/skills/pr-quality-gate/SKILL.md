---
name: pr-quality-gate
description: Apply an enforceable quality gate before opening or merging pull requests
license: MIT
compatibility: opencode
metadata:
  audience: engineering
  workflow: review
---
## What I do
- Enforce a release-ready PR checklist.
- Ensure validation and review outputs are captured.
- Improve merge confidence and auditability.

## Pass/fail gate

A PR is merge-ready only if all are true:
- acceptance criteria are validated with evidence,
- no unresolved high-severity code review findings,
- required tests/checks passed,
- risk/rollback notes are documented.

## Quality gate checklist
- Scope matches TD task acceptance criteria.
- Tests/checks pass for touched areas.
- Security-sensitive paths were not accessed or modified unexpectedly.
- Migration or rollout notes are documented when needed.
- Reviewer findings are resolved or explicitly deferred.

## Minimum evidence required

- Validator output with criteria-to-evidence mapping.
- Code-reviewer verdict and severity summary.
- Commands/checks run (or explicit rationale when not run).
- TD log/handoff references for traceability.

## Minimum PR summary sections
1. Why this change exists
2. What changed (high-level)
3. Validation performed
4. Risks and rollback plan
