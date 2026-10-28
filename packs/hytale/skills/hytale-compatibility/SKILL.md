---
name: hytale-compatibility
description: Load before assessing or changing behavior that must coexist with installed Hytale mods — HUD composition, inventory bonuses, extra drops, NPC spawning, world content.
---

# Hytale compatibility

Inventory installed artifacts and read successful-load/error evidence separately: a file's presence does not prove it loaded. Record exact server/mod versions and reproduce in staging.

Check modifier ownership, native multi-HUD plus MultipleHUD behavior, item transaction handling, cancelled block actions, player-placed block farming and repeated bonus rewards. LuckyMining or another extra-drop mod must not feed our XP/drop logic recursively.

Use optional capability bridges so metabolism, professions, character progression, dungeons and encounters can run independently. Test third-party consumables explicitly. Read-only live inspection may proceed when authorized; compatibility analysis alone does not authorize uploading artifacts, restarting production or modifying worlds.
