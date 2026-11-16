---
name: wow-libraries-packaging
description: Load before adding, upgrading or removing an embedded WoW library (LibStub, Ace3, others), editing .pkgmeta, using packager keywords, or changing how releases are built and uploaded.
---

# WoW libraries packaging

Libraries are embedded copies registered through `LibStub` (`LibStub("Name-1.0")`), which keeps the highest minor version loaded by any addon. Add them the way the repository already does: `.pkgmeta` `externals` fetched by the BigWigsMods packager, or a vendored `Libs/` folder. Never edit library code in place; list each library's `embeds.xml` or files in every flavor TOC before the code that uses it. Adding a library is `design-gated`.

The packager (BigWigsMods/packager, usually its GitHub Action on a tag) builds the zip from `.pkgmeta`: `package-as`, `externals`, `ignore`, `move-folders`, `enable-nolib-creation`. It replaces keywords such as `@project-version@` and strips or enables blocks such as `--@debug@ … --@end-debug@` and the flavor blocks (`--@retail@`, `--@non-retail@`, and others the packager documents). Check a keyword or block against the packager's README before using it. `.release/` is build output; never commit it.

Upload targets come from TOC metadata (`## X-Curse-Project-ID`, `## X-Wago-ID`, `## X-WoWI-ID`) and tokens in CI secrets (`CF_API_KEY`, `WAGO_API_TOKEN`, `WOWI_API_TOKEN`, `GITHUB_OAUTH`). Never write a token into the repository, a log or the tracker. Tagging, pushing a tag or running an upload is a release: only with explicit user authorization.
