import { tool } from "@opencode-ai/plugin"

type TDAction =
  | "status"
  | "start"
  | "focus"
  | "link"
  | "log"
  | "review"
  | "approve"
  | "reject"
  | "handoff"
  | "whoami"
  | "usage"
  | "create"
  | "epic"
  | "tree"
  | "dep"
  | "ws"
  | "query"
  | "search"
  | "critical-path"
  | "next"
  | "ready"
  | "blocked"
  | "in-review"
  | "reviewable"
  | "context"
  | "comment"
  | "update"
  | "files"
  | "unlink"
  | "block-issue"
  | "unblock-issue"

async function runTD(args: string[]) {
  const cmd = Bun.$`td ${args}`.nothrow().quiet()
  const result = await cmd
  return {
    exitCode: result.exitCode,
    stdout: result.stdout.toString().trim(),
    stderr: result.stderr.toString().trim(),
  }
}

export default tool({
  description:
    "Operate TD task workflow from the agent. Actions: status, start, focus, link, log (logType: decision/blocker/hypothesis/tried/result), review, approve, reject, handoff, whoami, usage, create, epic, tree, dep (depAction: add/list/blocking), ws (wsAction: start/tag/log/current/handoff), query, search, critical-path, next, ready, blocked, in-review, reviewable, context, comment, update, files, unlink, block-issue, unblock-issue",
  args: {
    action: tool.schema
      .enum([
        "status",
        "start",
        "focus",
        "link",
        "log",
        "review",
        "approve",
        "reject",
        "handoff",
        "whoami",
        "usage",
        "create",
        "epic",
        "tree",
        "dep",
        "ws",
        "query",
        "search",
        "critical-path",
        "next",
        "ready",
        "blocked",
        "in-review",
        "reviewable",
        "context",
        "comment",
        "update",
        "files",
        "unlink",
        "block-issue",
        "unblock-issue",
      ])
      .describe("TD action to execute"),
    task: tool.schema
      .string()
      .optional()
      .describe("Task key/id for start/focus/review/approve/reject/link/handoff, or task title for create"),
    files: tool.schema
      .array(tool.schema.string())
      .optional()
      .describe("Files to link for the link action"),
    message: tool.schema
      .string()
      .optional()
      .describe("Log message for the log action, or reason for approve/reject actions"),
    done: tool.schema
      .string()
      .optional()
      .describe("What was completed (for handoff action)"),
    remaining: tool.schema
      .string()
      .optional()
      .describe("What still needs to be done (for handoff action)"),
    decision: tool.schema
      .string()
      .optional()
      .describe("Key decisions made (for handoff action)"),
    uncertain: tool.schema
      .string()
      .optional()
      .describe("Areas of uncertainty or questions (for handoff action)"),
    newSession: tool.schema
      .boolean()
      .optional()
      .describe("Start a new session (for usage action)"),
    type: tool.schema
      .string()
      .optional()
      .describe("Issue type for create action: bug, feature, task, epic, chore"),
    priority: tool.schema
      .string()
      .optional()
      .describe("Priority for create action: P0, P1, P2, P3, P4"),
    labels: tool.schema
      .string()
      .optional()
      .describe("Comma-separated labels for create action"),
    description: tool.schema
      .string()
      .optional()
      .describe("Description text for create action"),
    parent: tool.schema
      .string()
      .optional()
      .describe("Parent issue ID for create action (for subtasks/epics)"),
    minor: tool.schema
      .boolean()
      .optional()
      .describe("Mark as minor task for create action (allows self-review)"),
    points: tool.schema
      .number()
      .optional()
      .describe("Story points for create action (Fibonacci: 1,2,3,5,8,13,21)"),
    acceptance: tool.schema
      .string()
      .optional()
      .describe("Acceptance criteria text for create action"),
    dependsOn: tool.schema
      .string()
      .optional()
      .describe("Comma-separated issue IDs this task depends on (for create action)"),
    blocks: tool.schema
      .string()
      .optional()
      .describe("Comma-separated issue IDs this task blocks (for create action)"),
    wsAction: tool.schema
      .enum(["start", "tag", "log", "current", "handoff"])
      .optional()
      .describe("Work session sub-action (for ws action)"),
    wsName: tool.schema
      .string()
      .optional()
      .describe("Work session name (for ws start)"),
    issueIds: tool.schema
      .array(tool.schema.string())
      .optional()
      .describe("Issue IDs to tag into work session (for ws tag)"),
    noStart: tool.schema
      .boolean()
      .optional()
      .describe("Do not auto-start tagged issues (for ws tag --no-start)"),
    depAction: tool.schema
      .enum(["add", "list", "blocking"])
      .optional()
      .describe("Dependency sub-action (for dep action)"),
    targetIssue: tool.schema
      .string()
      .optional()
      .describe("Target issue ID for dep add or tree add-child"),
    logType: tool.schema
      .enum(["decision", "blocker", "hypothesis", "tried", "result"])
      .optional()
      .describe("Structured log type flag (for log action)"),
    query: tool.schema
      .string()
      .optional()
      .describe("TDQ query string (for query action) or keyword (for search action)"),
    commentText: tool.schema
      .string()
      .optional()
      .describe("Comment text (for comment action)"),
    childIssue: tool.schema
      .string()
      .optional()
      .describe("Child issue ID to add under parent (for tree add-child)"),
    updateTitle: tool.schema
      .string()
      .optional()
      .describe("New title (for update action)"),
    updateDescription: tool.schema
      .string()
      .optional()
      .describe("New description (for update action)"),
  },
  async execute(input, context) {
    const action = input.action as TDAction

    const version = await runTD(["version"])
    if (version.exitCode !== 0) {
      return "TD is not available in this environment. Install from https://github.com/marcus/td"
    }

    switch (action) {
      case "status": {
        const result = await runTD(["status", "--json"])
        if (result.exitCode !== 0) return result.stderr || "Failed to read TD status"
        return result.stdout
      }

      case "whoami": {
        const result = await runTD(["whoami", "--json"])
        if (result.exitCode !== 0) return result.stderr || "Failed to read TD session identity"
        return result.stdout
      }

      case "start": {
        if (!input.task) return "Missing required argument: task"
        const result = await runTD(["start", input.task])
        return result.exitCode === 0 ? result.stdout || `Started ${input.task}` : result.stderr
      }

      case "focus": {
        if (!input.task) return "Missing required argument: task"
        const result = await runTD(["focus", input.task])
        return result.exitCode === 0 ? result.stdout || `Focused ${input.task}` : result.stderr
      }

      case "link": {
        if (!input.task) return "Missing required argument: task"
        const files = (input.files ?? []).filter(Boolean)
        if (files.length === 0) return "Missing required argument: files"

        const relativeFiles = files.map((file) => {
          if (file.startsWith("/")) {
            if (file.startsWith(context.worktree)) {
              return file.slice(context.worktree.length + 1)
            }
            return file
          }
          return file
        })

        const result = await runTD(["link", input.task, ...relativeFiles])
        return result.exitCode === 0 ? result.stdout || "Linked files" : result.stderr
      }

      case "log": {
        if (!input.message) return "Missing required argument: message"
        const args = ["log"]
        if (input.logType) {
          args.push(`--${input.logType}`)
        }
        args.push(input.message)
        const result = await runTD(args)
        return result.exitCode === 0 ? result.stdout || "Log entry added" : result.stderr
      }

      case "review": {
        if (!input.task) return "Missing required argument: task"
        const result = await runTD(["review", input.task])
        return result.exitCode === 0 ? result.stdout || `Submitted ${input.task} for review` : result.stderr
      }

      case "approve": {
        const args = ["approve"]
        if (input.task) {
          args.push(input.task)
        }
        if (input.message) {
          args.push("--reason", input.message)
        }
        args.push("--json")
        const result = await runTD(args)
        return result.exitCode === 0
          ? result.stdout || (input.task ? `Approved ${input.task}` : "Approved focused task")
          : result.stderr
      }

      case "reject": {
        const args = ["reject"]
        if (input.task) {
          args.push(input.task)
        }
        if (input.message) {
          args.push("--reason", input.message)
        }
        args.push("--json")
        const result = await runTD(args)
        return result.exitCode === 0
          ? result.stdout || (input.task ? `Rejected ${input.task}` : "Rejected focused task")
          : result.stderr
      }

      case "handoff": {
        const args = ["handoff"]

        if (input.task) {
          args.push(input.task)
        }

        if (input.done) {
          args.push("--done", input.done)
        }
        if (input.remaining) {
          args.push("--remaining", input.remaining)
        }
        if (input.decision) {
          args.push("--decision", input.decision)
        }
        if (input.uncertain) {
          args.push("--uncertain", input.uncertain)
        }

        const result = await runTD(args)
        return result.exitCode === 0 ? result.stdout || "Handoff captured" : result.stderr
      }

      case "usage": {
        const args = ["usage"]

        if (input.newSession) {
          args.push("--new-session")
        }

        const result = await runTD(args)
        return result.exitCode === 0 ? result.stdout : result.stderr
      }

      case "create": {
        if (!input.task) return "Missing required argument: task (title)"

        const args = ["create", input.task]

        if (input.type) {
          args.push("--type", input.type)
        }
        if (input.priority) {
          args.push("--priority", input.priority)
        }
        if (input.labels) {
          args.push("--labels", input.labels)
        }
        if (input.description) {
          args.push("--description", input.description)
        }
        if (input.parent) {
          args.push("--parent", input.parent)
        }
        if (input.minor) {
          args.push("--minor")
        }
        if (input.points) {
          args.push("--points", String(input.points))
        }
        if (input.acceptance) {
          args.push("--acceptance", input.acceptance)
        }
        if (input.dependsOn) {
          args.push("--depends-on", input.dependsOn)
        }
        if (input.blocks) {
          args.push("--blocks", input.blocks)
        }

        const result = await runTD(args)
        if (result.exitCode === 0) {
          const match = result.stdout.match(/CREATED (td-[a-f0-9]+)/)
          if (match) {
            return `Created task: ${match[1]}\n${result.stdout}`
          }
          return result.stdout || "Task created"
        }
        return result.stderr
      }

      case "epic": {
        if (!input.task) return "Missing required argument: task (title)"

        const args = ["epic", "create", input.task]
        if (input.priority) {
          args.push("--priority", input.priority)
        }
        if (input.labels) {
          args.push("--labels", input.labels)
        }
        if (input.description) {
          args.push("--description", input.description)
        }
        if (input.parent) {
          args.push("--parent", input.parent)
        }
        if (input.blocks) {
          args.push("--blocks", input.blocks)
        }
        if (input.dependsOn) {
          args.push("--depends-on", input.dependsOn)
        }

        const result = await runTD(args)
        return result.exitCode === 0 ? result.stdout || "Epic created" : result.stderr
      }

      case "tree": {
        if (!input.task) return "Missing required argument: task"

        if (input.childIssue) {
          const result = await runTD(["update", input.childIssue, "--parent", input.task])
          return result.exitCode === 0 ? result.stdout || `Added ${input.childIssue} as child of ${input.task}` : result.stderr
        }

        const result = await runTD(["tree", input.task])
        return result.exitCode === 0 ? result.stdout || "Tree displayed" : result.stderr
      }

      case "dep": {
        if (!input.task) return "Missing required argument: task"

        const depAction = input.depAction ?? "list"
        let args: string[] = []

        if (depAction === "add") {
          if (!input.targetIssue) return "Missing required argument: targetIssue"
          args = ["dep", "add", input.task, input.targetIssue]
        } else if (depAction === "blocking") {
          args = ["dep", input.task, "--blocking"]
        } else {
          args = ["dep", input.task]
        }

        const result = await runTD(args)
        return result.exitCode === 0 ? result.stdout || "Dependency command completed" : result.stderr
      }

      case "ws": {
        if (!input.wsAction) return "Missing required argument: wsAction"

        let args: string[] = []
        if (input.wsAction === "start") {
          if (!input.wsName) return "Missing required argument: wsName"
          args = ["ws", "start", input.wsName]
        } else if (input.wsAction === "tag") {
          const issueIds = (input.issueIds ?? []).filter(Boolean)
          if (issueIds.length === 0) return "Missing required argument: issueIds"
          args = ["ws", "tag", ...issueIds]
          if (input.noStart) {
            args.push("--no-start")
          }
        } else if (input.wsAction === "log") {
          if (!input.message) return "Missing required argument: message"
          args = ["ws", "log", input.message]
        } else if (input.wsAction === "current") {
          args = ["ws", "current"]
        } else {
          args = ["ws", "handoff"]
          if (input.done) args.push("--done", input.done)
          if (input.remaining) args.push("--remaining", input.remaining)
          if (input.decision) args.push("--decision", input.decision)
          if (input.uncertain) args.push("--uncertain", input.uncertain)
        }

        const result = await runTD(args)
        return result.exitCode === 0 ? result.stdout || "Work session command completed" : result.stderr
      }

      case "query": {
        if (!input.query) return "Missing required argument: query"
        const result = await runTD(["query", input.query])
        return result.exitCode === 0 ? result.stdout || "Query completed" : result.stderr
      }

      case "search": {
        if (!input.query) return "Missing required argument: query"
        const result = await runTD(["search", input.query])
        return result.exitCode === 0 ? result.stdout || "Search completed" : result.stderr
      }

      case "critical-path": {
        const result = await runTD(["critical-path"])
        return result.exitCode === 0 ? result.stdout || "Critical path displayed" : result.stderr
      }

      case "next": {
        const result = await runTD(["next"])
        return result.exitCode === 0 ? result.stdout || "Next item displayed" : result.stderr
      }

      case "ready": {
        const result = await runTD(["ready"])
        return result.exitCode === 0 ? result.stdout || "Ready items displayed" : result.stderr
      }

      case "blocked": {
        const result = await runTD(["blocked"])
        return result.exitCode === 0 ? result.stdout || "Blocked items displayed" : result.stderr
      }

      case "in-review": {
        const result = await runTD(["in-review"])
        return result.exitCode === 0 ? result.stdout || "In-review items displayed" : result.stderr
      }

      case "reviewable": {
        const result = await runTD(["reviewable"])
        return result.exitCode === 0 ? result.stdout || "Reviewable items displayed" : result.stderr
      }

      case "context": {
        if (!input.task) return "Missing required argument: task"
        const result = await runTD(["context", input.task])
        return result.exitCode === 0 ? result.stdout || "Context displayed" : result.stderr
      }

      case "comment": {
        if (!input.task) return "Missing required argument: task"
        if (!input.commentText) return "Missing required argument: commentText"
        const result = await runTD(["comment", input.task, input.commentText])
        return result.exitCode === 0 ? result.stdout || "Comment added" : result.stderr
      }

      case "update": {
        if (!input.task) return "Missing required argument: task"
        const args = ["update", input.task]

        if (input.updateTitle) {
          args.push("--title", input.updateTitle)
        }
        if (input.updateDescription) {
          args.push("--description", input.updateDescription)
        }
        if (input.priority) {
          args.push("--priority", input.priority)
        }
        if (input.type) {
          args.push("--type", input.type)
        }
        if (input.labels) {
          args.push("--labels", input.labels)
        }

        const result = await runTD(args)
        return result.exitCode === 0 ? result.stdout || "Issue updated" : result.stderr
      }

      case "files": {
        if (!input.task) return "Missing required argument: task"
        const result = await runTD(["files", input.task])
        return result.exitCode === 0 ? result.stdout || "Files displayed" : result.stderr
      }

      case "unlink": {
        if (!input.task) return "Missing required argument: task"
        const files = (input.files ?? []).filter(Boolean)
        if (files.length === 0) return "Missing required argument: files"

        const relativeFiles = files.map((file) => {
          if (file.startsWith("/")) {
            if (file.startsWith(context.worktree)) {
              return file.slice(context.worktree.length + 1)
            }
            return file
          }
          return file
        })

        const result = await runTD(["unlink", input.task, ...relativeFiles])
        return result.exitCode === 0 ? result.stdout || "Unlinked files" : result.stderr
      }

      case "block-issue": {
        if (!input.task) return "Missing required argument: task"
        const result = await runTD(["block", input.task])
        return result.exitCode === 0 ? result.stdout || `Blocked ${input.task}` : result.stderr
      }

      case "unblock-issue": {
        if (!input.task) return "Missing required argument: task"
        const result = await runTD(["unblock", input.task])
        return result.exitCode === 0 ? result.stdout || `Unblocked ${input.task}` : result.stderr
      }

      default:
        return `Unsupported action: ${action}`
    }
  },
})
