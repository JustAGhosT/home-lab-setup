"""Data models for the markdown linter."""

from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional


class IssueSeverity(Enum):
    """Severity levels for linting issues."""

    ERROR = auto()
    WARNING = auto()
    STYLE = auto()


@dataclass
class LintIssue:
    """Represents a single linting issue."""

    line: int
    column: int = 0
    code: str = ""
    message: str = ""
    severity: IssueSeverity = IssueSeverity.WARNING
    fixable: bool = False
    fix: Optional[Callable[[str], str]] = None
    context: str = ""

    def __str__(self) -> str:
        """Return a string representation of the issue."""
        return f"{self.severity.name}:{self.code} - {self.message} (line {self.line}, col {self.column})"


@dataclass
class FileReport:
    """Collection of lint issues for a single file."""

    path: Path
    issues: List[LintIssue] = field(default_factory=list)
    fixed_content: Optional[List[str]] = None

    @property
    def has_issues(self) -> bool:
        """Return True if there are any issues."""
        return bool(self.issues)

    @property
    def has_errors(self) -> bool:
        """Return True if there are any error-level issues."""
        return any(issue.severity == IssueSeverity.ERROR for issue in self.issues)

    @property
    def has_warnings(self) -> bool:
        """Return True if there are any warning-level issues."""
        return any(issue.severity == IssueSeverity.WARNING for issue in self.issues)

    @property
    def has_fixable_issues(self) -> bool:
        """Return True if there are any fixable issues."""
        return any(issue.fixable for issue in self.issues)

    def add_issue(self, issue: LintIssue) -> None:
        """Add an issue to the report."""
        self.issues.append(issue)

    def get_issues_by_severity(self, severity: IssueSeverity) -> List[LintIssue]:
        """Get all issues with the given severity."""
        return [issue for issue in self.issues if issue.severity == severity]
