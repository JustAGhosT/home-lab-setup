"""Core markdown linter implementation."""

import re
import sys
from pathlib import Path
from typing import Callable, Dict, List, Optional, Union

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
        "check_blank_lines_around_headings": True,  # MD022
        "check_blank_lines_around_lists": True,  # MD032
        "check_ordered_list_numbering": True,  # MD029
        "check_fenced_code_blocks": True,  # MD031, MD040
        "check_duplicate_headings": True,  # MD024
        "check_bare_urls": True,  # MD034
    }

    # Common markdown patterns
    # Bug fix: Improved regex patterns with better edge case handling
    HEADING_PATTERN = re.compile(r"^(?P<level>#{1,6})\s+(?P<content>.{0,1000})$")
    CODE_BLOCK_PATTERN = re.compile(r"^```[\w\-]*$")
    CODE_BLOCK_START_PATTERN = re.compile(r"^```(?P<language>[\w\-]*)$")
    HTML_COMMENT_SINGLE_LINE_PATTERN = re.compile(r"^<!--.*?-->\s*$")
    HTML_COMMENT_START_PATTERN = re.compile(r"^<!--")
    HTML_COMMENT_END_PATTERN = re.compile(r"-->\s*$")
    LIST_ITEM_PATTERN = re.compile(r"^\s*([*+-]|\d+\.)\s+")
    # Bug fix: Improve ordered list pattern to handle edge cases with spacing
    ORDERED_LIST_PATTERN = re.compile(
        r"^\s*(?P<number>\d+)\.(?P<content>\s+.+?)$"
    )
    UNORDERED_LIST_PATTERN = re.compile(r"^\s*[*+-]\s+")
    BLANK_LINE_PATTERN = re.compile(r"^\s*$")
    # Bug fix: Improve URL pattern to avoid false positives with markdown links
    BARE_URL_PATTERN = re.compile(r"(?<![<\[\(])(https?://[^\s<>\[\]()\"\']+)(?![>\]\)])")
    EMAIL_PATTERN = re.compile(
        r"(?<![<\[\(])([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})(?![>\]\)])"
    )
    CLOSED_ATX_HEADING_PATTERN = re.compile(r"^#{1,6}\s+[^\s].*[^\s]\s+#{1,6}\s*$")

    # Constants for repeated messages
    MSG_FENCED_CODE_BLOCKS_SPACING = (
        "Fenced code blocks should be surrounded by blank lines"
    )

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
            content = file_path.read_text(encoding="utf-8", errors="replace")
            lines = content.splitlines(keepends=False)

            # Initialize parsing state
            state = self._initialize_parsing_state()

            # Process each line
            for i, line in enumerate(lines, 1):
                state = self._process_line(report, i, line, lines, state)

            # Final checks
            self._perform_final_checks(report, content, lines)

        except Exception as e:
            self._add_issue(
                report,
                0,
                f"Error processing file: {str(e)}",
                "ERROR",
                severity=IssueSeverity.ERROR,
            )

        return report

    def _initialize_parsing_state(self) -> dict:
        """Initialize the parsing state for processing a markdown file."""
        return {
            "in_code_block": False,
            "in_html_comment": False,
            "in_list": False,
            "prev_line": "",
            "prev_line_blank": True,
            "current_list_type": None,
            "expected_ordered_number": 1,
            "list_start_line": 0,
            "seen_headings": set(),
        }

    def _process_line(
        self, report: FileReport, line_num: int, line: str, lines: list, state: dict
    ) -> dict:
        """Process a single line and update the parsing state."""
        is_blank = self.BLANK_LINE_PATTERN.match(line)

        if is_blank:
            return self._handle_blank_line(report, line_num, line, lines, state)

        # Handle code blocks
        code_block_match = self.CODE_BLOCK_START_PATTERN.match(line)
        if code_block_match:
            return self._handle_code_block(
                report, line_num, line, lines, state, code_block_match
            )

        # Skip processing if inside code blocks or HTML comments
        if state["in_code_block"] or state["in_html_comment"]:
            return self._update_state_for_skipped_line(state, line)

        # Handle HTML comments
        if self._handle_html_comment(line, state):
            return state

        # Perform line-level checks
        self._perform_line_checks(report, line_num, line)

        # Handle headings
        heading_match = self.HEADING_PATTERN.match(line)
        if heading_match:
            self._handle_heading(report, line_num, line, lines, state, heading_match)

        # Handle list items
        state = self._handle_list_items(report, line_num, line, state)

        # Check for common markdown mistakes
        if self.config["check_common_mistakes"]:
            self._check_common_mistakes(report, line_num, line)

        state["prev_line"] = line
        state["prev_line_blank"] = False
        return state

    def _handle_blank_line(
        self, report: FileReport, line_num: int, line: str, lines: list, state: dict
    ) -> dict:
        """Handle processing of blank lines."""
        state["prev_line"] = line
        state["prev_line_blank"] = True

        # Check if we're ending a list
        if state["in_list"] and state["current_list_type"]:
            self._check_list_end_spacing(report, line_num - 1, lines)
            state["in_list"] = False
            state["current_list_type"] = None
            state["expected_ordered_number"] = 1

        return state

    def _handle_code_block(
        self,
        report: FileReport,
        line_num: int,
        line: str,
        lines: list,
        state: dict,
        code_block_match,
    ) -> dict:
        """Handle code block start/end processing."""
        if not state["in_code_block"]:
            # Starting a code block
            if self.config["check_fenced_code_blocks"]:
                self._check_fenced_code_block_start(
                    report, line_num, state["prev_line_blank"], code_block_match
                )
        else:
            # Ending a code block
            if self.config["check_fenced_code_blocks"]:
                self._check_fenced_code_block_end(report, line_num, lines)

        state["in_code_block"] = not state["in_code_block"]
        state["prev_line"] = line
        state["prev_line_blank"] = False
        return state

    def _update_state_for_skipped_line(self, state: dict, line: str) -> dict:
        """Update state for lines that are skipped during processing."""
        state["prev_line"] = line
        state["prev_line_blank"] = False
        return state

    def _handle_html_comment(self, line: str, state: dict) -> bool:
        """Handle HTML comment processing. Returns True if line was handled."""
        # Check for single-line HTML comment (complete comment on one line)
        if self.HTML_COMMENT_SINGLE_LINE_PATTERN.match(line):
            state["prev_line"] = line
            state["prev_line_blank"] = False
            return True

        # Check for start of multi-line HTML comment
        if self.HTML_COMMENT_START_PATTERN.search(
            line
        ) and not self.HTML_COMMENT_END_PATTERN.search(line):
            state["in_html_comment"] = True
            state["prev_line"] = line
            state["prev_line_blank"] = False
            return True

        # Check for end of multi-line HTML comment
        if state["in_html_comment"] and self.HTML_COMMENT_END_PATTERN.search(line):
            state["in_html_comment"] = False
            state["prev_line"] = line
            state["prev_line_blank"] = False
            return True

        return False

    def _perform_line_checks(
        self, report: FileReport, line_num: int, line: str
    ) -> None:
        """Perform basic line-level checks."""
        # Check line length
        self._check_line_length(report, line_num, line)

        # Check for trailing whitespace
        if self.config["trim_trailing_whitespace"] and line.rstrip() != line:
            self._add_issue(
                report,
                line_num,
                "Trim trailing whitespace",
                "MD009",
                fix=lambda line: line.rstrip(),
            )

        # Check for consistent line endings
        expected_eol = self.config["end_of_line"]
        if expected_eol == "lf" and "\r\n" in line:
            self._add_issue(
                report,
                line_num,
                "Inconsistent line endings (CRLF)",
                "MD001",
                fix=lambda line: line.replace("\r\n", "\n"),
            )
        elif expected_eol == "crlf" and "\r\n" not in line and line.endswith("\n"):
            self._add_issue(
                report,
                line_num,
                "Inconsistent line endings (LF)",
                "MD001",
                fix=lambda line: line.rstrip("\n") + "\r\n",
            )

    def _handle_heading(
        self,
        report: FileReport,
        line_num: int,
        line: str,
        lines: list,
        state: dict,
        heading_match,
    ) -> None:
        """Handle heading processing."""
        self._check_heading(report, line_num, line, heading_match)

        # MD022: Check blank lines around headings
        if self.config["check_blank_lines_around_headings"]:
            self._check_heading_spacing(
                report, line_num, lines, state["prev_line_blank"]
            )

        # MD024: Check for duplicate headings
        if self.config["check_duplicate_headings"]:
            self._check_duplicate_headings(
                report, line_num, heading_match.group("content"), state["seen_headings"]
            )

    def _handle_list_items(
        self, report: FileReport, line_num: int, line: str, state: dict
    ) -> dict:
        """Handle list item processing."""
        list_match = self.LIST_ITEM_PATTERN.match(line)
        ordered_match = self.ORDERED_LIST_PATTERN.match(line)
        unordered_match = self.UNORDERED_LIST_PATTERN.match(line)

        if list_match:
            self._check_list_item(report, line_num, line)

            # MD032: Check blank lines around lists
            if self.config["check_blank_lines_around_lists"]:
                if not state["in_list"]:
                    self._check_list_start_spacing(
                        report, line_num, state["prev_line_blank"]
                    )
                state["in_list"] = True

            # Handle ordered list numbering
            if ordered_match and self.config["check_ordered_list_numbering"]:
                state = self._handle_ordered_list(
                    report, line_num, ordered_match, state
                )
            elif unordered_match:
                state = self._handle_unordered_list(state)

        elif state["in_list"] and state["current_list_type"]:
            # We're no longer in a list
            self._check_list_end_spacing(
                report, line_num - 1, []
            )  # lines not needed for this check
            state["in_list"] = False
            state["current_list_type"] = None
            state["expected_ordered_number"] = 1

        return state

    def _handle_ordered_list(
        self, report: FileReport, line_num: int, ordered_match, state: dict
    ) -> dict:
        """Handle ordered list processing."""
        number = int(ordered_match.group("number"))
        if state["current_list_type"] != "ordered":
            state["current_list_type"] = "ordered"
            state["expected_ordered_number"] = 1

        self._check_ordered_list_numbering(
            report, line_num, number, state["expected_ordered_number"]
        )
        state["expected_ordered_number"] += 1
        return state

    def _handle_unordered_list(self, state: dict) -> dict:
        """Handle unordered list processing."""
        if state["current_list_type"] != "unordered":
            state["current_list_type"] = "unordered"
            state["expected_ordered_number"] = 1
        return state

    def _perform_final_checks(
        self, report: FileReport, content: str, lines: list
    ) -> None:
        """Perform final checks after processing all lines."""
        # Bug fix: Check for final newline with proper validation
        if self.config["insert_final_newline"] and content:
            # Bug fix: Handle edge case where file ends with multiple newlines
            if not content.endswith("\n"):
                self._add_issue(
                    report,
                    len(lines),
                    "Missing final newline",
                    "MD047",
                    fix=lambda c: c + "\n",
                    file_level=True,
                )
            # Bug fix: Check for multiple trailing newlines
            elif content.endswith("\n\n\n") and not self.config["allow_multiple_blank_lines"]:
                # Count trailing newlines
                trailing_newlines = len(content) - len(content.rstrip("\n"))
                if trailing_newlines > 1:
                    self._add_issue(
                        report,
                        len(lines),
                        f"Multiple trailing newlines ({trailing_newlines} found, expected 1)",
                        "MD012",
                        fix=lambda c: c.rstrip("\n") + "\n",
                        file_level=True,
                    )

        # Store the fixed content if there are fixes
        if any(issue.fixable for issue in report.issues):
            report.fixed_content = self._apply_fixes(content, report.issues)

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

    def _get_line_length_fix(
        self, line: str, max_length: int
    ) -> Optional[Callable[[str], str]]:
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
            return lambda line: self._wrap_text_line(line, max_length)

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
            return (
                indent
                + content[:space_before]
                + "\n"
                + indent
                + content[space_before:].lstrip()
            )

        return line  # Can't find good break point

    def _check_heading(
        self, report: FileReport, line_num: int, line: str, match: re.Match
    ) -> None:
        """Check heading formatting and spacing."""
        level = len(match.group("level"))
        content = match.group("content")

        # Check for space after heading markers
        if not line.startswith(f"{'#' * level} "):
            self._add_issue(
                report,
                line_num,
                "Missing space after heading marker",
                "MD018",
                fix=lambda line: f"{'#' * level} {line.lstrip('#').lstrip()}",
            )

        # Check for trailing hashes
        if " #" in content:
            self._add_issue(
                report,
                line_num,
                "Remove trailing hash characters from heading",
                "MD026",
                fix=lambda line: line.split(" #")[0].rstrip(),
            )

        # Check for proper capitalization (first word only)
        if content and content[0].islower() and content[0].isalpha():
            self._add_issue(
                report,
                line_num,
                "First word in heading should be capitalized",
                "MD002",
                fix=lambda line: re.sub(
                    r"^(#+\s*)([a-z])", lambda m: m.group(1) + m.group(2).upper(), line
                ),
            )

    def _check_heading_spacing(
        self, report: FileReport, line_num: int, lines: List[str], prev_line_blank: bool
    ) -> None:
        """Check MD022: Headings should be surrounded by blank lines."""
        # Check if previous line is blank (unless it's the first line)
        if line_num > 1 and not prev_line_blank:
            self._add_issue(
                report,
                line_num,
                "Headings should be surrounded by blank lines",
                "MD022",
                severity=IssueSeverity.WARNING,
                fix=lambda content: content,  # Handled by _apply_spacing_fixes
            )

        # Check if next line is blank (unless it's the last line)
        if line_num < len(lines):
            next_line = lines[line_num]
            if next_line.strip() and not self.BLANK_LINE_PATTERN.match(next_line):
                self._add_issue(
                    report,
                    line_num,
                    "Headings should be surrounded by blank lines",
                    "MD022",
                    severity=IssueSeverity.WARNING,
                    fix=lambda content: content,  # Handled by _apply_spacing_fixes
                )

    def _check_list_start_spacing(
        self, report: FileReport, line_num: int, prev_line_blank: bool
    ) -> None:
        """Check MD032: Lists should be surrounded by blank lines (start)."""
        if line_num > 1 and not prev_line_blank:
            self._add_issue(
                report,
                line_num,
                "Lists should be surrounded by blank lines (start)",
                "MD032",
                severity=IssueSeverity.WARNING,
                fix=lambda content: content,  # Handled by _apply_spacing_fixes
            )

    def _check_list_end_spacing(
        self, report: FileReport, last_list_line: int, lines: List[str]
    ) -> None:
        """Check MD032: Lists should be surrounded by blank lines (end)."""
        # Check if there's a line after the list and it's not blank
        next_line_idx = last_list_line  # 0-based index
        if next_line_idx < len(lines):
            next_line = lines[next_line_idx]
            if next_line.strip() and not self.BLANK_LINE_PATTERN.match(next_line):
                # Make sure the next line is not another list item
                if not self.LIST_ITEM_PATTERN.match(next_line):
                    self._add_issue(
                        report,
                        last_list_line + 1,
                        "Lists should be surrounded by blank lines (end)",
                        "MD032",
                        severity=IssueSeverity.WARNING,
                        fix=lambda content: content,  # Handled by _apply_spacing_fixes
                    )

    def _check_ordered_list_numbering(
        self,
        report: FileReport,
        line_num: int,
        actual_number: int,
        expected_number: int,
    ) -> None:
        """Check MD029: Ordered list item prefix should be sequential."""
        if actual_number != expected_number:
            # Create a fix function that captures the correct expected number
            def fix_ordered_number(line_content, expected=expected_number):
                # Preserve the original indentation
                match = re.match(r"^(\s*)\d+\.(.*)$", line_content)
                if match:
                    indent, rest = match.groups()
                    return f"{indent}{expected}.{rest}"
                return line_content

            # Create a closure to capture the expected number
            def fix_func(content):
                return fix_ordered_number(content, expected_number)

            self._add_issue(
                report,
                line_num,
                f"Ordered list item prefix [Expected: {expected_number}; Actual: {actual_number}]",
                "MD029",
                severity=IssueSeverity.WARNING,
                fix=fix_func,
            )

    def _check_fenced_code_block_start(
        self,
        report: FileReport,
        line_num: int,
        prev_line_blank: bool,
        match: re.Match,
    ) -> None:
        """Check MD031 and MD040 for fenced code block start."""
        # MD031: Check blank line before code block
        if line_num > 1 and not prev_line_blank:
            self._add_issue(
                report,
                line_num,
                self.MSG_FENCED_CODE_BLOCKS_SPACING,
                "MD031",
                severity=IssueSeverity.WARNING,
                fix=lambda content: content,  # Handled by _apply_spacing_fixes
            )

        # MD040: Check if language is specified
        language = match.group("language") if match else ""
        if not language.strip():

            def add_language_fix(line_content):
                return line_content.replace("```", "```text")

            self._add_issue(
                report,
                line_num,
                "Fenced code blocks should have a language specified",
                "MD040",
                severity=IssueSeverity.WARNING,
                fix=add_language_fix,
            )

    def _check_fenced_code_block_end(
        self, report: FileReport, line_num: int, lines: List[str]
    ) -> None:
        """Check MD031 for fenced code block end."""
        # MD031: Check blank line after code block
        next_line_idx = line_num  # 0-based index for next line
        if next_line_idx < len(lines):
            next_line = lines[next_line_idx]
            if next_line.strip() and not self.BLANK_LINE_PATTERN.match(next_line):
                self._add_issue(
                    report,
                    line_num + 1,
                    self.MSG_FENCED_CODE_BLOCKS_SPACING,
                    "MD031",
                    severity=IssueSeverity.WARNING,
                    fix=lambda content: content,  # Handled by _apply_spacing_fixes
                )

    def _check_duplicate_headings(
        self,
        report: FileReport,
        line_num: int,
        heading_content: str,
        seen_headings: set,
    ) -> None:
        """Check MD024: Multiple headings with the same content."""
        heading_text = heading_content.strip().lower()
        original_heading = heading_content.strip()

        if heading_text in seen_headings:
            # Find the next available number for this heading
            counter = 2
            while f"{heading_text} {counter}" in seen_headings:
                counter += 1

            new_heading_text = f"{heading_text} {counter}"
            new_heading_display = f"{original_heading} {counter}"

            def fix_duplicate_heading(line_content):
                # Extract level from line content
                level_match = re.match(r"^(#+)", line_content)
                level = level_match.group(1) if level_match else "#"
                return line_content.replace(
                    f"{level} {original_heading}", f"{level} {new_heading_display}"
                )

            self._add_issue(
                report,
                line_num,
                f"Multiple headings with the same content (auto-numbering to '{new_heading_display}')",
                "MD024",
                severity=IssueSeverity.WARNING,
                fix=fix_duplicate_heading,
            )

            # Add the new numbered heading to seen_headings
            seen_headings.add(new_heading_text)
        else:
            seen_headings.add(heading_text)

    def _get_url_title(self, url: str) -> str:
        """Get a title for a URL using AI or web scraping."""
        try:
            import re as regex_module

            import requests

            # Try to fetch the page title with size limit
            response = requests.get(
                url,
                timeout=(5, 10),  # (connection timeout, read timeout)
                headers={"User-Agent": "HomeLab-MarkdownLinter/1.0"},
                stream=True,
                allow_redirects=True,
                verify=True,  # Explicitly verify SSL certificates
            )
            response.raise_for_status()

            # Read only up to 1MB to prevent memory exhaustion
            content = ""
            max_size = 1024 * 1024  # 1MB limit
            bytes_read = 0
            for chunk in response.iter_content(chunk_size=8192, decode_unicode=True):
                if chunk is None:
                    continue
                content += chunk
                bytes_read += len(chunk)
                if bytes_read > max_size:
                    break
            response.close()

            # Extract title from HTML
            title_match = regex_module.search(
                r"<title[^>]*>([^<]+)</title>", content, regex_module.IGNORECASE
            )
            if title_match:
                title = title_match.group(1).strip()
                # Clean up the title
                title = regex_module.sub(r"\s+", " ", title)
                if len(title) > 100:
                    title = title[:97] + "..."
                return title

        except Exception:
            pass

        # Fallback: Generate a simple title from the URL
        try:
            from urllib.parse import urlparse

            parsed = urlparse(url)
            domain = parsed.netloc.replace("www.", "")
            path_parts = [p for p in parsed.path.split("/") if p]

            if path_parts:
                # Use the last meaningful path component
                last_part = path_parts[-1]
                if "." in last_part:
                    last_part = last_part.split(".")[0]
                title = last_part.replace("-", " ").replace("_", " ").title()
                return f"{title} - {domain}"
            else:
                return domain.title()

        except Exception:
            # Final fallback
            return "Link"

    def _check_list_item(self, report: FileReport, line_num: int, line: str) -> None:
        """Check list item formatting and indentation."""
        # Check for proper indentation (2 or 4 spaces)
        indent = len(line) - len(line.lstrip())
        if indent % 2 != 0 and indent > 0:
            self._add_issue(
                report,
                line_num,
                "List items should be indented with multiples of 2 spaces",
                "MD007",
                fix=lambda line: " " * (indent + 1) + line.lstrip(),
            )

    def _check_common_mistakes(
        self, report: FileReport, line_num: int, line: str
    ) -> None:
        """Check for common markdown mistakes."""
        if self.config["check_bare_urls"]:
            self._check_bare_urls(report, line_num, line)
            self._check_bare_emails(report, line_num, line)

        self._check_list_marker_spacing(report, line_num, line)

    def _check_bare_urls(self, report: FileReport, line_num: int, line: str) -> None:
        """Check for bare URLs and convert them to markdown links."""
        if not ("http://" in line or "https://" in line):
            return

        matches = re.finditer(self.BARE_URL_PATTERN, line)
        for match in matches:
            url = match.group(1)
            if self._is_url_already_linked(line, match.start()):
                continue

            # Create a fix function that fetches a proper title and creates a markdown link
            def create_url_fix(url_to_fix):
                def fix_url(line_content):
                    title = self._get_url_title(url_to_fix)
                    return line_content.replace(url_to_fix, f"[{title}]({url_to_fix})")

                return fix_url

            self._add_issue(
                report,
                line_num,
                "Bare URL used, converting to markdown link with title",
                "MD034",
                fix=create_url_fix(url),
            )

    def _check_bare_emails(self, report: FileReport, line_num: int, line: str) -> None:
        """Check for bare email addresses and convert them to angle bracket format."""
        if "@" not in line:
            return

        matches = re.finditer(self.EMAIL_PATTERN, line)
        for match in matches:
            email = match.group(1)
            if self._is_email_already_formatted(line, match.start(1)):
                continue

            # Create a fix function for email addresses
            def create_email_fix(email_to_fix):
                def fix_email(line_content):
                    # Use word boundaries to ensure exact match
                    pattern = r"\b" + re.escape(email_to_fix) + r"\b"
                    return re.sub(pattern, f"<{email_to_fix}>", line_content)

                return fix_email

            self._add_issue(
                report,
                line_num,
                "Bare email address used, converting to angle bracket format",
                "MD034",
                fix=create_email_fix(email),
            )

    def _check_list_marker_spacing(
        self, report: FileReport, line_num: int, line: str
    ) -> None:
        """Check for multiple spaces after list markers."""
        if re.match(r"^\s*[*+-]\s{2,}\S", line):
            self._add_issue(
                report,
                line_num,
                "Use a single space after list markers",
                "MD030",
                fix=lambda line: re.sub(r"^([*+-])\s+", r"\1 ", line),
            )

    def _is_url_already_linked(self, line: str, start_pos: int) -> bool:
        """Check if URL is already part of a markdown link."""
        return start_pos > 0 and (
            line[start_pos - 1 : start_pos + 2] == "](" or line[start_pos - 1] == "]"
        )

    def _is_email_already_formatted(self, line: str, start_pos: int) -> bool:
        """Check if email is already in a markdown link or angle brackets."""
        if start_pos == 0:
            return False
        return line[start_pos - 1] in "<[](" or (
            start_pos > 1 and line[start_pos - 2 : start_pos] == "]("
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
        lines = content.splitlines(keepends=False)

        # Separate different types of fixes
        line_fixes = [
            i
            for i in issues
            if i.fixable and i.line > 0 and i.code not in ["MD022", "MD032", "MD031"]
        ]
        spacing_fixes = [
            i for i in issues if i.fixable and i.code in ["MD022", "MD032", "MD031"]
        ]
        file_fixes = [i for i in issues if i.fixable and i.line == 0]

        # Apply line-level fixes first (sort descending to avoid offset issues)
        sorted_line_fixes = sorted(line_fixes, key=lambda x: x.line, reverse=True)
        for issue in sorted_line_fixes:
            if issue.fix and 0 < issue.line <= len(lines):
                line_idx = issue.line - 1
                lines[line_idx] = issue.fix(lines[line_idx])

        # Apply spacing fixes (requires more complex handling)
        lines = self._apply_spacing_fixes(lines, spacing_fixes)

        # Handle file-level fixes
        for issue in file_fixes:
            if issue.fix:
                # Apply to the entire content
                fixed_content = issue.fix("\n".join(lines))
                lines = fixed_content.splitlines(keepends=False)

        # Ensure lines end with newlines (except the last one which will be handled by file write)
        return [line + "\n" if not line.endswith("\n") else line for line in lines]

    def _apply_spacing_fixes(
        self, lines: List[str], spacing_issues: List[LintIssue]
    ) -> List[str]:
        """Apply MD022, MD032, and MD031 spacing fixes by inserting blank lines."""
        insertions = self._collect_spacing_insertions(lines, spacing_issues)
        unique_insertions = self._remove_duplicate_insertions(insertions)
        return self._apply_insertions(lines, unique_insertions)

    def _collect_spacing_insertions(
        self, lines: List[str], spacing_issues: List[LintIssue]
    ) -> List[tuple]:
        """Collect all blank line insertions needed for spacing fixes."""
        insertions = []  # List of (line_index, position) tuples

        for issue in spacing_issues:
            line_idx = issue.line - 1  # Convert to 0-based index

            if issue.code == "MD022":  # Heading spacing
                insertions.extend(self._get_heading_spacing_insertions(lines, line_idx))
            elif issue.code == "MD032":  # List spacing
                insertions.extend(
                    self._get_list_spacing_insertions(line_idx, issue.message)
                )
            elif issue.code == "MD031":  # Fenced code block spacing
                insertions.extend(
                    self._get_code_block_spacing_insertions(
                        lines, line_idx, issue.message
                    )
                )

        return insertions

    def _get_heading_spacing_insertions(
        self, lines: List[str], line_idx: int
    ) -> List[tuple]:
        """Get spacing insertions needed for headings."""
        insertions = []

        # Check if blank line needed before heading
        if line_idx > 0 and line_idx - 1 < len(lines):
            prev_line = lines[line_idx - 1]
            if prev_line.strip():  # Previous line is not blank
                insertions.append((line_idx, "before"))

        # Check if blank line needed after heading
        if line_idx + 1 < len(lines):
            next_line = lines[line_idx + 1]
            if next_line.strip() and not self.BLANK_LINE_PATTERN.match(next_line):
                insertions.append((line_idx + 1, "before"))  # Insert before next line

        return insertions

    def _get_list_spacing_insertions(self, line_idx: int, message: str) -> List[tuple]:
        """Get spacing insertions needed for lists."""
        insertions = []

        if "(start)" in message or "(end)" in message:
            # Add blank line before the list (start) or before the next content (end)
            insertions.append((line_idx, "before"))

        return insertions

    def _get_code_block_spacing_insertions(
        self, lines: List[str], line_idx: int, message: str
    ) -> List[tuple]:
        """Get spacing insertions needed for fenced code blocks."""
        insertions = []

        if self.MSG_FENCED_CODE_BLOCKS_SPACING in message:
            # Check if this is a start or end of code block
            if line_idx < len(lines) and lines[line_idx].strip().startswith("```"):
                # Check if previous line needs spacing (start of code block)
                if line_idx > 0 and lines[line_idx - 1].strip():
                    insertions.append((line_idx, "before"))
                # Check if next line needs spacing (end of code block)
                if line_idx + 1 < len(lines) and lines[line_idx + 1].strip():
                    insertions.append((line_idx + 1, "before"))

        return insertions

    def _remove_duplicate_insertions(self, insertions: List[tuple]) -> List[tuple]:
        """Remove duplicate insertions and sort them."""
        # Sort insertions by line index in descending order to avoid offset issues
        insertions.sort(key=lambda x: x[0], reverse=True)

        # Remove duplicates
        seen = set()
        unique_insertions = []
        for insertion in insertions:
            if insertion not in seen:
                seen.add(insertion)
                unique_insertions.append(insertion)

        return unique_insertions

    def _apply_insertions(self, lines: List[str], insertions: List[tuple]) -> List[str]:
        """Apply the collected insertions to the lines."""
        new_lines = lines[:]
        for line_idx, position in insertions:
            if position == "before" and 0 <= line_idx <= len(new_lines):
                # Insert blank line before the specified line
                new_lines.insert(line_idx, "")

        return new_lines

    def check_directory(
        self, directory: Union[str, Path], exclude: Optional[List[str]] = None
    ) -> Dict[Path, FileReport]:
        """Check all markdown files in a directory."""
        from .find_markdown_files import find_markdown_files

        directory = Path(directory).resolve()
        exclude = exclude or []

        # Find all markdown files
        files = find_markdown_files(
            directory,
            exclude_dirs={
                ".git",
                "node_modules",
                "__pycache__",
                ".pytest_cache",
                ".mypy_cache",
            },
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
