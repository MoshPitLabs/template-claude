---
name: arma-replication-and-networking
description: Load before designing, implementing, or reviewing state that must synchronize between Arma Reforger authority and proxies, including RPCs, ownership, persistence, and network-visible UI data.
---

# Replication and Networking

## Mandatory design gate

Do not retrofit replication after implementation. New synchronized state is design-gated: `staff-engineer` decides the authority model and synchronization design (and records it as an ADR) before any code is written. The implementer follows that decision verbatim and stops if the code needs something it does not cover.

## Design workflow

1. Name the authoritative owner of every mutable value.
2. Identify who may request a change and who validates it.
3. Define what proxies observe, when they receive it, and how late joiners obtain current state.
4. Separate local presentation state from authoritative gameplay state.
5. Verify each replication attribute, component, callback, and RPC API against project code, vanilla source, or the Bohemia Interactive Community Wiki. `script_find_rpc_handlers` lists the RPC handlers a project already has.
6. Define initialization, ownership transfer, disconnect, reconnect, and stale-state behavior where relevant.
7. Prefer an existing verified `SCR_*` replication pattern.
8. Stop if the API or execution context cannot be verified.

Read `references/verified-authority-patterns.md` before design or review. Its security and bandwidth rules come from exploits and lag on a live server.

## Verification gate

Workbench compilation and single-player behavior are insufficient, and Workbench Play cannot test persistence at all (no `PersistenceSystem`). Record a local or hosted multiplayer test with at least one authority and one proxy, the action performed by each, expected state on each peer, observed state, and reconnect or late-join behavior when applicable.
