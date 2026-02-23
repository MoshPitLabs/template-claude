---
name: release-notes
description: Generate structured release notes from merged tasks, PR context, and review outcomes
license: MIT
compatibility: claude-code
metadata:
  audience: maintainers
  workflow: release
---
## What I do
- Convert implementation and PR context into release-ready notes.
- Separate user-facing changes from internal maintenance.
- Highlight known risks and follow-ups.

## Release modes

- Feature release: highlights + improvements + migration notes.
- Patch release: fixes-focused with minimal narrative.
- Hotfix release: incident context, fix summary, risk, and follow-up actions.

## Output template
- Highlights
- Fixes
- Improvements
- Breaking changes (if any)
- Post-release follow-ups

## Source-of-truth order

1. Merged PR descriptions and titles
2. Commit subjects within release window
3. Validator outcomes
4. Code-reviewer outcomes
5. TD handoff notes for unresolved follow-up work

## Inputs to gather
- Merged PR descriptions
- Commit subjects in release window
- Validator and reviewer conclusions

## Quality checks

- Call out breaking changes explicitly.
- Avoid implementation trivia; keep notes user-relevant.
- Include follow-up items when risk is deferred.
