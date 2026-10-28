# Linear tracking rules

Synced from `template-claude` (`packs/linear/`). Fills the tracker extension points of `.claude/rules/team.md` with Linear, through the Linear MCP server of the `mcp-servers` plugin (tools `mcp__plugin_mcp-servers_linear__*`). It may be applied together with other domain packs' rules. Team, project, labels and state names for this repository are in `.claude/local/linear.md`.

## Intake

- When the request names a Linear issue (an identifier such as `ABC-123` or a `linear.app` URL), load `linear-tracking`, read the issue (`get_issue`, `list_comments`; `extract_images` for screenshots), and read the parent and blocking issues it names. The issue is the work item: its description and comments feed `Task`, `Acceptance` and `Constraints`, and a conflict between the issue and the user's request goes to the user.
- Read `.claude/local/linear.md`. If it is missing, create it from `linear-tracking/references/local-linear-template.md` with the user's answers before the first write to Linear.

## Brief domain fields

```text
  Issue: <identifier and title, or "none">
```

The brief carries the content of the issue the subagent needs; subagents may read the issue but never write to Linear.

## Domain rules

- Only `team-lead` writes to Linear, and only to the work item, its sub-issues, and issues the user asked to create. Never change assignee, priority, estimate, cycle, project or labels of an existing issue unless the user asks.
- Create an issue only per `create_issues` in `.claude/local/linear.md` (default `ask`: confirm with the user first).
- Never delete, archive, merge diffs, or post to projects, initiatives or documents unless the user asks. These tools prompt or are denied by settings.
- Linear is the only place for status, progress, handoffs and comments on work. Never write them into repository files (no spec, handoff or status files); the final report to the user and the Linear comments carry them.
- Linear Markdown takes real newlines, not `\n` escape sequences. Comments are written for people: outcome, verdicts, and next step, not the internal brief.

## Tracking

| When | team-lead does |
|---|---|
| Intake with an issue | Read it (see `Intake`). |
| Intake without an issue, work is `standard` or `design-gated` or spans sessions | Offer to file one (`/linear-file`), per `create_issues`; work that spans sessions has no other record. `minor` work needs no issue. |
| First delegation to `senior-engineer` | Move the issue to the `started` state from `.claude/local/linear.md` if it is in a backlog or unstarted state. |
| Staff review, ADR written | Comment with the verdict or the ADR path, one or two lines. |
| Acceptance | Comment with the final report (what changed, check verdicts, checks left for the user). Move the issue to `done_state` only if `done_on_accept: yes`; otherwise the PR merge closes it. |
| Fix-forward after a failed check | Comment with the failing item, the observation and the evidence (short log excerpt), one comment per round. |
| Out-of-scope failure or finding | Offer to file it as a new issue related to the work item, per `create_issues`. |
| Handoff | Comment with the full handoff (a domain pack's handoff command, if it has one, lists the content; otherwise the final report does); this comment is the record the next session resumes from. |

Branches and PRs: use the issue's `gitBranchName` for a new branch, and put the issue identifier with a magic word (`Fixes ABC-123`, or `Part of ABC-123` when the PR does not finish it) in the PR body so Linear links it. The repository's `CLAUDE.md` and PR template take precedence.

## Skills by work type

| Work | Skill |
|---|---|
| Any Linear tool call (first call of the session) | `linear-tracking` |

## Domain report fields

| Agent | Fields |
|---|---|
| `team-lead` | `Issue: <identifier, state now, comments posted>` |
| others | none |

## Workflows

`/linear-start <issue>` (team-lead: pick up an issue), `/linear-file <description>` (team-lead: file an issue).
