---
name: wow-api-lookups
description: Load before verifying a World of Warcraft API function, event and its payload, widget method, template, CVar or constant, or before depending on a flavor's build — checks the Blizzard UI source at the pinned tag and version-matched wiki pages.
---

# WoW api lookups

Read `.claude/local/wow.toml` for the flavors, `## Interface` numbers, builds and the local UI source (template: `references/local-wow-template.toml`). Confirm the local clone of https://github.com/Gethe/wow-ui-source is at the tag for the flavor in question (read `<ui_source>/.git/HEAD`, or `git -C <ui_source> describe --tags` in a role with a full shell; if it is not, say so and ask for it to be checked out); a `live` checkout answers nothing about classic flavors.

Order of sources, per flavor:

1. `Interface/AddOns/Blizzard_APIDocumentationGenerated/*.lua` in the UI source: function names, arguments, returns, nilability, events and payloads, enums. The in-game `/api` command shows the same data.
2. Blizzard's own call sites (`rg -n 'C_Foo.Bar\(' <ui_source>`) for usage, templates (`*.xml`), mixins and secure handling. Functions not in the generated docs (older globals, widget methods) are confirmed this way or by the wiki.
3. warcraft.wiki.gg (`/wiki/API_<Name>`, `/wiki/<EVENT_NAME>`, `/wiki/Widget_API`) when the page's patch notes cover the pinned build. Ketho's `vscode-wow-api` annotations are generated from the same documentation and are a convenient index, not a separate authority.

Check deprecations (`Blizzard_Deprecated*` folders and `C_` namespace moves, for example `GetAddOnMetadata` → `C_AddOns.GetAddOnMetadata`) and whether the function is protected, needs a hardware event, or returns restricted values in combat on the pinned build.

Do not trust a "deprecated → replacement" table from a guide, forum or this repository without the source: community maps of retail and Forever changes contain wrong entries and describe early builds. Look up the old global and the `C_` function in the generated documentation (or the wiki page's removal note) for each flavor, read the return shape (table or multiple values), and note when data loads asynchronously and can be `nil` (request it, then wait for the `*_DATA_LOAD_RESULT` event). A page that says "Removed in patch 12.0" means the function is gone on Mainline-family clients, not on Classic flavors.

Return exact signatures, the flavor and build, file path and line at the tag or the URL, and what is still unverified at runtime. Never invent an event, payload argument, widget method, template or CVar to fill a gap.
