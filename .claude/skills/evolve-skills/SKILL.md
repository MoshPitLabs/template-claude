---
name: evolve-skills
description: Review and improve skill definitions in .claude/skills/*/SKILL.md. Evaluates skill design quality, actionability, completeness, orchestration effectiveness, cross-skill coherence, spec alignment, and over-engineering. Enforces a Content Gate that rejects non-actionable or redundant additions. Enforces a 500-line size budget per skill. Can target a specific skill or improve all skills. Use when the user wants to evolve, improve, or refine skill definitions.
argument-hint: "[skill-name]"
effort: high
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "Agent", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "AskUserQuestion"]
---

# Evolve Skills

You are the **Skill Evolution Orchestrator**. You spawn `staff-engineer` subagents to review all skill files in `.claude/skills/*/SKILL.md`. **You do not perform reviews yourself — you only coordinate and apply edits.** This includes the `evolve-*` skills themselves — self-evolution is expected. Subagents produce structured change recommendations; you apply them using the Edit tool. All additions are filtered through the Content Gate.

> **Self-evolution note:** Changes to skill files take effect on the *next* invocation, not the current one.

> **SIZE CONSTRAINT: Skill files MUST stay under 500 lines.** Evolution is about sharpening, not accumulating. Every cycle should leave skill files the same size or smaller. If a file exceeds 500 lines, the primary goal is consolidation — new content may only be added if an equal or greater amount is removed.

---

## Argument Handling

- **No argument** (`/evolve-skills`): Improve ALL skills in `.claude/skills/*/SKILL.md`.
- **With argument** (`/evolve-skills git-workflow`): Improve only the named skill.

If the argument doesn't match an existing skill directory, abort and inform the user.

---

## Pre-flight

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Use `AskUserQuestion` to confirm the evolution focus. Do not proceed until verified.
2. **Gather experience feedback** — Ask the operator: what's working well, what's not, any pain points. Store as `{experience_feedback}`.
3. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash. Store as `{today_date}`.
4. **Validate skill files exist** — Run `ls .claude/skills/*/SKILL.md` to list discoverable files.
5. **If targeting a specific skill** — Verify `.claude/skills/<arg>/SKILL.md` exists.
6. **Check for existing changelogs** — Run `ls docs/changelog/skills/*.md 2>/dev/null`.
7. **Measure file sizes** — Run `wc -l .claude/skills/*/SKILL.md` and record line counts:
   - **TRIM mode** (over 500 lines): consolidation primary — removals must exceed additions.
   - **BALANCED mode** (under 500 lines): additions allowed but offset by removals.

---

## Content Gate

**Every proposed addition MUST pass ALL 4 checks. Reject if ANY fails.**

1. **Executable** — Can Claude do this in a stateless session? Reject: mentoring, meetings, relationship-building, career development.
2. **Behavioral** — Does removing it change the skill's output? Reject: general LLM knowledge.
3. **Non-redundant** — Already expressed elsewhere in the file? Reject duplicates even if reworded.
4. **Concrete** — A specific action, check, or output format? Reject aspirational fluff ("think holistically", "drive excellence").

---

## Evaluation Dimensions

Every reviewer evaluates against ALL 8 dimensions. Dimensions 1, 3, and 5 propose additions — all must pass the Content Gate.

1. **Skill Design Quality** — Frontmatter (including `effort`, `argument-hint`, `allowed-tools`), argument handling, structure-brevity balance.
2. **Actionability** — Specific enough for reliable execution? Clear phases, concrete templates, defined outputs.
3. **Completeness** — Edge cases, error conditions, pre-flight checks, all workflow paths covered?
4. **Over-Engineering** — Verbose, redundant, or low-value sections to trim or consolidate?
5. **Orchestration** — Proper agent use, parallelism, correct agent types, task coordination lifecycle (TaskCreate → spawn → complete).
6. **Coherence** — Scope overlaps with other skills, terminology consistency, shared conventions.
7. **Spec Alignment** — Aligned with `docs/spec/` project patterns?
8. **Rename Consideration** — Only if compelling — stability has value.

---

## Changelog Format

All changes tracked in `docs/changelog/skills/<skill-name>.md`.

**Exact format:** `# Changelog: <skill-name>` > `## YYYY-MM-DD` > exactly 4 H3 sections in order:
- `### Summary` (1-2 sentences)
- `### Changes` (bulleted with reasoning)
- `### Dimensions Evaluated`
- `### Rename` (details or "No rename.")

Max 20 lines per entry. Prepend new entries (most recent first). Report honestly if no improvements found.

---

## Orchestration Workflow

### Team Setup

Before spawning any agents:
1. **Create Phase 1 tasks** — `TaskCreate(subject="Review <skill-name>")` per target skill.
2. **Create Phase 2 task** — `TaskCreate(subject="Coherence & Renames")`.

### Phase 1: Review & Improve (parallel)

Spawn one `staff-engineer` subagent per target skill. Spawn all in the same turn for maximum parallelism.

```
Agent(subagent_type="staff-engineer", prompt="...")
```

Each reviewer (read-only) follows the Phase 1 template: reads the target skill file, most recent changelog entry, relevant `docs/spec/` files, first ~80 lines of other skill files for ecosystem context, evaluates all 8 dimensions, reports structured recommendations.

**After each Phase 1 subagent completes**, the orchestrator:
1. Reviews recommendations against the Content Gate — reject additions that fail any check.
2. Applies approved changes via Edit.
3. Writes/updates and normalizes the changelog in `docs/changelog/skills/<name>.md`.
4. Tracks renames and coherence issues for Phase 2.
5. Verifies edits: `wc -l` for budget, frontmatter/sections intact, cross-references valid.

### Phase 2: Coherence & Renames (sequential)

After ALL Phase 1 changes are applied, spawn a single `staff-engineer` subagent (read-only) for coherence review.

The Phase 2 subagent reads all skill files (freshly improved versions), verifies rename recommendations, checks coherence (no scope overlaps, consistent terminology, accurate references, consistent argument handling), reports structured recommendations.

**After Phase 2 completes**, the orchestrator executes renames, applies coherence fixes via Edit, updates changelogs for affected skills.

### Wrap-up

1. Run `wc -l .claude/skills/*/SKILL.md`. If any exceed 500 lines, consolidate until under 500.
2. Report: files modified, before/after line counts, improvements made, renames/coherence fixes.
3. Reminder that NO changes have been committed — review with `git diff`.

---

## Phase 1 Spawning Template

Substitute `<name>`, `<skill-path>`, `{line_count}`, `{mode}`, `{today_date}`, `{verified_goal}`, `{experience_feedback}`.

```
Use the staff-engineer agent to review and improve a skill definition.

Target: <skill-path>/SKILL.md | Skill: <name> | Size: {line_count} lines | Mode: {mode}
Verified goal: {verified_goal}
Experience feedback: {experience_feedback}
Today's date: {today_date}

## Size Budget
Hard limit: 500 lines. TRIM (over 500): removals must exceed additions.
BALANCED (under 500): additions allowed but offset by removals. Report NET_LINES per change.

## Context
- Read docs/changelog/skills/<name>.md — ONLY the most recent entry.
- Read docs/spec/ selectively — only files relevant to the skill's domain.
- Read OTHER skill files — first ~80 lines only. Skip WebFetch.
- Operator experience feedback: {experience_feedback}

## Content Gate
Apply 4-check gate (Executable, Behavioral, Non-redundant, Concrete) — reject additions failing ANY check.

## Evaluate ALL 8 dimensions
(Skill Design Quality, Actionability, Completeness, Over-Engineering [HIGHEST PRIORITY], Orchestration, Coherence, Spec Alignment, Rename)

Over-Engineering is HIGHEST PRIORITY — every addition MUST be offset by a removal.

## Rules
- **Read-only** — analyze and recommend only.
- Minimize context: first 80 lines of other skills, relevant specs only.

## Output Format
### Summary (1-2 sentences + net line change)
### Recommended Changes
For each: CHANGE/DIMENSION/CONTEXT/NET_LINES/OLD_STRING/NEW_STRING (use <REMOVE> to delete, <INSERT_AFTER> to add)
### Changelog Entry (under 20 lines, 4 sections: Summary, Changes, Dimensions Evaluated, Rename)
### Rename Recommendation
### Coherence Issues
```

## Phase 2 Spawning Template

```
Use the staff-engineer agent to check cross-skill coherence and recommend fixes.
Today's date: {today_date}. **Read-only** — orchestrator applies all changes.

## Renames to Execute
<list recommended renames, or "No renames recommended.">

## Phase 1 Coherence Issues
<list issues from Phase 1, or "None reported.">

## Tasks
1. Read ALL skill files in .claude/skills/*/SKILL.md
2. Verify rename recommendations and prepare instructions (dir, frontmatter, references, changelog)
3. Check coherence: no scope overlaps, consistent terminology, accurate references, consistent conventions and argument handling

## Output Format
### Renames (or "No renames needed")
### Coherence Fixes (or "No coherence issues found")
### Changelog Entries
### Remaining Issues
```

---

## Rules

1. **Pre-flight before spawning.** Validate skill files and arguments first.
2. **TaskCreate before Agent calls.** Phase 1 (parallel) → Phase 2 (sequential).
3. **Always run Phase 2** — even for single-skill improvements.
4. **Only orchestrator edits files.** Subagents are read-only reviewers.
5. **Never commit.** No `git add`, `git commit`, or `git push`.
6. **Changelog mandatory.** Follow format above.
7. **500-line budget.** `wc -l` after edits; consolidate if over.
8. **Fail loud.** Report subagent failures immediately.
9. **Content Gate enforced.** Reject additions failing any check.
