#!/bin/sh -l
set -eu

# Failure handling utility function
die() { echo "$*" 1>&2 ; exit 1; }

MCIX_BIN_DIR="/usr/share/mcix/bin"
MCIX_CMD="$MCIX_BIN_DIR/mcix"
PATH="$PATH:$MCIX_BIN_DIR"

# Validate required inputs (from action.yml via env)
: "${PARAM_ASSETS:?Missing required input: assets}"
: "${PARAM_OUTPUT:?Missing required input: output}"
: "${PARAM_OVERLAY:?Missing required input: overlay}"

ASSETS="$PARAM_ASSETS"
OUTPUT="$PARAM_OUTPUT"
OVERLAY_LIST="$PARAM_OVERLAY"
PROPERTIES="${PARAM_PROPERTIES:-}"

# Build argv safely (no brittle quoted CMD string)
set -- "$MCIX_CMD" overlay apply \
  -assets "$ASSETS" \
  -output "$OUTPUT"

# Add each overlay (space or newline separated)
# shellcheck disable=SC2086
for dir in $OVERLAY_LIST; do
  set -- "$@" -overlay "$dir"
done

# Optional properties file
if [ -n "$PROPERTIES" ]; then
  set -- "$@" -properties "$PROPERTIES"
fi

echo "Executing: $*"

# Execute command
"$@"
status=$?

# Expose the return code as an action output
echo "return-code=$status" >> "$GITHUB_OUTPUT"
exit "$status"
