---
name: linear-tracking
description: How the team uses the Linear MCP tools — reading issues, moving states, commenting, filing issues — and the per-repository setup in .claude/local/linear.md. Load before the first Linear tool call of a session.
---

# Linear tracking

Tools are `mcp__plugin_mcp-servers_linear__<name>`. Rules for who writes what and when: `Tracking` in `.claude/rules/linear-tracking.md`.

## Repository setup

`.claude/local/linear.md` holds `team`, `project`, the labels for bugs and features, `started_state`, `done_state`, `done_on_accept`, and `create_issues`. Template: `references/local-linear-template.md`. Fill it with `list_teams`, `list_projects`, `list_issue_statuses` (by team) and `list_issue_labels`; never guess a team, state or label name.

## Reading

| Need | Tool |
|---|---|
| One issue, with branch name and relations | `get_issue` (`includeRelations: true`; ask for `gitBranchName` in `fields`) |
| Its discussion | `list_comments` (`issueId`) |
| Screenshots in a description or comment | `extract_images` (pass the Markdown) |
| Sub-issues | `list_issues` (`parentId`) |
| Duplicates before filing | `list_issues` (`query`, `team`) |
| States of a team | `list_issue_statuses` |

## Writing (team-lead only)

- `save_issue` without `id` creates (`team` and `title` required; `project`, `labels`, `parentId`, `relatedTo` as needed). With `id` it updates; set `state` to the name from `.claude/local/linear.md` or a state type (`started`, `completed`). Prefer `addLabels` over `labels`, which replaces the whole set, and `patch` over `description`, which replaces the whole text.
- `save_comment` with `issueId` and `body`; `parentId` to reply in a thread.
- Send Markdown with real newlines, never `\n` escapes.
- Every other write tool (labels, projects, documents, attachments, status updates, diffs, deletes) prompts the user; `merge_diff` is denied.

## Issue body when filing

Title: the outcome in a few words. Description: context, observed vs expected (bugs) or goal (features), acceptance, and evidence (log excerpt, file:line). Link the originating issue with `relatedTo`, or set `parentId` for a sub-task.
