#!/usr/bin/env python3
"""
Enhanced Markdown Linter Pre-commit Hook (Python)
Automatically fixes markdown issues and re-stages files
"""

import hashlib
import subprocess
import sys
from pathlib import Path


def get_file_hash(file_path):
    """Get SHA-256 hash of a file."""
    try:
        hash_sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            # Read file in chunks to handle large files safely
            for chunk in iter(lambda: f.read(8192), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    except (OSError, IOError):
        return None


def _get_repo_root():
    """
    Get the repository root directory.

    First attempts to use Git command to find the repo root dynamically.
    If Git is not available or the command fails, falls back to using
    the script directory's grandparent as the repo root.

    Returns:
        Path: The repository root directory
    """
    try:
        # Try to get repo root using Git command
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
            timeout=5,
        )
        repo_root = Path(result.stdout.strip())
        if repo_root.exists():
            return repo_root
    except (
        subprocess.CalledProcessError,
        FileNotFoundError,
        subprocess.TimeoutExpired,
    ):
        # Git command failed, fall back to script directory logic
        pass

    # Fallback: assume repo root is two levels up from script directory
    # This works when the hook is in tools/markdown_lint/ relative to repo root
    script_dir = Path(__file__).parent
    fallback_root = script_dir.parent.parent

    return fallback_root


def _validate_environment():
    """Validate Python and linter availability."""
    try:
        subprocess.run([sys.executable, "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("ERROR: Python is not available")
        return False

    linter_script = Path(__file__).parent / "__main__.py"
    if not linter_script.exists():
        print(f"ERROR: Markdown linter module not found: {linter_script}")
        return False

    return True


def _process_file(file_path, full_path, linter_script, linter_dir):
    """Process a single file and return True if modified."""
    print(f"Checking: {file_path}")

    before_hash = get_file_hash(full_path)
    if before_hash is None:
        print(f"WARNING: Could not read file: {file_path}")
        return False

    try:
        result = subprocess.run(
            [sys.executable, str(linter_script), str(full_path), "--fix"],
            capture_output=True,
            text=True,
            cwd=linter_dir,
        )

        if result.returncode == 0:
            after_hash = get_file_hash(full_path)
            if before_hash != after_hash:
                print("  -> File modified and fixed")
                return True
            else:
                print("  -> No changes needed")
                return False
        else:
            print(f"WARNING: Markdown linter failed for {file_path}: {result.stderr}")
            return False
    except Exception as e:
        print(f"WARNING: Error processing {file_path}: {e}")
        return False


def _stage_files(modified_files, repo_root):
    """Stage modified files with git."""
    print(f"\nRe-staging {len(modified_files)} modified file(s)...")

    for file_path in modified_files:
        try:
            print(f"  Staging: {file_path}")
            result = subprocess.run(
                ["git", "add", file_path], capture_output=True, text=True, cwd=repo_root
            )
            if result.returncode != 0:
                print(f"WARNING: Failed to stage {file_path}: {result.stderr}")
        except Exception as e:
            print(f"WARNING: Error staging {file_path}: {e}")


def main():
    """Main entry point for the pre-commit hook."""
    if len(sys.argv) < 2:
        print("No markdown files to process")
        return 0

    if not _validate_environment():
        return 1

    files = sys.argv[1:]
    script_dir = Path(__file__).parent
    repo_root = _get_repo_root()
    linter_script = script_dir / "__main__.py"

    modified_files = []
    files_processed = 0

    print("Enhanced Markdown Linter - Pre-commit Hook")
    print(f"Processing {len(files)} markdown file(s)...")

    for file_path in files:
        full_path = (
            Path(file_path) if Path(file_path).is_absolute() else repo_root / file_path
        )

        if not full_path.exists():
            print(f"WARNING: File not found: {file_path}")
            continue

        if _process_file(file_path, full_path, linter_script, script_dir):
            modified_files.append(file_path)

        files_processed += 1

    if modified_files:
        _stage_files(modified_files, repo_root)
        print("\n[SUCCESS] Modified files have been re-staged for commit.")
    else:
        print("\n[SUCCESS] No files needed modification.")

    print(f"Processed {files_processed} file(s), modified {len(modified_files)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
