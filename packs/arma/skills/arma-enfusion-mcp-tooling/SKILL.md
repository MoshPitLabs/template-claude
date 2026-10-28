---
name: arma-enfusion-mcp-tooling
description: Load before calling any enfusion-mcp tool (`mcp__enfusion-mcp__*`) — which tool answers which question, which ones change files or the open Workbench world, and the safety rules for the user's worlds and the EnfusionMCP handler scripts.
---

# enfusion-mcp Tooling

enfusion-mcp indexes the vanilla game data, the Bohemia wiki, and the addon projects, and drives a running Workbench through handler scripts in `Scripts/WorkbenchGame/EnfusionMCP/`. It is the only source of compile evidence (`wb_validate_scripts`) and the first source of engine-API evidence. Tools are named `mcp__enfusion-mcp__<tool>`; the short names below drop that prefix.

Tools that change files bypass the Edit/Write permission rules, so treat them as edits and keep them within the brief's `Paths`.

## Which tool for which question

| Question | Tools (read-only, allowed without asking) |
|---|---|
| Does this class / method exist, what is its signature? | `api_search`, `script_class_hierarchy`, `script_extract_interface`, `game_read` (vanilla `.c`), `wiki_search` / `wiki_read` |
| How does vanilla do X? | `game_browse`, `game_read`, `component_search`, `asset_search` |
| Which `modded class` chains or RPC handlers does a project have? | `script_overrides`, `script_find_rpc_handlers`, `script_analyze`, `script_lint` |
| What does this prefab / config contain and inherit? | `game_read`, `inheritance_chain`, `component_search` |
| Which resource is this GUID? Who references it? | `resolve_guid`, `find_references`, `find_broken_refs`, `find_unused_resources`, `refactor_merge_duplicate_guids` (diagnose only) |
| Does the addon compile? (W1) | `wb_validate_scripts` (one run covers every Workbench configuration; `addons_dir` = repository folder in multi-mod repositories) |
| What went wrong in the last run? | `logs_list`, `logs_summarize_errors`, `logs_tail`, `logs_filter` |
| Is the project / manifest sound? | `project_validate`, `list_dependencies`, `workshop_info`, `workshop_validate_manifest`, `workshop_check_deps` |
| Is Workbench up, and what is open? | `wb_connect`, `wb_diagnose`, `wb_state`, `wb_entity_list`, `wb_entity_inspect`, `wb_validate`, `world_validate_refs`, `world_compose_summary`, `world_diff` |
| UI resources | `ui_layout_inspect`, `ui_layout_validate`, `ui_styles_inspect`, `ui_localization_audit`, `ui_extract_strings` |
| Scenario, terrain, server config | `scenario_inspect`, `scenario_diff`, `terrain_inspect`, `terrain_navmesh_status`, `wb_terrain`, `server_validate_config`, `server_mod_list`, `server_scenario_picker`, `server_health_probe` |

A symbol found only by `api_search` is verified once you have read its declaration (`game_read`) or its wiki page; the search hit alone is not a source.

## Tools that change things

Allowed without asking (dev loop): `wb_validate_scripts` (spawns its own headless Workbench and exits), `wb_reload`, `wb_play`, `wb_stop`, `wb_entity_select`.

Ask every time:

- **Files:** `script_create`, `script_format`, `config_create`, `layout_create`, `prefab`, `wb_prefabs`, `wb_localization`, `wb_resources`, `wb_script_editor`, `faction_create`, `building_setup`, `scenario_create`, `scenario_create_conflict`, `scenario_apply_template`, `scenario_clone_area`, `game_duplicate`, `animation_graph`, `server_config`, `mod`, `project`, `refactor_move_resource_path`, `refactor_replace_guid`, `refactor_rename_project_id`, `refactor_normalize_dependencies`. The `refactor_*` writers rewrite GUIDs and paths across the project: design-gated, and only when the brief names the move.
- **The open world:** `wb_entity_create`, `wb_entity_modify`, `wb_entity_duplicate`, `wb_entity_delete`, `wb_component`, `wb_layers`, `wb_clipboard`, `wb_execute_action`, `wb_undo_redo`, `wb_open_resource`, `wb_projects`.
- **Processes:** `wb_launch`, `wb_cli_run`, `wb_build_data`.

Denied: `wb_save`, `wb_cleanup`, `server_launch`, `server_stop`.

## Safety rules

1. **The user's worlds.** Never call `wb_save`. Do not leave entities in a world the user edits: an entity that exists when the user saves is written into their layer and may not be removable from the editor afterwards. When a Workbench step needs an entity (for example building a prefab), use the `test_world` from `.claude/local/workbench.md` (or a world the user names), say so before creating it, and delete it before handing back.
2. **Handler scripts.** Never edit or delete `Scripts/WorkbenchGame/EnfusionMCP/`; `wb_cleanup` (which removes them) is denied. `wb_launch` copies the handlers into the project it launches, so launch only the `*.gproj` of the mod being worked on. If the repository links `Scripts/WorkbenchGame` to a shared folder (see the Notes in `.claude/local/workbench.md`), unlink it before publishing. Two projects that both contain the handlers must not depend on each other (duplicate classes).
3. **Play mode is not the game.** Workbench Play has no `PersistenceSystem`; save/load behaviour needs the game client or a dedicated server.
4. **Report what ran.** Quote the tool's verdict (for example `Script validation successful.`) rather than paraphrasing it as a pass.
5. **Probe before touching Workbench.** Every `wb_*` tool except `wb_connect`, `wb_diagnose` and `wb_validate_scripts` launches Workbench when it is not running. Call `wb_connect` first; if Workbench is down, use only `wb_validate_scripts` and the file and log tools. The `wb-launch-guard` hook denies the others while Workbench does not answer.
6. **Timeouts.** `wb_validate_scripts` has no `config` parameter (it was dropped: Workbench read `-config` as a server config file) and defaults to 100 s. For large projects, pass `timeout_seconds` from `validate_timeout` in `.claude/local/workbench.md` (at most 600; the server's `timeout` in `.mcp.json` is 600000 ms to match). A `⏱ TIMEOUT` verdict is `unknown`, not `fail`.
7. **Servers.** Start and stop dedicated servers and clients only through the commands recorded in `.claude/local/workbench.md`, after checking `tasklist.exe`.
8. **Context.** Lookups that read a lot of vanilla source (`game_read` of large files, log tails) belong in the `scout` agent when you are coordinating; it returns citations instead of file dumps.

The compile, reload, and Play-smoke cycle is defined once in `arma-workbench-workflow` (Dev loop).
