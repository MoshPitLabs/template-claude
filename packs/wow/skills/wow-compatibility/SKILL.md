---
name: wow-compatibility
description: Load before making a WoW addon work across flavors (retail, progression classic, classic era) or alongside other addons — UI replacements, shared libraries, other hooks on the same Blizzard frames.
---

# WoW compatibility

Flavors are separate games with separate APIs. Branch on `WOW_PROJECT_ID` against the project constants the pinned builds define, or feature-detect (`if C_Foo and C_Foo.Bar then`), and keep flavor-specific code in separate files listed only in that flavor's TOC when the difference is large. A function, event or template verified on one flavor is unverified on the others; record the flavor beside every entry in `Verified symbols so far`.

Flavor families (confirm every line on the pinned build; the Forever lines come from the community developer page https://wowforeverguides.com/addons/developers and the better-addons AI coding guide https://www.better-addons.com/ai-coding-guide/, both written against early builds, so they are hypotheses until checked):

| | Mainline-family: retail Midnight, WoW Forever | Classic Era, progression flavors |
|---|---|---|
| Interface | retail 12.0.x numbers; Forever `16001` (beta guide: not the 11500s of Classic Era) | per flavor in `.claude/local/wow.toml` |
| TOC suffix and client folder | `_Mainline.toc`; Forever may use `_Camelot.toc` or share `_Mainline.toc`; client folder `_retail_`, `_forever_` | `_Vanilla.toc`, `_Classic.toc` and the pinned build's other suffixes; `_classic_era_`, `_classic_` |
| Project constant | Forever reported `WOW_PROJECT_CAMELOT` (18) on one build, Mainline (1) on another: never branch on the ID alone | the flavor's own constants |
| Combat log | `COMBAT_LOG_EVENT_UNFILTERED` errors, `CombatLogGetCurrentEventInfo` removed or absent | available |
| Secret values | combat numbers, some names and booleans: guard with `issecretvalue` | none |
| Old globals | many moved to `C_` namespaces; on Forever `GetSpellInfo`, `GetItemInfo`, `GetTalentInfo` and others reported missing | usually still present; some `C_` backports exist, so feature-detect |
| Secure snippets | reported broken on early Forever builds (`loadstring_untainted`): do not depend on them there | work as before |
| Blizzard features | built-in damage meter and cooldown manager on Forever: skin, do not replace | none |

Pick the code path by what the client provides (feature detection first, named constants and `select(4, GetBuildInfo())` next), put family-specific files in only the TOCs that need them, and never port a retail restriction onto a Classic flavor (or the reverse) without a source for the pinned build.

Coexistence with other addons:

- Do not assume Blizzard frames are visible, positioned or unmodified: UI replacements (ElvUI, Bartender, unit frame addons) hide, reparent or skin them. Check for nil and hidden frames before hooking or anchoring.
- Other addons hook the same functions; hooks must not depend on running first or last.
- A shared library is the highest version any loaded addon embeds, not the one you shipped; code against the library's documented API only.
- Slash commands, addon-message prefixes, global names and keybinding headers must be unique to this addon.

Test matrix for in-game checks (for the user): each flavor in scope, a clean profile with only this addon, and the common UI replacements the project names in `CLAUDE.md` or `.claude/local/wow.toml`. Report each as pass, fail or not run.
