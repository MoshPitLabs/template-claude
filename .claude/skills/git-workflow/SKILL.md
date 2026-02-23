---
name: git-workflow
description: Branch naming, commit message format, PR conventions, and ownership rules for git operations
license: MIT
compatibility: claude-code
metadata:
  audience: engineering
  workflow: git
---
## Ownership

- `team-lead` — coordinates branching strategy, PR lifecycle, and releases.
- `senior-engineer` — executes commits, pushes, and branch operations within assigned worktree.
- PR creation is the `team-lead`'s responsibility; `senior-engineer` must not open PRs directly.

## Branch types

| Branch | Pattern | Example |
|--------|---------|---------|
| Production | `main` | `main` |
| Feature | `feature/<slug>` | `feature/user-authentication` |
| Bug fix | `bugfix/<slug>` | `bugfix/login-error` |
| Hotfix | `hotfix/<slug>` | `hotfix/security-patch` |
| Release | `release/<version>` | `release/v1.2.0` |

- `main` is protected; never push directly.
- Slugs should be lowercase, hyphen-separated, and scoped to the task.

## Commit message format

```
<type>: <subject>

<body>

<footer>
```

**Types:**

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructure, no behaviour change |
| `test` | Adding or updating tests |
| `chore` | Maintenance, tooling, config |
| `perf` | Performance improvement |

**Rules:**
- Subject: imperative mood, ≤72 chars, no trailing period.
- Body: optional; explain *why*, not *what*.
- Footer: reference issues (`Closes #123`) or breaking changes (`BREAKING CHANGE: ...`).

## PR conventions

**Title format:** matches commit type — `<type>: <concise description>`

Examples:
- `feat: add database-specialist agent`
- `fix: resolve token expiry race condition`
- `chore: update model selection guide`

**Required PR description fields:**
- **Summary** — what changed and why (1–3 bullets)
- **Impact** — discoverability, performance, breaking changes
- **Files changed** — brief breakdown of modified paths
- **Testing performed** — commands run, results observed
- **Issues closed** — `Closes #<id>` or Linear issue reference

## Guardrails

- Do not commit secrets, `.env` files, or credential artifacts.
- Keep commits atomic — one logical change per commit.
- Rebase or merge `origin/main` early when branches diverge; do not defer to merge time.
- Do not skip pre-commit hooks (`--no-verify`) without explicit team-lead approval.
