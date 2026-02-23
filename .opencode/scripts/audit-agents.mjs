#!/usr/bin/env node

import { promises as fs } from "node:fs"
import path from "node:path"

const VALID_TYPES = new Set(["primary", "subagent"])
const VALID_PERMISSION_ACTIONS = new Set(["ask", "allow", "deny"])
const SEVERITY = { critical: 0, high: 1, medium: 2, low: 3 }

function parseArgs(argv) {
  const args = { strict: false, format: "markdown", root: process.cwd() }
  for (let i = 2; i < argv.length; i++) {
    const token = argv[i]
    if (token === "--strict") {
      args.strict = true
    } else if (token === "--format") {
      args.format = argv[i + 1] || "markdown"
      i++
    } else if (token === "--root") {
      args.root = path.resolve(argv[i + 1] || process.cwd())
      i++
    }
  }

  if (!new Set(["markdown", "json"]).has(args.format)) {
    throw new Error(`Invalid --format value: ${args.format}`)
  }
  return args
}

async function walkMarkdownFiles(dir) {
  const out = []
  const entries = await fs.readdir(dir, { withFileTypes: true })
  for (const entry of entries) {
    const full = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      out.push(...(await walkMarkdownFiles(full)))
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      out.push(full)
    }
  }
  return out
}

function lineOf(text, offset) {
  return text.slice(0, offset).split("\n").length
}

function frontmatter(content) {
  const m = content.match(/^---\s*\n([\s\S]*?)\n---\s*(\n|$)/)
  if (!m) return null
  return { raw: m[1], offset: m.index || 0 }
}

function topLevelValue(fm, key) {
  const re = new RegExp(`^${key}:\\s*(.*)$`, "m")
  const m = fm.match(re)
  if (!m) return null
  return m[1].trim().replace(/^['"]|['"]$/g, "") || null
}

function findBlock(fm, key) {
  const lines = fm.split("\n")
  let start = -1
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith(`${key}:`)) {
      start = i
      break
    }
  }
  if (start === -1) return []

  const rows = []
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i]
    if (/^[A-Za-z0-9_-]+:\s*/.test(line)) break
    rows.push({ line, idx: i + 1 })
  }
  return rows
}

function addFinding(findings, finding) {
  findings.push(finding)
}

function validateAgent(filePath, relPath, content, findings) {
  const fmMatch = frontmatter(content)
  if (!fmMatch) {
    addFinding(findings, {
      severity: "critical",
      code: "missing_frontmatter",
      file: relPath,
      line: 1,
      message: "Missing or malformed YAML frontmatter.",
      suggestion: "Add required frontmatter with name/description/type/model.",
    })
    return
  }

  const fm = fmMatch.raw
  const startLine = lineOf(content, fmMatch.offset)
  const required = ["name", "description", "type", "model"]

  for (const field of required) {
    if (!topLevelValue(fm, field)) {
      addFinding(findings, {
        severity: "critical",
        code: "missing_required_field",
        file: relPath,
        line: startLine,
        message: `Missing required frontmatter field: ${field}`,
        suggestion: `Add '${field}:' to frontmatter.`,
      })
    }
  }

  const name = topLevelValue(fm, "name")
  const type = topLevelValue(fm, "type")
  const model = topLevelValue(fm, "model")
  const basename = path.basename(filePath, ".md")

  if (name && !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(name)) {
    addFinding(findings, {
      severity: "high",
      code: "invalid_name_format",
      file: relPath,
      line: startLine,
      message: `Agent name is not kebab-case: '${name}'`,
      suggestion: "Use lowercase kebab-case for name.",
    })
  }

  if (name && name !== basename) {
    addFinding(findings, {
      severity: "high",
      code: "name_filename_mismatch",
      file: relPath,
      line: startLine,
      message: `Frontmatter name '${name}' does not match filename '${basename}'.`,
      suggestion: "Rename file or align name field.",
    })
  }

  if (type && !VALID_TYPES.has(type)) {
    addFinding(findings, {
      severity: "high",
      code: "invalid_type",
      file: relPath,
      line: startLine,
      message: `Invalid agent type '${type}'.`,
      suggestion: "Use 'primary' or 'subagent'.",
    })
  }

  if (model && !/^[a-z0-9-]+\/[A-Za-z0-9._-]+$/.test(model)) {
    addFinding(findings, {
      severity: "high",
      code: "invalid_model_format",
      file: relPath,
      line: startLine,
      message: `Malformed model value '${model}'.`,
      suggestion: "Use provider/model format.",
    })
  }

  const permissionRows = findBlock(fm, "permission")
  for (const row of permissionRows) {
    if (/^\s{4}"\*":\s*allow\s*$/.test(row.line)) {
      addFinding(findings, {
        severity: "critical",
        code: "wildcard_allow_permission",
        file: relPath,
        line: startLine + row.idx - 1,
        message: "Wildcard allow permission detected ('*': allow).",
        suggestion: "Use ask/deny by default and explicit command patterns.",
      })
    }

    const action = row.line.match(/^\s{4}"[^"]+":\s*([A-Za-z]+)\s*$/)
    if (action && !VALID_PERMISSION_ACTIONS.has(action[1])) {
      addFinding(findings, {
        severity: "high",
        code: "invalid_permission_action",
        file: relPath,
        line: startLine + row.idx - 1,
        message: `Invalid permission action '${action[1]}'.`,
        suggestion: "Use only ask, allow, or deny.",
      })
    }
  }
}

function collectRefs(content) {
  const out = []
  const lines = content.split("\n")
  const re = /\.opencode\/agents\/[A-Za-z0-9_./-]+\.md/g
  for (let i = 0; i < lines.length; i++) {
    const matches = lines[i].match(re)
    if (!matches) continue
    for (const ref of matches) out.push({ ref, line: i + 1 })
  }
  return out
}

async function auditDocs(root, findings) {
  const docs = [
    "AGENTS.md",
    path.join(".opencode", "AGENTS_INDEX.md"),
    path.join(".opencode", "plugins", "README.md"),
  ]
  for (const rel of docs) {
    const full = path.join(root, rel)
    let content
    try {
      content = await fs.readFile(full, "utf8")
    } catch {
      continue
    }

    for (const { ref, line } of collectRefs(content)) {
      try {
        await fs.access(path.join(root, ref))
      } catch {
        addFinding(findings, {
          severity: "critical",
          code: "dead_agent_reference",
          file: rel,
          line,
          message: `Reference points to missing agent file: ${ref}`,
          suggestion: "Update docs to an existing path under .opencode/agents/.",
        })
      }
    }
  }
}

async function auditIndexInventory(root, agentFiles, findings) {
  const indexRel = path.join(".opencode", "AGENTS_INDEX.md")
  const indexPath = path.join(root, indexRel)
  const fsAgents = new Set(
    agentFiles.map((file) => path.relative(root, file).replace(/\\/g, "/")),
  )

  let content
  try {
    content = await fs.readFile(indexPath, "utf8")
  } catch (err) {
    if (err && err.code === "ENOENT") {
      const fallbackRel = "AGENTS.md"
      const fallbackPath = path.join(root, fallbackRel)

      let fallbackContent
      try {
        fallbackContent = await fs.readFile(fallbackPath, "utf8")
      } catch (fallbackErr) {
        if (fallbackErr && fallbackErr.code === "ENOENT") {
          addFinding(findings, {
            severity: "medium",
            code: "missing_agent_inventory_source",
            file: indexRel,
            line: 1,
            message:
              "AGENTS_INDEX.md is missing and no fallback inventory source (AGENTS.md) was found.",
            suggestion:
              "Restore .opencode/AGENTS_INDEX.md or add AGENTS.md with agent inventory links.",
          })
          return
        }
        throw fallbackErr
      }

      const fallbackAgents = new Set()
      for (const { ref } of collectRefs(fallbackContent)) {
        if (ref.startsWith(".opencode/agents/") && ref.endsWith(".md")) {
          fallbackAgents.add(ref)
        }
      }

      if (fallbackAgents.size === 0) {
        addFinding(findings, {
          severity: "medium",
          code: "empty_fallback_agent_inventory",
          file: fallbackRel,
          line: 1,
          message:
            "AGENTS_INDEX.md is missing and AGENTS.md does not contain agent inventory links.",
          suggestion:
            "Add .opencode/agents/*.md links to AGENTS.md or restore AGENTS_INDEX.md.",
        })
        return
      }

      const undocumented = []
      for (const rel of fsAgents) {
        if (!fallbackAgents.has(rel)) undocumented.push(rel)
      }

      if (undocumented.length > 0) {
        addFinding(findings, {
          severity: "medium",
          code: "agent_inventory_drift_fallback",
          file: fallbackRel,
          line: 1,
          message: `Fallback inventory is missing ${undocumented.length} agent entr${undocumented.length === 1 ? "y" : "ies"} present on disk.`,
          suggestion: `Add missing inventory links (e.g. ${undocumented.slice(0, 3).join(", ")}).`,
        })
      }

      return
    }

    throw err
  }

  const declaredMatch = content.match(/\*\*Total Components:\*\*\s*(\d+)\s+agents\b/i)
  if (declaredMatch) {
    const declared = Number(declaredMatch[1])
    if (Number.isFinite(declared) && declared !== agentFiles.length) {
      addFinding(findings, {
        severity: "critical",
        code: "agent_count_drift",
        file: indexRel,
        line: lineOf(content, declaredMatch.index || 0),
        message: `AGENTS_INDEX.md declares ${declared} agents, but filesystem contains ${agentFiles.length}.`,
        suggestion: "Update AGENTS_INDEX.md metadata/counts to match current agent inventory.",
      })
    }
  }

  const indexedAgents = new Set()
  for (const { ref } of collectRefs(content)) {
    if (ref.startsWith(".opencode/agents/") && ref.endsWith(".md")) {
      indexedAgents.add(ref)
    }
  }

  if (indexedAgents.size === 0) return

  const undocumented = []
  for (const rel of fsAgents) {
    if (!indexedAgents.has(rel)) undocumented.push(rel)
  }

  if (undocumented.length > 0) {
    addFinding(findings, {
      severity: "high",
      code: "agent_inventory_drift",
      file: indexRel,
      line: 1,
      message: `AGENTS_INDEX.md is missing ${undocumented.length} agent entr${undocumented.length === 1 ? "y" : "ies"} present on disk.`,
      suggestion: `Add missing inventory links (e.g. ${undocumented.slice(0, 3).join(", ")}).`,
    })
  }
}

function summarize(findings) {
  const summary = { critical: 0, high: 0, medium: 0, low: 0 }
  for (const f of findings) summary[f.severity]++
  return summary
}

function renderMarkdown(report) {
  const { summary, findings, agentCount, docCount } = report
  const lines = [
    "# Agent Audit Report",
    "",
    `- Agents scanned: ${agentCount}`,
    `- Markdown files checked: ${docCount}`,
    `- Findings: ${findings.length}`,
    "",
    "## Severity Summary",
    "",
    `- critical: ${summary.critical}`,
    `- high: ${summary.high}`,
    `- medium: ${summary.medium}`,
    `- low: ${summary.low}`,
    "",
  ]

  if (findings.length === 0) {
    lines.push("No findings. Audit passed.")
    return lines.join("\n")
  }

  lines.push("## Findings", "")
  for (const f of findings) {
    lines.push(`- [${f.severity}] ${f.file}:${f.line} (${f.code}) ${f.message}`)
    if (f.suggestion) lines.push(`  - Fix: ${f.suggestion}`)
  }
  return lines.join("\n")
}

async function main() {
  const args = parseArgs(process.argv)
  const root = path.resolve(args.root)
  const agentDir = path.join(root, ".opencode", "agents")

  const findings = []
  const agentFiles = await walkMarkdownFiles(agentDir)

  for (const file of agentFiles) {
    const content = await fs.readFile(file, "utf8")
    const rel = path.relative(root, file).replace(/\\/g, "/")
    validateAgent(file, rel, content, findings)
  }

  await auditDocs(root, findings)
  await auditIndexInventory(root, agentFiles, findings)

  findings.sort((a, b) => {
    const s = SEVERITY[a.severity] - SEVERITY[b.severity]
    if (s !== 0) return s
    if (a.file !== b.file) return a.file.localeCompare(b.file)
    return a.line - b.line
  })

  const report = {
    generatedAt: new Date().toISOString(),
    root,
    agentCount: agentFiles.length,
    docCount: 3,
    summary: summarize(findings),
    findings,
  }

  if (args.format === "json") {
    process.stdout.write(`${JSON.stringify(report, null, 2)}\n`)
  } else {
    process.stdout.write(`${renderMarkdown(report)}\n`)
  }

  if (args.strict && (report.summary.critical > 0 || report.summary.high > 0)) {
    process.exitCode = 1
  }
}

main().catch((err) => {
  process.stderr.write(`audit-agents failed: ${String(err)}\n`)
  process.exit(2)
})
