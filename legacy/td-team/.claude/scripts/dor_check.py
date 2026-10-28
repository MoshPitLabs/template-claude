#!/usr/bin/env python3
"""Definition-of-Ready (DoR) checker for a td issue tree.

Walks ``td tree <root> --json`` to enumerate every issue in the tree
(breadth-first from root_id), then ``td show <id> --json`` per issue to assert
each passes the DoR checklist in project-manager.md's "Definition of Ready
(DoR)" section.

  1. Clear title + description (heuristic: non-trivial description length — td
     has no structured what/where/why/AC fields, so this is a length proxy,
     not a semantic check; below-threshold issues need manual review)
  2. Scope label present: one of must-have/should-have/could-have (a project
     labelling convention; the checkable proxy for the DoR "estimated size"
     bullet)
  3. Files attached via ``td link``; dependencies declared or none (absence of
     a dependency is treated as "explicitly none")
  4. No unresolved blocking-question markers in the issue's logs (heuristic
     keyword scan — cannot semantically judge "resolved", only flag for review)

Also enforces the "Completeness check before reporting done" convention: when
--expected-count N is given, asserts the number of DIRECT child issues under
<root-id> equals N. When root_id has no children (a single-issue plan), the DoR
checks run against the root issue itself. --emit-map prints a markdown
id->title->labels table of root's direct children.

Read-only. Never edits, never writes. Stdlib + td CLI only.

NOTE ON td JSON SHAPES: td's `tree`/`show --json` field names are read
defensively (envelope-tolerant helpers below). If your installed td nests
these differently, adjust `normalize()`, `child_nodes()`, and the field reads
in `check_issue()`.
"""

import argparse
import json
import re
import subprocess
import sys

MOSCOW_LABELS = {"must-have", "should-have", "could-have"}
BLOCKING_MARKERS = re.compile(
    r"(unresolved|blocking question|needs a consult|open design dimension|"
    r"\btbd\b|needs decision|not settled|undetermined)",
    re.IGNORECASE,
)


def run_td_json(*args):
    result = subprocess.run(["td", *args, "--json"], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"dor_check.py: td {' '.join(args)} failed: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(2)
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        print(f"dor_check.py: td {' '.join(args)} returned non-JSON: {exc}", file=sys.stderr)
        sys.exit(2)
    if isinstance(payload, dict) and "error" in payload:
        print(f"dor_check.py: td {' '.join(args)} error: {payload['error']}", file=sys.stderr)
        sys.exit(2)
    return payload


def td_files(issue_id):
    """`td files <id> --json` -> list of {file_path,...} objects. td's `show`
    does NOT embed files, so they are fetched separately. Any failure -> []."""
    result = subprocess.run(["td", "files", issue_id, "--json"], capture_output=True, text=True)
    if result.returncode != 0:
        return []
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return []
    return payload if isinstance(payload, list) else []


def normalize(payload):
    """Unwrap common td envelopes to the issue/tree object of interest."""
    if isinstance(payload, dict):
        for key in ("issue", "tree", "data"):
            if key in payload and isinstance(payload[key], (dict, list)):
                return payload[key]
    return payload


def child_nodes(node):
    """Immediate child issue nodes of a tree node, tolerant of key naming."""
    if not isinstance(node, dict):
        return []
    for key in ("children", "child_issues", "issues", "childIssues"):
        val = node.get(key)
        if isinstance(val, list):
            return [c for c in val if isinstance(c, dict)]
    return []


def node_id(node):
    if isinstance(node, dict):
        return node.get("id") or node.get("issue_id")
    if isinstance(node, str):
        return node
    return None


def collect_tree_ids(root_id):
    """(all_descendant_ids, direct_child_count, direct_children) for the tree
    rooted at root_id, walked breadth-first via ``td tree <root>``.
    direct_children holds the raw child nodes for root_id's immediate children
    only (used by --emit-map)."""
    from collections import deque

    tree = normalize(run_td_json("tree", root_id))
    # The tree root may be the wrapper itself or its first element.
    root_node = tree[0] if isinstance(tree, list) and tree else tree

    visited = {root_id}
    all_descendant_ids = []
    direct_children = []
    # Seed the queue with the root's immediate children.
    queue = deque()
    for child in child_nodes(root_node):
        cid = node_id(child)
        if cid and cid not in visited:
            visited.add(cid)
            all_descendant_ids.append(cid)
            direct_children.append(child)
            queue.append(child)
    # BFS the rest.
    while queue:
        node = queue.popleft()
        for child in child_nodes(node):
            cid = node_id(child)
            if not cid or cid in visited:
                continue
            visited.add(cid)
            all_descendant_ids.append(cid)
            queue.append(child)
    return all_descendant_ids, len(direct_children), direct_children


def _as_paths(files):
    out = []
    for f in files or []:
        if isinstance(f, str):
            out.append(f)
        elif isinstance(f, dict):
            p = f.get("file_path") or f.get("path") or f.get("file") or f.get("name")
            if p:
                out.append(p)
    return out


def _log_bodies(issue):
    bodies = []
    for key in ("logs", "activity", "comments"):
        for entry in issue.get(key) or []:
            if isinstance(entry, dict):
                bodies.append(entry.get("message") or entry.get("body") or entry.get("text") or "")
            elif isinstance(entry, str):
                bodies.append(entry)
    return bodies


def check_issue(issue, min_desc_length):
    findings = []
    title = (issue.get("title") or "").strip()
    description = (issue.get("description") or "").strip()
    if not title:
        findings.append("FAIL title: empty")
    if not description or len(description) < min_desc_length:
        findings.append(
            f"FAIL description: below heuristic length threshold "
            f"({len(description)} < {min_desc_length} chars) — verify manually "
            f"it states what/where/why/acceptance-criteria"
        )

    labels = set(issue.get("labels") or [])
    if not (labels & MOSCOW_LABELS):
        findings.append(
            f"FAIL scope-label: none of {sorted(MOSCOW_LABELS)} present (labels={sorted(labels)})"
        )

    files = _as_paths(issue.get("files"))
    if not files:
        findings.append("FAIL files: none attached")

    blocking = [b for b in _log_bodies(issue) if BLOCKING_MARKERS.search(b)]
    if blocking:
        excerpt = blocking[0][:120].replace("\n", " ")
        findings.append(
            f"WARN blocking-question: {len(blocking)} log line(s) match blocking-keyword "
            f'heuristic, e.g. "{excerpt}..."'
        )

    return findings


def print_child_map(direct_children):
    """Print a markdown id->title->labels table of root's direct children,
    for verbatim inclusion in a plan-completion report."""
    print()
    print("| ID | Title | Labels |")
    print("| --- | --- | --- |")
    for child in direct_children:
        title = (child.get("title") or "").replace("|", "\\|")
        labels = ", ".join(sorted(child.get("labels") or [])) or "(none)"
        print(f"| {node_id(child)} | {title} | {labels} |")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("root_id", help="root/epic td issue id, e.g. td-a1b2")
    parser.add_argument(
        "--expected-count",
        type=int,
        default=None,
        help="expected direct-child-issue count (N); enforces created-child-count == N",
    )
    parser.add_argument(
        "--min-desc-length",
        type=int,
        default=40,
        help="heuristic minimum description length in chars (default: 40)",
    )
    parser.add_argument(
        "--emit-map",
        action="store_true",
        help="also print a markdown id->title->labels table of root's direct "
        "children, for verbatim inclusion in a plan-completion report",
    )
    args = parser.parse_args(argv)

    all_descendant_ids, direct_child_count, direct_children = collect_tree_ids(args.root_id)
    if all_descendant_ids:
        issue_ids_to_check = all_descendant_ids
    else:
        print(
            f"dor_check.py: no child issues found under root {args.root_id}; "
            "checking root issue itself",
            file=sys.stderr,
        )
        issue_ids_to_check = [args.root_id]

    total_fail = 0
    total_warn = 0
    for issue_id in issue_ids_to_check:
        issue = normalize(run_td_json("show", issue_id))
        # `td show` does not embed files — fetch them via `td files`.
        issue["files"] = td_files(issue_id)
        findings = check_issue(issue, args.min_desc_length)
        fails = [f for f in findings if f.startswith("FAIL")]
        warns = [f for f in findings if f.startswith("WARN")]
        total_fail += len(fails)
        total_warn += len(warns)
        if not findings:
            print(f"{issue_id}: PASS")
        else:
            status = "FAIL" if fails else "WARN"
            print(f"{issue_id}: {status}")
            for f in findings:
                print(f"  {f}")

    print()
    print(
        f"DoR summary: {len(issue_ids_to_check)} issue(s) checked, "
        f"{total_fail} FAIL finding(s), {total_warn} WARN finding(s)"
    )

    count_ok = True
    if args.expected_count is not None:
        count_ok = direct_child_count == args.expected_count
        marker = "OK" if count_ok else "MISMATCH"
        print(
            f"Completeness check: direct children under {args.root_id} = "
            f"{direct_child_count}, expected = {args.expected_count} [{marker}]"
        )

    if args.emit_map:
        print_child_map(direct_children)

    return 1 if (total_fail > 0 or not count_ok) else 0


if __name__ == "__main__":
    sys.exit(main())
