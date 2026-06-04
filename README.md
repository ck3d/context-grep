# context-grep

`context-grep` is a command-line tool that searches for [Vim regex](https://neovim.io/doc/user/pattern.html) patterns (typically within comments) and extracts the surrounding code context (like functions, classes, or modules) using Neovim's Treesitter integration.

It leverages the same "context" queries used by [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context), ensuring high-quality context extraction for a wide variety of languages.

## Features

- **Structural Grep**: Finds matches and identifies the logical code block they belong to.
- **JSON Output**: Produces structured JSON, ideal for piping into tools like `jq`, `fzf`, or custom scripts.
- **Language Aware**: Uses Treesitter to understand the structure of your code.

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

The `<pattern>` uses [Vim's regex syntax](https://neovim.io/doc/user/pattern.html), which differs from PCRE/extended grep: groups are `\(...\)`, alternation is `\|`, and quantifiers like `+` and `?` must be escaped (or prefix the pattern with `\v` for "very magic" mode). Only the first match on each line is reported.

### Example

Search for "TODO" in a Lua file and pretty-print with `jq`:

```bash
context-grep "TODO" sample.lua | jq .
```

### Output Format

The tool outputs a JSON array of match objects. Each object has the following fields:

| Field      | Description                                                                   |
| ---------- | ----------------------------------------------------------------------------- |
| `file`     | The file the match was found in.                                              |
| `match`    | The matched node (the enclosing comment when the hit is inside a comment).    |
| `target`   | The nearest non-comment code sibling the comment refers to.                   |
| `context`  | The enclosing structural scopes, ordered outermost → innermost. May be empty. |
| `filetype` | The Neovim filetype detected for the file.                                    |

The `match`, `target`, and `context` entries each carry the node's `text`, its 1-based start `line`, and its Treesitter `type`.

For example, running against [`test/sample.lua`](./test/sample.lua):

```bash
context-grep "inner comment" test/sample.lua | jq .
```

```json
[
  {
    "file": "test/sample.lua",
    "match": {
      "text": "-- TODO: inner comment",
      "line": 12,
      "type": "comment"
    },
    "target": {
      "text": "return x",
      "line": 13,
      "type": "block"
    },
    "context": [
      {
        "text": "local function bar()",
        "line": 11,
        "type": "function_declaration"
      }
    ],
    "filetype": "lua"
  }
]
```

## Supported Languages

`context-grep` supports any language for which a Treesitter "context" query is available. The Nix package pre-configures support for many languages, including:

- C, C++, Rust, Go, Python, JavaScript, TypeScript, Nix, Lua, Java, and many [more](./supported-languages.nix).

## Development

Enter the development shell and run the test suite:

```bash
nix develop
./test/run_tests.sh
```

The tests use [`jaq`](https://github.com/01mf02/jaq) (provided by the dev shell) to assert on the JSON output.
