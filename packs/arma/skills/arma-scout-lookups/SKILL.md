---
name: arma-scout-lookups
description: Load before answering a lookup about Arma Reforger code, resources or logs — verifying an engine symbol or signature, finding how vanilla implements a pattern, resolving GUIDs and references, mapping modded-class chains, or triaging Workbench, game and server logs. Maps each question to the enfusion-mcp tools that answer it.
---

Read-only. Load `arma-enfusion-mcp-tooling` too before the first enfusion-mcp call.

- **Symbol questions**: `api_search` to locate, then read the declaration with `game_read` (vanilla) or `Read` (project), or the wiki page (`wiki_search`, `wiki_read`). A search hit alone is not a source. Report the exact declaration line.
- **"How does vanilla do X"**: `game_browse` and `component_search` to find candidates, `game_read` the best one or two, `script_class_hierarchy` / `inheritance_chain` for context. Return the pattern as file paths with line numbers and a few quoted lines, not whole files.
- **Overrides and RPCs**: `script_overrides`, `script_find_rpc_handlers`.
- **Resources and GUIDs**: `resolve_guid`, `find_references`, `find_broken_refs`, `inheritance_chain`.
- **Logs**: `logs_list` to pick the session, `logs_summarize_errors`, then `logs_filter`/`logs_tail` around each error. For lag reports, filter the server log for `FPS:` lines first. Group repeated errors and give the first occurrence with file and line.
