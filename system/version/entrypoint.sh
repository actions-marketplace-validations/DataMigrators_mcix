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

# Optional but useful for debugging
echo "GITHUB_STEP_SUMMARY=${GITHUB_STEP_SUMMARY:-<unset>}" >&2 || true

# We'll store the real command status here so the trap can see it
MCIX_STATUS=0

# ------------
# Step summary
# ------------
write_step_summary() {
  rc=$1

  status_emoji="✅"
  status_title="Success"
  [ "$rc" -ne 0 ] && status_emoji="❌" && status_title="Failure"

  project_display="${PROJECT:-<none>}"
  [ -n "${PROJECT_ID:-}" ] && project_display="${project_display} (ID: ${PROJECT_ID})"

  {
    cat <<EOF
## ${status_emoji} MCIX DataStage Import – ${status_title}

| Property    | Value                          |
|------------|---------------------------------|
| **Project**  | \`${project_display}\`        |
| **Assets**   | \`${PARAM_ASSETS:-<none>}\`   |
| **Exit Code** | \`${rc}\`                    |
EOF

    if [ -n "${CMD_OUTPUT:-}" ]; then
      printf '\n### MettleCI Command Output\n\n'

      echo '```text'
      printf '%s\n' "$CMD_OUTPUT" | awk '
        /^Loaded plugins:/ { in_plugins = 1; next }
        in_plugins && /^\s*\*/ { next }  # skip plugin lines
        { print }
      '
      echo '```'
      echo

      echo '<details>'
      echo '<summary>Loaded plugins</summary>'
      echo
      echo '| Plugin | Version |'
      echo '| ------ | ------- |'

      printf '%s\n' "$CMD_OUTPUT" | awk '
        /^Loaded plugins:/ { in_plugins = 1; next }
        in_plugins && /^\s*\*/ {
          line = $0
          sub(/^\s*\*\s*/, "", line)

          plugin = line
          version = ""

          if (match(plugin, /\(([^()]*)\)[[:space:]]*$/)) {
            version = substr(plugin, RSTART + 1, RLENGTH - 2)
            plugin  = substr(plugin, 1, RSTART - 1)
            sub(/[[:space:]]*$/, "", plugin)
          }

          printf("| %s | %s |\n", plugin, version)
        }
      '

      echo
      echo '</details>'
    fi
  } >>"$GITHUB_STEP_SUMMARY"
}

# ---------
# Exit trap
# ---------
write_return_code_and_summary() {
  # Prefer MCIX_STATUS if set; fall back to $?
  rc=${MCIX_STATUS:-$?}

  echo "return-code=$rc" >>"$GITHUB_OUTPUT"

  [ -z "${GITHUB_STEP_SUMMARY:-}" ] && return

  write_step_summary "$rc"
}
trap write_return_code_and_summary EXIT

# ------------------------
# Build command to execute
# ------------------------
set -- "$MCIX_CMD" system version

# -------
# Execute
# -------
echo "Executing: $*"

# Run the command, capture its output and status, but don't let `set -e` kill us.
set +e
CMD_OUTPUT="$("$@" 2>&1)"
MCIX_STATUS=$?
set -e

# Echo original command output into the job logs
printf '%s\n' "$CMD_OUTPUT"

# Let the trap handle outputs & summary using MCIX_STATUS
exit "$MCIX_STATUS"
