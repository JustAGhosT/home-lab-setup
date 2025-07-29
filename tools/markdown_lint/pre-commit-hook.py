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
    """Get MD5 hash of a file."""
    try:
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            # Read file in chunks to handle large files safely
            for chunk in iter(lambda: f.read(8192), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    except (OSError, IOError):
        return None


def main():
    """Main entry point for the pre-commit hook."""
    if len(sys.argv) < 2:
        print("No markdown files to process")
        return 0

    # Validate Python is available
    try:
        subprocess.run([sys.executable, "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("ERROR: Python is not available")
        return 1

    files = sys.argv[1:]
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent.parent
    linter_dir = script_dir
    
    # Validate linter module exists
    linter_script = linter_dir / "__main__.py"
    if not linter_script.exists():
        print(f"ERROR: Markdown linter module not found: {linter_script}")
        return 1

    modified_files = []
    files_processed = 0

    print("Enhanced Markdown Linter - Pre-commit Hook")
    print(f"Processing {len(files)} markdown file(s)...")

    for file_path in files:
        # Resolve the full path relative to repo root
        if Path(file_path).is_absolute():
            full_path = Path(file_path)
        else:
            full_path = repo_root / file_path

        if not full_path.exists():
            print(f"WARNING: File not found: {file_path}")
            continue

        print(f"Checking: {file_path}")

        # Get file hash before processing
        before_hash = get_file_hash(full_path)
        if before_hash is None:
            print(f"WARNING: Could not read file: {file_path}")
            continue

        # Run markdown linter with --fix
        try:
            result = subprocess.run(
                [sys.executable, str(linter_script), str(full_path), "--fix"],
                capture_output=True,
                text=True,
                cwd=linter_dir,
            )

            if result.returncode == 0:
                # Get file hash after processing
                after_hash = get_file_hash(full_path)

                # Check if file was actually modified
                if before_hash != after_hash:
                    print("  -> File modified and fixed")
                    # Store the original relative path for git add
                    modified_files.append(file_path)
                else:
                    print("  -> No changes needed")
            else:
                print(f"WARNING: Markdown linter failed for {file_path}: {result.stderr}")

        except Exception as e:
            print(f"WARNING: Error processing {file_path}: {e}")

        files_processed += 1

    # Re-stage modified files if any
    if modified_files:
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

        print("\n[SUCCESS] Modified files have been re-staged for commit.")
    else:
        print("\n[SUCCESS] No files needed modification.")

    print(f"Processed {files_processed} file(s), modified {len(modified_files)}")

    # Always return success so commit proceeds
    return 0


if __name__ == "__main__":
    sys.exit(main())
