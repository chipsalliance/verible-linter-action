#!/usr/bin/env bash

event_file=event.json
diff_cmd="git diff FECH_HEAD"

if [ -f "$event_file" ]; then
  pr_branch=$(python3 -c "import sys, json; print(json.load(sys.stdin)['pull_request']['head']['ref'])" < event.json)
  base_branch=$(python3 -c "import sys, json; print(json.load(sys.stdin)['pull_request']['base']['ref'])" < event.json)
  git fetch origin "$pr_branch"
  git checkout "$pr_branch"
  echo "the PR branch is $pr_branch"
  echo "the base branch is $base_branch"
  diff_cmd="git diff $base_branch $pr_branch"
  export OVERRIDE_GITHUB_EVENT_PATH=$(pwd)/event.json
fi

touch "$INPUT_LOG_FILE"
export REVIEWDOG_GITHUB_API_TOKEN="$INPUT_GITHUB_TOKEN"

/opt/antmicro/action.py \
  --conf-file "$INPUT_CONFIG_FILE" \
  --extra-opts "$INPUT_EXTRA_ARGS" \
  --exclude-paths "$INPUT_EXCLUDE_PATHS" \
  --log-file "$INPUT_LOG_FILE" \
  "$INPUT_PATHS" || exitcode=$?

echo "Running reviewdog"

"$GOBIN"/reviewdog -efm="%f:%l:%c: %m" \
  -reporter="$INPUT_REVIEWDOG_REPORTER" \
  -fail-on-error="false" \
  -name="verible-verilog-lint" \
  -diff="$diff_cmd" < "$INPUT_LOG_FILE" || cat "$INPUT_LOG_FILE"

if [ -f "$event_file" ]; then
  git checkout -
fi

exit $exitcode
