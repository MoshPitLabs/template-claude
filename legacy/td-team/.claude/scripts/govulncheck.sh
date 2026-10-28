#!/bin/bash
# Sets the Go toolchain env (GOROOT/PATH/GOPROXY/GOSUMDB) that `govulncheck`
# needs, per security-engineer.md's Dependency-CVE guidance, so the recipe
# isn't hand-typed each session. May need Bash(dangerouslyDisableSandbox: true)
# if the Go build/vuln toolchain is not sandbox-compatible on your host.
set -euo pipefail

usage() {
    echo "Usage: govulncheck.sh [govulncheck-args...]" >&2
    echo "  Resolves GOROOT via native 'go env GOROOT', puts it on PATH," >&2
    echo "  sets GOPROXY=direct GOSUMDB=off (repo fetch posture), then runs" >&2
    echo "  'govulncheck' with the given args (default: ./...)." >&2
    exit 1
}

case "${1:-}" in
    -h|--help) usage ;;
esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "govulncheck.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

command -v go >/dev/null 2>&1 || {
    echo "govulncheck.sh: 'go' not found on PATH — install a Go toolchain first." >&2
    exit 1
}

command -v govulncheck >/dev/null 2>&1 || {
    echo "govulncheck.sh: 'govulncheck' not found on PATH — install via" >&2
    echo "  'go install golang.org/x/vuln/cmd/govulncheck@latest'" >&2
    exit 1
}

GOROOT=$(go env GOROOT) || {
    echo "govulncheck.sh: failed to resolve GOROOT via 'go env GOROOT'" >&2
    exit 1
}
export GOROOT
export PATH="${GOROOT}/bin:${PATH}"
export GOPROXY=direct
export GOSUMDB=off

if [ "$#" -eq 0 ]; then
    set -- ./...
fi

govulncheck "$@"
