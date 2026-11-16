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

Return exact signatures, the flavor and build, file path and line at the tag or the URL, and what is still unverified at runtime. Never invent an event, payload argument, widget method, template or CVar to fill a gap.
