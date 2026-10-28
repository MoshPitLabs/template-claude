---
name: arma-release-check
description: Assess an Arma Reforger addon's release readiness — dependencies, manifests, broken references, script compile (Workbench and dedicated server), handler scripts excluded, verification level, publish order — without publishing anything.
argument-hint: "[mod or list of mods]"
disable-model-invocation: true
---

Assess release readiness as team-lead for:

$ARGUMENTS

Load `arma-enfusion-mcp-tooling` and `arma-workbench-workflow`. Run the read-only checks yourself and quote their results:

- `project_validate`, `list_dependencies`, `workshop_info`, `workshop_check_deps`, `workshop_validate_manifest` per mod. Walk the full dependency chain (`arma-third-party-mod-audit`): a missing deep link kills a dedicated server while Workbench validation passes.
- `find_broken_refs` for unresolved resource references; `refactor_merge_duplicate_guids` for GUID collisions.
- W1: if the latest `.c` change has no quoted `wb_validate_scripts` result, delegate a `/arma-test`-style W1 run to `senior-engineer`. The server compile counts only from a dedicated-server log after the last `.c` change; otherwise it is `unknown`.
- Handler scripts: whether `Scripts/WorkbenchGame/EnfusionMCP/` (or a linked `Scripts/WorkbenchGame`) exists in a mod being published. Report it as `fail` with removal as a manual step; do not delete it and never run `wb_cleanup`.
- Verification level per mod (V1–V4, `arma-workbench-workflow`). Nothing is published below V3; persistence needs a dedicated-server restart test, periodic work a soak run.
- Versions: changelog versions match the Workshop versions; list the mods to publish in dependency order. First publishes go through the Workbench dialog (description and summary are entered there; preview images under 2 MB).
- PR body: when versions bump, check the PR body carries the version and patch-note sections the repository's PR template and `CLAUDE.md` require (`Pull requests` in `.claude/rules/team.md`).

Do not publish, upload, version, tag, commit, or delete. Return pass, fail, or unknown for: dependency integrity, script compilation, resource validation, handler scripts excluded, verification level, multiplayer, persistence, documentation, and publish order. List the exact manual Workbench and Workshop steps still required.
