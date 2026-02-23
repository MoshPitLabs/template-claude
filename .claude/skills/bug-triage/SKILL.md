---
name: bug-triage
description: Classify, prioritize, and route incoming bug reports using a consistent severity rubric and triage decision tree
license: MIT
compatibility: claude-code
metadata:
  audience: qa
  workflow: triage
---
## What I do
- Standardize bug report capture with a complete, reproducible template.
- Apply a P0–P3 severity rubric so every bug gets a consistent priority.
- Guide triage decisions: fix now, defer, or won't fix — with explicit criteria for each.
- Escalate P0 incidents to the team-lead immediately.
- Convert triaged reports into properly typed TD tasks.

## Bug report template

Use this template for every incoming bug. All fields are required before a report can be triaged.

```
### Bug report

**Title:** [Short, action-oriented description — e.g., "Login fails with valid credentials on Safari 17"]

**Severity:** [P0 / P1 / P2 / P3 — see Severity classification below]

**Steps to reproduce:**
1. [First step]
2. [Second step]
3. [Continue until bug is triggered]

**Expected behaviour:**
[What should happen]

**Actual behaviour:**
[What actually happens — include error messages, screenshots, or logs]

**Environment:**
- OS: [e.g., macOS 14.3 / Ubuntu 22.04 / Windows 11]
- Browser / runtime: [e.g., Chrome 122, Node 20.11, iOS 17.3]
- App version / commit: [e.g., v2.4.1 / abc1234]
- Reproducibility: [Always / Intermittent (~X% of attempts) / Once]

**Linked TD task:** [td-XXXXXX — leave blank until triage creates the task]
```

## Severity classification

Assign the highest severity that applies. When in doubt, escalate.

| Severity | Definition | Concrete examples |
|----------|------------|-------------------|
| **P0 — Critical** | Production is down or data is at risk. No workaround exists. Immediate action required. | Payment processing returns 500 for all users; user data exposed via API without auth; database corruption on write |
| **P1 — High** | Core feature is broken for a significant user segment. Workaround is painful or unavailable. | Login fails for SSO users; file upload silently drops data; checkout flow crashes on mobile |
| **P2 — Medium** | Non-critical feature is degraded or a workaround exists but is inconvenient. | Search returns stale results; email notifications delayed by >1 hour; dark mode colours incorrect |
| **P3 — Low** | Cosmetic issue, minor UX friction, or edge-case behaviour with minimal user impact. | Tooltip text has a typo; button alignment off by 2px on 4K displays; unused console warning logged |

**Escalation trigger:** Any bug initially filed as P2 or lower that is later found to affect data integrity or security must be immediately re-classified to P0 and escalated.

## Triage decision tree

Evaluate each triaged report against the three outcomes in order.

### Fix now
**Criteria (any one is sufficient):**
- Severity is P0 or P1.
- Bug blocks a release or a dependent task.
- Regression introduced in the current sprint.
- Security or data-integrity risk at any severity.

**Action:** Create a TD bug task immediately (see TD task creation format). For P0, also follow the escalation path.

---

### Defer
**Criteria (all must be true):**
- Severity is P2 or P3.
- No active user reports or SLA breach risk.
- A workaround exists and is documented in the report.
- Fixing now would destabilise in-flight work.

**Action:** Create a TD bug task with `priority: "P2"` or `"P3"`. Add a `defer` label and a comment explaining the deferral rationale and target milestone.

---

### Won't fix
**Criteria (any one is sufficient):**
- Bug is by design and the behaviour is documented.
- Reproduction rate is too low to justify investigation cost.
- Affected environment is end-of-life or unsupported.
- Fixing would require disproportionate effort relative to impact.

**Action:** Close the report with a comment explaining the won't-fix rationale. Link to relevant documentation if the behaviour is intentional. No TD task is created.

## Escalation path

### P0 escalation protocol

When a P0 bug is confirmed:

1. **Immediately notify the team-lead** via the project's primary communication channel (e.g., Slack `#incidents`, Linear comment, or direct message). Include:
   - Bug title and TD task ID (once created).
   - One-line impact summary: who is affected and how.
   - Current reproduction steps and any known workaround.

2. **Create the TD task first** (see TD task creation format), then share the task link in the notification.

3. **Update the TD task log** every 30 minutes with status until resolved:
   ```
   td_log(task: "td-XXXXXX", message: "P0 status update: [current state, next action]")
   ```

4. **Do not defer or close a P0** without explicit team-lead sign-off.

### Notification template

```
🚨 P0 Bug — [Title]
Task: td-XXXXXX
Impact: [Who is affected and what is broken]
Workaround: [None / describe workaround]
Assignee: [Name or TBD]
```

## TD task creation format

After triage, create a TD bug task using the `td` tool. Map the triaged report fields to TD parameters as follows:

| Bug report field | TD parameter |
|-----------------|--------------|
| Title | `task` |
| Severity (P0–P3) | `priority` |
| Steps + expected/actual | `description` |
| Acceptance criteria | `acceptance` |

### Example TD tool call

```
td_create(
  title: "Login fails with valid credentials on Safari 17",
  type: "bug",
  priority: "P1",
  points: 2,
  description: "Steps to reproduce: 1. Open Safari 17 on macOS 14. 2. Navigate to /login. 3. Enter valid credentials. 4. Click Sign in.\n\nExpected: User is redirected to dashboard.\nActual: Page reloads with no error message. Network tab shows 401.",
  acceptance: "1. Login succeeds with valid credentials on Safari 17. 2. Invalid credentials show a clear error message. 3. No regression on Chrome or Firefox."
)
```

After creating the task, update the bug report's **Linked TD task** field with the returned task ID, and link the report file if it exists on disk:

```
td_files(task: "td-XXXXXX", files: ["bugs/safari-login-2026-02-22.md"])
```
