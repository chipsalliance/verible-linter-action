# Verible Linter Action

This action uses [Verible](https://github.com/chipsalliance/verible) to identify coding style issues in SystemVerilog code.

![verible linter action](https://user-images.githubusercontent.com/8438531/140962421-0a51e7b8-dc1c-4f87-b84b-1c2f3462cfca.png)

## Usage

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
If you want to declare Verible version to be used,
you can pass its release tag in the input ``verible_version``.

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
a config file, Verible version and extra arguments for ``verible-verilog-lint``.

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
    verible_version: "v0.0-3100-gd75b1c47"
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Automatic review on PRs from external repositories

In GitHub Actions, workflows triggered by external repositories may only have
[read access to the main repository](https://docs.github.com/en/actions/reference/authentication-in-a-workflow#permissions-for-the-github_token).
In order to have automatic reviews on external PRs, you need to create two workflows.
One will be triggered on ``pull_request`` and upload the data needed by reviewdog as an artifact.
The artifact shall store the file pointed by ``$GITHUB_EVENT_PATH`` as ``verible-trigger.json``.
The other workflow will download the artifact and use the Verible action.

For example:
```yaml
name: verible-trigger-send
on:
  pull_request:

jobs:
  verible-trigger:
    runs-on: ubuntu-latest
    steps:
      - uses: antmicro/verible-linter-action/trigger-send@main
```

```yaml

name: verible-trigger-receive
on:
  workflow_run:
    workflows: verible-trigger-send
    types:
      - completed

jobs:
  verible-review:
    runs-on: ubuntu-latest
    steps:
      - uses: antmicro/verible-linter-action/trigger-receive@main
      - name: Run Verible action
        uses: chipsalliance/verible-linter-action@main
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```
