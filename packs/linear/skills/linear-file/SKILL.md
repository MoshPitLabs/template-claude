---
name: linear-file
description: File a Linear issue from a description, a finding, or a failure outside the current scope, after checking for duplicates.
argument-hint: "<what the issue is about>"
disable-model-invocation: true
---

File a Linear issue as team-lead for:

$ARGUMENTS

1. Load `linear-tracking` and read `.claude/local/linear.md` (create it first if missing). If `create_issues` is `never`, return the draft to the user instead of filing.
2. Gather the evidence the issue needs from the conversation or the repository (read-only): observed vs expected, file:line, log excerpt. Do not start a fix.
3. Search for duplicates (`list_issues` with `query` and `team`). If one matches, show it and ask whether to comment on it instead.
4. Draft the title, description, labels (bug or feature labels from the setup) and relations (`relatedTo` the current work item, or `parentId` for a sub-task).
5. Unless `create_issues` is `always` or the user already approved this issue, show the draft and confirm before `save_issue`.

Return the identifier and URL of the issue.
