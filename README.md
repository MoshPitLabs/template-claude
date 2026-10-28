# template-claude

A layered **Claude Code** agent team for repositories: a domain-free core (`team-lead`, `staff-engineer`, `senior-engineer`, `scout`, plus the specialists `security-engineer`, `sdet`, `project-manager`, `ux-designer`, `distinguished-engineer`) plus optional packs that add domain knowledge, tracker integration, hooks and permissions. A sync script renders core + packs and installs the result into your repositories.

- `core/` — agents, always-loaded team rules (roles, handoff brief, tiers, gates, extension points), `role-guard` and `verify-gate` hooks.
- `packs/arma/` — Arma Reforger (Enfusion) mod development: engine rules, W1–W4 gates, 18 skills, enfusion-mcp permissions and Workbench guard hooks.
- `packs/hytale/` — Hytale plugin and content development: server-pin and verification rules, 7 knowledge skills (API lookups, ECS/stats, assets/UI, persistence, worldgen, dungeons, compatibility), `/hytale-dev`, `/hytale-review`, `/hytale-release-check`, `/hytale-handoff`.
- `packs/usage/` — `/usage-report` (Claude Code cost, tokens, prompts and agent time by project, at API list prices) and `/context-report` (what fills the current session's context window); both render inline in T3 with a shared look.
- `packs/linear/` — Linear issue tracking (only `team-lead` writes; `/linear-start`, `/linear-file`).
- `sync-claude-config.sh` — installs the layers into target repositories, merging `settings.json` and `.mcp.json`, and never touching repository-owned files.
- `legacy/td-team/` — the previous `td`-based eight-agent setup, archived.

Requirements: `bash`, `jq`, `git`. Linear pack: the `mcp-servers` Claude Code plugin. Arma pack: the enfusion-mcp server (WSL build) and Arma Reforger Tools with Workbench. Hytale pack: JDK 25 (`javap`), `unzip`, and a repository-provided `scripts/verify.py`.

```bash
./sync-claude-config.sh                    # interactive: asks for packs, directory and repositories
./sync-claude-config.sh --dry-run ~/Code/<org> <repo>
./sync-claude-config.sh ~/Code/<org> <repo>
./sync-claude-config.sh --pack arma --pack linear <dir> <mod>   # Arma Reforger mod repository
./sync-claude-config.sh --pack hytale --pack linear <dir> <repo>  # Hytale plugin repository
./sync-claude-config.sh --render /tmp/team-render   # inspect the install
```

See `CLAUDE.md` for the layout and how to extend it, and `GENERALIZED-TEAM.md` for the design.
