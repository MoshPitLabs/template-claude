# Linear setup for this repository

Copy to `.claude/local/linear.md` and fill in. Repository-owned; the template sync never touches it. Names must match Linear exactly (`list_teams`, `list_projects`, `list_issue_statuses`, `list_issue_labels`).

```text
team: <team name or key>
project: <project name, or "none">
bug_labels: <labels for defects, e.g. Bug>
feature_labels: <labels for features, e.g. Feature>
started_state: <state set at first delegation, e.g. In Progress>
done_state: <state set on acceptance when done_on_accept is yes, e.g. Done>
done_on_accept: no   # yes | no — no leaves closing to the PR merge integration
create_issues: ask   # ask | always | never — when team-lead may file new issues
```
