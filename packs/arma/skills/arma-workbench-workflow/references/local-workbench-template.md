# Workbench Test Setup (template)

Copy to `.claude/local/workbench.md` and fill it in once. Agents read it on every test cycle instead of asking. `sync-claude-config.sh` never overwrites `.claude/local/`. Leave a value as `unset` rather than guessing; an agent that needs an unset value asks the user once and writes the answer here.

```text
gproj:            unset   # repository-relative .gproj, or a pattern for multi-mod repositories: per-mod: LHDF_*/LHDF_*.gproj
test_world:       unset   # project-relative .ent used for W3 smoke runs; never a world the user edits
play_smoke:       ask     # allowed | ask | off  — may an agent press Play (wb_play/wb_stop) in test_world?
open_test_world:  no      # yes = agent may wb_open_resource(test_world) itself; no = the user opens it
smoke_seconds:    20      # how long to stay in Play before reading logs
validate_timeout: 100     # wb_validate_scripts timeout_seconds (10-600); raise for large projects
addons_dir:       unset   # wb_validate_scripts addons_dir for multi-mod repositories: the repository folder; none for a single addon
server_start:     unset   # command that starts the local dedicated server, e.g. cmd.exe /c "E:\...\_server\start_server_dev.bat"
server_stop:      unset   # command that stops it
client_start:     unset   # command that starts a game client connected to it
server_logs:      unset   # folder holding the dedicated server's console/script logs (the MCP log tools do not read it)
w3_recipes:               # behaviour checks the user runs by hand, one per feature
  - unset
mp_setup:         unset   # how W4 is run for this repository (server config, client count, profiles)
```

## Notes

Record machine-specific facts here once they have worked for this repository: reload quirks, dependency load order, noisy log lines to ignore in smoke runs, handler-script links (for example a `Scripts/WorkbenchGame` junction that must be unlinked before publishing).
