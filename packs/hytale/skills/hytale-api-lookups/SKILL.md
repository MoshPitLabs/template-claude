---
name: hytale-api-lookups
description: Load before verifying a Hytale server API method, event, codec or asset schema, or before depending on the server version — checks the pinned local JAR and release-matched official documentation.
---

# Hytale api lookups

Read `.claude/local/hytale.toml` for paths, expected hash and version (template: `references/local-hytale-template.toml`). Compute the JAR SHA-256 and inspect `META-INF/MANIFEST.MF`. Enumerate classes with selective ZIP reads, then run `javap -public -classpath <jar> <fully.qualified.Class>` for signatures; use protected members or bytecode only where needed. Resolve overload argument semantics from official Javadocs or implementation, not parameter counts alone.

For assets, find one current shipped example and inspect the corresponding codec/schema before designing JSON. Source material is https://docs.hytale.com/api/ and https://docs.hytale.com/assets/ . Avoid pre-release docs for release binaries unless explicitly comparing them.

Return exact methods, types, version/hash, local path or URL, and anything not yet runtime-verified. Never invent a callback, event, ID prefix, or client capability to fill a gap.
