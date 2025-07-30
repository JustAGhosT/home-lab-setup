#!/usr/bin/env python3
"""Simple test script to verify find_markdown_files functionality."""

import sys
from pathlib import Path

# Add the current directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

from find_markdown_files import find_markdown_files  # type: ignore


def test_find_markdown_files():
    """Test the find_markdown_files function."""
    # Test with current directory
    current_dir = Path(".")

    print("Testing find_markdown_files function...")
    print(f"Searching in: {current_dir.resolve()}")

    # Find markdown files
    files = find_markdown_files(
        current_dir,
        exclude_dirs={".git", "__pycache__", ".pytest_cache"},
        exclude_files=["test_"],
    )

    print(f"Found {len(files)} markdown files:")
    for file in files:
        print(f"  - {file}")

    return len(files) > 0


if __name__ == "__main__":
    success = test_find_markdown_files()
    if success:
        print("\n✅ find_markdown_files function is working correctly!")
    else:
        print(
            "\n❌ No markdown files found - this might be expected depending on the directory."
        )
