# Arma Reforger (Enfusion) domain rules

Synced from `template-claude` (`packs/arma/`). Fills the extension points of `.claude/rules/team.md` for Arma Reforger mod repositories. Project specifics belong in this repository's `CLAUDE.md` or `.claude/local/`.

## Intake

- Locate the `*.gproj` of the mod in scope.
- When the work will be tested, read `.claude/local/workbench.md` and copy `test_world` and `play_smoke` into the brief. If the file is missing, `senior-engineer` creates it on its first test.
- For lookups that read a lot (vanilla source, large logs, many GUIDs), delegate to `scout` and carry its citations into `Verified symbols so far`. Small checks (one `api_search`, one `logs_summarize_errors`) the lead may run with the read-only enfusion-mcp tools after loading `arma-enfusion-mcp-tooling`.

## Tier triggers

`design-gated` when the work touches replication, persistence, a vanilla class not yet modded here, GUID or resource moves, or addon dependencies. Any of those also rules out `minor`.

## Hard-stop triggers

A GUID or resource move not in the brief; synchronized or persisted state with no approved design; a change to a world the brief does not name; an engine symbol that cannot be verified.

## Brief domain fields

```text
  Mod: <gproj of the mod being changed>
  Test setup: <test_world and play_smoke from .claude/local/workbench.md, or "not recorded">
  Verified symbols so far: <symbol — source path:line or wiki URL, from scout or earlier work>
```

`Constraints` always names the GUIDs, resource locations, and vanilla classes that must not change. `Acceptance` names the W1–W4 items that apply.

## Domain rules

- Enfusion and Enforce Script are thin in model training data. Never invent a class, method, attribute, or config property. Prefer an existing `SCR_*` implementation over first principles.
- An unverifiable symbol is a hard stop, never a `TODO(verify)` left in code.
- Only `wb_validate_scripts` proves a `.c` file compiles; there are no LSP diagnostics. Quote verdicts, do not paraphrase.
- Modding goes through `modded class`, prefab inheritance, and inherited `.conf`; never copy vanilla files.
- `.meta` GUIDs are identity. Do not hand-write `.et` prefabs (build them in Workbench); do not hand-edit `.xob`/`.edds`.
- The world open in Workbench belongs to the user: never `wb_save`, never leave entities in it. Test in `test_world` from `.claude/local/workbench.md`.
- Never edit, move, or delete `Scripts/WorkbenchGame/EnfusionMCP/` (enfusion-mcp's handler scripts); flag them before any publish.
- Never start, stop, or change Workbench, worlds, or servers from a read-only role (`team-lead`, `staff-engineer`, `security-engineer`, `project-manager`, `ux-designer`, `scout`). `sdet` and `distinguished-engineer` have the full enfusion-mcp server because they run the dev loop; the same limits apply to them as soon as their mode or role does not call for a change (`distinguished-engineer` in `design` or `investigate` mode).

## Skills by work type

Load before touching the file or deciding the topic:

| Work | Skill |
|---|---|
| Any `mcp__enfusion-mcp__*` call (first call of the session) | `arma-enfusion-mcp-tooling` |
| `.c` files | `arma-enforce-script-conventions`; plus `arma-modded-class-overrides` for any `modded class` |
| `.et`, `.conf`, `.meta`, `.st`, resource references, GUIDs | `arma-prefab-and-config-authoring` |
| `.layout`, imagesets, HUDs, menus, dialogs, string tables for UI | `arma-ui-layout-authoring` |
| State synchronized between authority and proxies, RPCs (W4 applies) | `arma-replication-and-networking` |
| Saving or loading state | `arma-persistence` |
| Timers, `CallLater`, per-frame updates, entity queries, spawning loops, lag reports | `arma-performance-budgets` |
| Third-party Workshop mods, dependency lists, bug attribution to vanilla vs mod | `arma-third-party-mod-audit` |
| Testing, reporting checks, recording results | `arma-workbench-workflow` |
| Lookups (symbols, vanilla patterns, GUIDs, logs) | `arma-scout-lookups` |

## Verification

Verify each engine symbol or resource property you introduce: `api_search` to locate it, then read the declaration with `game_read` (vanilla) or `Read` (project), or the Bohemia wiki page (`wiki_search`, `wiki_read`). A search hit alone is not a source. Symbols already used in the project count as verified; so do the entries under `Verified symbols so far`.

## Dev loop

From `arma-workbench-workflow`:

1. Read the relevant code and the nearest vanilla (`SCR_*`) implementation of the same pattern (`game_browse`, `game_read`).
2. Edit files with Edit/Write; use enfusion-mcp file tools (`prefab`, `wb_prefabs`, `layout_create`, `wb_localization`) where the skill says Workbench must produce the resource.
3. W1: `wb_validate_scripts` (with `addons_dir` from `.claude/local/workbench.md`). `verify-gate.sh` blocks finishing while `.c` edits have no later run.
4. `wb_connect` + `wb_reload`, then the W3 smoke run in `test_world` when `play_smoke` allows it.
5. Pre-checks that apply: `find_broken_refs` for resources, `ui_layout_validate` for layouts.
6. Fix failures within scope and loop until clean or blocked. List the remaining W2–W4 items.

`sdet` (test changes) and `distinguished-engineer` in `deep-impl` mode run the same loop for the `.c` files they change.

`/arma-dev` and `/arma-test` run `senior-engineer` in direct mode. A request that hits a `Tier trigger` stops before editing and points to `/arma-feature`.

## Design checklist

1. Read the affected code, resources, and prior ADRs.
2. Load the skill for the decision: `arma-replication-and-networking`, `arma-persistence`, `arma-modded-class-overrides`, `arma-prefab-and-config-authoring`, `arma-performance-budgets`, `arma-third-party-mod-audit`.
3. Find the comparable vanilla pattern (`game_browse`, `game_read`, `script_class_hierarchy`, `script_overrides`, `script_find_rpc_handlers`) and prefer it over a new design. Minimise overrides; prefer inheritance.
4. Verify every engine symbol the design names (see `Verification`).
5. For replication, fill the evidence matrix in `arma-replication-and-networking/references/verified-authority-patterns.md`.
6. The ADR names the exact classes, methods, attributes, and files the implementer will touch.

## Review checklist

- Override compatibility: base calls, repeated `BaseContainerProps`, vanilla subclasses that skip `super`.
- Prefab and config inheritance, GUID identity, `.meta` presence.
- Authority and proxy behaviour where W4 applies; server-side validation of every client request.
- Persistence rules where state is saved; the performance rules where timers, queries, or spawning loops changed.
- The runtime pitfalls in `arma-enforce-script-conventions/references/verified-language-patterns.md` (weak members, loop locals, statics, role at init).
- A `.c` diff without a quoted W1 result is `conditional` until one is provided.

## Lookups

Load `arma-scout-lookups`; it maps each question type (symbols, vanilla patterns, overrides and RPCs, resources and GUIDs, logs) to the enfusion-mcp tools that answer it.

## Acceptance evidence

- W1 quoted and not `fail` for any `.c` change.
- W3 smoke not `fail`.
- Fix-forward evidence comes from `logs_summarize_errors` (or `logs_tail`) for the session that failed.
- The remaining W2–W4 items (`arma-workbench-workflow`) go to the user; they do not block acceptance, but releases need V3 (`/arma-release-check`).
- Common PR pattern, not a requirement: player-facing notes are plain language without file names or code identifiers, and a mod version bump (a new changelog version heading) needs a per-mod version line.

## Domain report fields

| Agent | Fields |
|---|---|
| `senior-engineer` | `W1 result: <quoted verdict and validated configurations>`; `Server compile: pass \| fail \| unknown (no dedicated-server start since the change)`; `W3 smoke: pass \| fail \| skipped: <reason>`; `Pre-checks (find_broken_refs, ui_layout_validate):`; `Remaining checklist items for the user (W2–W4):` |
| `staff-engineer` | `Replication, persistence, compatibility, and GUID impact:`; `Applicable checklist items (W1–W4):` |
| `team-lead` | `W1 (Workbench) / server compile:`; `W3 smoke:`; `Verification level reached (V1–V4):`; `Checks for you (W2–W4):` |
| `sdet` | `W1 result:` and `W3 smoke:` as for `senior-engineer` when it changed `.c` files; `Checks only the user can run (W2–W4):` |
| `distinguished-engineer` | in `deep-impl`, the `senior-engineer` fields; otherwise `Verified symbols:` for every engine symbol a conclusion relies on |
| `security-engineer` | `Replication and authority trust boundaries reviewed (server-side validation of client requests):` |
| `ux-designer` | `Layouts and imagesets checked with ui_layout_validate / layout tools, or "not verified":` |
| `project-manager`, `scout` | none |

## Workflows

`/arma-dev`, `/arma-test` (senior-engineer, direct mode), `/arma-review` (staff-engineer), `/arma-feature`, `/arma-bug`, `/arma-release-check`, `/arma-handoff` (team-lead).
