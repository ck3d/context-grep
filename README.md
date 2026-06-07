# context-grep

`context-grep` is a command-line tool that searches for regular expressions and extracts the surrounding code context using Neovim's Treesitter integration.

## Usage

```bash
nix run github:ck3d/context-grep -- <pattern> <file>...
```

The `<pattern>` is parsed as a regular expression.
It supports standard PCRE-like syntax.

### Output Format

The tool outputs a JSON array of match objects.
Each object has the following fields:

| Field      | Description                                                                   |
| ---------- | ----------------------------------------------------------------------------- |
| `file`     | The file the match was found in.                                              |
| `filetype` | The detected filetype                                                         |
| `match`    | The matched node (the enclosing comment when the hit is inside a comment).    |
| `target`   | The nearest non-comment code sibling the comment refers to. Absent when none. |
| `context`  | The enclosing structural scopes, ordered outermost → innermost. May be empty. |

Each `match`, `target`, and `context` entry (when present) carries the node's `text`, its 1-based start `line`, its Treesitter `type`, and the `language` it was parsed as.

For example, running against [`test-harness/sample.md`](./test-harness/sample.md):

```bash
context-grep "TODO" test-harness/sample.md
```

```json
[
  {
    "file": "test-harness/sample.md",
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

### Pretty Print Format

Alternatively, you can output the search results in a human-readable, colorized, and structured format using the `--format pretty` flag.
For example:

```bash
context-grep --format pretty --color never --no-icons "TODO" test-harness/sample.md
```

```text
test-harness/sample.md:7 markdown
  1│  # Sample doc
   ┆
  6│  def process(data):
  7│      # TODO: handle empty input
  7│  # TODO: handle empty input
  8│  return data
```

## Supported Languages

`context-grep` supports any language for which an [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) query is available.
The Nix package pre-configures support for many [supported languages](./nvim-plugin-grammars/supported-languages.nix).

## Injected Languages

`context-grep` resolves matches against [injected languages](https://neovim.io/doc/user/treesitter.html#treesitter-language-injections).
A match inside an injected region is understood in that injected language, and the `context` may span multiple languages.

## Development

Use the `pre-commit` scripts for iterative per package development and `nix flake check` for a full repository check.
