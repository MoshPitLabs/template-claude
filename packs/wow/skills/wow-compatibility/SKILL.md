---
name: wow-compatibility
description: Load before making a WoW addon work across flavors (retail, progression classic, classic era) or alongside other addons — UI replacements, shared libraries, other hooks on the same Blizzard frames.
---

# WoW compatibility

Flavors are separate games with separate APIs. Branch on `WOW_PROJECT_ID` against the project constants the pinned builds define, or feature-detect (`if C_Foo and C_Foo.Bar then`), and keep flavor-specific code in separate files listed only in that flavor's TOC when the difference is large. A function, event or template verified on one flavor is unverified on the others; record the flavor beside every entry in `Verified symbols so far`.

Coexistence with other addons:

- Do not assume Blizzard frames are visible, positioned or unmodified: UI replacements (ElvUI, Bartender, unit frame addons) hide, reparent or skin them. Check for nil and hidden frames before hooking or anchoring.
- Other addons hook the same functions; hooks must not depend on running first or last.
- A shared library is the highest version any loaded addon embeds, not the one you shipped; code against the library's documented API only.
- Slash commands, addon-message prefixes, global names and keybinding headers must be unique to this addon.

Test matrix for in-game checks (for the user): each flavor in scope, a clean profile with only this addon, and the common UI replacements the project names in `CLAUDE.md` or `.claude/local/wow.toml`. Report each as pass, fail or not run.
