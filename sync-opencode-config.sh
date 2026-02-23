#!/usr/bin/env bash

# sync-opencode-config.sh
# Sync the .claude folder and .mcp.json to multiple repositories.
#
# Usage:
#   ./sync-opencode-config.sh [OPTIONS] <target-dir> [repo1 repo2 ...]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false
VERBOSE=false
BACKUP=true

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR_NAME=".claude"
SOURCE_CONFIG_DIR="$SOURCE_DIR/$CONFIG_DIR_NAME"
SOURCE_CONFIG_FILE="$SOURCE_DIR/.mcp.json"

EXCLUDE_PATTERNS=(
  "logs/"
  "data/"
  "node_modules/"
  "dist/"
  "build/"
  "*.log"
  ".DS_Store"
)

usage() {
  cat <<EOF
Usage: $0 [OPTIONS] <target-dir> [repo1 repo2 ...]

Sync the .claude folder and .mcp.json from this repository to other repositories.

Arguments:
  target-dir             Directory containing repositories to sync to
  repo1 repo2 ...        (Optional) Specific repository names to sync
                         If omitted, all git repositories in target-dir are used

Options:
  --dry-run              Show what would be synced without changes
  --verbose, -v          Verbose output
  --no-backup            Do not create timestamped backups of existing .claude
  --help, -h             Show this help

Examples:
  $0 ~/Development
  $0 ~/Development my-repo another-repo
  $0 --dry-run ~/Development
  $0 --verbose --no-backup ~/Development
EOF
  exit 0
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

is_git_repo() {
  local dir="$1"
  [[ -d "$dir/.git" ]]
}

build_exclude_args() {
  local args=()
  local pattern
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    args+=("--exclude=$pattern")
  done
  printf '%s\n' "${args[@]}"
}

sync_to_repo() {
  local repo_path="$1"
  local repo_name
  repo_name="$(basename "$repo_path")"

  if [[ "$(realpath "$repo_path")" == "$(realpath "$SOURCE_DIR")" ]]; then
    log_warn "Skipping source repository: $repo_name"
    return 0
  fi

  if ! is_git_repo "$repo_path"; then
    log_warn "$repo_name is not a git repository, skipping"
    return 0
  fi

  local dest_config_dir="$repo_path/$CONFIG_DIR_NAME"

  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY RUN] Would sync to: $repo_name"
    if [[ -d "$dest_config_dir" ]]; then
      echo "  -> Would update existing $CONFIG_DIR_NAME"
      if [[ "$BACKUP" == true ]]; then
        echo "  -> Would create backup before sync"
      fi
    else
      echo "  -> Would create new $CONFIG_DIR_NAME"
    fi
    echo "  -> Would sync .mcp.json"
    return 0
  fi

  log_info "Syncing to: $repo_name"

  if [[ -d "$dest_config_dir" && "$BACKUP" == true ]]; then
    local backup_dir="$dest_config_dir.backup.$(date +%Y%m%d_%H%M%S)"
    if [[ "$VERBOSE" == true ]]; then
      log_info "Creating backup: $(basename "$backup_dir")"
    fi
    mv "$dest_config_dir" "$backup_dir"
  fi

  mkdir -p "$dest_config_dir"

  mapfile -t EXCLUDE_ARGS < <(build_exclude_args)
  rsync -a "${EXCLUDE_ARGS[@]}" "$SOURCE_CONFIG_DIR/" "$dest_config_dir/"

  if [[ -f "$SOURCE_CONFIG_FILE" ]]; then
    cp "$SOURCE_CONFIG_FILE" "$repo_path/.mcp.json"
    if [[ "$VERBOSE" == true ]]; then
      log_info "Synced .mcp.json to: $repo_name"
    fi
  fi

  log_success "Synced to: $repo_name"
}

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
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
  --help | -h)
    usage
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [[ $# -lt 1 ]]; then
  log_error "Target directory is required"
  echo
  usage
fi

TARGET_DIR="$1"
shift
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

if [[ ! -d "$SOURCE_CONFIG_DIR" ]]; then
  log_error "Source $CONFIG_DIR_NAME folder not found: $SOURCE_CONFIG_DIR"
  exit 1
fi

if [[ ! -f "$SOURCE_CONFIG_FILE" ]]; then
  log_warn "Source .mcp.json not found: $SOURCE_CONFIG_FILE (will skip)"
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  log_error "Target directory does not exist: $TARGET_DIR"
  exit 1
fi

REPOS_TO_SYNC=()

if [[ $# -gt 0 ]]; then
  log_info "Syncing to specific repositories..."
  for repo_name in "$@"; do
    local_path="$TARGET_DIR/$repo_name"
    if [[ ! -d "$local_path" ]]; then
      log_warn "Repository not found: $repo_name"
      continue
    fi
    REPOS_TO_SYNC+=("$local_path")
  done
else
  log_info "Finding git repositories in $TARGET_DIR..."
  while IFS= read -r -d '' git_dir; do
    REPOS_TO_SYNC+=("$(dirname "$git_dir")")
  done < <(find "$TARGET_DIR" -maxdepth 2 -name ".git" -type d -print0 2>/dev/null)
fi

if [[ ${#REPOS_TO_SYNC[@]} -eq 0 ]]; then
  log_warn "No repositories found to sync"
  exit 0
fi

echo
log_info "Found ${#REPOS_TO_SYNC[@]} repository(ies)"
if [[ "$DRY_RUN" == true ]]; then
  log_info "DRY RUN mode enabled"
fi
if [[ "$BACKUP" == false ]]; then
  log_warn "Backups disabled (--no-backup)"
fi
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
