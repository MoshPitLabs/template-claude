---
name: arma-prefab-and-config-authoring
description: Load before changing `.et`, `.conf`, `.meta`, resource references, prefab inheritance, config inheritance, or any GUID-sensitive Arma Reforger resource.
---

# Prefab and Config Authoring

## Rules

1. Inspect the project's `*.gproj`, dependency GUIDs, nearby resources, and their `.meta` files (`list_dependencies`, `inheritance_chain`, `resolve_guid`, `find_references`).
2. Prefer prefab and config inheritance over copied vanilla resources.
3. Keep inherited overrides minimal and document why each changed property is needed.
4. Verify every component, property, resource path, and GUID reference against a real project or vanilla resource.
5. Treat `.meta` GUIDs as identity. Do not casually move, rename, or regenerate them. A new hand-written text resource needs its own `.meta` (format in the reference).
6. Do not hand-write `.et` prefabs; build them in Workbench (procedure in the reference).
7. Do not hand-edit compiled `.xob` or `.edds` assets.
8. Separate text-editable work from operations that must be performed in Workbench's Resource Browser or resource editors.
9. Stop if the base resource or referenced GUID cannot be resolved.
10. Runtime settings follow the configuration rules in the reference (sparse overrides, never write defaults to the profile).

Read `references/project-resource-patterns.md` before editing. It holds the patterns verified in Workbench; report repository-specific inheritance and verification evidence with the change.

## Completion evidence

Run `find_broken_refs` on the changed resources. Require the resource to resolve, open without errors in the relevant Workbench editor, preserve expected inheritance, and run in the intended in-editor scenario. List every move, rename, and GUID consequence explicitly.
