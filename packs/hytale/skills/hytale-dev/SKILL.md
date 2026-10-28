---
name: hytale-dev
description: Make a small Hytale change directly in senior-engineer and run the repository verification loop until clean.
argument-hint: "<change to make>"
disable-model-invocation: true
context: fork
agent: senior-engineer
---

Direct mode (see "Direct mode" in your instructions). Make this change:

$ARGUMENTS

Read `.claude/local/hytale.toml` and the Hytale knowledge skill for the topic (`Skills by work type` in `.claude/rules/hytale.md`). Make the smallest coherent change, then run `python3 scripts/verify.py` (or the configured `verify_command`) after the final source, config or asset change and fix failures in scope. Use meaningful domain tests for calculations and transactions, not tests that mirror the implementation. If the change is design-gated (schema migration, module lifecycle, world-generation contract, persistent dungeon or reward state, authority or threading), stop before editing and say it needs the design-gated workflow.

Report the changed paths, the source for every new API, the quoted verification result, data and config impact, and the runtime checks not run. Do not deploy.
