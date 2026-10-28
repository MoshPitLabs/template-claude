---
name: hytale-persistence
description: Load before designing, implementing or reviewing Hytale player-state persistence, schema migrations, lifecycle saves, or transactional progression rewards.
---

# Hytale persistence

Confine mutable player state to its owner and transfer immutable snapshots to I/O workers. Use explicit database transactions for skill purchases, currency/point deductions and reward claims. Persist stable player UUIDs, schema versions and idempotency keys; do not store entity references.

Cover join/load races, transfer, disconnect during async work, respawn and clean shutdown. Drain pending saves before closing the database. For SQLite, account for WAL and backup consistency. Preserve existing plugin identifiers and data paths until a migration plan is accepted.

Test old-schema upgrades, retries, duplicate rewards, restart recovery and concurrent purchase attempts. Define rollback expectations for every irreversible schema change. Server-global storage is scoped to that server/save, not all servers or singleplayer saves automatically.
