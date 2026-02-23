# Agent Tools and Permission Policy

This document defines the canonical `tools` and `permission` frontmatter policy for all agent roles in this repository.

## Overview

Explicit, complete tool declarations are required so that:

- every agent is auditable and predictable,
- bulk frontmatter edits can be applied mechanically,
- least-privilege defaults are enforced by role,
- custom permission profiles are preserved where intentional.

## Mandatory Tool Keys (exactly 7)

Every agent frontmatter MUST declare all seven keys under `tools`:

1. `edit` - in-place file modification capability.
2. `write` - create/overwrite file capability.
3. `skill` - ability to load skills.
4. `td` - access to TD task tool.
5. `webfetch` - external documentation/web retrieval.
6. `todowrite` - internal plan/checklist writing.
7. `bash` - shell command execution.

Rules:

- No missing keys.
- No extra keys in `tools`.
- No `null`/implicit values; each key is explicit `true` or `false`.

## Archetype Defaults (7-key tools matrix)

| Archetype | edit | write | skill | td | webfetch | todowrite | bash |
|---|---:|---:|---:|---:|---:|---:|---:|
| Orchestration | false | false | true | true | true | true | false |
| Planning | false | false | true | true | true | true | false |
| Read-only / Review | false | false | true | true | true | false | true †|
| Implementation | true | true | true | true | true | true | true |
| Specialized | custom | custom | true | true | custom | custom | custom |

† `bash: true` for Read-only / Review agents is constrained by a restrictive `permission.bash` block (only `ls`, `grep`, `head`, `wc`, and the audit script are allowed). The `bash: true` key enables the capability; the permission block limits its scope.

`Specialized` means per-agent custom profiles (defined below) that override generic defaults.

## Copy-Paste YAML Blocks by Archetype

Use these snippets as canonical templates. **These blocks represent the target state.** Some agents currently lack one or more keys and will require frontmatter updates — see the [Migration Required](#migration-required) section below for the explicit list.

### 1) Orchestration (`team-lead`)

```yaml
tools:
  edit: false
  write: false
  skill: true
  td: true
  webfetch: true
  todowrite: true
  bash: false
permission:
  bash:
    # bash: false in tools already disables bash; this block is retained for
    # defense-in-depth and provides an explicit audit trail.
    "*": deny
    "td*": deny  # belt-and-suspenders: td CLI must go through the td tool, not bash
  task:
    # task: controls which sub-agents this agent may invoke via the Task tool
    "*": deny
    product-manager: allow
    staff-engineer: allow
    validator: allow
```

### 2) Planning (`product-manager`)

```yaml
tools:
  edit: false
  write: false
  skill: true
  td: true
  webfetch: true
  todowrite: true
  bash: false
permission:
  bash:
    "*": deny
```

### 3) Read-only / Review (`validator`)

```yaml
tools:
  edit: false
  write: false
  skill: true
  td: true
  webfetch: true
  todowrite: false
  bash: true
permission:
  bash:
    "*": deny
    "ls*": allow
    "grep*": allow
    "head*": allow
    "wc*": allow
    "node .opencode/scripts/audit-agents.mjs*": allow
```

### 4) Implementation (staff + most techstack agents + aliases)

```yaml
tools:
  edit: true
  write: true
  skill: true
  td: true
  webfetch: true
  todowrite: true
  bash: true
permission:
  bash:
    "*": ask
```

### 5) Specialized (custom; preserve exact permission blocks)

There is no single `permission` template for this archetype. Use the per-agent blocks below exactly.

#### `git-flow-manager`

Keys being added: `webfetch`, `todowrite`, `bash` (implied by existing permission block).
Preserving: `permission.bash` block exactly as-is.

```yaml
tools:
  edit: false
  write: false
  skill: true
  td: true
  webfetch: true   # adding: was missing from current file
  todowrite: true  # adding: was missing from current file
  bash: true       # adding: implied by existing permission block; now explicit
permission:
  bash:
    "*": deny
    "git status*": allow
    "git branch*": allow
    "git checkout*": allow
    "git merge*": ask
    "git commit*": ask
    "git push*": ask
    "git pull*": allow
    "git log*": allow
    "git diff*": allow
    "git tag*": ask
    "gh pr *": ask
```

#### `linearapp`

Keys being added: `webfetch`, `todowrite`, `bash: false`.
Preserving: `permission.bash` and `mcp__linear__*` blocks exactly as-is.

```yaml
tools:
  edit: false
  write: true   # creates Linear issues (write), but never edits local files (edit: false)
  skill: true
  td: true
  webfetch: true   # adding: was missing from current file
  todowrite: true  # adding: was missing from current file
  bash: false
permission:
  bash:
    "*": deny
  mcp__linear__*: allow  # MCP tool namespace permission (not a bash glob);
                          # grants access to all Linear MCP tool calls
```

#### `nixos`

Keys being added: `webfetch`, `todowrite` (bash already present in permission block).
Preserving: `permission.bash` block exactly as-is.

```yaml
tools:
  edit: true
  write: true
  skill: true
  td: true
  webfetch: true   # adding: was missing from current file
  todowrite: true  # adding: was missing from current file
  bash: true
permission:
  bash:
    "*": ask              # default: all other bash commands require confirmation
    "nixos-rebuild*": ask # system-level rebuilds always require explicit approval
```

#### `prompt-engineering`

Keys being added: `webfetch`, `todowrite`, `bash`.
Preserving: `permission.bash: "*": deny` exactly as-is.

```yaml
tools:
  edit: true
  write: true
  skill: true
  td: true
  webfetch: true   # adding: was missing from current file
  todowrite: true  # adding: was missing from current file
  bash: false      # adding: consistent with existing bash: deny permission block
permission:
  bash:
    "*": deny
```

#### `rpg-mmo-systems-designer`

Keys being added: `webfetch`, `todowrite`, `bash`.
Preserving: `permission.bash: "*": deny` exactly as-is.

```yaml
tools:
  edit: true
  write: true
  skill: true
  td: true
  webfetch: true   # adding: was missing from current file
  todowrite: true  # adding: was missing from current file
  bash: false      # adding: consistent with existing bash: deny permission block
permission:
  bash:
    "*": deny
```

## Agent-to-Archetype Mapping (31 agents)

| Agent | Archetype |
|---|---|
| `team-lead` | Orchestration |
| `product-manager` | Planning |
| `validator` | Read-only / Review |
| `staff-engineer` | Implementation |
| `backend-golang` | Implementation |
| `backend-java-kotlin` | Implementation |
| `backend-typescript` | Implementation |
| `database-specialist` | Implementation |
| `devops-infrastructure` | Implementation |
| `frontend-react-typescript` | Implementation |
| `frontend-sveltekit` | Implementation |
| `fullstack-nextjs` | Implementation |
| `fullstack-sveltekit` | Implementation |
| `golang-backend-api` | Implementation |
| `golang-tui-bubbletea` | Implementation |
| `java-kotlin-backend` | Implementation |
| `mcp-server` | Implementation |
| `mlops-engineer` | Implementation |
| `nextjs-fullstack` | Implementation |
| `react-typescript` | Implementation |
| `security-engineer` | Implementation |
| `sveltekit-frontend` | Implementation |
| `sveltekit-fullstack` | Implementation |
| `testing-engineer` | Implementation |
| `tui-golang-bubbletea` | Implementation |
| `typescript-backend` | Implementation |
| `git-flow-manager` | Specialized |
| `linearapp` | Specialized |
| `nixos` | Specialized |
| `prompt-engineering` | Specialized |
| `rpg-mmo-systems-designer` | Specialized |


## Migration Required

The following agents currently have incomplete `tools:` blocks and MUST be updated.
Implementers should add only the listed missing keys — do not remove or reorder existing keys.

| Agent | Archetype | Missing keys to add |
|-------|-----------|---------------------|
| `team-lead` | Orchestration | `bash: false` |
| `product-manager` | Planning | `webfetch: true`, `todowrite: true`, `bash: false` |
| `validator` | Read-only / Review | `webfetch: true`, `todowrite: false`, `bash: true` |
| `staff-engineer` | Implementation | **entire `tools:` block** (currently absent) |
| `git-flow-manager` | Specialized | `webfetch: true`, `todowrite: true`, `bash: true` |
| `linearapp` | Specialized | `webfetch: true`, `todowrite: true`, `bash: false` |
| `nixos` | Specialized | `webfetch: true`, `todowrite: true` (bash already implied) |
| `prompt-engineering` | Specialized | `webfetch: true`, `todowrite: true`, `bash: false` |
| `rpg-mmo-systems-designer` | Specialized | `webfetch: true`, `todowrite: true`, `bash: false` |
| All 22 Implementation techstack agents | Implementation | `webfetch: true`, `todowrite: true`, `bash: true` (where missing) — see archetype YAML block |

**Rule**: For agents with an existing `tools:` block, insert missing keys in alphabetical order after the last existing key. For `staff-engineer`, insert the full Implementation YAML block.

## Preservation Rules (must not be overwritten)

The following 5 agents have custom permission profiles. Implementers MUST preserve their current `permission` blocks exactly, only adding missing tool keys where needed:

1. `git-flow-manager`
2. `linearapp`
3. `nixos`
4. `prompt-engineering`
5. `rpg-mmo-systems-designer`

Additional hard rule:

- Do not normalize these five to `"*": ask` or any generic bash policy.

## Rationale for Defaults

- Orchestration: coordinates other agents, tracks work (`td`, `todowrite`), and researches (`webfetch`) without directly mutating code.
- Planning: produces plans/tasks and research outputs, so it needs `td` + `webfetch` + `todowrite`, but not file mutation.
- Read-only / Review: should never write files; limited read-only shell commands support validation and audits.
- Implementation: executes end-to-end delivery and needs full editing plus controlled shell access (`ask` for bash permission).
- Specialized: role-specific risk models already exist; preserving them avoids regressions in security and workflow behavior. `webfetch: true` and `todowrite: true` are added as baseline capabilities consistent with the complexity of these roles. `bash` value is derived from each agent's existing permission block (`false` if `"*": deny` is the only rule; `true` if specific commands are allowed).
