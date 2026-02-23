#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";

interface TDResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

function runTD(args: string[]): TDResult {
  try {
    const stdout = execSync(`td ${args.join(" ")}`, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return {
      exitCode: 0,
      stdout: stdout.trim(),
      stderr: "",
    };
  } catch (error: any) {
    return {
      exitCode: error.status || 1,
      stdout: error.stdout?.toString().trim() || "",
      stderr: error.stderr?.toString().trim() || error.message,
    };
  }
}

// Define all TD tools
const tools: Tool[] = [
  {
    name: "td_status",
    description: "Get TD status including active task and session info",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_whoami",
    description: "Get TD session identity",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_start",
    description: "Start working on a task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id to start" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_focus",
    description: "Focus on a different task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id to focus" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_link",
    description: "Link files to a task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" },
        files: {
          type: "array",
          items: { type: "string" },
          description: "Files to link",
        },
      },
      required: ["task", "files"],
    },
  },
  {
    name: "td_log",
    description: "Add a log entry to the active task",
    inputSchema: {
      type: "object",
      properties: {
        message: { type: "string", description: "Log message" },
        logType: {
          type: "string",
          enum: ["decision", "blocker", "hypothesis", "tried", "result"],
          description: "Structured log type",
        },
      },
      required: ["message"],
    },
  },
  {
    name: "td_review",
    description: "Submit task for review",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id to review" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_approve",
    description: "Approve a task in review",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id to approve (optional if focused)" },
        reason: { type: "string", description: "Approval reason" },
      },
    },
  },
  {
    name: "td_reject",
    description: "Reject a task in review",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id to reject (optional if focused)" },
        reason: { type: "string", description: "Rejection reason" },
      },
    },
  },
  {
    name: "td_handoff",
    description: "Create handoff notes for task or session",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id (optional)" },
        done: { type: "string", description: "What was completed" },
        remaining: { type: "string", description: "What still needs to be done" },
        decision: { type: "string", description: "Key decisions made" },
        uncertain: { type: "string", description: "Areas of uncertainty or questions" },
      },
    },
  },
  {
    name: "td_usage",
    description: "Show TD usage stats",
    inputSchema: {
      type: "object",
      properties: {
        newSession: { type: "boolean", description: "Start a new session" },
      },
    },
  },
  {
    name: "td_create",
    description: "Create a new TD task/issue",
    inputSchema: {
      type: "object",
      properties: {
        title: { type: "string", description: "Task title" },
        type: {
          type: "string",
          enum: ["bug", "feature", "task", "epic", "chore"],
          description: "Issue type",
        },
        priority: {
          type: "string",
          enum: ["P0", "P1", "P2", "P3", "P4"],
          description: "Priority",
        },
        labels: { type: "string", description: "Comma-separated labels" },
        description: { type: "string", description: "Description text" },
        parent: { type: "string", description: "Parent issue ID for subtasks" },
        minor: { type: "boolean", description: "Mark as minor task (allows self-review)" },
        points: {
          type: "number",
          enum: [1, 2, 3, 5, 8, 13, 21],
          description: "Story points (Fibonacci)",
        },
        acceptance: { type: "string", description: "Acceptance criteria" },
        dependsOn: { type: "string", description: "Comma-separated issue IDs this depends on" },
        blocks: { type: "string", description: "Comma-separated issue IDs this blocks" },
      },
      required: ["title"],
    },
  },
  {
    name: "td_epic",
    description: "Create an epic",
    inputSchema: {
      type: "object",
      properties: {
        title: { type: "string", description: "Epic title" },
        priority: { type: "string", enum: ["P0", "P1", "P2", "P3", "P4"] },
        labels: { type: "string", description: "Comma-separated labels" },
        description: { type: "string", description: "Description text" },
        parent: { type: "string", description: "Parent epic ID" },
        blocks: { type: "string", description: "Comma-separated issue IDs this blocks" },
        dependsOn: { type: "string", description: "Comma-separated issue IDs this depends on" },
      },
      required: ["title"],
    },
  },
  {
    name: "td_tree",
    description: "Show or modify task tree structure",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task/epic to show tree for" },
        childIssue: { type: "string", description: "Child issue to add under task" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_dep",
    description: "Manage task dependencies",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" },
        action: {
          type: "string",
          enum: ["add", "list", "blocking"],
          description: "Dependency action",
        },
        targetIssue: { type: "string", description: "Target issue for 'add' action" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_ws",
    description: "Work session management",
    inputSchema: {
      type: "object",
      properties: {
        action: {
          type: "string",
          enum: ["start", "tag", "log", "current", "handoff"],
          description: "Work session action",
        },
        name: { type: "string", description: "Work session name (for start)" },
        issueIds: {
          type: "array",
          items: { type: "string" },
          description: "Issue IDs to tag",
        },
        noStart: { type: "boolean", description: "Don't auto-start tagged issues" },
        message: { type: "string", description: "Log message (for log)" },
        done: { type: "string", description: "What was completed (for handoff)" },
        remaining: { type: "string", description: "What remains (for handoff)" },
        decision: { type: "string", description: "Key decisions (for handoff)" },
        uncertain: { type: "string", description: "Uncertainties (for handoff)" },
      },
      required: ["action"],
    },
  },
  {
    name: "td_query",
    description: "Execute TDQ query",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "TDQ query string" },
      },
      required: ["query"],
    },
  },
  {
    name: "td_search",
    description: "Full-text search across tasks",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search keyword" },
      },
      required: ["query"],
    },
  },
  {
    name: "td_critical_path",
    description: "Show optimal sequence to unblock the most work",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_next",
    description: "Show highest-priority open issue",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_ready",
    description: "Show all ready (open) issues by priority",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_blocked",
    description: "Show all blocked issues",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_in_review",
    description: "Show all issues in review",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_reviewable",
    description: "Show issues this session can review (not self-implemented)",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "td_context",
    description: "Show full task context (logs, files, deps, acceptance criteria)",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_comment",
    description: "Add a comment to a task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" },
        text: { type: "string", description: "Comment text" },
      },
      required: ["task", "text"],
    },
  },
  {
    name: "td_update",
    description: "Update task metadata",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" },
        title: { type: "string", description: "New title" },
        description: { type: "string", description: "New description" },
        priority: { type: "string", enum: ["P0", "P1", "P2", "P3", "P4"] },
        type: { type: "string", enum: ["bug", "feature", "task", "epic", "chore"] },
        labels: { type: "string", description: "Comma-separated labels" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_files",
    description: "Show files linked to a task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_unlink",
    description: "Unlink files from a task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id" },
        files: {
          type: "array",
          items: { type: "string" },
          description: "Files to unlink",
        },
      },
      required: ["task", "files"],
    },
  },
  {
    name: "td_block",
    description: "Mark a task as blocked",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id to block" },
      },
      required: ["task"],
    },
  },
  {
    name: "td_unblock",
    description: "Unblock a task",
    inputSchema: {
      type: "object",
      properties: {
        task: { type: "string", description: "Task key/id to unblock" },
      },
      required: ["task"],
    },
  },
];

// Server implementation
const server = new Server(
  {
    name: "td-mcp-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools };
});

// Call tool handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  // Check if TD is available
  const versionCheck = runTD(["version"]);
  if (versionCheck.exitCode !== 0) {
    return {
      content: [
        {
          type: "text",
          text: "TD CLI is not available. Install from https://github.com/MoshPitLabs/td",
        },
      ],
    };
  }

  try {
    let result: TDResult;
    let cmdArgs: string[] = [];

    switch (name) {
      case "td_status":
        cmdArgs = ["status", "--json"];
        break;

      case "td_whoami":
        cmdArgs = ["whoami", "--json"];
        break;

      case "td_start":
        cmdArgs = ["start", args.task as string];
        break;

      case "td_focus":
        cmdArgs = ["focus", args.task as string];
        break;

      case "td_link": {
        const files = (args.files as string[]) || [];
        cmdArgs = ["link", args.task as string, ...files];
        break;
      }

      case "td_log": {
        cmdArgs = ["log"];
        if (args.logType) {
          cmdArgs.push(`--${args.logType}`);
        }
        cmdArgs.push(args.message as string);
        break;
      }

      case "td_review":
        cmdArgs = ["review", args.task as string];
        break;

      case "td_approve": {
        cmdArgs = ["approve"];
        if (args.task) cmdArgs.push(args.task as string);
        if (args.reason) cmdArgs.push("--reason", args.reason as string);
        cmdArgs.push("--json");
        break;
      }

      case "td_reject": {
        cmdArgs = ["reject"];
        if (args.task) cmdArgs.push(args.task as string);
        if (args.reason) cmdArgs.push("--reason", args.reason as string);
        cmdArgs.push("--json");
        break;
      }

      case "td_handoff": {
        cmdArgs = ["handoff"];
        if (args.task) cmdArgs.push(args.task as string);
        if (args.done) cmdArgs.push("--done", args.done as string);
        if (args.remaining) cmdArgs.push("--remaining", args.remaining as string);
        if (args.decision) cmdArgs.push("--decision", args.decision as string);
        if (args.uncertain) cmdArgs.push("--uncertain", args.uncertain as string);
        break;
      }

      case "td_usage": {
        cmdArgs = ["usage"];
        if (args.newSession) cmdArgs.push("--new-session");
        break;
      }

      case "td_create": {
        cmdArgs = ["create", args.title as string];
        if (args.type) cmdArgs.push("--type", args.type as string);
        if (args.priority) cmdArgs.push("--priority", args.priority as string);
        if (args.labels) cmdArgs.push("--labels", args.labels as string);
        if (args.description) cmdArgs.push("--description", args.description as string);
        if (args.parent) cmdArgs.push("--parent", args.parent as string);
        if (args.minor) cmdArgs.push("--minor");
        if (args.points) cmdArgs.push("--points", String(args.points));
        if (args.acceptance) cmdArgs.push("--acceptance", args.acceptance as string);
        if (args.dependsOn) cmdArgs.push("--depends-on", args.dependsOn as string);
        if (args.blocks) cmdArgs.push("--blocks", args.blocks as string);
        break;
      }

      case "td_epic": {
        cmdArgs = ["epic", "create", args.title as string];
        if (args.priority) cmdArgs.push("--priority", args.priority as string);
        if (args.labels) cmdArgs.push("--labels", args.labels as string);
        if (args.description) cmdArgs.push("--description", args.description as string);
        if (args.parent) cmdArgs.push("--parent", args.parent as string);
        if (args.blocks) cmdArgs.push("--blocks", args.blocks as string);
        if (args.dependsOn) cmdArgs.push("--depends-on", args.dependsOn as string);
        break;
      }

      case "td_tree": {
        if (args.childIssue) {
          cmdArgs = ["update", args.childIssue as string, "--parent", args.task as string];
        } else {
          cmdArgs = ["tree", args.task as string];
        }
        break;
      }

      case "td_dep": {
        const action = (args.action as string) || "list";
        if (action === "add") {
          cmdArgs = ["dep", "add", args.task as string, args.targetIssue as string];
        } else if (action === "blocking") {
          cmdArgs = ["dep", args.task as string, "--blocking"];
        } else {
          cmdArgs = ["dep", args.task as string];
        }
        break;
      }

      case "td_ws": {
        const action = args.action as string;
        if (action === "start") {
          cmdArgs = ["ws", "start", args.name as string];
        } else if (action === "tag") {
          cmdArgs = ["ws", "tag", ...((args.issueIds as string[]) || [])];
          if (args.noStart) cmdArgs.push("--no-start");
        } else if (action === "log") {
          cmdArgs = ["ws", "log", args.message as string];
        } else if (action === "current") {
          cmdArgs = ["ws", "current"];
        } else if (action === "handoff") {
          cmdArgs = ["ws", "handoff"];
          if (args.done) cmdArgs.push("--done", args.done as string);
          if (args.remaining) cmdArgs.push("--remaining", args.remaining as string);
          if (args.decision) cmdArgs.push("--decision", args.decision as string);
          if (args.uncertain) cmdArgs.push("--uncertain", args.uncertain as string);
        }
        break;
      }

      case "td_query":
        cmdArgs = ["query", args.query as string];
        break;

      case "td_search":
        cmdArgs = ["search", args.query as string];
        break;

      case "td_critical_path":
        cmdArgs = ["critical-path"];
        break;

      case "td_next":
        cmdArgs = ["next"];
        break;

      case "td_ready":
        cmdArgs = ["ready"];
        break;

      case "td_blocked":
        cmdArgs = ["blocked"];
        break;

      case "td_in_review":
        cmdArgs = ["in-review"];
        break;

      case "td_reviewable":
        cmdArgs = ["reviewable"];
        break;

      case "td_context":
        cmdArgs = ["context", args.task as string];
        break;

      case "td_comment":
        cmdArgs = ["comment", args.task as string, args.text as string];
        break;

      case "td_update": {
        cmdArgs = ["update", args.task as string];
        if (args.title) cmdArgs.push("--title", args.title as string);
        if (args.description) cmdArgs.push("--description", args.description as string);
        if (args.priority) cmdArgs.push("--priority", args.priority as string);
        if (args.type) cmdArgs.push("--type", args.type as string);
        if (args.labels) cmdArgs.push("--labels", args.labels as string);
        break;
      }

      case "td_files":
        cmdArgs = ["files", args.task as string];
        break;

      case "td_unlink": {
        const files = (args.files as string[]) || [];
        cmdArgs = ["unlink", args.task as string, ...files];
        break;
      }

      case "td_block":
        cmdArgs = ["block", args.task as string];
        break;

      case "td_unblock":
        cmdArgs = ["unblock", args.task as string];
        break;

      default:
        return {
          content: [
            {
              type: "text",
              text: `Unknown tool: ${name}`,
            },
          ],
          isError: true,
        };
    }

    result = runTD(cmdArgs);

    if (result.exitCode !== 0) {
      return {
        content: [
          {
            type: "text",
            text: result.stderr || result.stdout || "Command failed",
          },
        ],
        isError: true,
      };
    }

    return {
      content: [
        {
          type: "text",
          text: result.stdout || "Command completed successfully",
        },
      ],
    };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error executing TD command: ${error}`,
        },
      ],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("TD MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
