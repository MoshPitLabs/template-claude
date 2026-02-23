---
name: acceptance-criteria-authoring
description: Author clear, testable acceptance criteria for features, bugs, and chores using standard formats that QA can directly derive test cases from
license: MIT
compatibility: claude-code
metadata:
  audience: product
  workflow: planning
---
## What I do
- Define acceptance criteria (AC) in a consistent, testable format.
- Enforce minimum AC counts per task type to prevent under-specified work.
- Flag untestable or ambiguous criteria before implementation begins.
- Provide a direct mapping from AC to QA test cases.

## AC format standard

Use one of two formats. Choose the format that best fits the criterion's complexity.

### Format 1: Given/When/Then (behaviour-driven)

Use for user-facing features, API contracts, and any criterion with a clear trigger and observable outcome.

```
Given <precondition or system state>
When  <actor performs action or event occurs>
Then  <observable outcome that can be verified>
```

**Example — user login:**
```
Given a registered user with valid credentials
When  the user submits the login form
Then  the user is redirected to the dashboard and a session cookie is set
```

**Example — rate limiting:**
```
Given an unauthenticated client has made 100 requests in 60 seconds
When  the client sends request 101
Then  the server responds with HTTP 429 and a Retry-After header
```

### Format 2: Structured bullet (state-assertion)

Use for configuration, data integrity, structural, or non-behavioural criteria where there is no meaningful "when" trigger.

```
- <System/component> <verb> <observable property or constraint>
```

**Example — chore: add skill file:**
```
- File `.claude/skills/foo/SKILL.md` exists with valid YAML frontmatter.
- Frontmatter contains `name`, `description`, `license`, `compatibility`, and `metadata` keys.
- No dead links appear in the document body.
```

**Example — bug fix: null-pointer guard:**
```
- `UserService.getById(null)` returns `Optional.empty()` instead of throwing.
- Existing unit tests for `UserService` continue to pass.
```

### Mixing formats

A single task may use both formats. Apply Given/When/Then to behavioural criteria and structured bullets to structural or configuration criteria.

## Testability checklist

Before finalising any AC, verify every criterion passes all five checks:

- [ ] **Binary outcome** — the criterion is either fully met or not met; partial pass is not possible.
- [ ] **Observable** — the outcome can be verified by a human or automated test without access to internal state.
- [ ] **Scoped** — the criterion describes exactly one behaviour or property; compound "and" criteria are split.
- [ ] **Actor-independent** — the criterion holds regardless of who performs the action (no "the admin should feel…" language).
- [ ] **Falsifiable** — a concrete failing case exists; criteria that are always trivially true are rewritten or removed.
- [ ] **Unambiguous** — no weasel words (`fast`, `user-friendly`, `reasonable`) appear without a measurable threshold.
- [ ] **Implementation-free** — the criterion describes *what* must be true, not *how* to achieve it.

A criterion that fails any check must be rewritten before the task enters implementation.

## Anti-patterns

### 1. Vague quality adjectives

**Bad:**
```
The page should load quickly.
```
**Good:**
```
Given a cold-cache page load
When the user navigates to /dashboard
Then the page reaches Largest Contentful Paint (LCP) within 2.5 seconds on a 4G connection.
```

---

### 2. Compound criteria (hidden "and")

**Bad:**
```
The user can register and receive a confirmation email and log in immediately.
```
**Good (split into three):**
```
- The registration form submits successfully when all required fields are valid.
- A confirmation email is sent to the provided address within 60 seconds of registration.
- The user can log in with their credentials immediately after registration without email verification.
```

---

### 3. Implementation prescription

**Bad:**
```
Use Redis to cache the API response for 5 minutes.
```
**Good:**
```
Given a cacheable API response has been returned once
When the same request is made within 5 minutes
Then the response is served without hitting the origin service.
```

---

### 4. Untestable subjective criteria

**Bad:**
```
The onboarding flow should feel intuitive to new users.
```
**Good:**
```
Given a first-time user with no prior training
When the user completes the onboarding flow
Then the user reaches the main dashboard within 3 steps without accessing help documentation.
```

---

### 5. Missing precondition (floating "when")

**Bad:**
```
When the user clicks Delete, a confirmation dialog appears.
```
**Good:**
```
Given the user is viewing a resource they own
When the user clicks the Delete button
Then a confirmation dialog appears with the resource name and a Cancel option.
```

---

### 6. Acceptance criteria as implementation tasks

**Bad:**
```
Write unit tests for the payment service.
```
**Good:**
```
- All existing `PaymentService` unit tests pass after the change.
- A new unit test covers the refund path when the original charge is older than 30 days.
```

---

### 7. Criteria that duplicate existing behaviour

**Bad (for a bug fix task):**
```
The application continues to display the home page.
```
**Good:**
Omit regression criteria that are already covered by the existing test suite. Reference the test suite instead: "All existing smoke tests pass."

## AC-to-test-case mapping

QA derives test cases directly from AC. Each criterion maps to one or more test cases using the following rules.

### Mapping table

| AC element | QA test case element |
|---|---|
| `Given` clause | Test preconditions / fixture setup |
| `When` clause | Test action / stimulus |
| `Then` clause | Assertion / expected result |
| Structured bullet | Assertion in a state-verification test |
| Numeric threshold in `Then` | Performance or load test with that threshold as the pass criterion |
| Negative path implied by `Then` | Additional negative test case (e.g., invalid input → error response) |

### Derivation example

**AC (Given/When/Then):**
```
Given a registered user with valid credentials
When  the user submits the login form
Then  the user is redirected to /dashboard and a session cookie named `sid` is set
```

**Derived test cases:**

| # | Test case | Type |
|---|---|---|
| TC-1 | Valid credentials → redirect to /dashboard | Happy path |
| TC-2 | Valid credentials → `sid` cookie present in response | Happy path |
| TC-3 | Invalid password → no redirect, error message shown | Negative |
| TC-4 | Unregistered email → no redirect, error message shown | Negative |
| TC-5 | SQL injection in email field → no redirect, no server error | Security |

### Derivation rules

1. **One `Then` clause = at least one positive test case.**
2. **Each `Then` clause implies at least one negative test case** (what happens when the condition is *not* met).
3. **Numeric thresholds** (e.g., "within 2.5 seconds") generate a performance test with that value as the pass threshold.
4. **Structured bullets** map to assertion-only tests; no action step is needed.
5. **Compound `Then` clauses** (after splitting) each generate their own test case.

### Coverage gate

A task is not ready for QA sign-off unless every AC criterion has at least one corresponding test case with a pass/fail result recorded.

## Minimum AC count by task type

| Task type | Minimum AC count | Rationale |
|---|---|---|
| Feature | 3 | At minimum: happy path, one negative/edge case, one non-functional or structural criterion |
| Bug | 2 | At minimum: reproduction criterion (the bug no longer occurs) + regression criterion (existing behaviour preserved) |
| Chore | 1 | At minimum: one structural or output criterion confirming the work product exists and is correct |
| Epic | 0 (delegate to children) | Epics carry no direct AC; all criteria live on child tasks |
| Spike / research | 1 | At minimum: one output criterion (e.g., decision document exists, findings logged to TD) |

Tasks submitted for implementation with fewer than the minimum AC count are returned to the author for revision before a TD task is created.
