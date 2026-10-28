#!/usr/bin/env python3
"""Claude Code cost and usage report from local transcripts (~/.claude/projects).

Cost is recomputed from each API response's usage at first-party API list prices, deduplicated by
message id, main session plus subagents/*.jsonl. The cost-state records Claude Code writes reset
with every process start, so they undercount resumed sessions and are not used.

Writes a self-contained HTML page (styled with the host's theme CSS variables) and prints a JSON
summary on stdout: {"html": path, "height": px, "totals": {...}, "projects": [...], "unpriced": [...]}.

Usage: usage_report.py [--days N] [--project SUBSTRING]
The HTML goes to ~/.cache/claude-usage-report/report.html; USAGE_REPORT_DIR overrides the directory. There is
deliberately no output flag: read-only roles may run this command, and it must not write into a repository.
"""
import argparse
import glob
import json
import os
import sys
import time
from collections import defaultdict
from datetime import datetime, timezone

sys.dont_write_bytecode = True  # no __pycache__ next to the scripts: read-only roles run them inside a repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # report_style lives next to this script
import report_style as rs  # noqa: E402

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


def hours(s):
    return f"{s / 3600:,.1f} h" if s < 36000 else f"{s / 3600:,.0f} h"


def day(t):
    return datetime.fromtimestamp(t, timezone.utc).strftime("%b %d")


def days(first, last):
    return day(first) if day(first) == day(last) else f"{day(first)}–{day(last)}"


def plural(n, word):
    return f"{n:,} {word}{'' if n == 1 else 's'}"


TOP = 6  # rows per section; the rest are summarised in a "+N more" line


def render(rows, scope):
    tot = {k: sum(r[k] for r in rows) for k in ("cost", "tokens", "prompts", "seconds")}
    by_cost = sorted(rows, key=lambda r: -r["cost"])
    # Colour follows the project: the five most expensive keep their colour in every section.
    color = {r["name"]: c for r, c in zip(by_cost, rs.COLORS)}
    others = by_cost[len(rs.COLORS):]

    def col(r):
        return color.get(r["name"], rs.OTHER)

    def tip(r):
        return (f'{r["name"]}: {money(r["cost"])} over {plural(r["prompts"], "prompt")} in {plural(r["sessions"], "session")} · '
                f'{money(r["cost"] / r["prompts"])} per prompt · {rs.tokens(r["tokens"])} tokens · {hours(r["seconds"])} · '
                f'{days(r["first"], r["last"])}')

    def pct(x, of):
        return f"{x / of * 100:.0f}%" if of and x / of >= 0.01 else "<1%"

    segments = [(r["name"], r["cost"], col(r), f'{r["name"]}: {money(r["cost"])} ({pct(r["cost"], tot["cost"])} of spend)')
                for r in by_cost[:len(rs.COLORS)]]
    if others:
        o = sum(r["cost"] for r in others)
        segments.append(("Other", o, rs.OTHER, f"{len(others)} other projects: {money(o)} ({pct(o, tot['cost'])} of spend)"))
    legend = [(r["name"], money(r["cost"]), col(r)) for r in by_cost[:len(rs.COLORS)]]
    if others:
        legend.append((f"{len(others)} other projects", money(sum(r["cost"] for r in others)), rs.OTHER))

    metrics = [
        ("Dollars per human prompt", "What one prompt set in motion", lambda r: r["cost"] / r["prompts"], money, None),
        ("Cost", "API-equivalent spend", lambda r: r["cost"], money, tot["cost"]),
        ("Tokens processed", "Input, output and cache reads and writes", lambda r: r["tokens"], rs.tokens, tot["tokens"]),
        ("Active agent time", "Main sessions and subagents; gaps over 5 minutes excluded", lambda r: r["seconds"], hours, tot["seconds"]),
    ]
    sections, heights = [], []
    for title, sub, key, fmt, total in metrics:
        ranked = sorted(rows, key=lambda r: -key(r))
        shown = ranked[:TOP]
        cells = [(r["name"], key(r), fmt(key(r)), col(r), tip(r)) for r in shown]
        more = f"+{len(ranked) - TOP} more" if len(ranked) > TOP else ""
        head = fmt(total) if total is not None else f"{money(tot['cost'] / tot['prompts'])} overall"
        sections.append(rs.section(title, cells, key(ranked[0]), head, sub, more=more))
        heights.append(rs.section_height(len(shown), bool(more)))

    lead = by_cost[0]
    share = lead["cost"] / tot["cost"] if tot["cost"] else 0
    note = (f'<b>Largest project:</b> {rs.esc(lead["name"])}, {money(lead["cost"])} ({share * 100:.0f}% of spend) over '
            f'{plural(lead["prompts"], "prompt")} and {plural(lead["sessions"], "session")}, {days(lead["first"], lead["last"])}. '
            "Costs are recomputed from each response's token usage at first-party API list prices, subagents included; "
            "they are not a bill (subscriptions, fast mode and partner pricing are not reflected).")
    subtitle = (f'API-equivalent cost · {rs.tokens(tot["tokens"])} tokens · {tot["prompts"]:,} human prompts · '
                f'{hours(tot["seconds"])} agent time · {scope}')
    body = "\n".join([
        rs.hero(money(tot["cost"]), subtitle),
        rs.stack(segments),
        rs.legend(legend),
        rs.grid(sections),
        rs.note(note),
    ])
    height = rs.HEAD_H - 16 + rs.grid_height(heights) + rs.NOTE_H
    return rs.page(body), min(height, 2000), tot


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
    scope = (f"last {args.days:g} days" if args.days else "all sessions") + \
        (f' · projects matching "{args.project}"' if args.project else "") + " · this machine"
    page, height, tot = render(rows, scope)
    out_dir = os.environ.get("USAGE_REPORT_DIR") or os.path.join(
        os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "claude-usage-report")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "report.html")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(page)
    summary = {
        "html": out, "height": height, "scope": scope,
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
