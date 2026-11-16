---
name: wow-saved-variables
description: Load before adding, renaming or restructuring a WoW addon's SavedVariables, setting defaults or profiles, or writing a schema migration.
---

# WoW saved variables

Declare variables in every flavor TOC (`## SavedVariables` account-wide, `## SavedVariablesPerCharacter` per character). The client sets them before this addon's `ADDON_LOADED` and serializes them on logout or `/reload`; a crash or forced quit loses changes since the last write. Only strings, numbers, booleans and tables of them persist. Never store functions or frames, and avoid shared or cyclic references.

On `ADDON_LOADED`:

1. Create the table if nil.
2. Read `schemaVersion` (absent means the oldest schema) and run ordered, idempotent migration steps up to the current version. Keep data a step does not understand rather than deleting it, so that a downgrade to an older addon version loses nothing.
3. Fill missing defaults without overwriting stored values (or use AceDB-3.0 defaults if the addon already embeds it; AceDB strips values equal to defaults on logout, so a changed default changes every untouched profile).
4. Set `schemaVersion` last.

Keep saved data bounded: prune caches and per-character history with a limit, because large files slow every login and reload. The files live in `WTF/Account/<account>/SavedVariables/` (and per character below the realm folder); agents never edit `WTF/`. A file the user copies out for inspection is player data: do not paste its contents into the tracker.
