"""Utility module for finding markdown files in directories."""

from pathlib import Path
from typing import Iterator, List, Optional, Set, Union

# Constants
MARKDOWN_EXTENSIONS = {".md", ".markdown", ".mdown", ".mkd", ".mkdn"}


def _is_markdown_file(file_path: Path) -> bool:
    """Check if a file is a markdown file based on its extension."""
    return file_path.suffix.lower() in MARKDOWN_EXTENSIONS


def _matches_exclude_pattern(file_name: str, patterns: List[str]) -> bool:
    """Check if a filename matches any exclude pattern."""
    return any(
        pattern in file_name or file_name.startswith(pattern) for pattern in patterns
    )


def _should_exclude_file(file_path: Path, exclude_patterns: List[str]) -> bool:
    """Determine if a file should be excluded."""
    return _matches_exclude_pattern(file_path.name, exclude_patterns)


def _should_exclude_directory(dir_path: Path, exclude_dirs: Set[str]) -> bool:
    """Determine if a directory should be excluded."""
    return dir_path.name in exclude_dirs


def _get_accessible_items(directory: Path) -> Iterator[Path]:
    """Get items from directory, handling permission errors gracefully."""
    try:
        yield from directory.iterdir()
    except OSError:
        # Skip directories we can't access
        return


def _process_file(file_path: Path, exclude_patterns: List[str]) -> Optional[Path]:
    """Process a single file and return it if it's a valid markdown file."""
    if not _is_markdown_file(file_path):
        return None

    if _should_exclude_file(file_path, exclude_patterns):
        return None

    return file_path


def _collect_markdown_files(
    directory: Path, exclude_dirs: Set[str], exclude_files: List[str]
) -> List[Path]:
    """Collect markdown files from directory and subdirectories."""
    markdown_files = []
    directories_to_scan = [directory]

    while directories_to_scan:
        current_dir = directories_to_scan.pop()

        for item in _get_accessible_items(current_dir):
            if item.is_file():
                markdown_file = _process_file(item, exclude_files)
                if markdown_file:
                    markdown_files.append(markdown_file)
            elif item.is_dir() and not _should_exclude_directory(item, exclude_dirs):
                directories_to_scan.append(item)

    return markdown_files


def find_markdown_files(
    directory: Union[str, Path],
    exclude_dirs: Optional[Set[str]] = None,
    exclude_files: Optional[List[str]] = None,
) -> List[Path]:
    """
    Find all markdown files in a directory and its subdirectories.

    Args:
        directory: The directory to search in
        exclude_dirs: Set of directory names to exclude from search
        exclude_files: List of file patterns to exclude

    Returns:
        List of Path objects for found markdown files
    """
    directory_path = Path(directory)
    exclude_dirs = exclude_dirs or set()
    exclude_files = exclude_files or []

    if not (directory_path.exists() and directory_path.is_dir()):
        return []

    markdown_files = _collect_markdown_files(
        directory_path, exclude_dirs, exclude_files
    )
    return sorted(markdown_files)
