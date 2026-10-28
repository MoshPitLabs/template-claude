---
name: arma-persistence
description: Load before designing, implementing, or reviewing anything that saves or loads state in Arma Reforger — serializers, `PersistenceSystem`, Game Master save/load, player or vehicle records, placed-entity persistence, profile JSON files, or session restarts.
---

# Persistence

Every rule here comes from the DLG mod suite, which ran its own store beside vanilla persistence and paid for it in lost entities, duplicated value, and save-time lag on the live server.

## Design rules

1. **One store.** Mod state goes into the vanilla persistence system (serializers registered with it), not into a parallel set of JSON files. State that third-party mods register with vanilla (attachments, night vision, ACE data) is then saved too.
2. **Never release world-file entities from vanilla persistence.** Releasing records them as deleted: a session load then removes every world-file shop, safe zone, and hider. World-file entities keep their deterministic vanilla id.
3. **Roots are saved with their children.** Vanilla tracks children (vehicle interior props, items in a vehicle) as records of their own. Do not release or walk roots per save.
4. **Mark transient where it is created.** Whatever the mod spawns and does not want saved (mission tasks, temporary AI, helpers) is marked transient at spawn, or it piles up across restarts.
5. **One snapshot holds everything.** Money and inventory written to different files at different moments duplicate or lose value on a crash. No immediate writes per trade: a crash rolls back as a whole.
6. **No mod file writes during play.** Full saves on inventory changes (tree walk, pretty JSON, atomic write) ran up to four times a second in DLG.
7. **A file that does not parse is never written over.** Migrations write only when they changed something.
8. **Mods run without the system present.** Workbench Play has no `PersistenceSystem` (`PersistenceSystem.GetInstance()` returns null); code must check and degrade, not crash.
9. **Verify every serializer API** against vanilla serializers (`game_browse` for `*Serializer*`, `script_class_hierarchy`) before use; extend vanilla serializers through `modded class` and append after `super` (`arma-modded-class-overrides`).

Persistence that touches synchronized state is design-gated (`arma-replication-and-networking`).

## Verification

Workbench Play cannot test any of this. The test is W3 on the local dedicated server (start/stop commands in `.claude/local/workbench.md`):

1. Start the server with the mod, create the state, save (or wait for the save point), stop the server.
2. Start again and compare: the state is back, nothing is duplicated, world-file entities are all present, transient entities are gone.
3. Restart once more to catch pile-up across sessions.

Report each step as expected vs observed. Without a run, persistence stays `unknown` and the change is below V3.
