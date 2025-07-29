@echo off
REM Enhanced Markdown Linter Pre-commit Hook
REM Automatically fixes markdown issues and re-stages files
setlocal enabledelayedexpansion

REM Validate Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not available in PATH
    exit /b 1
)

REM Get repository root dynamically
for /f "delims=" %%i in ('git rev-parse --show-toplevel') do set "repo_root=%%i"

REM Change to the markdown linter directory
cd /d "%~dp0"

REM Initialize variables
set "files_modified=0"
set "temp_file=%TEMP%\markdown-lint-modified.txt"

REM Clear the temp file
if exist "%temp_file%" del "%temp_file%"

REM Process each file passed as argument
for %%f in (%*) do (
    echo Checking: %%f

    REM Calculate file hash before processing
    for /f %%i in ('certutil -hashfile "%%f" MD5 ^| find /v ":" ^| find /v "CertUtil"') do set "before_hash=%%i"

    REM Run markdown linter with --fix on the specific file
    python __main__.py "%%f" --fix

    REM Calculate file hash after processing
    for /f %%i in ('certutil -hashfile "%%f" MD5 ^| find /v ":" ^| find /v "CertUtil"') do set "after_hash=%%i"

    REM Check if file was modified
    if not "!before_hash!"=="!after_hash!" (
        echo File modified: %%f
        echo %%f >> "%temp_file%"
        set "files_modified=1"
    )
)

REM If files were modified, re-stage them
if "!files_modified!"=="1" (
    echo.
    echo Re-staging modified markdown files...

    REM Change back to repository root
    cd /d "!repo_root!"

    REM Re-stage each modified file
    for /f "tokens=*" %%a in ("%temp_file%") do (
        echo Staging: %%a
        git add "%%a"
        if errorlevel 1 (
            echo WARNING: Failed to stage %%a
        )
    )

    echo Modified files have been re-staged for commit.
    echo.
)

REM Clean up
if exist "%temp_file%" del "%temp_file%"

REM Always return success (0) so commit proceeds
exit /b 0
