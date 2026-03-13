#!/bin/bash
set -euo pipefail

# Generate Version.swift with the provided version
# Usage: ./scripts/generate-version.sh <version>
# Example: ./scripts/generate-version.sh 1.2.3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_FILE="$REPO_ROOT/Sources/kaiten-mcp/Version.swift"

if [[ $# -ge 1 && -n "$1" ]]; then
    VERSION="$1"
else
    VERSION="dev"
fi

cat > "$OUTPUT_FILE" << EOF
// Generated file. Do not edit manually.
// Run scripts/generate-version.sh to regenerate.

let kaitenMCPVersion = "$VERSION"
EOF

echo "Generated $OUTPUT_FILE with version: $VERSION"
