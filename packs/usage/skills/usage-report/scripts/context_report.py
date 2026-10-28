#!/usr/bin/env python3
"""Context window breakdown for one Claude Code session, from its transcript.

The total is exact: the input, cache-read and cache-write tokens of the session's last completed API
request. The split is estimated: system prompt and tool schemas come from the request-shape record,
everything else from the active message chain (user, assistant and attachment records back to the last
compaction). Each part is sized by its text length and scaled so the parts add up to the exact total;
thinking uses the recorded thinking-token counts and images their pixel size, unscaled.

Writes a self-contained HTML page and prints a JSON summary on stdout:
{"html", "height", "session", "model", "total", "window", "groups": [...], "scale"}.

Usage: context_report.py [--session ID]   (default: $CLAUDE_CODE_SESSION_ID, else the newest
transcript of the current directory's project). USAGE_REPORT_DIR overrides the output directory.
"""
import argparse
import base64
import glob
import json
import os
import struct
import sys
from collections import defaultdict

sys.dont_write_bytecode = True  # no __pycache__ next to the scripts: read-only roles run them inside a repository
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # report_style lives next to this script
import report_style as rs  # noqa: E402

ROOT = os.path.expanduser("~/.claude/projects")
WINDOWS = {"claude-haiku-4-5": 200_000}  # every other current model has a 1M-token window
CHARS_PER_TOKEN = 4.0  # only the starting point; the result is scaled to the exact total
ATTACHMENTS = {
    "deferred_tools_record": "Deferred tools & loaded schemas", "deferred_tools_delta": "Deferred tools & loaded schemas",
    "instructions": "CLAUDE.md & rules", "mcp_instructions_delta": "MCP server instructions",
    "skill_listing": "Skill listing", "agent_listing_delta": "Agent listing",
}
SKIP_ATTACHMENTS = {"prompt_snapshot"}  # bookkeeping copy of the system prompt and tools, not sent


def find_transcript(session):
    if session:
        hits = glob.glob(f"{ROOT}/*/{session}.jsonl")
        if hits:
            return hits[0]
        sys.exit(json.dumps({"error": f"no transcript for session {session}"}))
    slug = "".join(c if c.isalnum() else "-" for c in os.getcwd())
    files = glob.glob(f"{ROOT}/{slug}/*.jsonl")
    if not files:
        sys.exit(json.dumps({"error": "no session given and no transcript for this directory"}))
    return max(files, key=os.path.getmtime)


def image_tokens(block):
    data = (block.get("source") or {}).get("data") or ""
    raw = base64.b64decode(data[:64] + "=" * (-len(data[:64]) % 4)) if data else b""
    if raw[:8] == b"\x89PNG\r\n\x1a\n":
        w, h = struct.unpack(">II", raw[16:24])
        scale = min(1.0, 1568 / max(w, h))
        return int(w * scale * h * scale / 750)
    return 1600


def analyse(path):
    records = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            try:
                records.append(json.loads(line))
            except ValueError:
                pass
    assistants = [r for r in records if r.get("type") == "assistant" and (r.get("message") or {}).get("usage")]
    if not assistants:
        sys.exit(json.dumps({"error": "the session has no completed API request yet"}))
    last = assistants[-1]
    u = last["message"]["usage"]
    total = u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
    model = last["message"].get("model", "?")

    by_uuid = {r["uuid"]: r for r in records if r.get("uuid")}
    chain, node = [], last
    while node:
        chain.append(node)
        node = None if node.get("isCompactSummary") else by_uuid.get(node.get("parentUuid"))
    chain.reverse()

    shapes = {r["shapeHash"]: r["shape"] for r in records if r.get("type") == "api-request-shape"}
    requests = [r for r in records if r.get("type") == "api-request"]
    shape = shapes.get(requests[-1].get("shapeHash")) if requests else None

    est = defaultdict(float)      # (group, item) -> chars/4, scaled later
    fixed = defaultdict(float)    # (group, item) -> tokens, not scaled
    notes = defaultdict(int)
    if shape:
        est[("Fixed setup", "System prompt")] += sum(len(b.get("text", "")) for b in shape.get("system", [])) / CHARS_PER_TOKEN
        est[("Fixed setup", "Tool definitions")] += len(json.dumps(shape.get("tools", []))) / CHARS_PER_TOKEN
        notes["tools"] = len(shape.get("tools", []))

    tool_names = {}
    for r in chain:
        content = (r.get("message") or {}).get("content")
        for b in content if isinstance(content, list) else []:
            if b.get("type") == "tool_use":
                tool_names[b["id"]] = b["name"]

    def tool_item(name):
        if name == "Bash":
            return "Shell commands & output"
        if name in ("Read", "Write", "Edit", "MultiEdit", "NotebookEdit"):
            return "File reads & writes"
        if name in ("Grep", "Glob"):
            return "Searches"
        if "html_render" in name or "html_preview" in name:
            return "Inline pages (HTML)"
        if name in ("Agent", "Task"):
            return "Subagent briefs & reports"
        if name.startswith("mcp__"):
            return "Other MCP tools"
        return "Other tools"

    seen_ids = set()
    for r in chain:
        kind = r.get("type")
        if kind == "attachment":
            a = r.get("attachment") or {}
            if a.get("type") in SKIP_ATTACHMENTS:
                continue
            item = ATTACHMENTS.get(a.get("type"), "Environment, session & mode")
            notes["claude_md"] += a.get("type") == "instructions"
            est[("Injected context", item)] += len(json.dumps(a)) / CHARS_PER_TOKEN
            continue
        if kind not in ("user", "assistant"):
            continue
        msg = r.get("message") or {}
        if kind == "assistant" and msg.get("id") and msg["id"] not in seen_ids:
            seen_ids.add(msg["id"])
            fixed[("Conversation", "Thinking")] += ((msg.get("usage") or {}).get("output_tokens_details") or {}).get("thinking_tokens", 0)
        content = msg.get("content")
        if isinstance(content, str):
            content = [{"type": "text", "text": content}]
        for b in content or []:
            bt = b.get("type")
            if bt == "text":
                text = b.get("text", "")
                head = text.lstrip()
                if kind == "assistant":
                    key = ("Conversation", "My replies")
                elif head.startswith("Base directory for this skill"):
                    key = ("Loaded skills", head.split("\n")[0].rstrip("/").rsplit("/", 1)[-1])
                elif r.get("isMeta") or head.startswith(("<system-reminder>", "<command-", "<t3_context", "[Image:", "<local-command")):
                    key = ("Injected context", "Reminders & command output")
                else:
                    key = ("Conversation", "Your prompts")
                    notes["prompts"] += 1
                est[key] += len(text) / CHARS_PER_TOKEN
            elif bt == "image":
                fixed[("Conversation", "Images")] += image_tokens(b)
                notes["images"] += 1
            elif bt == "tool_use":
                est[("Tool traffic", tool_item(b.get("name", "")))] += len(json.dumps(b.get("input", {}))) / CHARS_PER_TOKEN
                notes["tool_calls"] += 1
            elif bt == "tool_result":
                item = tool_item(tool_names.get(b.get("tool_use_id"), ""))
                c = b.get("content")
                for x in c if isinstance(c, list) else [{"type": "text", "text": str(c or "")}]:
                    if x.get("type") == "image":
                        fixed[("Conversation", "Images")] += image_tokens(x)
                        notes["images"] += 1
                    else:
                        est[("Tool traffic", item)] += len(x.get("text") or json.dumps(x)) / CHARS_PER_TOKEN
            elif bt in ("thinking", "redacted_thinking"):
                notes["thinking"] += 1

    rest = total - sum(fixed.values())
    scale = rest / sum(est.values()) if est and rest > 0 else 1.0
    items = {k: v * scale for k, v in est.items()}
    for k, v in fixed.items():
        items[k] = items.get(k, 0) + v
    return dict(path=path, model=model, total=total, items=items, scale=scale, notes=notes,
                messages=sum(1 for r in chain if r.get("type") in ("user", "assistant")),
                cache=(u.get("cache_read_input_tokens", 0), u.get("cache_creation_input_tokens", 0), u.get("input_tokens", 0)),
                has_shape=bool(shape))


GROUPS = [  # order = colour order
    ("Tool traffic", "Commands run and what came back"),
    ("Injected context", "Added by the harness, not typed by anyone"),
    ("Loaded skills", "Skill bodies stay in context once loaded"),
    ("Conversation", "What was said, and the thinking behind it"),
    ("Fixed setup", "System prompt and tool schemas, sent with every request"),
]


def render(a):
    total, window = a["total"], WINDOWS.get(a["model"], 1_000_000)
    n = a["notes"]
    tips = {"Thinking": f'{n["thinking"]} blocks; recorded thinking tokens',
            "Images": f'{n["images"]} images', "Your prompts": f'{n["prompts"]} messages',
            "Tool definitions": f'{n["tools"]} tool schemas',
            "CLAUDE.md & rules": f'{n["claude_md"]} copies (re-read after changes)'}
    groups = []
    for (name, sub), color in zip(GROUPS, rs.COLORS):
        rows = sorted(((item, v) for (g, item), v in a["items"].items() if g == name and v >= 50), key=lambda x: -x[1])
        if rows:
            groups.append((name, sub, color, rows, sum(v for _, v in rows)))
    top = max(v for *_, rows, _ in groups for _, v in rows)

    def pct(x):
        return f"{x / total * 100:.0f}%" if x / total >= 0.01 else "<1%"

    segments = [(name, t, c, f"{name}: {t:,.0f} tokens ({pct(t)} of context)") for name, _, c, _, t in groups]
    free = window - total
    sections, heights = [], []
    for name, sub, color, rows, t in groups:
        cells = [(item, v, rs.tokens(v), color, f"{item}: ~{v:,.0f} tokens" + (f" · {tips[item]}" if item in tips else ""))
                 for item, v in rows]
        sections.append(rs.section(name, cells, top, f"{rs.tokens(t)} · {pct(t)}", sub, color))
        heights.append(rs.section_height(len(rows)))
    biggest_name, biggest = max(((item, v) for (g, item), v in a["items"].items() if item != "Tool definitions"), key=lambda x: x[1])
    cached, written, uncached = a["cache"]
    body = "\n".join([
        rs.hero(rs.tokens(total), f'of {window // 1000:,}k tokens · {total / window * 100:.1f}% of the {a["model"]} window · {a["messages"]} messages'),
        rs.stack(segments, (free, f"Free: {free:,} tokens"), ["0", f"{window // 4000}k", f"{window // 2000}k", f"{window * 3 // 4000}k",
                                                               f"{window // 1000}k" if window < 1_000_000 else "1M"]),
        rs.legend([(name, rs.tokens(t), c) for name, _, c, _, t in groups] + [("Free", rs.tokens(free), "--secondary")]),
        rs.grid(sections),
        rs.note(f"<b>Largest single item:</b> {rs.esc(biggest_name)} (~{rs.tokens(biggest)}, {pct(biggest)} of context). "
                f"<b>Cache:</b> {cached:,} tokens read from cache, {written:,} written, {uncached:,} uncached on the last request. "
                "The total is exact, from the API's usage for the last completed request; the split is estimated from content size "
                f"and scaled to that total (×{a['scale']:.2f} over 4 characters per token)."
                + ("" if a["has_shape"] else " No request-shape record was found, so the system prompt and tool schemas are folded into the other groups.")),
    ])
    height = rs.HEAD_H + rs.grid_height(heights) + rs.NOTE_H
    return rs.page(body), min(height, 2000), groups, window


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--session", default=os.environ.get("CLAUDE_CODE_SESSION_ID"), help="session id (default: this session)")
    args = ap.parse_args()
    a = analyse(find_transcript(args.session))
    page, height, groups, window = render(a)
    out_dir = os.environ.get("USAGE_REPORT_DIR") or os.path.join(
        os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "claude-usage-report")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "context.html")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(page)
    json.dump({"html": out, "height": height, "session": os.path.basename(a["path"])[:-6], "model": a["model"],
               "total": a["total"], "window": window, "scale": round(a["scale"], 2),
               "groups": [{"name": name, "tokens": round(t), "items": {i: round(v) for i, v in rows}} for name, _, _, rows, t in groups]},
              sys.stdout, indent=1)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
