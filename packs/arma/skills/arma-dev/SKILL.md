---
name: arma-dev
description: Make a small Arma Reforger change directly in senior-engineer and run the dev loop (W1 compile, reload, Play smoke) until clean.
argument-hint: "<change to make>"
disable-model-invocation: true
context: fork
agent: senior-engineer
---

Direct mode (see "Direct mode" in your instructions). Make this change:

$ARGUMENTS

Load `arma-workbench-workflow` and read `.claude/local/workbench.md` (create it from the template if missing). Make the smallest coherent change, then run the dev loop and repeat it until it is clean or you are blocked. If the change is design-gated (replication, persistence, a vanilla class not yet modded here, GUID/resource moves, a new dependency), stop before editing and say it needs `/arma-feature`.

Report the changed files, the W1 verdict (quoted), the smoke result, and what the user should check by eye.
