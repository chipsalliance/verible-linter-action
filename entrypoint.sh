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
patch=$(mktemp)

/opt/antmicro/action.py \
  --conf-file "$INPUT_CONFIG_FILE" \
  --extra-opts "$INPUT_EXTRA_ARGS" \
  --exclude-paths "$INPUT_EXCLUDE_PATHS" \
  --log-file "$INPUT_LOG_FILE" \
  --patch "$patch" \
  "$INPUT_PATHS" || exitcode=$?

# If posing both change suggestions and review
# first remove the fixed parts from (INPUT_LOG_FILE)
# in order not to double-report
if [ "$INPUT_SUGGEST_FIXES" = "true" ] && [ "$INPUT_REVIEWDOG_REPORTER" = "github-pr-review" ]
then
  # remove every line containing "(fixed)" and the preceding line
  perl -i -ne 'push @lines, $_;
    splice @lines, 0, 2 if /\(fixed\)/;
    print shift @lines if @lines > 1
    }{ print @lines;' "$INPUT_LOG_FILE"

  echo "posting autofix results"
  "$GOBIN"/reviewdog -name="verible-verilog-lint" \
    -f=diff -f.diff.strip=1 \
    -reporter="github-pr-review" \
    -filter-mode="diff_context" \
    -level="info" \
    -diff="$diff_cmd" \
    -fail-on-error="false" <"$patch" || true
fi
rm "$patch"

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
