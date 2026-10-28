# Design: generalized agent team with domain packs

The team is a lean four-agent core that knows nothing about any engine, language or tracker. Domain knowledge arrives in packs layered on top at sync time. The design originated in `template-claude-armareforger` (Arma Reforger pack) and was generalized here; domain packs live under `packs/` (`arma`, `hytale`, `linear`).

## Extension points

Core agents refer to "the team rules in `.claude/rules/team.md` and any domain rules in `.claude/rules/`". Each domain rules file fills named sections of `team.md` (`Intake`, `Tier triggers`, `Hard-stop triggers`, `Brief domain fields`, `Domain rules`, `Skills by work type`, `Verification`, `Dev loop`, `Design checklist`, `Review checklist`, `Lookups`, `Acceptance evidence`, `Tracking`, `Domain report fields`, `Workflows`). A section a pack does not fill is skipped. Several packs may fill the same section.

## Layering

`sync-claude-config.sh` installs `core/`, then each `packs/<pack>/`, into the target's `.claude/`:

- agents, rules, hooks, skills, scripts, config are copied (a pack overriding a core file logs a warning);
- `settings.json` files are deep-merged: objects merge, arrays concatenate without duplicates, later packs win on scalars;
- `agent-tools.conf` (`<agent> <tool | @file>`) appends tools to the agents' `tools:` lists, so agent files stay domain-free while read-only roles get only read-only tools;
- `.mcp.json` servers are merged into the target's, with `@TARGET_REPO@` replaced by the repository path;
- everything installed is recorded in `.claude/.template-manifest`, so a later sync removes only files the template stopped shipping.

Packs are chosen per run (`--pack`, or a numbered prompt listing `packs/*/` when the script runs in a terminal), so a new pack needs no change to the script.

Never touched: `CLAUDE.md`, `.claude/local/`, `.claude/settings.local.json`, `.claude/agent-memory*/`, and files the template did not install.

## Hooks driven by pack config

- `role-guard.sh` holds all logic for path allowlists and read-only shell per `agent_type`; packs add paths and read-only commands in `.claude/config/role-guard.<pack>.conf`.
- `verify-gate.sh` implements "files matching X changed after the last call to verifier Y → block once" from `.claude/config/verify-gate.<pack>.conf`. Tool calls whose result was an error are ignored, so a call denied by `role-guard.sh` cannot block finishing.

## Platform facts relied on

- **Skill `paths:` is not used.** A skill with `paths:` is unknown to the Skill tool until a matching file has been read in that session, so reviewers working from a diff could not load it. The work-type → skill mapping lives in the pack rules (`Skills by work type`).
- **Rules without `paths:`** in `.claude/rules/` load at launch and reach subagents.
- **Agent `tools:`** accepts `mcp__<server>__*`; without `tools:` an agent inherits everything from the main session.
- **Agent `skills:` preloading** does not apply to agent-teams teammates, so packs must not rely on it.
- **`agent_type` in hook input** is set for subagents and for a main session started through settings `"agent"` (tested), so `role-guard.sh` can key on it.
- **Plugins** cannot ship rules and rename MCP tools (`mcp__plugin_<plugin>_<server>__<tool>`), so distribution is by sync, not by plugin.

## Predecessor

The earlier setup in `legacy/td-team/` (eight roles, the `td` tracker, agent teams, ~40 doctrine and helper scripts, `specs/`) is kept for reference only. The five specialists (`security-engineer`, `sdet`, `project-manager`, `ux-designer`, `distinguished-engineer`) were migrated into `core/agents/` and rewritten: their charters and quality gates stayed, the `td` commands, agent-teams messaging, consensus voting, role-specific skills and helper scripts were removed. Engagement conditions moved into the `Specialists` table of `core/rules/team.md`, path limits into `role-guard.sh`, and issue creation by `project-manager` became a plan that `team-lead` files through the tracker pack (only `team-lead` writes to it). `td` itself, the persistent advisor seats and the Fable-tier routing machinery were not carried over.
