# context-grep

`context-grep` is a command-line tool that searches for [Vim regex](https://neovim.io/doc/user/pattern.html) patterns (typically within comments) and extracts the surrounding code context (like functions, classes, or modules) using Neovim's Treesitter integration.

It leverages the same "context" queries used by [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context), ensuring high-quality context extraction for a wide variety of languages.

## Features

- **Structural Context**: Matches lines with a Vim regex (including "very magic" mode), then uses Treesitter to identify the logical code block (function, class, module) each match belongs to.
- **Comment-Aware**: When a hit lands inside a comment, resolves the `target` — the code the comment actually refers to.
- **Injected Languages**: Understands code embedded in other code (e.g. Python in a Markdown block, SQL in a string); context can span multiple languages.
- **JSON Output**: Produces structured JSON, ideal for piping into tools like `jq`, `fzf`, or custom scripts.

## Installation

`context-grep` is packaged as a Nix flake. It requires [Nix](https://nixos.org/download) with [flakes enabled](https://nixos.wiki/wiki/Flakes).

Run it directly without installing:

```bash
nix run github:ck3d/context-grep -- "FIXME" sample.lua
```

Install it into your profile:

```bash
nix profile install github:ck3d/context-grep
```

## Usage

```bash
context-grep <pattern> <file>...
```

The `<pattern>` uses Vim's regex syntax, which differs from PCRE/extended grep: groups are `\(...\)`, alternation is `\|`, and quantifiers like `+` and `?` must be escaped (or prefix the pattern with `\v` for "very magic" mode). Only the first match on each line is reported.

You can pass multiple files (or a glob); matches from all of them are merged into a single JSON array:

```bash
context-grep "TODO" test/*.lua | jq .
```

Files that can't be read, have no Treesitter parser, or have no context query are skipped with a warning on stderr. `context-grep` exits with status `1` on invalid arguments or an invalid pattern.

### Output Format

The tool outputs a JSON array of match objects. Each object has the following fields:

| Field      | Description                                                                   |
| ---------- | ----------------------------------------------------------------------------- |
| `file`     | The file the match was found in.                                              |
| `match`    | The matched node (the enclosing comment when the hit is inside a comment).    |
| `target`   | The nearest non-comment code sibling the comment refers to. Absent when none. |
| `context`  | The enclosing structural scopes, ordered outermost → innermost. May be empty. |
| `filetype` | The Neovim filetype detected for the file.                                    |

Each `match`, `target`, and `context` entry (when present) carries the node's `text`, its 1-based start `line`, its Treesitter `type`, and the `language` it was parsed as.

For example, running against [`test/sample.md`](./test/sample.md):

```bash
context-grep "TODO" test/sample.md | jq .
```

```json
[
  {
    "file": "test/sample.md",
    "match": {
      "text": "# TODO: handle empty input",
      "line": 7,
      "type": "comment",
      "language": "python"
    },
    "target": {
      "text": "return data",
      "line": 8,
      "type": "block",
      "language": "python"
    },
    "context": [
      {
        "text": "# Sample doc",
        "line": 1,
        "type": "section",
        "language": "markdown"
      },
      {
        "text": "def process(data):\n    # TODO: handle empty input",
        "line": 6,
        "type": "function_definition",
        "language": "python"
      }
    ],
    "filetype": "markdown"
  }
]
```

This match lives in a Python code block embedded in Markdown, so the `context` spans both languages — the outer Markdown `section` and the inner Python `function_definition`.

## Supported Languages

`context-grep` supports any language for which a Treesitter "context" query is available. The Nix package pre-configures support for many languages, including:

- C, C++, Rust, Go, Python, JavaScript, TypeScript, Nix, Lua, Java, and many [more](./supported-languages.nix).

## Injected Languages

`context-grep` resolves matches against [injected languages](https://neovim.io/doc/user/treesitter.html#treesitter-language-injections) — code embedded in another language, such as a fenced code block in Markdown or SQL inside a string. A match inside an injected region is understood in that injected language, and the `context` may span multiple languages (e.g. an outer Markdown section enclosing an inner Python function). The `language` field on each entry tells you which language it came from.

## Development

Enter the development shell and run the test suite:

```bash
nix develop
./test/run_tests.sh
```

The tests use [`jaq`](https://github.com/01mf02/jaq) (provided by the dev shell) to assert on the JSON output.
