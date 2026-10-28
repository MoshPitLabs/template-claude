# Replication Evidence Matrix

Complete this matrix in the design or the final report:

| Concern | Verified source | Decision | Test |
|---|---|---|---|
| Authority owner | path or wiki URL | owner | authority observation |
| Mutation request | path or wiki URL | caller and validation | proxy-to-authority action |
| Replicated state | path or wiki URL | fields/events | peer state comparison |
| Initial state | path or wiki URL | initialization order | fresh session |
| Late join/reconnect | path or wiki URL | recovery behavior | reconnect or late join |
| Failure handling | path or wiki URL | rejection/fallback | invalid or stale request |

Do not use an API name in the design until its declaration and execution context are verified. No generic RPC snippet is provided because an unverified example would violate the team's API rules.

## Verified facts

- `[Attribute(...), RplProp(onRplName: "...")]` must share one bracket; see `arma-enforce-script-conventions/references/verified-language-patterns.md`.
- Vanilla map buildings have an `RplComponent`; `IEntity.IsLoaded()` identifies entities loaded from the world file.
- Workbench Play has no `PersistenceSystem` (`PersistenceSystem.GetInstance()` returns null) and no Game Master saving. Late-join and persistence rows of this matrix are tested in the game client or on a dedicated server.

## Security rules

Learned from DLG on a live server and from the survival mods it replaced.

- **Validate every request on the server.** Never trust a player id, price, amount, or target sent by a client. Route checks through one shared guard (in the core mod) rather than per handler; distance and ownership are part of that guard.
- **Game Master attributes check the calling player** on read and write. The photo-mode prefab has its own attribute manager, so a check on the editor alone is not enough.
- **Identity is the audited platform identity only.** Name-based fallback ids let one player take over another's data. A development fallback must not be enableable from a server config.
- **Price and value rules run when the catalog loads**, so a kit's parts cannot be sold for more than the kit.
- **The role is known one frame after init.** `Replication.IsServer()` is false during world load; registration that requires it silently skips world-file entities. Skip work only on known clients.

## Bandwidth and timing rules

- **Clients build static data from shipped configs.** The server sends only the override delta and a hash; never ship a large JSON catalog over RPC (DLG sent 150-300 KB in 4000-character reliable RPCs in one frame).
- **Full sync once per connection, deltas afterwards.** Respawn is not a reason to resend everything the player owns.
- **Server-only ticking.** Start timers after the role is known and only where the server acts. Lists every entity needs replicate once, on the owning system, not per entity.
- **Names are data.** Display names go to the client from the server or from the shipped catalog; the client never resolves hundreds of prefabs to read names.
- **An attribute's options come from a replicated list**, never from a list each side builds on its own.
