---
name: hytale-worldgen
description: Load before defining or changing Hytale world presets, biome layouts, seeds, or generation-provider integration.
---

# Hytale worldgen

Distinguish the legacy Hytale provider from newer HytaleGenerator HandleProvider and asset schemas. Verify the provider codec and configuration against the exact server build.

Inspect `Server/HytaleGenerator/WorldStructures`, `Biomes`, `Assignments` and `GraphGenerators` in the supplied assets. Keep preset, seed, generator version and pack version together. Generation changes do not redesign saved chunks; test new worlds and boundary behavior before changing an existing world.

Prototype a fixed-seed two-biome world, inspect spawn safety and chunk continuity, and measure generation cost. Keep expensive pure planning off the world thread and commit through supported world-generation mechanisms. Do not promise native graph generation enforces gameplay room-connectivity constraints without a prototype.
