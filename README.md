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
    - uses: antmicro/verible-actions@main
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
```

You can provide optional arguments to specify paths, exclude paths,
a config file and extra arguments for ``verible-verilog-lint``.

```yaml
- uses: antmicro/verible-actions@main
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
