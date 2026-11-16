# World of Warcraft addon rules

Synced from `template-claude` (`packs/wow/`). Fills the extension points of `.claude/rules/team.md` for World of Warcraft addon repositories. Project specifics belong in this repository's `CLAUDE.md` or `.claude/local/`.

## Intake

- Read `.claude/local/wow.toml` (supported flavors, the `## Interface` number and build per flavor, the local Blizzard UI source and its tag, the game folder, lint, test and verify commands). If it is missing, create it from `.claude/skills/wow-api-lookups/references/local-wow-template.toml` and replace the sample values after checking the installed game build and the TOC files.
- Locate the addon's TOC files (`<Addon>.toc` and any flavor TOCs such as `<Addon>_Mainline.toc`, `<Addon>_Vanilla.toc`) and the flavors the work must run on. An API that exists on one flavor is unverified on the others.
- Read the relevant architecture records (`docs/adr/`) and `.pkgmeta` when libraries or packaging are in scope.
- For lookups that read a lot (Blizzard UI source, many API pages, long error dumps), delegate to `scout` and carry its citations into `Verified symbols so far`.

## Tier triggers

`design-gated` when the work touches the SavedVariables schema or its migration, secure templates, protected actions or combat-lockdown behavior, hooks into or replacement of Blizzard UI code, an addon-message protocol other clients or versions read, adding or dropping a game flavor, or a new embedded library. Any of those also rules out `minor`. Small layout, text or option changes stay `minor` when the pattern already exists in the addon.

`security-engineer` joins (see `Specialists`) when the work parses data another player controls: addon messages, chat, import strings, or anything that reaches `loadstring` or a format the addon executes.

## Hard-stop triggers

An API, event, widget method or template that cannot be resolved for every flavor in scope against the pinned build (return it with the sources checked and continue independent work); a change that automates gameplay or works around a protected-action or hardware-event restriction (Blizzard's addon policy forbids it, so this is a refusal, not a design question); publishing, uploading or tagging a release, or touching CurseForge, Wago or WoWInterface tokens without explicit scope authorization; editing anything under the game's `WTF/` folder. Read-only inspection of the game folder (`Logs/`, a copy of a SavedVariables file the user points to) may proceed when relevant. Authorization already given stays valid.

## Brief domain fields

```text
  Flavors: <flavors in scope, with the ## Interface number of each from .claude/local/wow.toml>
  TOC files: <TOC files that must list new or moved files>
  SavedVariables: <variables and schema version touched, or "none">
  Migration: <schema change and the migration step, or "none">
  Combat behavior: <protected frames or actions involved, or "none">
  Verification: <command, normally the verify_command in .claude/local/wow.toml>
  Release access authorized: <what the user allowed, or "none">
  Verified symbols so far: <symbol — Blizzard UI source path:line at tag, or wiki URL, per flavor>
```

`Constraints` always names the addon folder name, the SavedVariables names and keys, slash commands, addon-message prefixes and public globals that must not change. `Acceptance` names the checks that apply from `Acceptance evidence`.

## Domain rules

- The client runs a sandboxed Lua 5.1: no `require`, no file or network access, no `io`, a reduced `os`. Code reaches other files only through the addon's private table (`local addonName, ns = ...`) or globals. The only persistence is SavedVariables, read at load and written on logout or `/reload`; a crash loses changes since the last write.
- Files load in the order the TOC (and included XML) lists them. A file not listed never loads; every flavor TOC must list it.
- SavedVariables are not available before `ADDON_LOADED` for this addon. Merge defaults and run migrations there, never at file scope. Never remove or rename a saved key without a migration, and never discard data a migration does not understand.
- Do not create globals except the ones the addon intends to expose (frame names, slash command entries, the SavedVariables themselves). Prefix every exposed name with the addon's name.
- Taint: code that touches a protected frame or function must stay secure. Use `hooksecurefunc`, `HookScript` and secure templates; never replace a Blizzard global function or method, and never write fields into Blizzard frames or tables that secure code reads. While `InCombatLockdown()` is true, do not create, show, hide, move, resize or re-attribute protected frames; queue the change for `PLAYER_REGEN_ENABLED`.
- Protected actions (casting, targeting, movement) run only through secure templates driven by the user's click or key press. Some functions also require a hardware event. Never automate gameplay decisions; Blizzard's UI add-on policy prohibits it and the game blocks or disconnects for it.
- Data from other players (addon messages, chat, imported strings) is untrusted: bound its size, validate its shape, never `loadstring` it or use it as a table key path, and rate-limit what it triggers. Respect the addon-message prefix and throttle limits of the pinned build.
- Flavors diverge: check `WOW_PROJECT_ID` or feature-detect (`C_Namespace and C_Namespace.Func`) instead of assuming the newest retail API. Combat information on current retail may be restricted for addons (for example as secret values that cannot be compared); confirm what the pinned build allows before designing combat logic.
- Embed libraries through `.pkgmeta` externals or the repository's existing vendoring, register them with `LibStub`, and never edit vendored library code in place. Do not commit packager output (`.release/`) or release tokens.
- Treat old forum posts, wiki pages without a version note and addon code from other flavors as hypotheses until checked against the pinned build.
- An unverifiable API is a hard stop, never a `TODO(verify)` left in code. Never invent an event, payload argument, widget method, template or CVar.

## Skills by work type

Load before touching the file or deciding the topic:

| Work | Skill |
|---|---|
| API, event or template research, the flavor and build pin | `wow-api-lookups` |
| TOC fields, flavor TOCs, load order, load-on-demand, dependencies, startup events | `wow-toc-and-loading` |
| Frames, XML, templates and mixins, options panels, Edit Mode, fonts, localization | `wow-frames-ui` |
| Secure templates, protected actions, combat lockdown, taint, hooks into Blizzard UI | `wow-secure-and-taint` |
| SavedVariables, defaults, profiles, schema migrations | `wow-saved-variables` |
| Event handlers, `OnUpdate`, timers, memory, CPU cost | `wow-events-performance` |
| Addon messages, serialization, import and export strings | `wow-addon-comms` |
| Libraries, `.pkgmeta`, packager keywords, release builds, project IDs | `wow-libraries-packaging` |
| Multiple flavors, other addons (UI replacements, shared libraries, hooks on the same frames) | `wow-compatibility` |

## Verification

Verify each API, event, widget method, template and CVar you introduce, for every flavor in scope, against the Blizzard UI source at the pinned tag (the generated API documentation in `Blizzard_APIDocumentationGenerated`, or Blizzard's own call sites) or against the flavor's warcraft.wiki.gg page when its version note covers the pinned build (`wow-api-lookups`). A search hit, forum post or another addon's code alone is not a source. Symbols already used in the project for the same flavors count as verified, as do the entries under `Verified symbols so far`.

## Dev loop

1. Read the relevant code, the TOC files, and a Blizzard call site for the same API or pattern at the pinned tag.
2. Edit files with Edit/Write. List new files in every flavor TOC (or the XML file that includes them).
3. Run the `verify_command` from `.claude/local/wow.toml` (default `luacheck .`, plus `busted` when the repository has specs). Run it after the final Lua, XML or TOC change. Check that each TOC's `## Interface` matches the pin.
4. In-game checks need the game client, which agents cannot drive: list them for the user (`/reload` with Lua errors shown, the affected feature in and out of combat, `Logs/taint.log` with `/console taintLog 1` when secure code changed) unless the user reports results.
5. Fix failures within scope and loop until clean or blocked.

Lint and unit tests do not prove in-game behavior. `verify-gate.sh` has no WoW rule: the verification command stays your responsibility, and a shell call that is not that command never counts as verification.

`/wow-dev` runs `senior-engineer` in direct mode. A request that hits a `Tier trigger` stops before editing and points to the core tier workflow.

## Design checklist

1. Read the affected code, TOC files and prior ADRs.
2. Load the skill for the decision (`wow-secure-and-taint`, `wow-saved-variables`, `wow-addon-comms`, `wow-compatibility`, `wow-libraries-packaging`).
3. Verify every API, event and template the design names, per flavor (see `Verification`).
4. Check load order and the event the code starts on, combat-lockdown paths and their deferral, taint introduced into Blizzard frames, SavedVariables migration and rollback to an older addon version, protocol versioning between clients on different addon versions, untrusted input bounds, per-event and per-frame cost, flavor differences and coexistence with common UI replacements.
5. The ADR names the files, frames, events, SavedVariables keys and message formats the implementer will touch. Record decisions in `docs/adr/`, not progress files.

## Review checklist

- New globals, and TOC files that miss a new file on any flavor.
- Combat lockdown: protected frame changes or secure attributes set in combat; replaced Blizzard functions or fields written into Blizzard frames (taint).
- SavedVariables read before `ADDON_LOADED`; schema changes without a migration; data a migration drops.
- Untrusted input from addon messages, chat or import strings: size bounds, validation, `loadstring`.
- Event handlers and `OnUpdate` work that runs every frame or allocates per call; handlers never unregistered.
- APIs used on a flavor that lacks them.
- A source diff without verification evidence from the final source state is `conditional`; lint and unit tests are distinct from in-game checks.

## Lookups

Load `wow-api-lookups`. Prefer `rg` over the local Blizzard UI source at the pinned tag (path in `.claude/local/wow.toml`), then warcraft.wiki.gg (https://warcraft.wiki.gg/wiki/World_of_Warcraft_API, https://warcraft.wiki.gg/wiki/Events, https://warcraft.wiki.gg/wiki/Widget_API). Upstream source of the UI code: https://github.com/Gethe/wow-ui-source (tags per build, branches per flavor).

## Acceptance evidence

- Successful verification (lint, tests) after the final relevant change, quoted.
- Every TOC lists the new files and carries the pinned `## Interface` number for its flavor.
- Changed SavedVariables keys, migrations and addon-message formats listed.
- In-game checks still outstanding (reload without Lua errors, the feature in and out of combat, taint log, each flavor in scope) go to the user as pass, fail, or not run with the reason. Do not claim an in-game test from reading code or a log the user did not produce for this change.

## Domain report fields

| Agent | Fields |
|---|---|
| `senior-engineer` | `Verification: <quoted lint and test result>`; `Flavors and TOCs updated:`; `In-game checks: pass \| fail \| not run: <reason>`; `SavedVariables/migration impact:`; `Combat and taint risks:`; `Published: no` |
| `staff-engineer` | `Taint, SavedVariables and flavor impact:` |
| `team-lead` | `Verification reached (lint / tests / in-game by user):`; `Published: yes \| no`; `Checks for you:` |
| `sdet`, `distinguished-engineer` | as `senior-engineer` for the code they change |
| `security-engineer` | `Untrusted input paths (addon messages, chat, imports) and release-token exposure reviewed:` |
| `project-manager`, `scout`, `ux-designer` | none |

## Workflows

`/wow-dev` (senior-engineer, direct mode), `/wow-review` (staff-engineer), `/wow-release-check`, `/wow-handoff` (team-lead).
