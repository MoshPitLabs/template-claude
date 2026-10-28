---
name: context-report
description: Visualize the current Claude Code session's context window — how many tokens are in use and what fills them (tool traffic, injected context, loaded skills, conversation, fixed setup). Use when the user asks how full the context is, what is taking up context, or for a context breakdown.
argument-hint: "[--session ID]"
---

Run the context script, which lives in the `usage-report` skill next to this one (this skill's base directory is shown above as "Base directory for this skill"; replace its last path part `context-report` with `usage-report`):

```bash
python3 -I <skills directory>/usage-report/scripts/context_report.py $ARGUMENTS
```

Without `--session` it reports the current session (`$CLAUDE_CODE_SESSION_ID`). It prints a JSON summary with `html` (the file), `height`, `total`, `window`, `groups` and `scale`.

Show the result:

- If an inline HTML tool is available (for example T3's `html_render`), read the `html` file and pass its full content with the summary's `height` and a title such as "Context window". Do not restate what the page shows.
- Otherwise reply with the total and window, and a compact table of `groups` with their largest items, plus the path to the HTML file.

Then add only what the page does not say, briefly:

- The figures are as of the last completed request; this turn (including rendering the page) is not in them.
- If the context is above about 60% of the window, or one group dominates, say what would free the most room (`/compact` for tool traffic; a fresh session for loaded skills and injected context).
