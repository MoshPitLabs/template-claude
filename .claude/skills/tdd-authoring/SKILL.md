---
name: tdd-authoring
description: Author structured Technical Design Documents (TDDs) that translate task requirements into testable, reviewable design artifacts
license: MIT
compatibility: opencode
metadata:
  audience: engineering
  workflow: design
---
## What I do
- Guide the staff-engineer through producing high-quality Technical Design Documents (TDDs).
- Enforce a consistent TDD structure with problem framing, design alternatives, explicit tradeoffs, and acceptance mapping.
- Ensure every TDD is reviewable, testable, and ready for Senior Engineer handoff.

## TDD document template

Save all TDDs to `specs/tdd/` using kebab-case filenames: `specs/tdd/<task-id>-<short-description>.md`

```markdown
# TDD: <Feature or Task Title>

**Task:** td-xxx
**Author:** staff-engineer
**Status:** draft | approved
**Date:** YYYY-MM-DD

## Problem statement

What problem does this solve? Why does it need to be solved now?
Include the user or system impact if left unresolved.

## Constraints

Technical, product, or operational constraints that bound the solution space:
- Performance: ...
- Compatibility: ...
- Security: ...
- Timeline: ...

## Design options

### Option A: <Name>

**Description:** Brief explanation of the approach.

**Pros:**
- ...

**Cons:**
- ...

**Estimated effort:** S / M / L

---

### Option B: <Name>

**Description:** Brief explanation of the approach.

**Pros:**
- ...

**Cons:**
- ...

**Estimated effort:** S / M / L

---

*(Add Option C if a third viable alternative exists.)*

## Decision

**Chosen option:** Option A / B / C

**Rationale:** Why this option was selected over the alternatives. Reference specific constraints or tradeoffs that drove the decision.

**Rejected options summary:**
- Option A: rejected because ...
- Option B: rejected because ...

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ... | low/med/high | low/med/high | ... |

## Acceptance mapping

Map each acceptance criterion from the TD task to the design element that satisfies it:

| Acceptance criterion | Satisfied by | Verification method |
|----------------------|-------------|---------------------|
| AC 1: ... | Component / interface / behavior | Unit test / integration test / manual check |
| AC 2: ... | ... | ... |

## Implementation notes for Senior Engineer

Concrete guidance: file paths, patterns to follow, test expectations, edge cases to handle.

- Files to create or modify: ...
- Patterns to follow: ...
- Test expectations: ...
- Edge cases: ...
```

## Quality checklist

Before handing off a TDD, verify all of the following pass:

- [ ] **Testable design** — Every acceptance criterion maps to a concrete verification method (unit test, integration test, or explicit manual check). No criterion is left unmapped.
- [ ] **Tradeoffs documented** — At least two design options are presented with explicit pros/cons. The rejected options section explains why each was not chosen.
- [ ] **Dependencies identified** — All external dependencies (services, libraries, data stores, other TD tasks) are named. Blocking dependencies are flagged.
- [ ] **Risks listed** — The risks table is populated with at least one entry. Each risk has a mitigation strategy, not just an acknowledgment.
- [ ] **Acceptance mapping complete** — Every acceptance criterion from the TD task appears in the acceptance mapping table with a verification method.
- [ ] **Constraints are explicit** — The constraints section names real bounds (not placeholders). Vague entries like "performance must be good" are replaced with measurable targets.
- [ ] **Implementation notes are actionable** — The Senior Engineer section contains specific file paths, patterns, or test expectations — not generic advice.

## Handoff protocol

### Staff-engineer → product-manager handoff

After completing a TDD, the staff-engineer must:

1. **Save the TDD** to `specs/tdd/<task-id>-<short-description>.md`.
2. **Log the TDD path** to TD:
   ```
   TD(action: "log", message: "TDD drafted: specs/tdd/<filename>.md", logType: "result")
   ```
3. **Link the file** to the task:
   ```
   TD(action: "link", task: "td-xxx", files: ["specs/tdd/<filename>.md"])
   ```
4. **Record the handoff** with full context:
   ```
   TD(action: "handoff",
     task: "td-xxx",
     done: "TDD drafted at specs/tdd/<filename>.md. Covers problem statement, two design options, decision rationale, risks, and acceptance mapping.",
     remaining: "Senior Engineer implementation pending team-lead routing.",
     decision: "<Key design decision made and why>",
     uncertain: "<Any open questions that need product or engineering input before implementation begins>"
   )
   ```

### Required artifacts at handoff

| Artifact | Location | Required |
|----------|----------|----------|
| TDD document | `specs/tdd/<task-id>-<short-description>.md` | Yes |
| TD log entry (result) | TD task log | Yes |
| TD file link | TD task file list | Yes |
| TD handoff entry | TD task handoff | Yes |
| Open questions flagged | TDD `## Open questions` section | If any exist |

### What the product-manager does with the handoff

The product-manager reviews the TDD for requirement alignment, resolves open questions, and routes the approved TDD to the team-lead for Senior Engineer assignment.

## Anti-patterns

### 1. Too vague — problem statement without impact

**Bad:**
```
## Problem statement
The current system is slow and needs improvement.
```

**Good:**
```
## Problem statement
The search endpoint returns results in 4–8 seconds under load, causing a 23% abandonment rate on the search page. Users on mobile connections experience timeouts. This needs to be resolved before the Q2 launch.
```

---

### 2. Too implementation-specific — design options that are really just one option

**Bad:**
```
## Design options
### Option A: Use Redis cache with a 5-minute TTL and LRU eviction
### Option B: Use Redis cache with a 10-minute TTL and LFU eviction
```
These are configuration variants of the same approach, not genuine alternatives.

**Good:**
```
## Design options
### Option A: In-process memory cache (e.g., LRU map)
### Option B: Distributed cache (e.g., Redis)
### Option C: Database query optimization with materialized views
```

---

### 3. Missing risks — risks table left empty or with placeholder text

**Bad:**
```
## Risks
No significant risks identified.
```

**Good:**
```
## Risks
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Cache invalidation lag causes stale results | medium | medium | Add cache-busting on write; set max TTL to 60s |
| Redis unavailability causes full outage | low | high | Implement fallback to direct DB query with circuit breaker |
```

---

### 4. Missing alternatives — decision without rejected options

**Bad:**
```
## Decision
**Chosen option:** Option A
**Rationale:** This is the best approach for our use case.
```

**Good:**
```
## Decision
**Chosen option:** Option A — In-process memory cache

**Rationale:** Our service is single-instance and the dataset fits in memory (~50 MB). Distributed cache adds operational overhead (Redis cluster, connection pooling, serialization) that is not justified at current scale.

**Rejected options summary:**
- Option B (Redis): Adds ~2ms network latency per cache hit and requires Redis infrastructure we do not currently operate.
- Option C (Materialized views): Requires schema migration and adds DB write overhead; not viable within the Q2 timeline.
```

---

### 5. Acceptance mapping incomplete — criteria listed without verification methods

**Bad:**
```
## Acceptance mapping
| Acceptance criterion | Satisfied by |
|----------------------|-------------|
| Search returns in < 500ms | Caching layer |
```

**Good:**
```
## Acceptance mapping
| Acceptance criterion | Satisfied by | Verification method |
|----------------------|-------------|---------------------|
| Search returns in < 500ms at p95 under 100 RPS | In-process LRU cache with 60s TTL on search results | Load test with k6: 100 VUs, 60s duration; assert p95 < 500ms in results |
```
