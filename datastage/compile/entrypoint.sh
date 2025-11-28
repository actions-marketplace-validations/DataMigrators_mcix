#!/bin/sh -l

# ███╗   ███╗███████╗████████╗████████╗██╗     ███████╗ ██████╗██╗
# ████╗ ████║██╔════╝╚══██╔══╝╚══██╔══╝██║     ██╔════╝██╔════╝██║
# ██╔████╔██║█████╗     ██║      ██║   ██║     █████╗  ██║     ██║
# ██║╚██╔╝██║██╔══╝     ██║      ██║   ██║     ██╔══╝  ██║     ██║
# ██║ ╚═╝ ██║███████╗   ██║      ██║   ███████╗███████╗╚██████╗██║
# ╚═╝     ╚═╝╚══════╝   ╚═╝      ╚═╝   ╚══════╝╚══════╝ ╚═════╝╚═╝
# MettleCI DevOps for DataStage       (C) 2025-2026 Data Migrators

set -eu

# -----
# Setup
# -----
MCIX_BIN_DIR="/usr/share/mcix/bin"
MCIX_CMD="$MCIX_BIN_DIR/mcix"
PATH="$PATH:$MCIX_BIN_DIR"

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT must be set}"

# -----------------
# Utility functions
# -----------------

# Failure handling utility functions
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

write_return_code() {
  rc=$?
  echo "return-code=$rc" >>"$GITHUB_OUTPUT"
}
trap write_return_code EXIT

# Validate mutually exclusive project/project-id arguments
choose_project() {
  if [ -n "$PARAM_PROJECT" ] && [ -n "$PARAM_PROJECT_ID" ]; then
    die "Provide either 'project' or 'project-id', not both."
  fi

  if [ -z "$PARAM_PROJECT" ] && [ -z "$PARAM_PROJECT_ID" ]; then
    die "You must provide either 'project' or 'project-id'."
  fi
}

# Normalise "true/false", "1/0", etc.
normalise_bool() {
  case "$1" in
    1|true|TRUE|yes|YES|on|ON) echo 1 ;;
    0|false|FALSE|no|NO|off|OFF|"") echo 0 ;;
    *) die "Invalid boolean: $1" ;;
  esac
}

# ---------------
# Step summary
# ---------------
# Action-specific summary for this entrypoint
write_step_summary() {
  rc=$1

  status_emoji="🎉"
  status_title="Success"
  [ "$rc" -ne 0 ] && status_emoji="❌" && status_title="Failure"

  project_display="${PROJECT:-<none>}"
  [ -n "${PROJECT_ID:-}" ] && project_display="${project_display} (ID: ${PROJECT_ID})"

  include_flag="$(normalise_bool "${PARAM_INCLUDE_ASSET_IN_TEST_NAME:-0}")"
  include_label="No"
  [ "$include_flag" -eq 1 ] && include_label="Yes"

  cat >>"$GITHUB_STEP_SUMMARY" <<EOF
## ${status_emoji} MCIX DataStage Compile – ${status_title}

### 📁 Project
\`${project_display}\`

### 📄 Report
\`${PARAM_REPORT}\`

### 🔧 Include Asset In Test Name
\`${include_label}\`

### 🚦 Exit Code
\`${rc}\`
EOF
}

# Generic trap that always sets return-code and writes the step summary
write_return_code_and_summary() {
  rc=$?
  echo "return-code=$rc" >>"$GITHUB_OUTPUT"

  # Only write step summary if GitHub provides the file
  [ -z "${GITHUB_STEP_SUMMARY:-}" ] && exit "$rc"

  write_step_summary "$rc"
  exit "$rc"
}
trap write_return_code_and_summary EXIT

# -------------------
# Validate parameters
# -------------------

# Required arguments
require() {
  # $1 = var name, $2 = human label (for error)
  eval "v=\${$1-}"
  if [ -z "$v" ]; then
    die "Missing required input: $2"
  fi
}

require PARAM_API_KEY "api-key"
require PARAM_URL "url"
require PARAM_USER "user"
require PARAM_REPORT "report"

# ------------------------
# Build command to execute
# ------------------------

# Start argv
set -- "$MCIX_CMD" datastage compile

# Core flags
set -- "$@" -api-key "$PARAM_API_KEY"
set -- "$@" -url "$PARAM_URL"
set -- "$@" -user "$PARAM_USER"
set -- "$@" -report "$PARAM_REPORT"

# Mutually exclusive project / project-id handling (safe with set -u)
PROJECT="${PARAM_PROJECT:-}"
PROJECT_ID="${PARAM_PROJECT_ID:-}"
choose_project
[ -n "$PROJECT" ]    && set -- "$@" -project "$PROJECT"
[ -n "$PROJECT_ID" ] && set -- "$@" -project-id "$PROJECT_ID"

# Optional scalar flags
# None in this action

# Optional boolean flags (with parameter variation handling)
if [ "$(normalise_bool "${PARAM_INCLUDE_ASSET_IN_TEST_NAME:-0}")" -eq 1 ]; then
  set -- "$@" -include-asset-in-test-name
fi

# -------
# Execute
# -------
echo "Executing: $*"

"$@"

status=$?
exit "$status"
