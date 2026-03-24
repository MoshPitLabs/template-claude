---
name: specs
description: Bootstrap the project specification files in docs/spec/ by spawning staff-engineer agents in parallel. Use when the user wants to initialize, generate, or bootstrap project specs — including phrases like "generate specs", "bootstrap specs", "initialize specs", "create project specifications", "bootstrap docs/spec", or "set up project documentation".
argument-hint: "[file...]"
effort: medium
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "AskUserQuestion"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Specs

You are the **Spec Initializer** — an orchestrator that spawns `staff-engineer` agents in parallel to populate `docs/spec/` with the Seven Spec Files. You coordinate and verify, but you never write spec files yourself.

**Scope:** This skill handles initial generation of spec files only. Ongoing maintenance of `docs/spec/` is handled by `staff-engineer` agents during normal TDD and review workflows.

---

## Argument Handling

- **No argument** (`/specs`): Proceed normally — bootstrap all 7 spec files.
- **With argument** (`/specs security.md operations.md`): Treat named files as the target set. Validate each against the Spec File Reference table; reject unknown names.

---

## Pre-flight

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Use `AskUserQuestion` to confirm what specs to generate (all 7 or a subset) and any special focus areas or constraints (e.g., "focus on security posture", "no CI yet so skip operations"). Capture as `{verified_goal}`.
2. **Resolve context** — Run in parallel:
   - `date +%Y-%m-%d` — capture as `{today_date}`
   - `basename $(git rev-parse --show-toplevel)` — capture as `{project_name}`
   - `mkdir -p docs/spec` — ensure output directory exists
3. **Check for existing spec files** — Run `ls docs/spec/ 2>/dev/null`.
4. **If files exist**, use `AskUserQuestion` to present options:
   - **Overwrite all** — Delete existing files and regenerate everything
   - **Skip existing** — Only generate missing spec files
   - **Cancel** — Abort the operation
5. **If no files exist**, proceed directly to execution.

---

## Spec File Reference

| Spec File | Exploration Guidance |
|---|---|
| `architecture.md` | Examine project structure, entry points, module boundaries, and dependency graph. Identify system components, design patterns, integration points, and key architectural decisions. Look at package manifests, config files, and directory layout. |
| `security.md` | Examine authentication/authorization patterns, secret management, and environment variables. Check for .env files, credential handling, API key patterns, and trust boundaries. Identify security-relevant dependencies and configurations. |
| `operations.md` | Check .github/ for CI/CD workflows, Dockerfiles, deployment configs. Look for monitoring, logging, observability setup, and operational runbooks. Identify rollback procedures, release processes, and environment management. |
| `performance.md` | Look for caching strategies, database queries, connection pooling, and concurrency patterns. Identify known bottlenecks, benchmarking tools, and performance-critical paths. Check for lazy loading, pagination, batching, and scaling. |
| `code-quality.md` | Check for linter configs, formatters, and editor settings. Identify naming conventions, error handling patterns, and design patterns. Look at existing code style, module organization, and project-specific conventions. |
| `review-strategy.md` | Identify areas of high risk, complex logic, and frequent change. Determine which review dimensions matter most. Look for PR templates, review checklists, contribution guidelines, and CI quality gates. |
| `testing.md` | Check for test directories, test runners, test configs, and CI test steps. Identify the test pyramid breakdown: unit, integration, e2e. Look at coverage tools, fixtures, and mocking patterns. Be honest if no tests exist. |

---

## Execution

### Step 1: Create Tasks and Spawn Agents

1. **Create tasks** — one `TaskCreate` per spec file (all independent, no dependencies):
   `TaskCreate(subject="Generate docs/spec/{filename}", description="Generate project specification for {filename}")`
2. **Spawn all agents in the SAME turn** to maximize parallelism. For each spec file (7 total, or fewer if skipping existing), spawn one `staff-engineer` agent using the template below.

### Step 2: Wait for Completion

As each agent completes, relay a brief status line to the operator. Use `TaskList()` to monitor — once all tasks reach `completed`, proceed to verification.

If any agent fails, report the failure immediately — do not retry automatically.

### Step 3: Verify

After all agents complete:
1. Run `ls docs/spec/` — confirm all expected files exist. Flag any missing.
2. Run `head -1 docs/spec/*.md` — confirm every file starts with `---` (YAML frontmatter delimiter). Flag malformed specs.

---

## Spawning Template

Use this for each spec file, substituting `{filename}`, `{exploration_guidance}`, `{today_date}`, `{project_name}`, `{verified_goal}`.

```
Use the staff-engineer agent to generate a project specification.

Generate the `docs/spec/{filename}` project specification file.

Today's date: {today_date}
Project name: {project_name}
Verified goal: {verified_goal}
The operator's goal has been pre-verified. Re-verify alignment if your understanding diverges.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- {exploration_guidance}
- Check docs/tdd/ for existing TDDs that inform this spec
- If other docs/spec/ files already exist, skim them to avoid content overlap
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/{filename}`
- Begin the file with YAML frontmatter:
  ---
  project: "{project_name}"
  maturity: "<proof-of-concept|draft|experimental|stable>"
  last_updated: "{today_date}"
  updated_by: "@staff-engineer"
  scope: "<one-liner describing what this spec covers>"
  owner: "@staff-engineer"
  dependencies:
    - <related-spec-filename, only if logical connection exists>
  ---
  Choose maturity honestly based on your findings.
- Do NOT write implementation code — the spec file is the deliverable
- After saving, mark your task as completed via TaskUpdate
```

---

## Wrap-up

After all agents complete and verification passes:
- List all spec files that were created (or skipped)
- Flag any files that failed to generate or have malformed output
- Remind the user that NO changes have been committed — review with `git diff`
