# Override Evidence Checklist

Capture these facts for each override:

- Original class and source path or wiki URL.
- Exact original method declaration.
- Comparable verified `modded class` source.
- Base-call behavior and ordering.
- Execution context: authority, proxy, owner, or Workbench-only.
- Known side effects and state touched.
- Other likely mod extension points.
- Workbench scenario that exercises the override.
- Multiplayer scenario when state or behavior can diverge.

Add a pattern below only after it has compiled in Workbench against the target game version. Example paths name their repository (`DLG_*`, `LHDF_*`).

## Verified patterns

- **Repeat the attribute line on modded config classes.** When vanilla declares `[BaseContainerProps(...), ...] class X`, a `modded class X` must repeat that exact attribute line above it. Without it scripts still compile, but the class drops out of the container registry and every config or prefab that uses it fails at load with "Unknown class 'X'" (seen with `SCR_VotingEditorIn` in `GameMode_Editor.et`). This is a W2/W3 failure, not a W1 one.
- **Append through modded classes instead of overriding vanilla configs.** To add entries to a vanilla config-driven list (Game Master content browser, GM attributes, serializers), mod the class that reads the list and append at the end of its method, calling `super` first. The addon then overrides no vanilla `.conf`, so it stacks with other mods. Examples: `LHDF_Core/Scripts/Game/LHDF_Core/Editor/LHDF_ContentBrowserEditorComponent.c`, `LHDF_Persistence/Scripts/Game/LHDF_Persistence/LHDF_AIGroupLoad.c` (mods `SCR_EditableEntityComponentSerializer`).
- **Some vanilla methods cannot be chained.** A vanilla method whose own subclasses override it without calling `super` (building damage handling, some voting classes) cannot be extended by chaining: your override runs, but the subclass path skips it. Read the vanilla overrides (`script_overrides`, `script_class_hierarchy`) before relying on a chain.
- **Several mods appending to one list.** When more than one of your mods appends to the same vanilla list (attributes, placing lists), the order depends on load order. Route them through one registry with sort keys in the shared core mod.
- **Replacing a third-party method without `super`.** If an override replaces a third-party mod's method instead of chaining it, log the third-party version it was written against and recheck it on every update of that mod; an update can break it silently.
