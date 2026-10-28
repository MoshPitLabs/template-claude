---
name: arma-ui-layout-authoring
description: Load before designing or editing Arma Reforger `.layout` files, widget hierarchies, HUDs, menus, dialogs, imagesets, Game Master icons, string tables, focus navigation, or accessibility behavior.
---

# UI Layout Authoring

## Scope by change size

- **Edit to an existing layout** (label, position, style, imageset swap): make the change, keep widget names and GUIDs, report W2/W3.
- **New screen, menu, dialog, or HUD element**: also define the states that actually occur (at minimum normal, empty/unavailable, focus), controller and keyboard navigation, and readable contrast. Skip states the feature cannot reach. Report the state list and focus order with the change.

## Workflow

1. Discover the addon's actual UI paths; do not assume a top-level `UI/` directory exists.
2. Inspect existing layouts, styles, imagesets, UI prefabs, widget names, and controller code before proposing a hierarchy (`ui_layout_inspect`, `ui_styles_inspect`, `game_browse` for vanilla layouts).
3. Verify every widget class, property, event, and resource reference against project resources, vanilla source, or the Bohemia Interactive Community Wiki.
4. Build windows as real menus with a layout, not as widgets created from script inside a configurable dialog. A script-built window in DLG had no controller focus, a dead confirm button, and combo lists that opened outside the dialog root.
5. Specify keyboard/mouse and controller focus order and recovery behavior.
6. Account for readable contrast, text expansion, representative resolutions, safe areas, and non-color-only status cues.
7. Keep gameplay authority and data mutation outside layout resources. Data the UI displays comes from the server or the shipped catalog; a UI that writes synchronized state is W4 and needs a replication decision (`arma-replication-and-networking`).
8. Preserve resource GUIDs and inheritance. Do not duplicate a vanilla layout when a minimal inherited resource is viable.
9. Localized text goes through string tables (`ui_extract_strings` finds hardcoded strings, `ui_localization_audit` checks coverage).

Read `references/verified-layout-patterns.md` before authoring. Only the patterns recorded there have been verified; any other widget or property still needs a source.

## Verification

Run `ui_layout_validate` on every changed layout. Then the user opens the resource in the Workbench UI editor (W2), and the change is exercised in-editor or in-game across its states (W3). Network-fed displays require authority/proxy validation when the UI writes state (W4).
