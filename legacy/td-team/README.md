# template-claude

A project-scoped **Claude Code** configuration that turns a repo into a
coordinated team of specialist sub-agents (team-lead, project-manager,
staff/senior/distinguished engineers, sdet, security-engineer, ux-designer)
with planning, design, implementation, review, and verification gates.

It is adapted from
[`ALT-F4-LLC/dotfiles.vorpal`](https://github.com/ALT-F4-LLC/dotfiles.vorpal/tree/main/src/user/claude-code),
with three upstream dependencies removed and one added:

| Removed | Replaced with |
|---|---|
| **Vorpal** (build tool / toolchain wrapper) | native tools (`go`, `cargo`, …) |
| **Mimir / Loki / OTEL** (telemetry) | dropped entirely (transcript-only signals) |
| **Docket** (issue tracker) | **[td](https://github.com/marcus/td)** — a local-first, SQLite issue tracker for AI coding sessions |

Every `td` command surface in the agents/skills/scripts was **verified against a
live `td 0.51.0`**, not just ported from docs.

## Requirements

- **[td](https://github.com/marcus/td)** on `PATH` (`td version`) — the task tracker the whole workflow drives.
- `jq`, `git`, `bash`, `python3` — used by the hooks and helper scripts.
- Optional, per task: `gh`, `go` + `govulncheck`, `cargo`, `bun`/`npm`.
- Claude Code with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (set in `settings.json`) for the multi-agent team workflow.

## Layout

```
.claude/
  settings.json      # model, permissions, sandbox, hooks (via $CLAUDE_PROJECT_DIR), statusline
  statusline.sh      # color status bar
  agents/            # 8 role sub-agents
  hooks/             # 6 lifecycle hooks (git-commit guard, /tmp guard, stop-guard, teammate hooks)
  scripts/           # helper scripts the agents/skills call at runtime
  skills/            # td, vote, tdd, adr, prd, ux-spec, commit, code-review-verdict, team-doctrine, …
specs/               # PRDs / ADRs / TDDs / UX specs + reserved reference files live here
```

Paths are **project-relative** (`.claude/scripts/…`, `.claude/skills/…`): the
config works directly in this repo. Agent-memory (`~/.claude/agent-memory/`),
caches, and team state stay at the user level.

## Key conventions

- **Task tracking is `td`.** Run `td init` once per repo (creates `.todos/`, which is gitignored). The **[[td]]** skill is the full command reference.
- **Specs live in `specs/`.** The `prd`/`adr`/`tdd`/`ux-spec`/`init-specs` skills write markdown files under `specs/` and attach them to the relevant issue with `td link <id> specs/<file>`. (td has no document store.)
- **Consensus voting is a hand-rolled convention** (td has no `vote` command): a proposal is a `--label vote` issue, each reviewer's verdict is a `td log "VOTE …"` line, and the coordinator computes weighted quorum by hand and closes with `td approve`. See the **vote** skill and `scripts/vote_delegate.sh`.
- **Role attribution rides on a label** (td has no assignee): `scripts/td_claim.sh <id> <role>` does `td start` and adds the role as a label, which `scripts/roster_sweep.sh` and the stop-guard hook query via `td query "labels ~ <role>"`.
- **No commits without explicit instruction** — enforced by `hooks/guard-no-commit-hook.sh` and every agent's charter.

## What was pruned from upstream

Per a "keep only what the agents/skills call at runtime" scope:

- The upstream **prompt-authoring CI test suite** (`scripts/test/**`) and unreferenced validators (`coupling_check`, `gate_check`, `changelog_normalize`, `config_render_diff`, etc.).
- The **evolve-\*** self-evolution skills are not part of this template. Their reference/scripts that came along (`evolve-phase0-templates.md`, `evolve_signals.py`, `symmetry_check.py`, `doctrine_check.sh`) are retained but telemetry-free and effectively dormant until those skills are added.

## Using it

1. Ensure `td` is installed, then `cd` into a project using this config and run `td init`.
2. Talk to Claude Code normally — the **team-lead** agent is the default entry point and routes work to the specialists.
3. Inspect task state anytime with `td usage`, `td list`, or `td monitor`.
