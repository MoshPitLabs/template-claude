---
name: wow-toc-and-loading
description: Load before editing a WoW addon's TOC files, adding or moving Lua/XML files, adding flavor TOCs, load-on-demand modules or dependencies, or changing which event the addon initializes on.
---

# WoW toc and loading

The client picks the TOC per flavor: a suffixed file (`<Addon>_Mainline.toc`, `_Vanilla.toc`, `_Classic.toc` and other suffixes the pinned build recognizes) wins over `<Addon>.toc`. The folder name, not the `## Title`, is the addon's name. Every TOC a flavor loads must list every file in load order, directly or through an XML `<Script>`/`<Include>`. `## Interface` may list several comma-separated numbers on builds that support it; keep each number equal to the pin in `.claude/local/wow.toml`.

Common fields: `## Title`, `## Notes`, `## Version` (often `@project-version@`), `## SavedVariables`, `## SavedVariablesPerCharacter`, `## Dependencies` (alias `RequiredDeps`), `## OptionalDeps`, `## LoadOnDemand`, `## LoadWith`, `## IconTexture`, `## AddonCompartmentFunc`, `## X-*` metadata. Verify any field newer than the oldest flavor in scope against the wiki's TOC format page before relying on it.

Startup order: each file runs at load with `...` = addon name and the private table. Then `ADDON_LOADED` fires with this addon's name (SavedVariables now exist), later `PLAYER_LOGIN` (most game data available), then `PLAYER_ENTERING_WORLD` on every loading screen (`isInitialLogin`, `isReloadingUi`). Filter `ADDON_LOADED` by name and unregister it once handled. Load-on-demand addons load through `C_AddOns.LoadAddOn` (older flavors: the global `LoadAddOn`) and must not assume login events will fire again.

A dependency changes load order and can stop the addon loading when absent; prefer `OptionalDeps` plus a runtime check unless the dependency is truly required.
