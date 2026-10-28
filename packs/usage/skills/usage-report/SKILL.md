---
name: usage-report
description: Report Claude Code cost and usage across this machine's projects — API-equivalent cost, tokens, human prompts, active agent time, and dollars per human prompt by project. Use when the user asks what their Claude Code usage cost, which project is most expensive, or for a usage report.
argument-hint: "[--days N] [--project TEXT]"
---

Run the report script from this skill's base directory (shown above as "Base directory for this skill") with the user's arguments. `--days N` limits it to the last N days, `--project TEXT` to project folders containing TEXT:

```bash
python3 -I <base directory>/scripts/usage_report.py $ARGUMENTS
```

It reads `~/.claude/projects/` (main sessions and subagent transcripts), prices every API response at first-party list prices, writes a self-contained HTML report to `~/.cache/claude-usage-report/report.html` (same look as `/context-report`, shared through `scripts/report_style.py`), and prints a JSON summary with `html` (the file), `height`, `totals`, `projects` and `unpriced_models`.

Show the result:

- If an inline HTML tool is available (for example T3's `html_render`), read the `html` file and pass its full content with the summary's `height` and a title such as "Claude Code costs and usage". Do not restate what the page shows.
- Otherwise reply with a compact table from `projects` (project, cost, prompts, $/prompt, agent hours), the totals, and the path to the HTML file.

Then add only what the page does not say:

- Any `unpriced_models`: their usage counts as $0 until they are added to `PRICES` in the script.
- The figures are API-equivalent list prices, not a bill: subscription plans, fast mode surcharges, and partner pricing (Bedrock, Vertex) are not reflected.
- Projects are grouped by working-directory folder name, so one repository checked out in two places shows as two projects.
