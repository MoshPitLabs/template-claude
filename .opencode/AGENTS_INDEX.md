# OpenCode Components Index

Complete catalog of all components in this template repository.

**Total Components:** 6 agents | 2 commands | 8 skills | 5 plugins | 1 tool

---

## Summary

| Component Type | Count | Description |
|---|---|---|
| **Team Agents** | 6 | Core delivery pipeline agents |
| **Slash Commands** | 2 | Workflow automation commands |
| **Workflow Skills** | 8 | Bundled skill resources |
| **Plugins** | 5 | Native TypeScript automation plugins |
| **Custom Tools** | 1 | AI tool integrations |

**Total Components:** 6 agents | 2 commands | 8 skills | 5 plugins | 1 tool

---

## Team Agents (6)

- [staff-engineer](agents/staff-engineer.md)
- [senior-engineer](agents/senior-engineer.md)
- [product-manager](agents/product-manager.md)
- [qa-engineer](agents/qa-engineer.md)
- [ux-designer](agents/ux-designer.md)
- [team-lead](agents/team-lead.md)

## Slash Commands (2)

- [/plan](commands/plan.md) - Create a TD-linked implementation plan with worktree execution map
- [/build](commands/build.md) - Implement a plan with full team orchestration and TD tracking

## Workflow Skills (8)

- [acceptance-criteria-authoring](skills/acceptance-criteria-authoring/) - Author clear, testable acceptance criteria for features, bugs, and chores using standard formats that QA can directly derive test cases from
- [bug-triage](skills/bug-triage/) - Classify, prioritize, and route incoming bug reports using a consistent severity rubric and triage decision tree
- [design-system](skills/design-system/) - Enforce consistent component naming, interaction patterns, accessibility standards, design tokens, and handoff conventions across all UI/UX design work
- [git-worktree-flow](skills/git-worktree-flow/) - One-task-per-worktree delivery with branch, merge, and cleanup hygiene
- [pr-quality-gate](skills/pr-quality-gate/) - Enforceable PR quality checklist before opening or merging
- [release-notes](skills/release-notes/) - Structured release note generation from merged tasks and PR context
- [tdd-authoring](skills/tdd-authoring/) - Author structured Technical Design Documents (TDDs) that translate task requirements into testable, reviewable design artifacts
- [td-workflow](skills/td-workflow/) - TD lifecycle enforcement across planning, implementation, and review

## Plugins (5)

- [security.ts](plugins/security.ts) - Blocks dangerous commands, protects `.env` and credential files
- [logging.ts](plugins/logging.ts) - Comprehensive JSONL event logging for all operations
- [notifications.ts](plugins/notifications.ts) - Session analytics with rich in-app TUI toast notifications
- [post-stop-detector.ts](plugins/post-stop-detector.ts) - Detects orphaned files created after session ends
- [td-enforcer.ts](plugins/td-enforcer.ts) - Enforces task-driven development with TD CLI integration

## Custom Tools (1)

- [td.ts](tools/td.ts) - TD CLI integration tool (31 actions for task-driven development)

---

*Last updated: 2026-02-22*
