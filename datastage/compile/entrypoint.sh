#!/bin/sh
# Don't use -l here; we want to preserve the PATH and other env vars 
# as set in the base image, and not have it overridden by a login shell

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
export MCIX_BIN_DIR="/usr/share/mcix/bin"
export MCIX_CMD="mcix" 
export MCIX_JUNIT_CMD="/usr/share//mcix/mcix-junit-to-summary"
# Make us immune to runner differences or potential base-image changes
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$MCIX_BIN_DIR"

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT must be set}"

# We'll store the real command status here so the trap can see it
MCIX_STATUS=0

# -----------------
# Utility functions
# -----------------

# Failure handling utility functions
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

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

# Ensure report file lands in the GitHub workspace so it survives container exit
resolve_report_path() {
  p="$1"

  # If already absolute, keep it
  case "$p" in
    /*) echo "$p" ;;
    *)
      # If relative, anchor it under workspace
      base="${GITHUB_WORKSPACE:-/github/workspace}"
      echo "${base}/${p#./}"
      ;;
  esac
}

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

# Ensure PARAM_REPORT will always be /github/workspace/...
# so it survives container exit and is accessible as an artifact.
PARAM_REPORT="$(resolve_report_path "$PARAM_REPORT")"
mkdir -p "$(dirname "$PARAM_REPORT")"
report_display="${PARAM_REPORT#${GITHUB_WORKSPACE:-/github/workspace}/}"

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

include_flag="$(normalise_bool "${PARAM_INCLUDE_ASSET_IN_TEST_NAME:-0}")"
include_label="No"

if [ "$include_flag" -eq 1 ]; then
  set -- "$@" -include-asset-in-test-name
  include_label="Yes"
fi

# ------------
# Step summary
# ------------
write_step_summary() {
  rc=$1

  # Only attempt a summary if GitHub provided a writable summary file
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ] && [ -w "$GITHUB_STEP_SUMMARY" ]; then
    "$MCIX_JUNIT_CMD" "$PARAM_REPORT" "MCIX DataStage Compile" >>"$GITHUB_STEP_SUMMARY" || true
  else
    echo "GitHub didn't provide a writable summary file; skipping junit summary generation" >>"$GITHUB_STEP_SUMMARY"
  fi
}

# ---------
# Exit trap
# ---------
write_return_code_and_summary() {
  # Prefer MCIX_STATUS if set; fall back to $?
  rc=${MCIX_STATUS:-$?}

  echo "return-code=$rc" >>"$GITHUB_OUTPUT"
  echo "report=$PARAM_REPORT" >>"$GITHUB_OUTPUT"

  [ -z "${GITHUB_STEP_SUMMARY:-}" ] && return

  write_step_summary "$rc"
}
trap write_return_code_and_summary EXIT

# -------
# Execute
# -------
echo "Executing: $*"

# Check the repository has been checked out
if [ ! -e "/github/workspace/.git" ] && [ ! -e "/github/workspace/$PARAM_ASSETS" ]; then
  die "Repo contents not found in /github/workspace. Did you forget to run actions/checkout@v4 before this action?"
fi

# Run the command, capture its output and status, but don't let `set -e` kill us.
set +e
CMD_OUTPUT="$("$@" 2>&1)"
MCIX_STATUS=$?
set -e

# Echo original command output into the job logs
printf '%s\n' "$CMD_OUTPUT"

# Let the trap handle outputs & summary using MCIX_STATUS
exit "$MCIX_STATUS"
