#!/bin/sh -l
set -eu

# Failure handling utility function
die() { echo "$*" 1>&2 ; exit 1; }

MCIX_BIN_DIR="/usr/share/mcix/bin"
MCIX_CMD="$MCIX_BIN_DIR/mcix"
PATH="$PATH:$MCIX_BIN_DIR"

# Validate required vars
: "${PARAM_API_KEY:?Missing required input: api-key}"
: "${PARAM_URL:?Missing required input: url}"
: "${PARAM_USER:?Missing required input: user}"
: "${PARAM_ASSETS:?Missing required input: assets}"

# Optional arguments
PROJECT="${PARAM_PROJECT:-}"
PROJECT_ID="${PARAM_PROJECT_ID:-}"

# 1) Fail if BOTH project and project-id were provided
if [ -n "$PROJECT" ] && [ -n "$PROJECT_ID" ]; then
  die "ERROR: Both 'project' and 'project-id' were provided. Please specify only one."
fi

# 2) Fail if NEITHER project or project-id were provided
if [ -z "$PROJECT" ] && [ -z "$PROJECT_ID" ]; then
  die "ERROR: You must provide either 'project' or 'project-id'." 
fi

# Build command to execute
CMD="$MCIX_CMD datastage import \
    -api-key \"$PARAM_API_KEY\" \
    -url \"$PARAM_URL\" \
    -user \"$PARAM_USER\" \
    -assets \"$PARAM_ASSETS\""

# Add optional project/project-id
[ -n "$PROJECT" ] && CMD="$CMD -project \"$PROJECT\""
[ -n "$PROJECT_ID" ] && CMD="$CMD -project-id \"$PROJECT_ID\""

echo "Executing: $CMD"

# Execute the command
# shellcheck disable=SC2086
sh -c "$CMD"
status=$?

echo "return-code=$status" >> "$GITHUB_OUTPUT"
exit "$status"
