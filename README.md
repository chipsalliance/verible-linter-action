Verible Lint Action
===================

Usage
-----

See [action.yml](action.yml)

This is a GitHub Action used to lint Verilog and SystemVerilog source files
and comment erroneous lines of code in Pull Requests automatically.
The GitHub Token input is used to provide
[reviewdog](https://github.com/reviewdog/reviewdog)
access to the PR.
If you don't wish to use the automatic PR review,
you can omit the ``github_token`` input.
If you'd like to use a reporter of reviewdog other than ``github-pr-review``,
you can pass its name in the input ``reviewdog_reporter``.

Here's a basic example to lint all ``*.v`` and ``*.sv`` files:
```yaml
name: Verible linter example
on:
  pull_request:
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: chipsalliance/verible-linter-action@main
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
```

You can provide optional arguments to specify paths, exclude paths,
a config file and extra arguments for ``verible-verilog-lint``.

```yaml
- uses: chipsalliance/verible-linter-action@main
  with:
    config_file: 'config.rules'
    paths: |
      ./rtl
      ./shared
    exclude_paths: |
      ./rtl/some_file
    extra_args: "--check_syntax=true"
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

Automatic review on PRs from external repositories
--------------------------------------------------

In GitHub Actions, workflows triggered by external repositories may only have
[read access to the main repository](https://docs.github.com/en/actions/reference/authentication-in-a-workflow#permissions-for-the-github_token).
In order to have automatic reviews on external PRs, you need to create two workflows.
One will be triggered on ``pull_request`` and upload the data needed by reviewdog as an artifact.
The artifact shall store the file pointed by ``$GITHUB_EVENT_PATH`` as ``event.json``.
The other workflow will download the artifact and use the Verible action.

For example:
```yaml
name: upload-event-file
on:
  pull_request:

...
      - run: cp "$GITHUB_EVENT_PATH" ./event.json
      - name: Upload event file as artifact
        uses: actions/upload-artifact@v2
        with:
          name: event.json
          path: event.json
```

```yaml
name: review-triggered
on:
  workflow_run:
    workflows: ["upload-event-file"]
    types:
      - completed

jobs:
  review_triggered:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: 'Download artifact'
        id: get-artifacts
        uses: actions/github-script@v3.1.0
        with:
          script: |
            var artifacts = await github.actions.listWorkflowRunArtifacts({
               owner: context.repo.owner,
               repo: context.repo.repo,
               run_id: ${{github.event.workflow_run.id }},
            });
            var matchArtifact = artifacts.data.artifacts.filter((artifact) => {
              return artifact.name == "event.json"
            })[0];
            var download = await github.actions.downloadArtifact({
               owner: context.repo.owner,
               repo: context.repo.repo,
               artifact_id: matchArtifact.id,
               archive_format: 'zip',
            });
            var fs = require('fs');
            fs.writeFileSync('${{github.workspace}}/event.json.zip', Buffer.from(download.data));
      - run: |
          unzip event.json.zip
      - name: Run Verible action with Reviewdog
        uses: chipsalliance/verible-linter-action@main
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```
