---
name: wow-dev
description: Make a small World of Warcraft addon change directly in senior-engineer and run the repository verification loop until clean.
argument-hint: "<change to make>"
disable-model-invocation: true
context: fork
agent: senior-engineer
---

Direct mode (see "Direct mode" in your instructions). Make this change:

$ARGUMENTS

Read `.claude/local/wow.toml` and the WoW knowledge skill for the topic (`Skills by work type` in `.claude/rules/wow-addons.md`). Make the smallest coherent change, list new files in every flavor TOC, then run the `verify_command` (default `luacheck .`) after the final Lua, XML or TOC change and fix failures in scope. Use meaningful tests for pure logic (parsers, migrations, calculations) where the repository has specs, not tests that mirror the implementation. If the change is design-gated (SavedVariables schema or migration, secure or protected frames, combat lockdown, hooks into Blizzard UI, an addon-message protocol, a flavor added or dropped, a new library), stop before editing and say it needs the design-gated workflow.

Report the changed paths, the source and flavor for every new API, the quoted verification result, SavedVariables impact, and the in-game checks for the user. Do not tag, package or publish.
