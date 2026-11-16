---
name: wow-release-check
description: Assess a World of Warcraft addon release — Interface numbers, TOC contents, packaging, SavedVariables migration, in-game evidence — before an authorized tag or upload, without publishing anything.
argument-hint: "[version or tag]"
disable-model-invocation: true
---

Assess release readiness as team-lead for:

$ARGUMENTS

Load `wow-api-lookups` and `wow-libraries-packaging`. Read `.claude/local/wow.toml`, the TOC files, `.pkgmeta` and the changes since the last release tag, then run the read-only checks yourself and quote their results:

- Every flavor TOC carries the pinned `## Interface` number, lists every file the release ships, and declares the SavedVariables the code uses; `## Version` uses the packager keyword or the intended version.
- `.pkgmeta`: externals pinned as the repository intends, `ignore` excludes development files (specs, `.claude/`, docs not meant for players), no `.release/` output or tokens committed.
- Lint after the final source change (`luacheck`). If tests exist or the latest verification predates the last source change, delegate a `/wow-dev`-style run to `senior-engineer`.
- SavedVariables migration from the previous release and behavior after a downgrade (`wow-saved-variables`); addon-message compatibility with the previous release (`wow-addon-comms`).
- In-game evidence from the user per flavor: reload without Lua errors, the changed features in and out of combat, taint log when secure code changed.

Do not tag, push, package, upload, version or delete. Prepare the version, the changelog entry and the release steps, and release only within explicit user authorization (authorization already given stays valid). Return pass, fail, or unknown for TOC and Interface, packaging, lint and tests, migration, and in-game evidence, and state whether anything was published. List the manual steps still required.
