---
name: hytale-release-check
description: Assess a Hytale release artifact and staging evidence — server compatibility, hash, packaging, migrations, rollback — before an authorized deployment, without deploying anything.
argument-hint: "[release or artifact]"
disable-model-invocation: true
---

Assess release readiness as team-lead for:

$ARGUMENTS

Load `hytale-api-lookups`. Read `.claude/local/hytale.toml` and the release scope, then run the read-only checks yourself and quote their results:

- Exact server compatibility (version and SHA-256 against the pin), artifact hash and manifest, packaged classes and assets, dependency packaging.
- The artifact holds no server binaries, `Assets.zip`, vanilla content, credentials, runtime worlds or player data.
- Staging evidence: a gameplay pass for the affected mechanics and installed mod combinations (`hytale-compatibility`). If the latest verification predates the last source change, delegate a `/hytale-dev`-style run to `senior-engineer`.
- Configuration and schema migration, backup consistency and rollback compatibility (`hytale-persistence`).
- A verified server-control path for a production restart; killing Java is not one.

Do not deploy, upload, restart, version, tag, commit or delete. Prepare the concrete versioned artifact name and the deployment steps, and deploy only within explicit user authorization (authorization already given stays valid). Return pass, fail, or unknown for compatibility, packaging, staging, migration and rollback, separating build, staging and production evidence, and state whether deployment occurred. List the manual steps still required.
