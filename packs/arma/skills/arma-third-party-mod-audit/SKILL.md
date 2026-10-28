---
name: arma-third-party-mod-audit
description: Load before adding a third-party Workshop mod to a scenario or dependency list, writing a patch or compatibility mod for one, or attributing a bug ("X disappears", "slot refuses items", "invisible vehicles") to vanilla versus a loaded mod.
---

# Third-Party Mod Audit

Each check below comes from a DLG incident with a Workshop mod.

## Before a mod joins the baseline

1. **File-list collisions.** Compare the mod's file list with the map's and every other loaded mod's (`list_resources`, `workshop_info`). A bicycle mod shipped a leftover terrain at the map's paths and removed terrain tiles; a Game Master structures mod shipped 186 prefabs at vanilla paths under its own GUIDs and replaced core editor configs. Replaced vanilla files are a reason to refuse; small config deltas that stack are fine.
2. **Full dependency chain.** Walk every link to the leaves (`workshop_check_deps`, `list_dependencies`). A chain deeper than the scenario's list killed the server at start while Workbench validation passed.
3. **Models present.** A listed prefab needs its model mod in the baseline (WCS Vehicles ships prefabs without models).
4. **Timers and queries.** Read its periodic scripts (`arma-performance-budgets`): a whole-map query every five minutes froze the live server.
5. **Garbage rules.** Mods can change garbage collection (WCS Core deleted corpses and bought vehicles after minutes). Garbage rules are set by the scenario; owned vehicles are blacklisted.
6. **Licence.** Assets under the Arma Public License cannot be relicensed or copied into your mods without checking the licence first.

## Attributing behaviour

Read the mod's files before changing anything. The RPG-only second weapon slot was WCS, not vanilla, and the inventory screen had its own compatibility check besides the storage. State the source file that causes the behaviour in the report.

## Patch mods

- Generic mods reference vanilla only. Everything specific to a third-party mod lives in its patch mod from the start.
- A patch mod may hold all integration for its third-party mod; its README says so.
- Optional links between your own mods use the provider pattern (an interface in the core mod), not a hard dependency.
- A replacement of a third-party method without `super` logs the third-party version it was written against and is rechecked on every update of that mod.
- Removed mods stay removed; the README lists them with the reason.
