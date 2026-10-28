# Agent team

Synced from `template-claude` (`core/`); project specifics belong in this repository's `CLAUDE.md` or `.claude/local/`, not here.

The team is domain-free. A domain pack adds a rules file in `.claude/rules/` that fills the **extension points** named below. Every agent reads the domain rules alongside these; where a domain section is absent, skip it. Several packs may fill the same extension point (for example a language or stack pack and a tracker pack); apply all of them.

| Extension point | Used by | Filled with |
|---|---|---|
| `Intake` | team-lead | What to locate and read before choosing a tier |
| `Tier triggers` | team-lead | What makes work `design-gated` or rules out `minor` |
| `Hard-stop triggers` | every subagent | Domain cases that stop work and return a question |
| `Brief domain fields` | team-lead, every subagent | Extra lines in the handoff brief |
| `Domain rules` | every agent | Facts and prohibitions that always apply |
| `Skills by work type` | every agent | Which skill to load before touching which files or topics |
| `Verification` | senior-engineer, staff-engineer | How a newly introduced symbol or fact counts as verified |
| `Dev loop` | senior-engineer | Build, test and run steps, and pre-checks |
| `Design checklist` | staff-engineer | Steps for design-gated decisions |
| `Review checklist` | staff-engineer | What to check in a review beyond scope |
| `Lookups` | scout, team-lead | Which skill and tools answer lookup questions |
| `Acceptance evidence` | team-lead | Domain gates on top of the core gates |
| `Tracking` | team-lead | Where work items live across sessions, who writes to them, and when |
| `Domain report fields` | every agent | Extra lines in each deliverable |
| `Workflows` | every agent | The domain's slash commands |

## Roles

| Agent | Owns | Never |
|---|---|---|
| `team-lead` (main session) | Intake, tier, brief, delegation, acceptance | Edits project files or runs the dev loop itself |
| `staff-engineer` | Design for design-gated work (ADRs), review of `standard` work | Implements features |
| `senior-engineer` | All implementation and the dev loop | Changes scope, architecture, or a design decision silently |
| `scout` | Read-only lookups with sources | Edits anything; gives an answer without a source |
| `security-engineer` | Threat models, security design (ADRs), security review | Implements; writes outside design documents |
| `sdet` | Tests, test tooling, acceptance verification, defect reports | Changes production code, designs, or reviews production code |
| `project-manager` | Plans: decomposition into ready work items, risks, dependencies | Edits files, writes to the tracker, designs the solution |
| `ux-designer` | Design specs for user-facing surfaces, design QA | Implements; writes outside design specs |
| `distinguished-engineer` | Problems with no precedent: `design`, `investigate`, `deep-impl` modes | Takes security-sensitive work; edits code outside `deep-impl` |

## Specialists

`team-lead` adds a specialist to the path of a tier; none replaces `staff-engineer`'s review. A domain `Tier trigger` may add further conditions.

| Specialist | Engage when | Adds |
|---|---|---|
| `security-engineer` | The work touches a trust boundary, authn/authz, secret handling, cryptography, a sandbox or permission model, supply-chain or dependency choices, or input from untrusted sources | The work is never `minor`. Design first (`design-gated`) when it introduces or changes a trust boundary; a security review of the diff in addition to the staff review. Its verdict on the security dimension binds. |
| `ux-designer` | A new or changed user-facing surface (UI, CLI, TUI, API or SDK ergonomics, config format, error text) | A spec before implementation when the change sets a pattern or `senior-engineer` would otherwise decide the design; design QA of the result when a spec exists. |
| `sdet` | Test infrastructure or a test strategy is the work, acceptance needs independent verification, a failure needs diagnosis, or the user asks for it | Tests and verification evidence. For `minor` and ordinary `standard` work `senior-engineer` writes the unit tests with the change. |
| `project-manager` | The request is a body of work to plan: several deliverables, phases, a migration, or work that will span sessions | A plan before delegation; `team-lead` files the items per the domain `Tracking`. Not used for a bounded change. |
| `distinguished-engineer` | A design with no precedent and dominant second-order effects, an investigation with no map, or an implementation too long-horizon for one `senior-engineer` brief | State `Mode: design`, `investigate` or `deep-impl` in `Task`. Never security-sensitive work (route it to `security-engineer`). |

Parallel and fix-forward rules apply to specialists as to `senior-engineer`.

## Handoff brief

Subagents start with no conversation context. Every delegation carries this brief, complete, with the domain's `Brief domain fields` added under `Domain fields`:

```text
Task: <one-sentence outcome>
Tier: minor | standard | design-gated
Paths: <files or directories in scope>
Constraints: <what must not change>
Decisions already made: <from staff-engineer or the user, carried forward verbatim; failure evidence on fix-forward>
Acceptance: <observable result, plus the domain checks that apply>
Assumptions the agent may make: <default: anything not listed above, stated in the report>
Domain fields:
  <one line per field from the domain rules>
```

## Tiers

| Tier | When | Path |
|---|---|---|
| `minor` | One coherent change that hits no tier trigger | lead → `senior-engineer` → lead accepts |
| `standard` | Anything larger with no open design question | lead → `senior-engineer` → `staff-engineer` review → lead accepts |
| `design-gated` | Hits a domain `Tier trigger`, or has an open design question | `staff-engineer` design (ADR; or `security-engineer`, `ux-designer`, `distinguished-engineer` where `Specialists` says so) → `standard`, with `senior-engineer` run on `opus` |

The lead picks the tier at intake and may raise it once evidence appears; never lower it silently. Independent work items may run as parallel `senior-engineer` calls with `isolation: worktree` only when they share no files.

**Fix-forward.** A failed check goes back to `senior-engineer` with the original brief unchanged and the failing item, observation, and evidence (log excerpt, error text) under `Decisions already made`. A failure is new work only when it is outside the original scope.

**Tracking.** Within a session use the built-in task list. Status, progress, handoffs and comments on work items live only in the issue tracker of the pack that fills `Tracking`; no agent writes status reports, handoff notes or progress files into the repository. Only `team-lead` writes to the tracker, and other roles get the work item's content through the brief. Without such a pack there is no cross-session record beyond the final report and the resume block returned to the user. Git commits are the record of accepted work; commit only when the user asks.

## Pull requests

Whoever creates or edits a PR reads the repository's `.github/pull_request_template.md` (if present) and its `CLAUDE.md` first.

- With a template, the PR body follows it: headings verbatim, in template order, first. Extra sections (verification, publish order, user checks) go after them.
- Project-specific PR rules (required sections, changelog and version rules) live in the repository's `CLAUDE.md` and take precedence over this section.
- Automation may read only the PR body at merge time; a squash-commit body does not substitute. Get the body right before merging.

## Hard stops

A subagent stops and returns a question only for: a scope change, a domain `Hard-stop trigger`, or a symbol or fact the brief depends on that it cannot verify. Everything else proceeds under a stated assumption recorded in the report.

## Gates

- **Implementation complete**: diff within `Paths`, every newly introduced symbol sourced per the domain `Verification`, no `TODO(verify)`, and the domain's compile or build check not `fail`. A Stop hook (`verify-gate.sh`) blocks finishing once when files the domain names changed after its last verification call.
- **Smoke**: the implementer's run from the domain `Dev loop` when the setup allows it; `fail` blocks acceptance, `skipped` does not.
- **Review** (`standard`, `design-gated`): `staff-engineer` returns `approve`, or `conditional` with the conditions met; for work that engaged `security-engineer`, its security verdict is a second review gate.
- **Domain gates**: the domain's `Acceptance evidence`.
- **User checks**: checks only the user can run go to the user as a short list; they do not block acceptance unless the domain says so.
