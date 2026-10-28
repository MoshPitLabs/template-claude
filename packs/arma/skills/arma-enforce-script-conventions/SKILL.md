---
name: arma-enforce-script-conventions
description: Load before creating, editing, or reviewing Arma Reforger `.c` files or when Enforce Script syntax, naming, lifecycle, or source placement is in question.
---

# Enforce Script Conventions

## Rules

1. Discover the addon's actual script roots and capitalization before editing (`Scripts/Game/<Addon>/...` is common, not guaranteed).
2. Read adjacent project `.c` files and a comparable verified vanilla implementation (`game_browse`, `game_read`) before choosing structure.
3. Verify every class, method, attribute, annotation, enum, callback, and signature against project code, unpacked vanilla source, or the Bohemia Interactive Community Wiki. An `api_search` hit is verified only after its declaration is read.
4. Match existing naming and file placement. Do not import conventions from C#, Java, or C++ without Enforce evidence.
5. Keep changes narrow. Do not combine feature work with broad style cleanup.
6. Preserve lifecycle ordering and base behavior unless a verified pattern requires otherwise.
7. If an API point cannot be verified, stop and report it instead of writing placeholder code; never leave a `TODO(verify)` behind.
8. Never use absent LSP diagnostics as syntax evidence. Only `wb_validate_scripts` proves a file compiles.

## Before editing

- Read `references/verified-language-patterns.md` (source order, compile pitfalls, runtime pitfalls). Most of its items compile cleanly and fail only at runtime, so W1 alone does not catch them.
- Record the exact files or wiki pages that verify the syntax and API surface.
- Identify the in-editor behavior (W3) that will validate the change.

## Completion evidence

Report verified symbols with their sources, files changed, and the W1 result from `wb_validate_scripts`, quoting the verdict. If W1 could not run, state that syntax remains unverified.
