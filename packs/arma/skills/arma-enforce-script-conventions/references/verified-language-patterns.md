# Enforce Script Verification Notes

Use this file as a checklist, not as an API catalog.

## Source order

1. Existing project implementation that already compiles.
2. Unpacked vanilla Arma Reforger script from the same game version (`game_read`, `api_search`).
3. Bohemia Interactive Community Wiki documentation (`wiki_search`, `wiki_read`).

For each adopted pattern, record the source path or URL in the final report. Confirm the declaration, parameter types, return type, attributes, visibility, lifecycle context, and whether base behavior must be called.

## Reject as evidence

- A symbol remembered by the model.
- A similarly named API from another Bohemia title.
- Search snippets without their declaring source.
- An IDE suggestion or lack of diagnostics.
- Pseudocode presented as compilable Enforce Script.

Add a pattern below only after it has compiled in Workbench against the target game version. Example paths name the repository they come from (`DLG_*` = dlg-mod-suite, `LHDF_*` = lhdf-dynamic-framework); in another repository, find the equivalent in your own code.

## Verified pitfalls: compile errors

Each item was hit and resolved in a real addon build (Arma Reforger, 2026-09/10).

- **One bracket per member.** `[Attribute(...)]` and `[RplProp(...)]` on separate lines above one member fails to compile with "Expected '[', not a 'class'", reported on the *class* line rather than the member. Combine them: `[Attribute(defvalue: "0", desc: "..."), RplProp(onRplName: "OnSettingsReplicated")]`. Example: `LHDF_GameMasterAdditions/Scripts/Game/LHDF_GameMasterAdditions/SafeZone/LHDF_SafeZoneComponent.c`.
- **Plausible names that do not exist.** `Math3D.IntersectionPointBox` does not exist. Treat any math/geometry helper as unverified until its declaration is read with `game_read` or `api_search`.
- **Bit and integer operations in a float expression.** `m_vMin[1] + (cells[i] & 0xFFFF) * 0.1` fails with "Unknown operator" or "Incompatible parameter '0xFFFF'": the expression is typed float from its left side. `%` inside a float expression does not compile either. Do the integer work in an `int` local first; read array elements into an `int` before shifting. `Math.Clamp` with hex literals fails the same way; use `Math.ClampInt`. Example: `LHDF_Core/Scripts/Game/LHDF_Core/World/LHDF_TerrainGrid.c`.
- **Long string concatenation.** A very long `a + b + c + ...` fails with "Formula too complex". Build the string with `+=` over several statements.
- **Reserved words as names.** `out`, `inout`, `notnull`, `ref` and `event` are keywords. `vector out = ...;` fails with "Broken expression (missing ';'?)" at that line; `event` cannot name a parameter.
- **Workbench validation is not the server compile.** `wb_validate_scripts` checks WORKBENCH, PC and console configurations in one run but never a dedicated-server configuration; the server compile has caught errors the Workbench run missed. Read the server log at the first dedicated-server start after a `.c` change. The validation log lists the mounted project folders: check that the project you changed is among them and comes from the repository (pass `addons_dir` in multi-mod repositories), because a pass for the wrong project looks the same. Validating through the scenario project mounts every project it depends on.

## Verified pitfalls: runtime behavior

- **Members without `ref` are weak.** A member that holds a freshly created object must be `ref`, or the object is freed at once. In DLG the shop stayed on "Loading" with no error because of this.
- **`continue` does not end a `switch` case.** Use `if` / `else` chains when a case must skip the rest of a loop body.
- **Loop locals keep their value.** A local declared inside a loop body without an initialiser is not reset on the next pass: `LHDF_BuildingOpening opening;` stayed set after the first opening and later children overwrote it; `float sum;` in a `for` kept adding the previous pass's values. Always initialise loop locals (`= null`, `= 0`, `= string.Empty`, `= vector.Zero`), also those passed as `out` that the callee sets only sometimes. Example: `LHDF_Core/Scripts/Game/LHDF_Core/World/LHDF_BuildingCatalog.c`.
- **Attribute `enums:` providers run while scripts load**, before statics exist. Reading a static array there is a null access in Workbench. Build the list locally inside the provider.
- **Statics outlive the world.** Static collections (registries, module lists, providers) are not cleared between worlds and leak into the next session. Own state in a world system or a component instead.
- **Role at init.** `Replication.IsServer()` is false during world load. Decide the role one frame after init; skip work only on known clients.
- **Building parts on a dedicated server.** A placed building's child entities (windows, doors, entries) have no prefab data there (`GetPrefabData()` is null) and `FindComponentData` on the building answers null, though both work in Workbench. Read component data from the prefab source (`SCR_BaseContainerTools.FindEntitySource` / `FindComponentSource`) and tell parts apart by their mesh path (`GetVObject().GetResourceName()`, `Assets/Structures/BuildingsParts/Windows|Doors|Entry`). The prefab source's own children cannot place socketed parts: their `coords` are `0 0 0`. Example: `LHDF_Core/Scripts/Game/LHDF_Core/World/LHDF_BuildingCatalog.c`.
- **Map entities.** Vanilla map buildings carry an `RplComponent` (from `Building_Base.et`), so "has no RplComponent" does not identify an entity placed in the world file. Use `IEntity.IsLoaded()` (true for entities loaded from the world). Example: `LHDF_GameMasterAdditions/Scripts/Game/LHDF_GameMasterAdditions/Hider/LHDF_MapEntityHiderFilter.c`.
- **Editor deletion order.** Deleting an AI group right after despawning its members throws in the editor. Delete the members first and the group entity later.

## Editing files with tools

When a script edits `.c` files (Python, sed), preserve line endings: in Python open with `newline=''`. A stray carriage return inside a comment once became a line break and broke the class.
