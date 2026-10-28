#!/usr/bin/env bash

# sync-claude-config.sh
# Sync the generic Claude Code agent team (core/) plus one or more domain packs (packs/<name>/)
# into one or more repositories.
#
# The install is rendered into a staging directory first:
#   core/{agents,rules,hooks,scripts}       -> .claude/
#   packs/<pack>/{agents,skills,rules,hooks,scripts,config} -> .claude/ (after core)
#   core/settings.json + packs/<pack>/settings.json -> .claude/settings.json (objects merged,
#     arrays concatenated without duplicates, the later pack wins on scalars)
#   packs/<pack>/agent-tools.conf           -> tools appended to the agents' tools: lists
#   packs/<pack>/.mcp.json                  -> .mcp.json servers (@TARGET_REPO@ = repository path)
#
# Never touched in a target: CLAUDE.md, .claude/local/, .claude/settings.local.json,
# .claude/agent-memory*/, and any file the template did not install (tracked in
# .claude/.template-manifest), so repository-specific skills and agents survive a sync.
#
# Usage:
#   ./sync-claude-config.sh [OPTIONS] <target-dir> [repo1 repo2 ...]
#   ./sync-claude-config.sh [--pack NAME] --render <dir>
#   ./sync-claude-config.sh            (in a terminal: asks for packs, target directory and repositories)

# Bash only; re-run under bash when started as "sh sync-claude-config.sh".
if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
VERBOSE=false
BACKUP=true
RENDER_DIR=""
PACKS=()
PROMPT=true
PROMPTED=false

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$SOURCE_DIR/core"
MANAGED_DIRS=(agents skills hooks rules scripts config)
MANAGED_FILES=(settings.json)
MANIFEST_NAME=".template-manifest"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS] <target-dir> [repo1 repo2 ...]
       $0 [--pack NAME] --render <dir>

Sync the Claude Code team (core/ plus domain packs from packs/) into other repositories.

Arguments:
  target-dir             Directory containing repositories to sync to
  repo1 repo2 ...        (Optional) Specific repository names to sync
                         If omitted, every git repository or Enfusion addon
                         (folder with a *.gproj) in target-dir is used

In a terminal, whatever the command line leaves out is asked for: the packs (no --pack),
the target directory, and which of the found repositories to sync (no repository names).
The equivalent command line is printed before anything changes.

Options:
  --pack NAME            Domain pack to layer on core (repeatable; default: linear)
                         Available: $(cd "$SOURCE_DIR/packs" && ls -d -- */ 2>/dev/null | tr -d / | tr '\n' ' ')
  --render DIR           Write the rendered .claude/ and .mcp.json into DIR and exit
  --dry-run              Show what would change without changing anything
  --verbose, -v          Verbose output
  --no-backup            Do not back up the managed files before syncing
  --yes, -y              Never prompt; use the defaults above (also when not in a terminal)
  --help, -h             Show this help

@TARGET_REPO@ in a pack's .mcp.json is replaced with each target repository's path.

Examples:
  $0 ~/Code/MyOrg app-one app-two
  $0 --pack arma --pack linear "/mnt/e/ArmaRefoger Projects" my-mod
  $0 --dry-run ~/Code/MyOrg
  $0 --render /tmp/team-render
  $0                     # interactive
EOF
  exit 0
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_verbose() { if [[ "$VERBOSE" == true ]]; then echo "  $1"; fi; }

# Prompts are on when nothing turned them off and both stdin and stderr are a terminal.
interactive() { [[ "$PROMPT" == true && -t 0 && -t 2 ]]; }

# Prints the 1-based indices selected by $2 from $1 items, one per line, in the order given.
# Accepts numbers and ranges separated by spaces or commas ("1 3", "2-4") and "all"; fails on
# anything else or on an empty selection.
parse_selection() {
  local count=$1 tok lo hi i seen=" " toks
  read -ra toks <<<"${2//,/ }"
  for tok in "${toks[@]+"${toks[@]}"}"; do
    if [[ "$tok" == all || "$tok" == a ]]; then
      lo=1 hi=$count
    elif [[ "$tok" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      lo=$((10#${BASH_REMATCH[1]})) hi=$((10#${BASH_REMATCH[2]}))
    elif [[ "$tok" =~ ^[0-9]+$ ]]; then
      lo=$((10#$tok)) hi=$lo
    else
      return 1
    fi
    ((lo >= 1 && lo <= hi && hi <= count)) || return 1
    for ((i = lo; i <= hi; i++)); do
      [[ "$seen" == *" $i "* ]] && continue
      seen+="$i "
      echo "$i"
    done
  done
  [[ "$seen" != " " ]]
}

# Asks for a multiple choice on stderr until the answer is valid; Enter takes $2.
# Usage: choose <question> <default answer> <label>... ; sets CHOICES to the 0-based indices.
CHOICES=()
choose() {
  local question=$1 default=$2 answer i indices
  shift 2
  for ((i = 1; i <= $#; i++)); do
    printf '  %2d) %s\n' "$i" "${!i}" >&2
  done
  while true; do
    read -r -p "$question [$default]: " answer || {
      echo >&2
      log_error "Aborted"
      exit 1
    }
    [[ -z "$answer" ]] && answer=$default
    CHOICES=()
    if indices=$(parse_selection $# "$answer"); then
      for i in $indices; do CHOICES+=($((i - 1))); done
      return 0
    fi
    echo "  Enter numbers or ranges between 1 and $# (for example: 1 3, 2-4, all)." >&2
  done
}

# The first heading of a pack's rules file, as a one-line description.
pack_description() {
  local f
  for f in "$SOURCE_DIR/packs/$1"/rules/*.md; do
    [[ -f "$f" ]] && sed -n '1s/^# *//p' "$f"
    return 0
  done
}

prompt_packs() {
  local names=() labels=() defaults=() d name i
  for d in "$SOURCE_DIR"/packs/*/; do
    name=$(basename "$d")
    names+=("$name")
    labels+=("$(printf '%-8s %s' "$name" "$(pack_description "$name")")")
    [[ "$name" == linear ]] && defaults+=("${#names[@]}")
  done
  echo >&2
  echo "Packs to layer on core (later packs win on conflicting settings):" >&2
  choose "Packs" "${defaults[*]:-1}" "${labels[@]}"
  for i in "${CHOICES[@]}"; do PACKS+=("${names[$i]}"); done
  PROMPTED=true
}

# Deep merge for settings and .mcp.json: objects merge recursively, arrays concatenate
# without duplicates, scalars from the right-hand side win.
JQ_MERGE='def dm($a; $b):
  if ($a|type) == "object" and ($b|type) == "object" then
    reduce ($b|to_entries[]) as $e ($a; .[$e.key] = dm(.[$e.key]; $e.value))
  elif ($a|type) == "array" and ($b|type) == "array" then
    $a + [$b[] | select(. as $x | any($a[]; . == $x) | not)]
  elif $b == null then $a
  else $b end;'

# Append the lines of $2 (a file) to the tools: list in the frontmatter of agent file $1.
append_agent_tools() {
  local agent_file="$1" tools_file="$2"
  awk -v tools_file="$tools_file" '
    function flush() { while ((getline t < tools_file) > 0) print "  - " t; close(tools_file); done = 1 }
    NR == 1 && /^---/ { fm = 1; print; next }
    fm && /^---/ { if (intools && !done) flush(); fm = 0; intools = 0; print; next }
    fm && /^tools:/ { intools = 1; print; next }
    fm && intools && !/^  - / { if (!done) flush(); intools = 0 }
    { print }
  ' "$agent_file" >"$agent_file.tmp" && mv "$agent_file.tmp" "$agent_file"
}

# Render core + packs into $1 (gets $1/.claude/ and $1/mcp.json).
render_stage() {
  local stage="$1" claude="$1/.claude" pack pack_dir d rel
  mkdir -p "$claude"

  for d in "${MANAGED_DIRS[@]}"; do
    [[ -d "$CORE_DIR/$d" ]] && mkdir -p "$claude/$d" && cp -a "$CORE_DIR/$d/." "$claude/$d/"
  done
  cp "$CORE_DIR/settings.json" "$claude/settings.json"
  echo '{"mcpServers": {}}' >"$stage/mcp.json"

  for pack in "${PACKS[@]}"; do
    pack_dir="$SOURCE_DIR/packs/$pack"
    for d in "${MANAGED_DIRS[@]}"; do
      [[ -d "$pack_dir/$d" ]] || continue
      while IFS= read -r rel; do
        [[ -e "$claude/$d/$rel" ]] && log_warn "pack $pack overrides $d/$rel"
      done < <(cd "$pack_dir/$d" && find . -type f | sed 's#^\./##')
      mkdir -p "$claude/$d" && cp -a "$pack_dir/$d/." "$claude/$d/"
    done
    if [[ -f "$pack_dir/settings.json" ]]; then
      jq -s "$JQ_MERGE dm(.[0]; .[1])" "$claude/settings.json" "$pack_dir/settings.json" >"$claude/settings.json.tmp"
      mv "$claude/settings.json.tmp" "$claude/settings.json"
    fi
    if [[ -f "$pack_dir/.mcp.json" ]]; then
      jq -s "$JQ_MERGE dm(.[0]; .[1])" "$stage/mcp.json" "$pack_dir/.mcp.json" >"$stage/mcp.json.tmp"
      mv "$stage/mcp.json.tmp" "$stage/mcp.json"
    fi
    if [[ -f "$pack_dir/agent-tools.conf" ]]; then
      local agent entry tools_file="$stage/tools.tmp"
      while read -r agent entry; do
        if [[ ! -f "$claude/agents/$agent.md" ]]; then
          log_warn "pack $pack adds tools to unknown agent $agent"
          continue
        fi
        if [[ "$entry" == @* ]]; then
          grep -vE '^[[:space:]]*(#|$)' "$pack_dir/${entry#@}" >"$tools_file"
        else
          echo "$entry" >"$tools_file"
        fi
        append_agent_tools "$claude/agents/$agent.md" "$tools_file"
      done < <(grep -vE '^[[:space:]]*(#|$)' "$pack_dir/agent-tools.conf")
      rm -f "$tools_file"
    fi
  done
  chmod +x "$claude"/hooks/*.sh "$claude"/scripts/*.sh 2>/dev/null || true
}

# A git repository or an Enfusion addon (a folder containing a *.gproj).
is_sync_target() {
  local dir="$1"
  [[ -d "$dir/.git" ]] || compgen -G "$dir/*.gproj" >/dev/null
}

# Paths relative to .claude/ of every file the template installs.
template_manifest() {
  (
    cd "$STAGE/.claude"
    for d in "${MANAGED_DIRS[@]}"; do
      [[ -d "$d" ]] && find "$d" -type f ! -name '.DS_Store'
    done
    for f in "${MANAGED_FILES[@]}"; do
      [[ -f "$f" ]] && echo "$f"
    done
  ) | sort
}

# The staged mcp.json pointed at repository $1, merged over its existing .mcp.json.
render_mcp_json() {
  local repo_path="$1" existing='{}'
  [[ -f "$repo_path/.mcp.json" ]] && existing="$(cat "$repo_path/.mcp.json")"
  jq --arg p "$repo_path" 'walk(if type == "string" then gsub("@TARGET_REPO@"; $p) else . end)' "$STAGE/mcp.json" |
    jq -s "$JQ_MERGE dm(.[0]; .[1])" <(echo "$existing") -
}

sync_to_repo() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$repo_path")"

  if [[ "$(realpath "$repo_path")" == "$(realpath "$SOURCE_DIR")" ]]; then
    log_warn "Skipping source repository: $repo_name"
    return 0
  fi

  if ! is_sync_target "$repo_path"; then
    log_warn "$repo_name is neither a git repository nor an addon (*.gproj), skipping"
    return 0
  fi

  local dest="$repo_path/.claude"
  local old_manifest="$dest/$MANIFEST_NAME"
  local new_manifest
  new_manifest="$(template_manifest)"

  # Files the template installed last time but no longer ships.
  local stale=()
  if [[ -f "$old_manifest" ]]; then
    mapfile -t stale < <(comm -23 <(sort "$old_manifest") <(echo "$new_manifest"))
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY RUN] $repo_name"
    while IFS= read -r rel; do
      if [[ ! -f "$dest/$rel" ]]; then
        echo "  + $rel"
      elif ! cmp -s "$STAGE/.claude/$rel" "$dest/$rel"; then
        echo "  ~ $rel"
      else
        log_verbose "= $rel"
      fi
    done <<<"$new_manifest"
    for rel in "${stale[@]}"; do [[ -n "$rel" ]] && echo "  - $rel"; done
    if [[ "$(jq -S -c . "$STAGE/mcp.json")" != '{"mcpServers":{}}' ]]; then
      if ! cmp -s <(render_mcp_json "$repo_path") "$repo_path/.mcp.json" 2>/dev/null; then
        echo "  ~ .mcp.json"
      fi
    fi
    return 0
  fi

  log_info "Syncing to: $repo_name"

  if [[ "$BACKUP" == true && -d "$dest" ]]; then
    local backup_dir
    backup_dir="$repo_path/.claude.backup.$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    while IFS= read -r rel; do
      if [[ -f "$dest/$rel" ]]; then
        mkdir -p "$backup_dir/$(dirname "$rel")"
        cp -a "$dest/$rel" "$backup_dir/$rel"
      fi
    done < <({ echo "$new_manifest"; printf '%s\n' "${stale[@]}"; } | sort -u)
    [[ -f "$repo_path/.mcp.json" ]] && cp -a "$repo_path/.mcp.json" "$backup_dir/mcp.json"
    log_verbose "Backup: $(basename "$backup_dir")"
  fi

  mkdir -p "$dest"
  for rel in "${stale[@]}"; do
    [[ -n "$rel" && -f "$dest/$rel" ]] || continue
    rm -f "$dest/$rel"
    log_verbose "removed $rel"
  done
  # Remove directories the stale files leave empty, inside the managed directories only (and the directory itself when it ends up empty).
  for d in "${MANAGED_DIRS[@]}"; do
    [[ -d "$dest/$d" ]] && find "$dest/$d" -type d -empty -delete 2>/dev/null || true
  done

  while IFS= read -r rel; do
    mkdir -p "$dest/$(dirname "$rel")"
    if [[ "$rel" == "settings.json" && -f "$dest/$rel" ]]; then
      # Keep top-level keys the repository added (enabledPlugins, ...); the template's keys win.
      # Drop keys the template used to install and no longer ships (they would shadow the user's).
      jq -s '.[0] + .[1]
        | if ((.statusLine.command // "") | test("\\.claude/scripts/statusline\\.sh")) then del(.statusLine) else . end' \
        "$dest/$rel" "$STAGE/.claude/$rel" >"$dest/$rel.tmp" && mv "$dest/$rel.tmp" "$dest/$rel"
      log_verbose "merged $rel"
    else
      cp -a "$STAGE/.claude/$rel" "$dest/$rel"
    fi
  done <<<"$new_manifest"
  echo "$new_manifest" >"$old_manifest"

  # .mcp.json: the packs' servers, pointed at this repository; servers the repository added stay.
  if [[ "$(jq -S -c . "$STAGE/mcp.json")" != '{"mcpServers":{}}' ]]; then
    render_mcp_json "$repo_path" >"$repo_path/.mcp.json.tmp" && mv "$repo_path/.mcp.json.tmp" "$repo_path/.mcp.json"
  fi

  local pack msg
  for pack in "${PACKS[@]}"; do
    if [[ -x "$SOURCE_DIR/packs/$pack/sync-check.sh" ]]; then
      while IFS= read -r msg; do
        [[ -n "$msg" ]] && log_warn "$msg"
      done < <("$SOURCE_DIR/packs/$pack/sync-check.sh" "$repo_path")
    fi
  done

  log_success "Synced to: $repo_name"
}

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  --pack)
    PACKS+=("${2:?--pack needs a name}")
    shift 2
    ;;
  --render)
    RENDER_DIR="${2:?--render needs a directory}"
    shift 2
    ;;
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  --verbose | -v)
    VERBOSE=true
    shift
    ;;
  --no-backup)
    BACKUP=false
    shift
    ;;
  --yes | -y)
    PROMPT=false
    shift
    ;;
  --help | -h)
    usage
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]+"${POSITIONAL_ARGS[@]}"}"

command -v jq >/dev/null || {
  log_error "jq is required"
  exit 1
}

if [[ ! -d "$CORE_DIR" ]]; then
  log_error "Core folder not found: $CORE_DIR"
  exit 1
fi

if [[ ${#PACKS[@]} -eq 0 ]] && interactive; then
  prompt_packs
fi
[[ ${#PACKS[@]} -eq 0 ]] && PACKS=(linear)
for pack in "${PACKS[@]}"; do
  if [[ ! -d "$SOURCE_DIR/packs/$pack" ]]; then
    log_error "Pack not found: packs/$pack"
    exit 1
  fi
done

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
render_stage "$STAGE"

if [[ -n "$RENDER_DIR" ]]; then
  mkdir -p "$RENDER_DIR"
  cp -a "$STAGE/.claude" "$RENDER_DIR/"
  cp "$STAGE/mcp.json" "$RENDER_DIR/.mcp.json"
  log_success "Rendered core + ${PACKS[*]} into $RENDER_DIR"
  exit 0
fi

if [[ $# -lt 1 ]] && interactive; then
  echo >&2
  while true; do
    read -e -r -p "Target directory (repositories inside it, or a repository itself) [$PWD]: " answer || {
      echo >&2
      log_error "Aborted"
      exit 1
    }
    answer=${answer:-$PWD}
    answer="${answer/#\~/$HOME}"
    [[ -d "$answer" ]] && break
    echo "  Not a directory: $answer" >&2
  done
  set -- "$answer"
  PROMPTED=true
fi

if [[ $# -lt 1 ]]; then
  log_error "Target directory is required"
  echo
  usage
fi

TARGET_DIR="$1"
shift
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
TARGET_DIR="${TARGET_DIR%/}"
REPOS_GIVEN=$#

if [[ ! -d "$TARGET_DIR" ]]; then
  log_error "Target directory does not exist: $TARGET_DIR"
  exit 1
fi

REPOS_TO_SYNC=()

if [[ $# -gt 0 ]]; then
  for repo_name in "$@"; do
    local_path="$TARGET_DIR/$repo_name"
    if [[ ! -d "$local_path" ]]; then
      log_warn "Repository not found: $repo_name"
      continue
    fi
    REPOS_TO_SYNC+=("$local_path")
  done
else
  log_info "Finding git repositories and addons in $TARGET_DIR..."
  while IFS= read -r -d '' repo_dir; do
    REPOS_TO_SYNC+=("$repo_dir")
  done < <(
    find "$TARGET_DIR" -maxdepth 2 \( -name ".git" -type d -o -name "*.gproj" -type f \) -print0 2>/dev/null |
      xargs -0 -r -n1 dirname | sort -u | tr '\n' '\0'
  )
fi

if [[ ${#REPOS_TO_SYNC[@]} -eq 0 ]]; then
  log_warn "No repositories found to sync"
  exit 0
fi

# Repository names as given on the command line: relative to the target directory.
repo_label() {
  if [[ "$1" == "$TARGET_DIR" ]]; then echo .; else echo "${1#"$TARGET_DIR"/}"; fi
}

ALL_REPOS_SELECTED=true
if [[ $REPOS_GIVEN -eq 0 ]] && interactive; then
  labels=()
  for repo_path in "${REPOS_TO_SYNC[@]}"; do labels+=("$(repo_label "$repo_path")"); done
  echo >&2
  echo "Repositories found in $TARGET_DIR:" >&2
  choose "Sync to" "all" "${labels[@]}"
  selected=()
  for i in "${CHOICES[@]}"; do selected+=("${REPOS_TO_SYNC[$i]}"); done
  [[ ${#selected[@]} -lt ${#REPOS_TO_SYNC[@]} ]] && ALL_REPOS_SELECTED=false
  REPOS_TO_SYNC=("${selected[@]}")
  PROMPTED=true
fi

if [[ "$PROMPTED" == true ]]; then
  cmd=("$0")
  for pack in "${PACKS[@]}"; do cmd+=(--pack "$pack"); done
  [[ "$DRY_RUN" == true ]] && cmd+=(--dry-run)
  [[ "$VERBOSE" == true ]] && cmd+=(--verbose)
  [[ "$BACKUP" == false ]] && cmd+=(--no-backup)
  cmd+=("$TARGET_DIR")
  if [[ "$ALL_REPOS_SELECTED" == false || $REPOS_GIVEN -gt 0 ]]; then
    for repo_path in "${REPOS_TO_SYNC[@]}"; do cmd+=("$(repo_label "$repo_path")"); done
  fi
  echo >&2
  echo "Equivalent command:" >&2
  printf '  %s\n' "$(printf '%q ' "${cmd[@]}")" >&2
  read -r -p "Proceed? [Y/n]: " answer || exit 1
  if [[ "$answer" =~ ^[Nn] ]]; then
    log_info "Nothing changed"
    exit 0
  fi
fi

echo
log_info "Found ${#REPOS_TO_SYNC[@]} repository(ies); packs: ${PACKS[*]}"
[[ "$DRY_RUN" == true ]] && log_info "DRY RUN mode enabled"
[[ "$BACKUP" == false ]] && log_warn "Backups disabled (--no-backup)"
echo

SUCCESS_COUNT=0
ERROR_COUNT=0

for repo_path in "${REPOS_TO_SYNC[@]}"; do
  if sync_to_repo "$repo_path"; then
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done

echo
echo "======================================"
log_info "Sync Summary"
echo "  Total repositories: ${#REPOS_TO_SYNC[@]}"
if [[ "$DRY_RUN" == true ]]; then
  echo "  Would sync: $SUCCESS_COUNT"
else
  echo "  Successfully synced: $SUCCESS_COUNT"
fi
if [[ $ERROR_COUNT -gt 0 ]]; then
  echo "  Errors: $ERROR_COUNT"
fi
echo "======================================"
