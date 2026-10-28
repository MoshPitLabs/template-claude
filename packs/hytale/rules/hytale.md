# Hytale development rules

Synced from `template-claude` (`packs/hytale/`). Fills the extension points of `.claude/rules/team.md` for Hytale plugin and content repositories. Project specifics belong in this repository's `CLAUDE.md` or `.claude/local/`.

## Intake

- Read `.claude/local/hytale.toml` (server JAR and assets paths, pinned version and SHA-256, verify command). If it is missing, create it from `.claude/skills/hytale-api-lookups/references/local-hytale-template.toml` and replace the sample values after inspecting the installed resources.
- Establish the exact server version and hash before depending on APIs. Local binaries and assets are reference inputs, not project-owned distributable files.
- Read the relevant architecture records (`docs/adr/`).
- For lookups that read a lot (many classes, large archives, logs), delegate to `scout` and carry its citations into `Verified symbols so far`.

## Tier triggers

`design-gated` when the work touches schema migrations, module dependency or lifecycle, a new world-generation contract, persistent dungeon or reward state, or authority and threading. Any of those also rules out `minor`. Small balance or configuration changes stay `minor` when their semantics are established.

## Hard-stop triggers

An API or asset-schema question that cannot be resolved against the pinned JAR (return it with the sources checked and continue independent work); production deployment, destructive world operations, or changes to external credentials without explicit scope authorization. Read-only inspection and disposable local verification may proceed when relevant. Authorization already given stays valid.

## Brief domain fields

```text
  Server: <version and SHA-256 from .claude/local/hytale.toml>
  Enabled features: <feature toggles in scope>
  World/save scope: <affected worlds or saves, or "none">
  Data migration: <schema or save changes, or "none">
  Verification: <command, normally python3 scripts/verify.py>
  Live access authorized: <what the user allowed, or "none">
  Verified symbols so far: <symbol — javap output, doc URL or asset path, from scout or earlier work>
```

`Constraints` always names the plugin identifiers, data paths and public configuration that must not change. `Acceptance` names the checks that apply from `Acceptance evidence`.

## Domain rules

- The server owns gameplay state in singleplayer and multiplayer. Work on the owning world thread; use command buffers for structural changes during ECS iteration. Send immutable snapshots to I/O workers.
- Keep native health/stamina separate from long-term energy. Compose stable, owned modifiers and remove only our contributions.
- Use the damage pipeline for starvation and dehydration harm. Confirm successful consumption before restoring resources or awarding XP.
- Persist reward and skill-point changes transactionally and handle reconnect, transfer, death, shutdown and restart.
- Feature toggles must not impose optional feature dependencies. Asset registration is distinct from runtime enablement; topology and content changes initially require a restart.
- Do not bundle `HytaleServer.jar`, `Assets.zip`, vanilla content, authentication stores or live player data. Inspect archives selectively. Never edit them, `universe/`, `runtime/`, `.dev/`, `build/` or `.gradle/` by hand (`settings.json` denies the first group).
- Treat old APIs and README feature claims as hypotheses until checked against the pinned server JAR and runtime.
- An unverifiable API or asset schema is a hard stop, never a `TODO(verify)` left in code. Never invent a callback, event, ID prefix or client capability.

## Skills by work type

Load before touching the file or deciding the topic:

| Work | Skill |
|---|---|
| API or signature research, asset schemas, the server pin | `hytale-api-lookups` |
| ECS systems, stats modifiers, movement effects, damage | `hytale-ecs-stats` |
| JSON assets, consumables, custom HUD or UI pages | `hytale-assets-ui` |
| Player storage, schema migrations, reward transactions | `hytale-persistence` |
| World presets, biomes, seeds, generator providers | `hytale-worldgen` |
| Instances, procedural rooms, run recovery | `hytale-dungeons` |
| Third-party mods, HUD composition, drop and consumable interactions | `hytale-compatibility` |

## Verification

Verify each API and asset claim you introduce against the pinned JAR (`javap` signatures, codecs, shipped examples) and release-matched official docs (`hytale-api-lookups`). A search hit or a README claim alone is not a source. Symbols already used in the project count as verified, as do the entries under `Verified symbols so far`. Release-matched binaries take precedence over examples of uncertain version.

## Dev loop

1. Read the relevant code, the pinned server's classes and a shipped asset example for the same pattern.
2. Edit files with Edit/Write.
3. Run `python3 scripts/verify.py` (or the `verify_command` in `.claude/local/hytale.toml`). It checks the pinned resources and runs the real build. Run it after the final source, config or asset change.
4. Run a disposable server or client smoke when the setup allows it.
5. Fix failures within scope and loop until clean or blocked. List the runtime checks not run.

Compilation does not prove gameplay behavior. `verify-gate.sh` has no Hytale rule: the checked verification command stays your responsibility, and a shell call that is not that command never counts as a build.

`/hytale-dev` runs `senior-engineer` in direct mode. A request that hits a `Tier trigger` stops before editing and points to the core tier workflow.

## Design checklist

1. Read the affected code and prior ADRs.
2. Load the skill for the decision (`hytale-ecs-stats`, `hytale-persistence`, `hytale-worldgen`, `hytale-dungeons`, `hytale-compatibility`).
3. Verify every API and codec the design names (see `Verification`).
4. Check world-thread confinement, reference validity after async work, lifecycle cleanup, native prediction ordering, transactional and idempotent rewards, cancellation, independent module toggles, crash recovery, bounded generation and coexistence with installed mods.
5. The ADR names the classes, methods, assets and schemas the implementer will touch. Record decisions in `docs/adr/`, not progress files.

## Review checklist

- World-thread confinement and reference validity after async work or world transfer.
- Lifecycle cleanup, cancellation, and ordering against native systems.
- Double restoration, XP or rewards; idempotency keys; migration rollback.
- Independent feature toggles and coexistence with installed mods.
- Unbounded generation or per-tick work.
- A source diff without verification evidence from the final source state is `conditional`; compilation and unit tests are distinct from server startup and client gameplay checks.

## Lookups

Load `hytale-api-lookups`; prefer `rg`, selective ZIP reads (`unzip -l`, `unzip -p`) and `javap` over unpacking entire archives. Official docs: https://docs.hytale.com/ and https://docs.hytale.com/api/ .

## Acceptance evidence

- Successful verification after the final relevant change, quoted, with the artifact name and hash.
- Changed schemas and assets listed.
- Runtime checks still outstanding (client or server smoke, compatibility pass) go to the user as pass, fail, or not run with the reason. Do not claim a live test from a log inspection.

## Domain report fields

| Agent | Fields |
|---|---|
| `senior-engineer` | `Build/API/resource check: <quoted verification result>`; `Runtime smoke: pass \| fail \| not run: <reason>`; `Enabled feature combinations tested:`; `Persistence/migration impact:`; `Compatibility risks:`; `Deployed: no` |
| `staff-engineer` | `Persistence, threading, and compatibility impact:` |
| `team-lead` | `Verification reached (build / staging / production):`; `Deployed: yes \| no`; `Checks for you:` |
| `sdet`, `distinguished-engineer` | as `senior-engineer` for the code they change |
| `security-engineer` | `Credential, player-data and server-binary exposure reviewed:` |
| `project-manager`, `scout`, `ux-designer` | none |

## Workflows

`/hytale-dev` (senior-engineer, direct mode), `/hytale-review` (staff-engineer), `/hytale-release-check`, `/hytale-handoff` (team-lead).
