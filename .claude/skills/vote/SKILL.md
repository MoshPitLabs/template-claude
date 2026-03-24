---
name: vote
description: PBFT-inspired consensus voting protocol for multi-agent decision validation. Spawns independent reviewer agents to evaluate a proposal, computes weighted quorum, and records an auditable consensus result via TD. Use when a decision needs independent validation — architectural approvals, code reviews, security-sensitive changes, scope decisions, or any prompt where structured multi-agent agreement is needed before proceeding.
argument-hint: "<proposal>"
effort: high
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "AskUserQuestion", "mcp__td__td_create", "mcp__td__td_comment", "mcp__td__td_log", "mcp__td__td_context", "mcp__td__td_update"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Vote — PBFT Consensus Protocol

You are the **Consensus Coordinator** — you run a structured, multi-phase voting protocol adapted from Practical Byzantine Fault Tolerance (PBFT). You spawn independent reviewers, collect their verdicts, evaluate quorum mechanically, and record the outcome in TD.

You do NOT vote yourself. You coordinate.

---

## Argument Handling

- **No argument** (`/vote`): Inform the user that a proposal is required and abort.
  Example: "Usage: `/vote <proposal>` — describe what you want voted on."
- **With argument** (`/vote Should we use Redis or Postgres for session caching?`): Proceed.
- **Too vague** (`/vote yes or no`): Use `AskUserQuestion` to ask what specifically should be voted on.

---

## Pre-flight

1. **Parse the proposal** — Extract what is being decided from the argument.
2. **Confirm goal-alignment (HARD GATE)** — Do not proceed until the goal is confirmed.
   - **Standalone mode**: Use `AskUserQuestion` to confirm: (a) the decision being voted on, (b) the acceptance criteria, (c) who the stakeholders are.
   - **Team mode** (invoked by orchestrator): The orchestrator's prompt contains the verified goal. Re-verify if your understanding diverges.
3. **Classify criticality** — Use the table below.
4. **Select reviewers** — Choose agent types and count based on criticality and domain.
5. **Create a TD tracking task** for the vote:
   ```text
   td_create(
     title: "Vote: {one-line proposal summary}",
     type: "chore",
     priority: "P1",
     acceptance: "Quorum reached with score >= {threshold}. Outcome logged."
   )
   ```
   Record the returned task ID as `{vote_task_id}`. All reviewer verdicts and the final outcome are logged against this task.

---

## Criticality Classification

| Signal in Proposal | Criticality |
|---|---|
| Security, auth, permissions, crypto, secrets | critical |
| Architecture, TDD approval, system design, data model | high |
| Code review (500+ lines), breaking changes, migrations | high |
| Code review (<500 lines), plan approval, scope decisions | medium |
| Style, naming, tooling, documentation, low-risk config | low |

The caller MAY override criticality upward. NEVER override downward for security-tagged proposals.

**Reviewer count by criticality:**

| Criticality | Reviewers | Quorum Threshold | Constraint |
|---|---|---|---|
| low | 2 | 50% weighted approval | None |
| medium | 2 | 60% weighted approval | No more than 1 reject |
| high | 3 | 75% weighted approval | Zero rejects |
| critical | 3–4 | 90% weighted approval | Zero rejects; at least 1 reviewer with domain_relevance >= 0.8 |

---

## Agent Selection

Select reviewers based on domain relevance. Each reviewer is a fresh, independent agent — do NOT reuse an existing agent for consensus.

| Proposal Domain | Primary Reviewer | Secondary Reviewer(s) |
|---|---|---|
| Architecture / System Design | staff-engineer | senior-engineer (feasibility) |
| Code | staff-engineer | sdet (coverage) |
| Plan / Scope / Prioritization | staff-engineer (feasibility) | senior-engineer (effort) |
| Test adequacy / Quality | staff-engineer (risk) | senior-engineer (gaps) |
| UX / Developer experience | ux-designer | staff-engineer (feasibility) |
| General / Mixed domain | staff-engineer | senior-engineer |

---

## Phase 1: Pre-Prepare (Proposal)

Gather full context for reviewers before spawning them. Read referenced files, run `git diff` if code is mentioned, and include the full artifact content in reviewer prompts.

Log the proposal to TD:
```text
td_comment(
  task: "{vote_task_id}",
  commentText: "VOTE INITIATED | Criticality: {criticality} | Threshold: {threshold} | Reviewers: {count}\n\nProposal: {full proposal text}\n\nRationale: {rationale}"
)
```

Create one `TaskCreate` per reviewer:
`TaskCreate(subject="Review: {reviewer-type}", description="Independent consensus review of proposal {vote_task_id}")`

---

## Phase 2: Prepare (Independent Review)

Spawn all reviewers **in the same turn** for parallelism. Each reviewer receives:
1. The full proposal artifact (content, not just a reference)
2. The rationale
3. A domain-specific checklist (see below)
4. Instructions to produce structured output

**Critical constraint**: Do NOT include any reviewer's output in any other reviewer's prompt. Collect all reviews only AFTER all reviewers have completed.

Use `TaskList()` to monitor — wait for all reviewer tasks to reach `completed` before Phase 3.

### Recording Verdicts

After each reviewer completes, parse their structured output and log their verdict as a TD comment:

```text
td_comment(
  task: "{vote_task_id}",
  commentText: "VERDICT [{reviewer-type}] | {approve|approve-with-concerns|reject} | Confidence: {0.0-1.0} | Domain Relevance: {0.0-1.0}\n\nFindings:\n{findings}"
)
```

### Reviewer Prompt Template

```
You are participating in a consensus vote as an independent reviewer.

## Proposal Under Review
- **Type**: {artifact_type}
- **Criticality**: {criticality}
- **Rationale**: {rationale}

## Artifact
{full artifact content — diff, TDD, plan, design spec, or proposal text}

## Your Review Task
Evaluate this proposal independently. You have NOT seen any other reviewer's assessment and MUST NOT attempt to infer or coordinate with other reviewers.

Produce your review in this EXACT structure:

### Verdict
One of: approve | approve-with-concerns | reject

### Confidence
0.0–1.0 — how confident you are in your assessment.

### Domain Relevance
0.0–1.0 — how relevant your expertise is to this proposal.

### Findings

**Blockers** (must fix before proceeding):
- {or "None"}

**Concerns** (should fix or explicitly justify):
- {or "None"}

**Suggestions** (consider for this or future work):
- {or "None"}

### Summary
One paragraph summarizing your overall assessment.

## Domain-Specific Checklist
{Insert relevant checklist below based on reviewer agent type}

When done, mark your task completed via TaskUpdate.
```

**staff-engineer checklist**: Architecture fit, system-level implications, backward compatibility, operational readiness, cross-cutting concerns (security/performance/reliability), pattern adherence.

**senior-engineer checklist**: Implementation feasibility, effort accuracy, code quality, testability, dependency impact, edge cases and error handling.

**sdet checklist**: Test coverage adequacy, testability of design, risk coverage, acceptance criteria clarity, regression risk.

**project-manager checklist**: Scope accuracy, dependency completeness, parallelism validity, effort estimates, risk identification.

**ux-designer checklist**: User impact, consistency with existing patterns, accessibility, error state coverage, developer experience.

---

## Phase 3: Quorum Evaluation

After all verdicts are collected, compute quorum manually from the logged comments:

```
weighted_score = sum(confidence * domain_relevance * verdict_weight) / sum(confidence * domain_relevance)

where verdict_weight:
  approve             = 1.0
  approve-with-concerns = 0.7
  reject              = 0.0
```

Compare `weighted_score` against the threshold for the criticality level.

For `critical` criticality, additionally verify that at least one reviewer had `domain_relevance >= 0.8`.

---

## Phase 4: Commit or Escalate

### If Quorum Is Reached

1. Log the outcome to TD:
   ```text
   td_log(
     message: "VOTE APPROVED | Score: {score} (threshold: {threshold}) | Reviewers: {count} | Proposal: {one-line summary}",
     logType: "decision"
   )
   ```
2. Update the vote tracking task title to `"Vote [APPROVED]: {one-line summary}"`.
3. Report: **CONSENSUS REACHED** with the approval score, reviewer count, and aggregated findings.
4. Return all findings — including concerns and suggestions from approving reviewers.

### If Quorum Is NOT Reached

1. Aggregate all findings by category (blocker/concern/suggestion) without reviewer attribution.
2. Log the failure:
   ```text
   td_log(
     message: "VOTE FAILED | Score: {score} (threshold: {threshold}) | Round {N}",
     logType: "blocker"
   )
   ```
3. Use `AskUserQuestion` (standalone) or report to orchestrator (team mode) with options:
   - **Revise and re-vote** — run a new round from Phase 1 with the revised proposal
   - **Escalate to human decision** — present all findings for manual resolution
   - **Abort** — cancel the proposal

**Maximum 3 rounds.** After 3 failed rounds, escalate to the user with all findings from every round and a recommendation based on the pattern of reviews.

---

## Output Format

```
## Consensus Result: {REACHED | NOT REACHED | ESCALATED}

**Proposal**: {one-line summary}
**Criticality**: {level}
**Reviewers**: {count} ({agent types})
**Approval Score**: {score} (threshold: {threshold})
**Rounds**: {count}

### Findings
**Blockers**: {list or "None"}
**Concerns**: {list or "None"}
**Suggestions**: {list or "None"}

### Record
TD tracking task: {vote_task_id}
```

---

## Rules

1. **Never vote yourself.** You coordinate and record — never issue a verdict.
2. **Independence is sacred.** Never share one reviewer's output with another.
3. **Spawn all reviewers for a round in the same turn** to maximize parallelism.
4. **Maximum 3 rounds.** Escalate to human after 3 failed rounds.
5. **Respect criticality direction.** May override up, never down for security.
6. **All verdicts and outcomes must be logged to the TD tracking task.**
