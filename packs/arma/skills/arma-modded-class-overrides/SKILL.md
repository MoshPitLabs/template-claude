---
name: arma-modded-class-overrides
description: Load before adding or reviewing `modded class`, inherited behavior changes, or compatibility-sensitive overrides of vanilla Arma Reforger classes.
---

# Modded Class Overrides

## Workflow

1. Find the original declaration (`game_read`, `script_class_hierarchy`) and at least one verified modded implementation of comparable behavior. `script_overrides` lists the `modded class` chains the project already has.
2. Confirm the target can be modded and verify the exact method signature and lifecycle.
3. Explain why inheritance or composition cannot meet the goal with a smaller compatibility surface.
4. Identify base calls, ordering assumptions, side effects, and interactions with other mods extending the same class.
5. Override only the required behavior. Preserve base behavior unless the approved design explicitly replaces it.
   Check that vanilla's own subclasses call `super` in the method you chain (see the reference).
6. Do not copy an entire vanilla class into the addon.
7. Stop if the original declaration or method contract cannot be verified.

## Review questions

- Does this override use an exact verified signature?
- Is a base call required, optional, or intentionally omitted?
- Does the modded class repeat vanilla's `[BaseContainerProps(...)]` line when vanilla has one?
- Does load order or another mod's override affect behavior?
- Is state changed on the correct authority?
- Can prefab/config inheritance solve the problem with less script interception?

Read `references/verified-override-patterns.md` before implementation. It lists the patterns verified in Workbench; record new source evidence in the final report.

## Definition of done

The override is minimal, compatibility risks are explicit, W1 passes, and the affected behavior runs in-editor (W3). Multiplayer-sensitive overrides also pass authority/proxy verification.
