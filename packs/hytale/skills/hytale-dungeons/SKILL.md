---
name: hytale-dungeons
description: Load before building or reviewing Hytale instance lifecycle, seeded dungeon room generation, or run recovery.
---

# Hytale dungeons

`InstancesPlugin.spawnInstance` copies an existing template; it does not itself solve a procedural layout. Verify template existence and readiness before teleporting players. Use supported exit and safe-removal APIs rather than deleting live world directories.

Represent a run with ID, seed, template version, participant IDs, return locations, stage and reward claims. A room plan needs connector compatibility, non-overlap, reachable entrance/exit and bounded generation. Test native graph generation against those constraints before choosing it over a room solver.

Validate disconnect/death, shutdown/restart, timeouts, missing destination worlds, and once-only completion rewards. Track owned entities/prefabs for cleanup. Separate persistent run state from runtime entity references and budget placement across ticks.
