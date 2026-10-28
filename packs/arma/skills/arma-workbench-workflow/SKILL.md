---
name: arma-workbench-workflow
description: The Arma Reforger dev loop and the single verification checklist (W1–W4). Load before testing a change (compile, reload, Play smoke run), when reporting which checks apply, or when recording their results.
---

# Workbench Workflow

There are no Enforce Script LSP diagnostics; absence of editor errors is not evidence. Every item below is reported as `pass`, `fail`, `unknown`, or `n/a`. The implementer runs W1 and, when the test setup allows it, the W3 smoke run through enfusion-mcp. The rest of W2–W4 are GUI or multiplayer steps and stay `unknown` until the user runs them. Load `arma-enfusion-mcp-tooling` before the first `mcp__enfusion-mcp__*` call.

## Test setup

Read `.claude/local/workbench.md` at the start of every test cycle. If it is missing, create it from `references/local-workbench-template.md` with every value `unset` except the defaults, ask the user once for `gproj`, `test_world`, and `play_smoke`, and write the answers. In a multi-mod repository `gproj` is a pattern (for example `per-mod: LHDF_*/LHDF_*.gproj`): use the project of the mod being changed. Never ask again for a value that is recorded.

## Dev loop

Run this after each coherent edit and repeat it until clean. Do not hand back after the first failure you can fix within scope.

1. **W1**: `wb_validate_scripts(gproj_path, addons_dir, timeout_seconds)` with `addons_dir` and `timeout_seconds` from the record. On `fail`, fix and rerun; run it once more after the last edit before the final report. Check the result: it must list the validated configurations and the mounted project folders must be the repository's, not packed Workshop copies (a pass for the wrong project looks the same).
2. **Sync the open editor**: `wb_connect` (it never launches Workbench). If Workbench is up and the diff has `.c` files, run `wb_reload(target: "scripts")` so the user's editor has the new code. If Workbench is down, skip this step and the smoke run. Do not call other `wb_*` tools while it is down: they launch Workbench as a side effect (a hook blocks them).
3. **W3 smoke**: only when `play_smoke` is `allowed`, Workbench is up, and `wb_state` reports edit mode. If `test_world` is not the open world, open it with `wb_open_resource` only when `open_test_world` is `yes`; otherwise report the smoke run as skipped. Then `wb_play`, poll `wb_state` until mode is play, wait about `smoke_seconds` (poll `wb_state` again rather than sleeping), `wb_stop`, and read `logs_summarize_errors(which: "workbench")`. A new script error or VM exception that points at a changed file counts as `fail`: fix it and loop. With `play_smoke: ask`, ask once per session before the first run.
4. **Report**: W1 verdicts (quoted), smoke result (`pass`, `fail`, `skipped: <reason>`), and the W2–W4 items still left for the user.

The smoke run shows that the addon loads and starts in Play without script errors. It does not show that the feature behaves correctly: W3 behaviour stays with the user unless the smoke run itself exercises it.

## Which items apply

| Trigger in the diff | Items |
|---|---|
| any `.c` file | W1 |
| `.et`, `.conf`, `.layout`, `.emat`, `.ent`, `.meta`, `.st` | W1, W2 |
| behaviour the user can observe | W3 |
| `RplProp`, `RplRpc`, `Rpc(`, `IsMaster`, `IsProxy`, `RplComponent`, `Replication.` | W4 |
| persistence: serializers, `PersistenceSystem`, Game Master save/load | W3 in the real game or a dedicated server (`arma-persistence`) |
| timers, queries, spawning loops, per-frame code | soak note (`arma-performance-budgets`) |

Nothing else triggers W4. A UI that only displays synchronized data is W3; it is W4 only if the UI itself writes that state.

## Checklist

- **W1 compile** — the implementer runs `wb_validate_scripts` and reports the verdict and errors, quoted. The tool spawns its own Workbench (the editor does not need to be open), and one run validates every configuration Workbench knows (WORKBENCH, PC, XBOX, PS4, PS5); there is no `config` parameter. In a multi-mod repository pass the repository folder as `addons_dir`, or the dependencies load from packed Workshop copies and the run checks those. If the run fails for an environmental reason (timeout, missing addon dependencies, or a stall: validation hangs intermittently, so retry once) rather than a script verdict, report `unknown` with the reason and hand W1 to the user: load the addon in Workbench, no new script compile errors. Compile errors are often reported on a line other than the cause (a bad attribute on a member is reported on the class line).
- **Server compile** — `wb_validate_scripts` never compiles a dedicated-server configuration, and the server compile has caught errors the Workbench run missed. The first dedicated-server start after a `.c` change is that check: read the server log (`server_logs` in the record) for script errors. It is part of W4, or of the persistence test when that runs first; until then report it as `unknown`.
- **W2 resource** — open each changed resource in its editor; no missing references; reload or restart if the resource type requires it. `find_broken_refs`, `world_validate_refs` and `ui_layout_validate` are pre-checks the implementer runs, but they do not replace opening the resource.
- **W3 behaviour** — the smallest in-editor scenario that exercises the change; expected vs observed. Use the recorded `test_world`; do not add test entities to it. The smoke run covers load and startup errors; the user covers behaviour (`w3_recipes`). Workbench Play has no `PersistenceSystem` (`GetInstance()` returns null), so anything that saves or loads must be checked in the game client or on a dedicated server with the mod loaded.
- **W4 multiplayer** — authority plus one proxy; observe the synchronized state on both. A dedicated server plus a client is the usual setup. Start and stop them only with the commands recorded as `server_start`, `server_stop` and `client_start` (the `server_launch`/`server_stop` MCP tools are denied: they do not know about servers started by those scripts). Check `tasklist.exe` first: the user may already be running the server or the client. If the commands are `unset`, W4 goes to the user.

## Verification levels

Releases are judged by the highest level reached, not by the checklist alone. Nothing is published below V3.

| Level | Meaning |
|---|---|
| V1 | W1 passes |
| V2 | V1 plus the smoke run (or the user's load in Workbench) without new errors |
| V3 | Behaviour checked in game (W3), persistence on a dedicated server where it applies |
| V4 | W4 with server and client (server compile clean), plus a soak run longer than the longest timer of any loaded mod |

## Reporting

Report one line per applicable item, with the `wb_validate_scripts` summary for W1, the verification level reached, and the `unknown` items as a short list for the user.

When the user reports a W2–W4 failure, the evidence (their observation plus `logs_summarize_errors` or `logs_tail` for that session) is fixed forward within the same change rather than opened as new work.

Record machine-specific procedures in the Notes section of `.claude/local/workbench.md` once they have worked for this repository.
