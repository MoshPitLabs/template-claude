---
name: arma-test
description: Run the Arma Reforger dev loop (W1 compile, reload, Play smoke, log triage) on the current state without editing anything.
argument-hint: "[focus, or \"last run\" to triage the logs of a session you ran yourself]"
disable-model-invocation: true
context: fork
agent: senior-engineer
---

Direct mode, read-only. Test the addon as it is now, with focus on:

$ARGUMENTS

Load `arma-workbench-workflow` and `arma-enfusion-mcp-tooling`, and read `.claude/local/workbench.md`. Do not edit any file.

- If the focus says the user just ran something themselves ("last run", a server or client session), triage that session instead of running Play: `logs_list`, `logs_summarize_errors`, then `logs_filter` around each error. For lag, read the server log's `FPS:` lines first.
- Otherwise run W1 (`wb_validate_scripts` with the recorded `addons_dir`), then the editor reload and the W3 smoke run if the setup allows them.

Report each verdict and each error with its file and line, grouped by root cause, and name the likely fix. Fix nothing; the user decides with `/arma-dev` or `/arma-bug`.
