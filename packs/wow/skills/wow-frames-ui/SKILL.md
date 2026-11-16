---
name: wow-frames-ui
description: Load before building or reviewing WoW addon frames, XML layouts, templates and mixins, options or settings panels, Edit Mode integration, minimap or compartment buttons, fonts, scaling or localization.
---

# WoW frames ui

Create frames with `CreateFrame(type, name, parent, template)`; give a global name only when something must find the frame by name (and prefix it with the addon name). Prefer mixins (`CreateFromMixins`, `Mixin`, XML `mixin=` with `OnLoad` methods) and frame pools for repeated rows instead of creating frames per update. Frames are never garbage-collected: reuse them.

Verify every template and widget method against the UI source at the pinned tag (`wow-api-lookups`); templates differ between flavors and change between patches (for example `BackdropTemplate` became required for backdrops in 9.0). Options panels on current clients use the Settings API (`Settings.RegisterVerticalLayoutCategory`, `Settings.RegisterCanvasLayoutCategory`, `Settings.RegisterAddOnCategory`); older flavors may only have `InterfaceOptions_AddCategory`. Feature-detect.

Blizzard's Edit Mode and its frames taint easily; do not reparent or move Blizzard Edit Mode frames from insecure code. Use a library the repository already embeds (such as LibEditMode) or keep the addon's frames separate. Anything that is or contains a protected frame follows `wow-secure-and-taint`.

Strings shown to players go through the addon's locale table (AceLocale or a `L` table keyed by `GetLocale()`); do not concatenate translated fragments. Layout checks (anchors, scaling with UI scale, text overflow in long locales) are in-game checks for the user.
