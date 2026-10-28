#!/usr/bin/env python3
"""File-collision linter for a td epic's execution plan.

Given a root/epic issue id, walks ``td tree <root> --json`` to enumerate
descendant issues, then ``td show <id> --json`` per issue for its attached
files and dependencies. Flags:

  (a) COLLISION  two issues in the *same* execution layer touching the same
      file (a same-layer collision is a planning bug regardless of any
      dependency link — a dependency cannot fix concurrent execution).
  (b) WARNING    two issues in *different* layers touching the same file with
      no dependency chain (direct or transitive, either direction) connecting
      them — the ordering happens to keep them serialized, but nothing records
      that the ordering is required.

td has no docket-style "phases". The execution LAYER used above is derived
from the dependency DAG: an issue's layer is the longest dependency depth from
a dependency-free root (issues with no unmet dependency are layer 0, an issue
depending on a layer-0 issue is layer 1, etc.). Issues in the same layer can
run concurrently, so same-layer file overlap is the collision case — the exact
intent of the original same-phase check.

Mechanizes project-manager.md's "No-collision duty" (producer-side) and
team-lead.md's consumer-side re-check.

Read-only against td (a `td tree` plus a `td show` per issue; never mutates).
Stdlib only — invokes the `td` CLI as a subprocess.

NOTE ON td JSON SHAPES: field names are read defensively. If your installed td
nests files/dependencies differently, adjust `_files_of()` / `_deps_of()`.
"""

import argparse
import itertools
import json
import subprocess
import sys
from collections import defaultdict, deque


def run_td(*args):
    result = subprocess.run(["td", *args, "--json"], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"error: td {' '.join(args)} failed: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(2)
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        print(f"error: td {' '.join(args)} returned non-JSON: {exc}", file=sys.stderr)
        sys.exit(2)
    if isinstance(payload, dict) and "error" in payload:
        print(f"error: td {' '.join(args)} error: {payload['error']}", file=sys.stderr)
        sys.exit(2)
    return payload


def _unwrap(payload, *keys):
    if isinstance(payload, dict):
        for key in keys:
            val = payload.get(key)
            if isinstance(val, (dict, list)):
                return val
    return payload


def _node_id(node):
    if isinstance(node, dict):
        return node.get("id") or node.get("issue_id")
    if isinstance(node, str):
        return node
    return None


def _children(node):
    if not isinstance(node, dict):
        return []
    for key in ("children", "child_issues", "issues", "childIssues"):
        val = node.get(key)
        if isinstance(val, list):
            return [c for c in val if isinstance(c, dict)]
    return []


def enumerate_tree_ids(root):
    tree = _unwrap(run_td("tree", root), "issue", "tree", "data")
    root_node = tree[0] if isinstance(tree, list) and tree else tree
    ids = set()
    queue = deque([root_node])
    seen_nodes = 0
    while queue:
        node = queue.popleft()
        seen_nodes += 1
        for child in _children(node):
            cid = _node_id(child)
            if cid and cid not in ids:
                ids.add(cid)
                queue.append(child)
    return ids


def _td_list(*args):
    """Run `td <args> --json`; return a list ([] on any failure)."""
    result = subprocess.run(["td", *args, "--json"], capture_output=True, text=True)
    if result.returncode != 0:
        return []
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return []
    return payload if isinstance(payload, list) else []


def _files_of(files):
    """Extract file paths from a `td files <id> --json` array (field
    `file_path`, tolerant of alternative key names / bare strings)."""
    out = set()
    for f in files or []:
        if isinstance(f, str):
            out.add(f)
        elif isinstance(f, dict):
            p = f.get("file_path") or f.get("path") or f.get("file") or f.get("name")
            if p:
                out.add(p)
    return out


def load_issue_details(issue_ids):
    """`td show` embeds neither files nor dependencies, so fetch each per
    issue: files via `td files <id>` (array of {file_path,...}), dependencies
    via `td dep <id>` ({"dependencies": [issue-id strings], "issue": {...}})."""
    files_by_issue = {}
    depends_on = defaultdict(set)
    for issue_id in issue_ids:
        files_by_issue[issue_id] = _files_of(_td_list("files", issue_id))
        dep_payload = run_td("dep", issue_id)
        deps = dep_payload.get("dependencies") if isinstance(dep_payload, dict) else []
        for d in deps or []:
            did = _node_id(d)
            if did and did in issue_ids:
                depends_on[issue_id].add(did)
    return files_by_issue, depends_on


def compute_layers(issue_ids, depends_on):
    """Longest-path depth per issue over the depends_on DAG. Cycles -> layer 0
    for the nodes involved (best-effort; td rejects most cycles at add time)."""
    layer = {}

    def depth(node, stack):
        if node in layer:
            return layer[node]
        if node in stack:
            return 0  # cycle guard
        stack.add(node)
        deps = depends_on.get(node, ())
        d = 0 if not deps else 1 + max(depth(dep, stack) for dep in deps)
        stack.discard(node)
        layer[node] = d
        return d

    for issue_id in issue_ids:
        depth(issue_id, set())
    return layer


def _reachable(start, target, depends_on):
    seen = set()
    stack = [start]
    while stack:
        node = stack.pop()
        if node == target:
            return True
        if node in seen:
            continue
        seen.add(node)
        stack.extend(depends_on.get(node, ()))
    return False


def linked(a, b, depends_on):
    """Whether a dependency chain (either direction, transitive) connects a and b."""
    return _reachable(a, b, depends_on) or _reachable(b, a, depends_on)


def find_collisions(root):
    issue_ids = enumerate_tree_ids(root)
    files_by_issue, depends_on = load_issue_details(issue_ids)
    layer_by_issue = compute_layers(issue_ids, depends_on)

    file_to_issues = defaultdict(set)
    for issue_id, files in files_by_issue.items():
        for f in files:
            file_to_issues[f].add(issue_id)

    collisions = []
    warnings = []
    for f, touching in file_to_issues.items():
        if len(touching) < 2:
            continue
        for a, b in itertools.combinations(sorted(touching), 2):
            layer_a, layer_b = layer_by_issue.get(a, 0), layer_by_issue.get(b, 0)
            if layer_a == layer_b:
                collisions.append((f, a, b, layer_a))
            elif not linked(a, b, depends_on):
                warnings.append((f, a, b, layer_a, layer_b))

    return collisions, warnings


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", required=True, help="root/epic issue id, e.g. td-a1b2")
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON instead of text")
    args = parser.parse_args(argv)

    collisions, warnings = find_collisions(args.root)

    if args.json:
        print(
            json.dumps(
                {
                    "root": args.root,
                    "collisions": [{"file": f, "issue_a": a, "issue_b": b, "layer": p} for f, a, b, p in collisions],
                    "warnings": [
                        {"file": f, "issue_a": a, "issue_b": b, "layer_a": pa, "layer_b": pb}
                        for f, a, b, pa, pb in warnings
                    ],
                },
                indent=2,
            )
        )
    else:
        if not collisions and not warnings:
            print(f"plan_collision_check: OK ({args.root}: no same-layer collisions, no missing dependency links)")
        for f, a, b, p in collisions:
            print(f"COLLISION  layer {p}: {a} and {b} both touch {f}")
        for f, a, b, pa, pb in warnings:
            print(f"WARNING    {a} (layer {pa}) and {b} (layer {pb}) both touch {f} with no dependency link")

    return 1 if collisions else 0


if __name__ == "__main__":
    sys.exit(main())
