#!/bin/sh -l
set -eu

MCIX_BIN_DIR="/usr/share/mcix/bin"
MCIX_CMD="$MCIX_BIN_DIR/mcix"
PATH="$PATH:$MCIX_BIN_DIR"

# Validate required vars
: "${PARAM_API_KEY:?Missing required input: api-key}"
: "${PARAM_URL:?Missing required input: url}"
: "${PARAM_USERNAME:?Missing required input: username}"
: "${PARAM_REPORT:?Missing required input: report}"

# Optional arguments
PROJECT="${PARAM_PROJECT:-}"
PROJECT_ID="${PARAM_PROJECT_ID:-}"

# PARAM_RULES: ${{ inputs.rules }}
# PARAM_INCLUDED_TAGS: ${{ inputs.included-tags }}
# : ${{ inputs.excluded-tags }}
# PARAM_TEST_SUITE: ${{ inputs.test-suite }}
# PARAM_IGNORE_TEST_FAILURES: ${{ inputs.ignore-test-failures }}

# Failure handling utility function
die() { echo "$*" 1>&2 ; exit 1; }

# 1) Fail if BOTH project and project-id were provided
if [ -n "$PROJECT" ] && [ -n "$PROJECT_ID" ]; then
  die "ERROR: Both 'project' and 'project-id' were provided. Please specify only one."
fi

# 2) Fail if NEITHER project or project-id were provided
if [ -z "$PROJECT" ] && [ -z "$PROJECT_ID" ]; then
  die "ERROR: You must provide either 'project' or 'project-id'." 
fi

# Build command to execute
CMD="$MCIX_CMD asset-analysis test \
 -api-key \"$PARAM_API_KEY\" \
 -url \"$PARAM_URL\" \
 -username \"$PARAM_USERNAME\" \
 -report \"$PARAM_REPORT\""

# Add optional argument flags
#[ -n "$PARAM_INCLUDE_ASSET_IN_TEST_NAME" ] && CMD="$CMD -include-asset-in-test-name"

# Add optional project/project-id
[ -n "$PROJECT" ] && CMD="$CMD -project \"$PROJECT\""
[ -n "$PROJECT_ID" ] && CMD="$CMD -project-id \"$PROJECT_ID\""

# Echo diagnostics for included and excluded tags
[ -n "$PARAM_INCLUDED_TAGS" ] && CMD="$CMD -include-tag \"$PARAM_INCLUDED_TAGS\""
[ -n "$PARAM_EXCLUDED_TAGS" ] && CMD="$CMD -exclude-tag \"$PARAM_EXCLUDED_TAGS\""

echo "Executing: $CMD"

# Execute the command
# shellcheck disable=SC2086
sh -c "$CMD"
status=$?

echo "return-code=$status" >> "$GITHUB_OUTPUT"
exit "$status"






  Options:
    -api-key
      CP4D API key
    -exclude-tag
      Tags of compliance rules to exclude (case insensitive)
    -ignore-test-failures
      Returns zero when testing completes regardless of failures
      Default: false
    -include-job-in-test-name
      Test case names will include the job name in the jUnit report
      Default: false
    -include-tag
      Tags of compliance rules to include (case insensitive), includes
      everything by default
    -path
      location of project export directory or zip file
    -project
      Project Name
    -project-cache
      Project cache directory, enables incremental testing
  * -report
      report name (.csv or .xml)
  * -rules
      location of all the rule files
    -test-suite
      Name of test suite being run, only required if running this command
      multiple times for the same project
    -url
      Base URL for CP4D instance
    -username
      CP4D user name