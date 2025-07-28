"""Core markdown linter implementation."""

import re
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Pattern, Set, Tuple, Union

from .models import FileReport, IssueSeverity, LintIssue


class MarkdownLinter:
    """Markdown linter and fixer."""

    # Default configuration
    DEFAULT_CONFIG = {
        "max_line_length": 120,
        "require_blank_line_before_heading": True,
        "require_blank_line_after_heading": True,
        "allow_multiple_blank_lines": False,
        "trim_trailing_whitespace": True,
        "end_of_line": "lf",  # 'lf' or 'crlf'
        "insert_final_newline": True,
        "check_markdownlint": True,
        "check_common_mistakes": True,
    }

    # Common markdown patterns - Fixed ReDoS vulnerability
    HEADING_PATTERN = re.compile(r"^(?P<level>#{1,6})\s+(?P<content>[^\r\n]*)$")
    CODE_BLOCK_PATTERN = re.compile(r"^```[\w\-]*$")
    HTML_COMMENT_PATTERN = re.compile(r"^<!--.*?-->\s*$")
    LIST_ITEM_PATTERN = re.compile(r"^\s*([*+-]|\d+\.)\s+")

    def __init__(self, config: Optional[dict] = None):
        """Initialize the linter with the given configuration."""
        self.config = {**self.DEFAULT_CONFIG, **(config or {})}
        self.reports: Dict[Path, FileReport] = {}

    def check_file(self, file_path: Union[str, Path]) -> FileReport:
        """Check a single markdown file for issues."""
        file_path = Path(file_path)
        report = FileReport(file_path)
        self.reports[file_path] = report

        try:
            # Read file content
            content = file_path.read_text(encoding="utf-8")
            lines = content.splitlines(keepends=False)

            # Initialize state
            in_code_block = False
            in_html_comment = False
            in_list = False
            list_indent = 0
            prev_line = ""

            # Process each line
            for i, line in enumerate(lines, 1):
                # Skip empty lines
                if not line.strip():
                    prev_line = line
                    continue

                # Check for code blocks
                if self.CODE_BLOCK_PATTERN.match(line):
                    in_code_block = not in_code_block
                    continue

                # Skip code blocks and HTML comments
                if in_code_block or in_html_comment:
                    prev_line = line
                    continue

                # Check for HTML comments
                if self.HTML_COMMENT_PATTERN.match(line):
                    in_html_comment = False  # Single line comment
                    continue

                # Check line length
                self._check_line_length(report, i, line)

                # Check for trailing whitespace
                if self.config["trim_trailing_whitespace"] and line.rstrip() != line:
                    self._add_issue(
                        report, i, "Trim trailing whitespace", "MD009", fix=lambda l: l.rstrip()
                    )

                # Check for consistent line endings
                if "\r\n" in line:
                    self._add_issue(
                        report,
                        i,
                        "Inconsistent line endings (CRLF)",
                        "MD001",
                        fix=lambda l: l.replace("\r\n", "\n"),
                    )

                # Check headings
                heading_match = self.HEADING_PATTERN.match(line)
                if heading_match:
                    self._check_heading(report, i, line, heading_match)

                # Check list items
                list_match = self.LIST_ITEM_PATTERN.match(line)
                if list_match:
                    self._check_list_item(report, i, line, list_match)

                # Check for common markdown mistakes
                if self.config["check_common_mistakes"]:
                    self._check_common_mistakes(report, i, line, prev_line)

                prev_line = line

            # Check for final newline
            if self.config["insert_final_newline"] and content and not content.endswith("\n"):
                self._add_issue(
                    report,
                    len(lines),
                    "Missing final newline",
                    "MD047",
                    fix=lambda c: c + "\n",
                    file_level=True,
                )

            # Store the fixed content if there are fixes
            if any(issue.fixable for issue in report.issues):
                report.fixed_content = self._apply_fixes(content, report.issues)

        except Exception as e:
            self._add_issue(
                report, 0, f"Error processing file: {str(e)}", "ERROR", severity=IssueSeverity.ERROR
            )

        return report

    def _check_line_length(self, report: FileReport, line_num: int, line: str) -> None:
        """Check if the line exceeds the maximum allowed length."""
        max_length = self.config["max_line_length"]
        if len(line) > max_length:
            # Try to determine if we can auto-fix this line
            fix_func = self._get_line_length_fix(line, max_length)
            self._add_issue(
                report,
                line_num,
                f"Line too long ({len(line)} > {max_length} characters)",
                "MD013",
                fix=fix_func,
            )

    def _get_line_length_fix(self, line: str, max_length: int) -> Optional[Callable[[str], str]]:
        """Determine if and how to fix a long line."""
        stripped = line.strip()

        # Don't auto-fix code blocks, tables, or very complex structures
        if (
            stripped.startswith("```")
            or stripped.startswith("|")
            or stripped.startswith("    ")
            or "---" in stripped
        ):
            return None

        # Don't auto-fix headings or very short overruns (< 10 chars)
        if stripped.startswith("#") or len(line) - max_length < 10:
            return None

        # Auto-fix text paragraphs and list items
        if self._can_wrap_text(stripped):
            return lambda l: self._wrap_text_line(l, max_length)

        return None

    def _can_wrap_text(self, line: str) -> bool:
        """Check if a line can be safely wrapped."""
        stripped = line.strip()
        # Can wrap normal text, list items, and simple markdown
        return (
            not stripped.startswith(">")  # Not blockquote
            and not re.match(r"^\s*\d+\.", stripped)  # Not numbered list (for now)
            and "http" not in stripped  # Not URLs (handle separately)
            and "[" not in stripped
            and "]" not in stripped
        )  # Not complex links

    def _wrap_text_line(self, line: str, max_length: int) -> str:
        """Wrap a text line at word boundaries."""
        if len(line) <= max_length:
            return line

        # Preserve leading whitespace
        leading_space = len(line) - len(line.lstrip())
        indent = line[:leading_space]
        content = line[leading_space:]

        # Find the best break point
        break_point = max_length - leading_space
        if break_point >= len(content):
            return line

        # Find word boundary before break point
        space_before = content.rfind(" ", 0, break_point)
        if space_before > break_point // 2:  # Reasonable break point found
            return indent + content[:space_before] + "\n" + indent + content[space_before:].lstrip()

        return line  # Can't find good break point

    def _check_heading(self, report: FileReport, line_num: int, line: str, match: re.Match) -> None:
        """Check heading formatting and spacing."""
        level = len(match.group("level"))
        content = match.group("content")

        # Check for space after heading markers
        if not line.startswith(f"{'#' * level} "):
            self._add_issue(
                report,
                line_num,
                f"Missing space after heading marker",
                "MD018",
                fix=lambda l: f"{'#' * level} {l.lstrip('#').lstrip()}",
            )

        # Check for trailing hashes
        if " #" in content:
            self._add_issue(
                report,
                line_num,
                "Remove trailing hash characters from heading",
                "MD026",
                fix=lambda l: l.split(" #")[0].rstrip(),
            )

        # Check for proper capitalization (first word only)
        if content and content[0].islower() and content[0].isalpha():
            self._add_issue(
                report,
                line_num,
                "First word in heading should be capitalized",
                "MD002",
                fix=lambda l: re.sub(
                    r"^(#+\s*)([a-z])", lambda m: m.group(1) + m.group(2).upper(), l
                ),
            )

    def _check_list_item(
        self, report: FileReport, line_num: int, line: str, match: re.Match
    ) -> None:
        """Check list item formatting and indentation."""
        # Check for proper indentation (2 or 4 spaces)
        indent = len(line) - len(line.lstrip())
        if indent % 2 != 0 and indent > 0:
            self._add_issue(
                report,
                line_num,
                "List items should be indented with multiples of 2 spaces",
                "MD007",
                fix=lambda l: " " * (indent + 1) + l.lstrip(),
            )

    def _check_common_mistakes(
        self, report: FileReport, line_num: int, line: str, prev_line: str
    ) -> None:
        """Check for common markdown mistakes."""
        # Check for bare URLs and insecure HTTP - Combined security fix
        if "http://" in line or "https://" in line:
            # Simple check for bare URLs (very basic, might have false positives)
            words = re.split(r"[\s<>]", line)
            for word in words:
                if word.startswith("http://"):
                    self._add_issue(
                        report,
                        line_num,
                        f"Insecure HTTP URL found, use HTTPS instead: {word}",
                        "SEC001",
                        severity=IssueSeverity.WARNING,
                    )
                if (word.startswith("http://") or word.startswith("https://")) and "](" not in line:
                    self._add_issue(
                        report,
                        line_num,
                        f"Bare URL used, consider using a link reference: {word}",
                        "MD034",
                    )

        # Check for multiple spaces after list markers
        if re.match(r"^\s*[*+-]\s{2,}\S", line):
            self._add_issue(
                report,
                line_num,
                "Use a single space after list markers",
                "MD030",
                fix=lambda l: re.sub(r"^([*+-])\s+", r"\1 ", l),
            )

    def _add_issue(
        self,
        report: FileReport,
        line_num: int,
        message: str,
        code: str,
        fix: Optional[Callable[[str], str]] = None,
        severity: IssueSeverity = IssueSeverity.WARNING,
        file_level: bool = False,
    ) -> None:
        """Add an issue to the report."""
        issue = LintIssue(
            line=line_num if not file_level else 0,
            message=message,
            code=code,
            severity=severity,
            fixable=fix is not None,
            fix=fix,
        )
        report.add_issue(issue)

    def _apply_fixes(self, content: str, issues: List[LintIssue]) -> List[str]:
        """Apply all fixes to the content and return the fixed lines."""
        lines = content.splitlines(keepends=True)

        # Sort issues by line number (descending) to avoid offset issues
        sorted_issues = sorted(
            [i for i in issues if i.fixable and i.line > 0], key=lambda x: x.line, reverse=True
        )

        # Apply fixes from bottom to top
        for issue in sorted_issues:
            if issue.fix and 0 < issue.line <= len(lines):
                line_idx = issue.line - 1
                lines[line_idx] = issue.fix(lines[line_idx])

        # Handle file-level fixes
        for issue in issues:
            if issue.fix and issue.line == 0:
                # Apply to the entire content
                fixed_content = issue.fix("".join(lines))
                lines = fixed_content.splitlines(keepends=True)

        return lines

    def check_directory(
        self, directory: Union[str, Path], exclude: Optional[List[str]] = None
    ) -> Dict[Path, FileReport]:
        """Check all markdown files in a directory."""
        from find_markdown_files import find_markdown_files  # type: ignore

        directory = Path(directory).resolve()
        exclude = exclude or []

        # Find all markdown files
        files = find_markdown_files(
            directory,
            exclude_dirs={".git", "node_modules", "__pycache__", ".pytest_cache", ".mypy_cache"},
            exclude_files=exclude,
        )

        # Check each file
        for file_path in files:
            self.check_file(file_path)

        return self.reports

    def fix_files(self, dry_run: bool = False) -> int:
        """Apply all fixes to files with issues."""
        fixed_count = 0

        for file_path, report in self.reports.items():
            if not report.has_fixable_issues:
                continue

            if dry_run:
                print(
                    f"Would fix {len([i for i in report.issues if i.fixable])} "
                    f"issues in {file_path}"
                )
                continue

            if report.fixed_content is not None:
                try:
                    with open(file_path, "w", encoding="utf-8") as f:
                        f.writelines(report.fixed_content)
                    fixed_count += 1
                    print(
                        f"Fixed {len([i for i in report.issues if i.fixable])} "
                        f"issues in {file_path}"
                    )
                except Exception as e:
                    print(f"Error fixing {file_path}: {e}", file=sys.stderr)

        return fixed_count