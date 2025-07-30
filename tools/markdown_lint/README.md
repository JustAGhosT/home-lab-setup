# Markdown Linter

A powerful and extensible markdown linter and fixer with support for common style issues.

## Features

- 🚀 **Fast and efficient** - Built with performance in mind
- 🔧 **Auto-fixing** - Automatically fix many common issues
- 📋 **Configurable** - Customize rules to fit your needs
- 📊 **Detailed reporting** - Get clear feedback on issues
- 🔌 **Extensible** - Easily add custom rules

## Installation

### Using pip

```bash
pip install -e .
```

## Usage

### Command Line

```bash
# Lint all markdown files in the current directory
mdlint .

# Fix issues automatically
mdlint --fix .

# Show what would be fixed without making changes
mdlint --fix --dry-run .

# Specify a custom config file
mdlint --config .mdlintrc .
```

### Options

``` text
Usage: mdlint [OPTIONS] [PATHS]...

  Lint and fix markdown files.

Options:
  --max-line-length INTEGER  Maximum allowed line length  [default: 120]
  --fix                      Automatically fix fixable issues
  --dry-run                  Show what would be fixed without making changes
  --format [text|json]       Output format  [default: text]
  --no-color                 Disable colored output
  -v, --verbose              Increase verbosity (can be used multiple times)
  --exclude TEXT             Exclude files/directories that match the given
                             glob patterns (can be used multiple times)
  --severity [error|warning|style]
                             Minimum severity to report  [default: warning]
  --version                  Show the version and exit.
  --help                     Show this message and exit.

```

## Configuration

Create a `.mdlintrc` file in your project root to configure the linter:

```json
{
  "max_line_length": 100,
  "require_blank_line_before_heading": true,
  "require_blank_line_after_heading": true,
  "allow_multiple_blank_lines": false,
  "trim_trailing_whitespace": true,
  "insert_final_newline": true,
  "check_common_mistakes": true
}
```

## Rules

### MD001 - Inconsistent line endings

**Description**: Inconsistent line endings (CRLF vs LF)

**Fixable**: Yes

---

### MD002 - First heading should be a top-level heading

**Description**: First heading should be a top-level heading

**Fixable**: No

---

### MD007 - Unordered list indentation

**Description**: Unordered list indentation

**Fixable**: Yes

---

### MD009 - Trailing spaces

**Description**: Trailing spaces

**Fixable**: Yes

---

### MD012 - Multiple consecutive blank lines

**Description**: Multiple consecutive blank lines

**Fixable**: Yes

---

### MD013 - Line length

**Description**: Line length

**Fixable**: No

---

### MD018 - No space after hash on atx style heading

**Description**: No space after hash on atx style heading

**Fixable**: Yes

---

### MD022 - Headings should be surrounded by blank lines

**Description**: Headings should be surrounded by blank lines

**Fixable**: Yes

---

### MD026 - Trailing punctuation in heading

**Description**: Trailing punctuation in heading

**Fixable**: Yes

---

### MD030 - Spaces after list markers

**Description**: Spaces after list markers

**Fixable**: Yes

---

### MD034 - Bare URL used

**Description**: Bare URL used

**Fixable**: No

---

### MD047 - Files should end with a single newline character

**Description**: Files should end with a single newline character

**Fixable**: Yes

## Integration

### Pre-commit Hook

Add this to your `.pre-commit-config.yaml`:

```yaml
repos:

  - repo: https://github.com/JustAGhosT/home-lab-setup
    rev: v0.1.0
    hooks:

      - id: mdlint

        args: [--fix]
```

## Development

### Setup

1. Clone the repository
2. Install development dependencies:

   ```bash
   pip install -e ".[dev]"
   pre-commit install
   ```

### Running Tests

```bash
pytest
```

### Linting

```bash
flake8 markdown_lint tests
black markdown_lint tests
isort markdown_lint tests
mypy markdown_lint
```

## License

MIT
