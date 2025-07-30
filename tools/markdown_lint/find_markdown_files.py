"""Utility module for finding markdown files in directories."""

from pathlib import Path
from typing import List, Optional, Set, Union


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
    directory = Path(directory)
    exclude_dirs = exclude_dirs or set()
    exclude_files = exclude_files or []

    markdown_files = []
    markdown_extensions = {".md", ".markdown", ".mdown", ".mkd", ".mkdn"}

    def should_exclude_file(file_path: Path) -> bool:
        """Check if a file should be excluded based on exclude patterns."""
        file_name = file_path.name
        for pattern in exclude_files:
            if pattern in file_name or file_name.startswith(pattern):
                return True
        return False

    def should_exclude_dir(dir_path: Path) -> bool:
        """Check if a directory should be excluded."""
        return dir_path.name in exclude_dirs

    def scan_directory(current_dir: Path) -> None:
        """Recursively scan directory for markdown files."""
        try:
            for item in current_dir.iterdir():
                if item.is_file():
                    # Check if it's a markdown file
                    if item.suffix.lower() in markdown_extensions:
                        if not should_exclude_file(item):
                            markdown_files.append(item)
                elif item.is_dir():
                    # Recursively scan subdirectories if not excluded
                    if not should_exclude_dir(item):
                        scan_directory(item)
        except (PermissionError, OSError):
            # Skip directories we can't access
            pass

    if directory.exists() and directory.is_dir():
        scan_directory(directory)

    # Sort files for consistent ordering
    return sorted(markdown_files)
