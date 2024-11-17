# ESH Template Check Pre-Commit Hook

This pre-commit hook processes [`esh`](https://github.com/jirutka/esh) templates, renders them with test cases specified
in `YAML` front matter, and optionally runs [`shellcheck`](https://github.com/koalaman/shellcheck) on the generated
files.

## Features

- Parses YAML front matter to extract test cases and `shellcheck` arguments.
- Preprocesses ESH templates for each test case.
- Runs `shellcheck` with specified arguments, if provided.

## Setup

To use this hook in your repository:

1. Add this repo to your `.pre-commit-config.yaml`:

  ```yaml
  - repo: https://github.com/RobertDeRose/esh-template-check
    rev: v0.0.1
    hooks:
      - id: esh-template-check
  ```

### Supported Arguments

- **-k**
  - Keep the generated output after running. Stores generated output in `esh_template_output`
  - If you enable keeping the output, it is recommended add the above directory to your `.gitignore` file
- **-v**
  - Enable verbose output when an error occurs
- **-s=SHELL**
  - Override the Shell that ESH will use, by default uses Bash

### Supported Front Matter

- **check_args**
  - This should be a string that will be passed in as the arguments to shellcheck
- **test_cases**
  - This is an array of key/value pairs to be set as variables for the **template**

## Example Template

```bash
#!/bin/bash
<%# --- -%>
<%# check_args: -s bash  -%>
<%# test_cases: -%>
<%#   - VAR1: one -%>
<%#     VAR2: two -%>
<%#   - VAR1: a -%>
<%#     VAR2: b -%>
<%#   - VAR1: 1 -%>
<%#     VAR2: 2 -%>
<%# --- -%>

<% if [[ "${VAR1}" =~ ^(one|a)$ ]]; then -%>
<%= "# Generating script for ${VAR2}" %>
hello_world() {
    local name
<% if [[ "${VAR1}" == "one" ]]; then %>
    name="Rob"
<% elif [[ "${VAR1}" == "a" ]]; then %>
    name="Bob"
<% fi %>
    echo "Hello ${name} you got ${VAR2}"
}
```
