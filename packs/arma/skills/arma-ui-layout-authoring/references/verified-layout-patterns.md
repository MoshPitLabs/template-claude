# UI Evidence Checklist

Record evidence for:

- Existing project layout or vanilla layout used as the pattern.
- Exact widget classes and property sources.
- Styles, imagesets, fonts, and resource GUIDs.
- Widget-name contracts consumed by controller code.
- Focus order for keyboard/mouse and controller.
- State matrix: normal, loading, empty, unavailable, failure, selected, and dismissed.
- Resolution, aspect-ratio, safe-area, and text-expansion checks.
- Workbench editor and in-game scenario used for validation.

Do not store illustrative layout syntax here. Add examples only after they have opened successfully in Workbench against the target version.

## Verified facts

- UI textures need width and height divisible by 4 (DXT compression).
- Game Master entity icons are white glyphs on a transparent background (the UI tints them); the content-browser card picture is a separate field. Details in `arma-prefab-and-config-authoring/references/project-resource-patterns.md`.
- Localized text goes through string tables registered in the `.gproj`; same reference.
- Members of a menu or controller class that own a freshly created object must be `ref`; a weak member freed the shop's data at once and the window stayed on "Loading" with no error.
- 3D previews of vehicles leaked until relog (and WCS armament pods never rendered). Show vehicles with their Game Master picture; keep 3D previews for items.
- The vanilla multi-select attribute packs 31 flags into a 32-bit float, which holds only 24 exactly. Keep multi-select lists at 24 entries or fewer, matched by id; DLG's 93-entry list hid most entries after a Game Master edit and saved that state.
- Area mesh resolution has a maximum of 60; 64 throws and draws no border. Border colour through an inherited material with a colour override works.
- Store what a trader or list offers, on one axis, with a reset that always works, rather than what it hides.
