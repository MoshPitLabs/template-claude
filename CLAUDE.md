# Claude Code Project Configuration

This project uses Claude Code with team-based AI agent orchestration and Task-Driven (TD) workflow.

## Project Setup

### Status Line

The project includes a custom status line that displays context window usage in real-time:

**Display**: `[Model] # [###---] | 42.5% used | ~115k left | session_id`

- Visual progress bar with color coding (green → yellow → red)
- Percentage and remaining tokens
- Session ID tracking

**Status lines available**: 9 versions in `.claude/status_lines/` (v6 is active)

See `.claude/status_lines/README.md` for all versions and customization options.

### Hooks

This project includes security and TD enforcement hooks in `.claude/hooks/`:

- **security-check.sh** - Blocks sensitive files (.env, keys, credentials) and dangerous commands
- **td-enforcer.sh** - Requires active TD task before file edits, auto-links files to tasks

Hooks are configured in `.claude/config.json` and run automatically on tool execution.

### Required Dependencies

- **TD CLI** - Task-Driven development CLI (https://github.com/MoshPitLabs/td)
  - Required for td-enforcer.sh to work
  - Install: Follow TD CLI installation instructions
  - Initialize in project: `td init`

### Workflow

1. **Start a TD task** before editing files:
   ```bash
   td start <task-id>
   ```

2. **Edit files** - hooks will auto-link files to active task

3. **Commit changes** when done:
   ```bash
   git add .
   git commit -m "your message"
   ```

### Agent Team

This project defines 6 specialized agents in `.opencode/agents/`:

- **team-lead** - Orchestrates delivery, delegates to role agents
- **staff-engineer** - Produces TDDs, performs code reviews
- **senior-engineer** - Implements code in isolated worktrees
- **product-manager** - Plans work, creates TD tasks with acceptance criteria
- **qa-engineer** - Tests and verifies acceptance criteria, produces bug reports
- **ux-designer** - Creates design specs for planning

### Skills

Available workflow skills in `.opencode/skills/`:
- `git-worktree-flow` - One task per worktree execution
- `td-workflow` - TD lifecycle enforcement
- `tdd-authoring` - Technical design documents
- `pr-quality-gate` - PR merge readiness checklist
- `acceptance-criteria-authoring` - AC creation guidelines
- `bug-triage` - Bug report handling
- `release-notes` - Release documentation
- `design-system` - UI/UX design patterns
- `git-workflow` - Git best practices
- `frontend-design` - Frontend design specs

### Commands

- `/plan` - Create implementation plan
- `/build` - Execute plan with orchestration

## Security

The security hook blocks access to:
- `.env` files (except `.env.example`, `.env.sample`, `.env.template`)
- Key material (`.pem`, `.key`, SSH keys, certificates, keystores)
- Credential files
- Dangerous `rm -rf` command patterns

Violations are logged to `~/.claude/logs/security/security.jsonl`.

## TD Enforcement

The TD enforcer hook:
- **Blocks** Write/Edit operations when no active TD task exists
- **Auto-links** modified files to the active task
- **Auto-logs** file edits to TD task logs
- **Gracefully handles** TD not being installed (allows normal operation)

Events are logged to `~/.claude/logs/td/td_enforcer.jsonl`.

## Migration Notes

This project was migrated from OpenCode to Claude Code. See `.claude/MIGRATION.md` for details.

## Documentation

- Hook configuration: `.claude/hooks/README.md`
- Migration details: `.claude/MIGRATION.md`
- Agent team workflow: `.opencode/docs/agent-team-workflow.md`
- Agent tools policy: `.opencode/docs/agent-tools-policy.md`
