---
name: hytale-ecs-stats
description: Load before implementing or reviewing Hytale ECS systems, health and stamina modifiers, movement effects, or damage handling.
---

# Hytale ecs stats

Read `hytale-api-lookups` when a method is uncertain. Mutate entities on the owning world context; an entity index of zero is per archetype chunk, not a once-per-world tick. Reacquire references after world transfers and asynchronous work. Use command buffers for structural mutations during iteration.

Stat-changing systems must respect `EntityStatsSystems.StatModifyingSystem` ordering. Native health/stamina remain distinct from long-term energy. Use named modifiers owned by the feature and remove only those keys; do not cache a baseline indefinitely when other mods may change it. Verify prediction semantics before selecting flags.

Route damaging shortages through `DamageSystems.executeDamage` with an intentional cause and test cancellation, death attribution and feedback. Use simulation delta for active depletion and define pause/offline policy explicitly. A concurrent map does not make mutable state snapshots atomic.
