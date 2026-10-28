---
name: arma-performance-budgets
description: Load before writing or reviewing Arma Reforger code with timers, `CallLater`, per-frame updates, entity queries (`QueryEntitiesBySphere`, AABB), spawning or deleting loops, map scans, or client-side catalog building, and when triaging FPS drops, server freezes, or lag reports.
---

# Performance Budgets

Each rule is a DLG live-server incident. None of these costs showed in short Workbench sessions.

## Code rules

1. **No whole-map queries.** A third-party `QueryEntitiesBySphere` at the origin with radius 999999 froze the live server for 6.5-6.9 s every five minutes. Entities register with their system; systems iterate their own registry. Query only the radius the feature needs.
2. **Server-only ticking.** Start timers after the role is known (one frame after init), and only on the side that acts. One-second timers on clients for server-only logic are pure waste.
3. **Iterate known sets.** Iterate characters from the AI world or a registry, cache per-tick results, and hook player-only controls only for players (safe zones hooked every character's controls every frame, AI included).
4. **React to events, not to polling.** A Game Master dragging an entity re-ran a 2 km query and a navmesh rebuild every second; listen to the editor's transform event and wait until the transform is stable.
5. **One test decides both directions, with hysteresis.** Attach and detach logic that used different distance tests respawned a helper entity every second next to large vehicles.
6. **Spread bursts.** Spawning and deleting go through a work queue with a per-frame time budget, never in single-frame bursts.
7. **Scan once, cache per world.** Map scans and building measurements run once into a shared world index, cached on disk; reports run on request, not at every start.
8. **Clients do not resolve prefabs in bulk.** Shop search loaded a prefab container per entry, about 2,000 in one frame. Names and display data come from the server or the shipped catalog.
9. **No 3D previews for vehicles**; they leaked until relog.
10. **State a budget** for new periodic work (interval, entities touched, worst case) in the report.

## Triage order for lag and FPS reports

1. Read the `FPS:` lines of the server log (they include AI counts) with `logs_filter` before blaming code. A Game Master-placed spawner with target 0 (unlimited) took AI from 23 to 679.
2. In the client log, look first for repeating spawns or repeating errors.
3. Check third-party timers and queries before your own: read the mod's scripts (`game_read` on its pak, or its source).
4. Only then profile your code; measurements need the live or dedicated server (for example the repository's perf flags, `-logStats`), not Workbench.

## Verification

Periodic work needs a soak run longer than the longest timer of any loaded mod (DLG's freeze was every five minutes; the tests ran shorter). Record the soak duration in the report; without one, the change is below V4.
