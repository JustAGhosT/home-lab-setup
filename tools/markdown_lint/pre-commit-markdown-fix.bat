@echo off
REM Enhanced Markdown Linter Pre-commit Hook
REM Automatically fixes markdown issues and re-stages files
setlocal enabledelayedexpansion

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

    REM Get file modification time before processing
    for %%i in ("%%f") do set "before_time=%%~ti"

    REM Run markdown linter with --fix on the specific file
    python __main__.py "%%f" --fix

    REM Get file modification time after processing
    for %%i in ("%%f") do set "after_time=%%~ti"

    REM Check if file was modified
    if not "!before_time!"=="!after_time!" (
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
    cd /d "%~dp0..\.."

    REM Re-stage each modified file
    for /f "tokens=*" %%a in (%temp_file%) do (
        echo Staging: %%a
        git add "%%a"
    )

    echo Modified files have been re-staged for commit.
    echo.
)

REM Clean up
if exist "%temp_file%" del "%temp_file%"

REM Always return success (0) so commit proceeds
exit /b 0
