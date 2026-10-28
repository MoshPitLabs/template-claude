# template-claude

Source of the Claude Code agent team for repositories. The team itself is domain-free (`core/`); domain knowledge and tracker integration live in packs (`packs/`): `arma` (Arma Reforger / Enfusion mods), `hytale` (Hytale plugins and content), `linear` (Linear issue tracking) and `usage` (Claude Code cost and usage report). `sync-claude-config.sh` layers the packs on top of core and pushes the result into repositories. This file is not synced; each repository keeps its own `CLAUDE.md` for project rules. Design and rationale: `GENERALIZED-TEAM.md`.

Replaces the earlier `td`-based eight-agent setup, kept for reference in `legacy/td-team/` (not synced, not loaded by Claude Code). Its eight roles live on in `core/agents/` rewritten against the layered rules; `td`, agent-teams mode, voting and the helper scripts did not carry over.

## Layout

| Path | Installed as | Purpose |
|---|---|---|
| `core/agents/` | `.claude/agents/` | `team-lead` (main session), `staff-engineer`, `senior-engineer`, `scout`, and the specialists `security-engineer`, `sdet`, `project-manager`, `ux-designer`, `distinguished-engineer`; no domain content |
| `core/rules/team.md` | `.claude/rules/team.md` | Always-loaded team rules: roles, handoff brief, tiers, hard stops, gates, and the **extension points** a domain fills (several packs may fill the same one) |
| `core/hooks/` | `.claude/hooks/` | `role-guard.sh`, `verify-gate.sh`; both read `.claude/config/*.conf` from packs |
| `core/settings.json` | `.claude/settings.json` (merged with each pack's) | `agent: team-lead`, core hooks. The status line is global (user level), not part of the template |
| `packs/arma/rules/arma-enfusion.md` | `.claude/rules/` | Fills every extension point for Arma Reforger: engine rules, tier and hard-stop triggers, brief fields, skills by work type, dev loop, checklists, W1–W4 report fields |
| `packs/arma/skills/` | `.claude/skills/` | 11 knowledge skills, 7 workflow skills (`/arma-dev`, `/arma-test`, `/arma-feature`, `/arma-bug`, `/arma-review`, `/arma-release-check`, `/arma-handoff`) |
| `packs/arma/hooks/wb-launch-guard.sh` | `.claude/hooks/` | Workbench launch guard |
| `packs/arma/config/` | `.claude/config/` | `role-guard.arma.conf` (team-lead may edit `.claude/local/`; `tasklist.exe` is read-only), `verify-gate.arma.conf` (W1 gate) |
| `packs/arma/settings.json` | merged into `.claude/settings.json` | enfusion-mcp permissions (112 tools classified from the server's annotations), `wb_*` hook, `MCP_TOOL_TIMEOUT` |
| `packs/arma/agent-tools.conf`, `enfusion-readonly-tools.txt` | appended to agents' `tools:` | Read-only enfusion tools for `team-lead`, `staff-engineer`, `security-engineer`, `project-manager`, `ux-designer`, `scout`; `mcp__enfusion-mcp__*` for `senior-engineer`, `sdet`, `distinguished-engineer` |
| `packs/arma/.mcp.json` | `.mcp.json` (servers merged; `@TARGET_REPO@` → repository path) | enfusion-mcp server (WSL build) |
| `packs/arma/sync-check.sh` | not installed | Post-sync warnings (missing `workbench.md`, leftover opencode files) |
| `packs/hytale/rules/hytale.md` | `.claude/rules/` | Fills the extension points for Hytale: server pin (`.claude/local/hytale.toml`), tier and hard-stop triggers, brief fields, skills by work type, `scripts/verify.py` dev loop, checklists, report fields |
| `packs/hytale/skills/` | `.claude/skills/` | 7 knowledge skills (`hytale-api-lookups`, `-ecs-stats`, `-assets-ui`, `-persistence`, `-worldgen`, `-dungeons`, `-compatibility`), 4 workflow skills (`/hytale-dev`, `/hytale-review`, `/hytale-release-check`, `/hytale-handoff`) |
| `packs/hytale/config/role-guard.hytale.conf` | `.claude/config/` | team-lead may edit `.claude/local/`; `javap`, `sha256sum`, `unzip -l/-p/-v/-Z` are read-only |
| `packs/hytale/settings.json` | merged into `.claude/settings.json` | Denies Edit/Write of `HytaleServer.jar`, `Assets.zip`, `auth.enc` and `universe/` |
| `packs/hytale/agent-tools.conf` | appended to agents' `tools:` | `Bash` for `scout` (role-guard keeps it read-only) so it can run `javap` and selective ZIP reads |
| `packs/hytale/sync-check.sh` | not installed | Warns when `.claude/local/hytale.toml` or `scripts/verify.py` is missing, or `.team/`/`.codex/` remain from the Codex template |
| `packs/linear/rules/linear-tracking.md` | `.claude/rules/` | Fills `Tracking`, `Intake`, `Brief domain fields`, `Domain rules` and report fields for Linear: only team-lead writes, when states move, what gets a comment, when issues are filed |
| `packs/linear/skills/` | `.claude/skills/` | `linear-tracking` (knowledge: tools, setup file), `/linear-start`, `/linear-file` |
| `packs/linear/settings.json` | merged into `.claude/settings.json` | Linear MCP permissions: read-only tools, `save_issue` and `save_comment` allowed; other writes ask; `merge_diff` denied |
| `packs/linear/agent-tools.conf`, `linear-readonly-tools.txt` | appended to agents' `tools:` | `mcp__plugin_mcp-servers_linear__*` for `team-lead`; the read-only list for the other roles |
| `packs/linear/config/role-guard.linear.conf` | `.claude/config/` | team-lead may edit `.claude/local/` (for `linear.md`) |
| `packs/linear/sync-check.sh` | not installed | Warns when `.claude/local/linear.md` is missing |
| `packs/usage/skills/usage-report/` | `.claude/skills/` | `/usage-report [--days N] [--project TEXT]`: cost, tokens, human prompts, agent time and dollars per prompt by project, recomputed from `~/.claude/projects/` transcripts at API list prices (`scripts/usage_report.py`); shown inline through T3's `html_render`, otherwise as a table plus `~/.cache/claude-usage-report/report.html` |
| `packs/usage/rules/usage-reporting.md` | `.claude/rules/` | Fills `Workflows` and `Domain rules` (the report covers every project on the machine) |
| `packs/usage/config/role-guard.usage.conf`, `agent-tools.conf` | `.claude/config/`, appended to agents' `tools:` | Report command read-only for team-lead (no output flag; `USAGE_REPORT_OUT` overrides the path but a leading assignment is not read-only); `mcp__t3-code__html_render` for `team-lead` |
| `legacy/td-team/` | never | Archived previous setup (`td` tracker, eight agents, scripts, specs) |
| `.claude/local/`, `CLAUDE.md`, `.claude/settings.local.json` in a target | never | Repository-owned |

This repository has no `.claude/` of its own, so sessions here run without the team. `./sync-claude-config.sh --render <dir>` writes the exact install into `<dir>` for inspection.

## Team

| Agent | Model | Role |
|---|---|---|
| `team-lead` | sonnet, effort high | Main session (`"agent": "team-lead"`). Intake, tier, brief, delegation, acceptance. Writes only pack paths (`.claude/local/`) and the tracker (Linear); no status or handoff files in the repository; read-only shell |
| `staff-engineer` | opus, effort high | Design of design-gated work (ADRs in `docs/adr/`), review of standard work |
| `senior-engineer` | sonnet, effort high; `opus` per call for design-gated briefs | All implementation including UI; runs the dev loop |
| `scout` | haiku, effort high | Read-only lookups with citations; loads the domain's lookup skill if a pack ships one |
| `security-engineer` | opus, effort high | Threat models, security ADRs, security review; docs paths only, read-only shell |
| `sdet` | opus, effort high | Tests, test tooling, acceptance verification, defect reports; no production code |
| `project-manager` | sonnet, effort high | Decomposes work into ready work items and returns the plan; no edits, no tracker writes (team-lead files the items) |
| `ux-designer` | opus, effort high | Design specs in `docs/ux/`, design QA; no implementation |
| `distinguished-engineer` | fable, effort xhigh | Problems without precedent in `design`, `investigate` or `deep-impl` mode; never security-sensitive work |

Flow: `minor` = lead → senior → accept; `standard` adds a staff review; `design-gated` starts with a staff ADR. The specialists join a tier's path under the `Specialists` table in `core/rules/team.md` (security-sensitive work is never `minor`). Details in `core/rules/team.md`; domain triggers and gates in the pack rules files.

To run a session in a target repository without the team-lead restrictions, start it with `claude --agent senior-engineer` or set `"agent"` in its `.claude/settings.local.json`.

## Hooks

- **`role-guard.sh`** (core; PreToolUse: Edit, Write, MultiEdit, NotebookEdit, Bash). Keeps team-lead, staff-engineer, security-engineer and ux-designer to their document paths (`docs/adr|tdd`, `specs/`, `docs/ux`) and read-only shell commands, and scout and project-manager to no edits. `sdet`, `distinguished-engineer` and `senior-engineer` are not restricted by the hook; their limits are in their agent files. Keyed on the hook input's `agent_type` (set for subagents and for the main session started through settings `"agent"`). Packs add paths and read-only commands in `.claude/config/role-guard.<pack>.conf`.
- **`verify-gate.sh`** (core; Stop, SubagentStop). Blocks finishing once when files a pack names changed after the pack's last verification call in that transcript. Calls whose result was an error (denied, failed) do not count as changes or as verification. Rules in `.claude/config/verify-gate.<pack>.conf`; Arma: `.c` files and `script_create` → `wb_validate_scripts`. With no such file it does nothing.
- **`wb-launch-guard.sh`** (Arma; PreToolUse: `mcp__enfusion-mcp__wb_.*`). Denies `wb_*` calls that would launch Workbench while its NET API (port 5775, WSL gateway host) does not answer.

## enfusion-mcp facts the team depends on (Arma pack)

- `wb_validate_scripts` has no `config` parameter (dropped in enfusion-workbench-mcp `baa1162`: Workbench read `-config` as a server config file). One run validates WORKBENCH, PC and console configurations; it never compiles a dedicated-server configuration. The server compile shows only in a dedicated-server log.
- In multi-mod repositories pass the repository folder as `addons_dir`, or dependencies load from packed Workshop copies.
- Tool annotations (`readOnlyHint`, `destructiveHint`) in the server source are accurate. When the server gains tools, classify them into `packs/arma/settings.json` (allow / ask / deny) and, if read-only, into `packs/arma/enfusion-readonly-tools.txt`.

## Sync

```bash
./sync-claude-config.sh --dry-run ~/Code/<org> <repo>...
./sync-claude-config.sh ~/Code/<org> <repo>...
# Arma Reforger mods, with Linear tracking
./sync-claude-config.sh --pack arma --pack linear "/mnt/e/ArmaRefoger Projects" <repo>...
# Hytale plugins, with Linear tracking
./sync-claude-config.sh --pack hytale --pack linear "/mnt/e/Hytale Projects" <repo>...
```

Without repository names, every git repository or Enfusion addon (a folder with a `*.gproj`) in the target directory is synced.

Run in a terminal, the script asks for whatever the command line leaves out: the packs (no `--pack`; Enter takes `linear`), the target directory (Enter takes the current directory), and which of the found repositories to sync (no repository names; Enter takes all). It then prints the equivalent command line and asks to proceed. `--yes` (or stdin/stderr not being a terminal) skips every prompt and keeps the defaults, so scripted use is unchanged.

`--pack NAME` picks the pack (default `linear`; repeatable; `--pack arma` alone for a repository without Linear; a name with no `packs/<name>/` fails). The Arma, Hytale and usage packs are opt-in: pass `--pack arma`, `--pack hytale` or `--pack usage` where they apply. The script renders core + packs into a staging directory, backs up the files it replaces to `.claude.backup.<timestamp>/`, records what it installed in `.claude/.template-manifest`, and removes only template files that the template no longer ships. Skills or agents a repository adds itself, top-level settings keys it added, and MCP servers it added are kept. `.mcp.json` is written only when a pack ships one (the Arma pack's enfusion-mcp server) (`@TARGET_REPO@` → repository path).

## Extending

- **Core** stays domain-free: no engine names, file types, tools or commands. A domain need that core cannot express becomes a new extension point in `core/rules/team.md`, referenced from the agents.
- **New pack**: `packs/<name>/` with any of `rules/`, `skills/`, `hooks/`, `config/`, `settings.json`, `agent-tools.conf`, `.mcp.json`, `sync-check.sh`. Its rules file fills the extension points it needs. Skill ids carry the pack's prefix (`linear-…`), and a skill's `name` equals its directory name.
- **Arma skills**: `packs/arma/skills/arma-<kebab-id>/SKILL.md` (every skill id carries the `arma-` prefix, and `name` equals the directory name) with `name` and a `description` that states when to load it. Add it to `Skills by work type` in `arma-enfusion.md`. Keep bodies short and move detail into `references/`, which the body must point to. Every engine fact needs a source: a compiled project file, vanilla source, or the wiki. Example paths name their repository.
- **Linear**: the server comes from the user-level `mcp-servers` plugin, so the pack ships no `.mcp.json`. When the server gains tools, classify them into `packs/linear/settings.json` and, if read-only, into `linear-readonly-tools.txt`. Per-repository team, project, labels and states live in the target's `.claude/local/linear.md`.
- **Do not use skill `paths:` frontmatter**: a path-scoped skill is unknown to the Skill tool until a matching file has been read in that session, so a reviewer working from `git diff` or a designer could not load it. Map work types to skills in the pack's rules file (`Skills by work type`) instead.
- **Usage pack**: when a new model ships, add its prices to `PRICES` in `packs/usage/skills/usage-report/scripts/usage_report.py` (input, output, cache read per million tokens; cache writes are derived as 1.25x/2x input). The report lists models it could not price.
- **Workflow skills**: `disable-model-invocation: true`; `context: fork` with `agent:` to run inside a subagent.
- **Agents**: a `tools` list without `Agent` (subagents can spawn subagents otherwise); path limits go in `role-guard.sh` (core roles) or a pack's `role-guard.<pack>.conf`.
