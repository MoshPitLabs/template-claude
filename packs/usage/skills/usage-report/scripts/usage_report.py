#!/usr/bin/env python3
"""Claude Code cost and usage report from local transcripts (~/.claude/projects).

Cost is recomputed from each API response's usage at first-party API list prices, deduplicated by
message id, main session plus subagents/*.jsonl. The cost-state records Claude Code writes reset
with every process start, so they undercount resumed sessions and are not used.

Writes a self-contained HTML page (styled with the host's theme CSS variables) and prints a JSON
summary on stdout: {"html": path, "height": px, "totals": {...}, "projects": [...], "unpriced": [...]}.

Usage: usage_report.py [--days N] [--project SUBSTRING]
The HTML path defaults to ~/.cache/claude-usage-report/report.html; USAGE_REPORT_OUT overrides it. There is
deliberately no output flag: read-only roles may run this command, and it must not write into a repository.
"""
import argparse
import glob
import html
import json
import os
import sys
import time
from collections import defaultdict
from datetime import datetime, timezone

ROOT = os.path.expanduser("~/.claude/projects")
# $ per million tokens: input, output, cache read. Cache writes cost 1.25x input (5 min) or 2x input (1 h).
PRICES = {
    "claude-fable-5-1": (10.0, 50.0, 0.25),
    "claude-fable-5": (10.0, 50.0, 1.00),
    "claude-opus-5-5": (4.0, 20.0, 0.20),
    "claude-opus-5": (5.0, 25.0, 0.50),
    "claude-opus-4-8": (5.0, 25.0, 0.50),
    "claude-opus-4-7": (5.0, 25.0, 0.50),
    "claude-opus-4-6": (5.0, 25.0, 0.50),
    "claude-sonnet-5-5": (2.0, 10.0, 0.20),
    "claude-sonnet-5": (2.0, 10.0, 0.20),
    "claude-sonnet-4-6": (3.0, 15.0, 0.30),
    "claude-haiku-5-5": (0.10, 0.50, 0.01),
    "claude-haiku-4-5": (1.0, 5.0, 0.10),
}
IDLE_CAP_S = 300  # a gap longer than this between events is idle time, not agent time
NOISE = ("<local-command", "<command-name>", "<command-message>", "This session is being continued",
         "[Request interrupted", "<task-notification>", "<system-reminder>", "Base directory for this skill")


def parse_ts(record):
    t = record.get("timestamp")
    if not t:
        return None
    try:
        return datetime.fromisoformat(t.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def is_human_prompt(r):
    if r.get("type") != "user" or r.get("isMeta") or r.get("isSidechain") or r.get("promptSource") == "system":
        return False
    content = r.get("message", {}).get("content")
    if isinstance(content, list):
        if not content or content[0].get("type") == "tool_result":
            return False
        content = next((b.get("text", "") for b in content if b.get("type") == "text"), "")
    return isinstance(content, str) and not content.lstrip().startswith(NOISE)


def price(model, usage, unpriced):
    if model not in PRICES:
        unpriced.add(model)
        return 0.0
    p_in, p_out, p_read = PRICES[model]
    created = usage.get("cache_creation") or {}
    w1h = created.get("ephemeral_1h_input_tokens", 0)
    w5m = created.get("ephemeral_5m_input_tokens", usage.get("cache_creation_input_tokens", 0) - w1h)
    return (usage.get("input_tokens", 0) * p_in + usage.get("output_tokens", 0) * p_out
            + usage.get("cache_read_input_tokens", 0) * p_read
            + w5m * p_in * 1.25 + w1h * p_in * 2) / 1e6


def new_acc():
    return dict(cost=0.0, tokens=0, prompts=0, seconds=0.0, sessions=0, first=None, last=None)


def scan(path, since, seen, acc, unpriced, count_prompts):
    """Adds one transcript's events at or after `since` to acc; returns the transcript's cwd."""
    cwd, prev = None, None
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            cwd = cwd or r.get("cwd")
            t = parse_ts(r)
            if t is None or t < since:
                continue
            kind = r.get("type")
            if kind in ("user", "assistant"):
                if prev and 0 < t - prev <= IDLE_CAP_S:
                    acc["seconds"] += t - prev
                prev = t
                acc["first"] = min(acc["first"] or t, t)
                acc["last"] = max(acc["last"] or t, t)
            if kind == "assistant":
                msg = r.get("message", {})
                usage, key = msg.get("usage"), msg.get("id") or r.get("requestId")
                if usage and key and key not in seen and msg.get("model") != "<synthetic>":
                    seen.add(key)
                    acc["cost"] += price(msg.get("model"), usage, unpriced)
                    acc["tokens"] += sum(usage.get(k, 0) for k in (
                        "input_tokens", "output_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
            elif count_prompts and is_human_prompt(r):
                acc["prompts"] += 1
    return cwd


def collect(since, project_filter):
    projects, unpriced = defaultdict(new_acc), set()
    for main in glob.glob(f"{ROOT}/*/*.jsonl"):
        if os.path.getmtime(main) < since:
            continue
        seen, acc = set(), new_acc()
        cwd = scan(main, since, seen, acc, unpriced, count_prompts=True)
        for sub in glob.glob(os.path.join(main[:-len(".jsonl")], "subagents", "*.jsonl")):
            scan(sub, since, seen, acc, unpriced, count_prompts=False)
        if not cwd or acc["first"] is None:
            continue
        name = os.path.basename(cwd.rstrip("/")) or cwd
        if project_filter and project_filter.lower() not in name.lower():
            continue
        p = projects[name]
        p["sessions"] += 1
        for k in ("cost", "tokens", "prompts", "seconds"):
            p[k] += acc[k]
        p["first"] = min(filter(None, [p["first"], acc["first"]]))
        p["last"] = max(filter(None, [p["last"], acc["last"]]))
    rows = [dict(name=k, **v) for k, v in projects.items() if v["prompts"]]
    rows.sort(key=lambda r: -r["cost"] / r["prompts"])
    return rows, sorted(m for m in unpriced if m)


def money(x):
    return f"${x / 1000:.1f}k" if x >= 10000 else f"${x:,.2f}" if x < 100 else f"${x:,.0f}"


def tokens(x):
    return f"{x / 1e9:.1f}B" if x >= 1e9 else f"{x / 1e6:.1f}M" if x >= 1e6 else f"{x / 1e3:.0f}k"


def hours(s):
    return f"{s / 3600:,.1f} h" if s < 36000 else f"{s / 3600:,.0f} h"


def day(t):
    return datetime.fromtimestamp(t, timezone.utc).strftime("%b %d")


def kpis(d):
    items = [(money(d["cost"]), "API-equivalent cost"), (tokens(d["tokens"]), "processed tokens"),
             (f'{d["prompts"]:,}', "human prompts"), (hours(d["seconds"]), "active agent time")]
    return '<div class="kpis">' + "".join(f"<div><b>{v}</b><span>{l}</span></div>" for v, l in items) + "</div>"


STYLE = """
body { margin:0; font-family:var(--font-sans); color:var(--foreground); }
.kpis { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; padding:8px 0 20px; border-bottom:1px solid var(--border); }
.kpis b { display:block; font:500 26px/1.2 var(--font-mono); }
.kpis span { font-size:12px; color:var(--muted-foreground); }
h3 { display:flex; justify-content:space-between; align-items:baseline; margin:22px 0 14px; font-size:16px; font-weight:500; }
h3 small, .scope { font-size:12px; font-weight:400; color:var(--muted-foreground); }
.row { display:grid; grid-template-columns:200px 1fr 80px; align-items:center; gap:14px; height:30px; cursor:default; }
.name { font-size:14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.track { height:14px; background:var(--secondary); border-radius:4px; }
.bar { display:block; height:100%; border-radius:4px; background:var(--muted-foreground); opacity:.55; }
.row.hi .bar { background:var(--chart-1); opacity:1; }
.row:hover .bar { opacity:1; }
.val { text-align:right; font:13px var(--font-mono); }
p { margin:14px 0 0; font-size:12px; line-height:1.5; color:var(--muted-foreground); }
.lead { margin-top:26px; padding-top:18px; border-top:1px solid var(--border); }
.lead h4 { margin:0 0 10px; font-size:16px; font-weight:500; }
.lead h4 small { margin-left:8px; font-size:12px; font-weight:400; color:var(--muted-foreground); }
"""


def render(rows, scope):
    tot = {k: sum(r[k] for r in rows) for k in ("cost", "tokens", "prompts", "seconds")}
    per = [r["cost"] / r["prompts"] for r in rows]
    n_hi = 3 if len(rows) > 5 else 1
    bars = []
    for i, (r, v) in enumerate(zip(rows, per)):
        tip = (f'{r["name"]}: {money(r["cost"])} over {r["prompts"]} prompts in {r["sessions"]} sessions · '
               f'{tokens(r["tokens"])} tokens · {hours(r["seconds"])}')
        bars.append(f'<div class="row{" hi" if i < n_hi else ""}" title="{html.escape(tip)}">'
                    f'<span class="name">{html.escape(r["name"])}</span>'
                    f'<span class="track"><span class="bar" style="width:{max(v / per[0] * 100, 0.8):.2f}%"></span></span>'
                    f'<span class="val">{money(v)}</span></div>')
    if len(rows) > n_hi:
        rest = per[n_hi:]
        caption = (f'The {"three most expensive projects cost" if n_hi == 3 else "most expensive project costs"} '
                   f'{money(per[n_hi - 1]) + "–" if n_hi > 1 else ""}{money(per[0])} per human prompt; '
                   f'the rest range from {money(min(rest))}–{money(max(rest))}. ')
    else:
        caption = ""
    caption += "First-party API list prices; subagent usage included; agent time excludes gaps over 5 minutes."
    lead = max(rows, key=lambda r: r["cost"])
    span = (lead["last"] - lead["first"]) / 86400
    page = f"""<!doctype html><html><head><meta charset="utf-8"><style>{STYLE}</style></head><body>
<div class="scope">{html.escape(scope)}</div>
{kpis(tot)}
<h3>What one human prompt set in motion <small>API-equivalent dollars per prompt</small></h3>
{"".join(bars)}
<p>{caption}</p>
<div class="lead"><h4>{html.escape(lead["name"])}<small>{day(lead["first"])}–{day(lead["last"])} · {span:.1f} days elapsed · {lead["sessions"]} sessions</small></h4>
{kpis(lead)}</div>
</body></html>"""
    height = 20 + 90 + 60 + 30 * len(rows) + 50 + 150
    return page, height, tot


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--days", type=float, help="only events from the last N days")
    ap.add_argument("--project", help="only projects whose folder name contains this text")
    args = ap.parse_args()

    since = time.time() - args.days * 86400 if args.days else 0
    rows, unpriced = collect(since, args.project)
    if not rows:
        print(json.dumps({"error": "no sessions with human prompts match", "root": ROOT}))
        return 1
    scope = ("Last " + (f"{args.days:g} days" if args.days else "") if args.days else "All sessions") + \
        (f' · projects matching "{args.project}"' if args.project else "") + " · this machine"
    page, height, tot = render(rows, scope)
    out = os.environ.get("USAGE_REPORT_OUT") or os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")),
                                   "claude-usage-report", "report.html")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(page)
    summary = {
        "html": out, "height": min(height, 2000), "scope": scope,
        "totals": {"cost_usd": round(tot["cost"], 2), "tokens": tot["tokens"], "prompts": tot["prompts"],
                   "agent_hours": round(tot["seconds"] / 3600, 1)},
        "projects": [{"name": r["name"], "cost_usd": round(r["cost"], 2), "prompts": r["prompts"],
                      "usd_per_prompt": round(r["cost"] / r["prompts"], 2), "sessions": r["sessions"],
                      "tokens": r["tokens"], "agent_hours": round(r["seconds"] / 3600, 1)} for r in rows],
        "unpriced_models": unpriced,
    }
    json.dump(summary, sys.stdout, indent=1)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
