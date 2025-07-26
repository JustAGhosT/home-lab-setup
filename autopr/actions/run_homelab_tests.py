import asyncio
import os
import pydantic
import re
import shlex
from typing import Optional, List, Dict

from .base import Action  # type: ignore


from pydantic import field_validator

class Inputs(pydantic.BaseModel):
    """Inputs for the RunHomelabTests action."""
    test_type: str = "All"  # Unit, Integration, Workflow, or All
    coverage: bool = False
    generate_report: bool = True
    test_path: Optional[str] = None  # Optional specific test path
    fix_issues: bool = False  # Whether to attempt to fix common issues

    @field_validator('test_type')
    def validate_test_type(cls, v):
        allowed_values = ["Unit", "Integration", "Workflow", "All"]
        if v not in allowed_values:
            raise ValueError(f"test_type must be one of {allowed_values}")
        return v

class FailedTest(pydantic.BaseModel):
    """Details about a failed test."""
    name: str
    error_message: str


class Outputs(pydantic.BaseModel):
    """Outputs from the RunHomelabTests action."""
    success: bool
    total_tests: int
    passed_tests: int
    failed_tests: int
    skipped_tests: int
    pass_rate: float
    test_results: str
    report_path: Optional[str] = None
    failed_test_details: List[FailedTest] = []
    issues_fixed: bool = False
    fix_details: Optional[str] = None


class RunHomelabTests(Action[Inputs, Outputs]):
    """
    Run Azure HomeLab tests using PowerShell and return the results.
    
    This action executes the HomeLab test runner script with the specified parameters
    and returns the test results. It can also attempt to fix common issues if requested.
    """

    id = "run-homelab-tests"

    async def run(self, inputs: Inputs) -> Outputs:
        # Construct the PowerShell command
        tests_dir = os.path.join(os.environ.get('GITHUB_WORKSPACE', '.'), 'tests')
        script_path = os.path.join(tests_dir, 'Run-HomeLab-Tests.ps1')
        
        cmd = [
            "pwsh",
            "-Command",
            f"cd {shlex.quote(tests_dir)}; "
            f".{os.sep}Run-HomeLab-Tests.ps1 "
            f"-TestType {shlex.quote(inputs.test_type)} "
        ]
        
        if inputs.coverage:
            cmd[-1] += "-Coverage "
            
        if inputs.generate_report:
            cmd[-1] += "-GenerateReport "
            
        if inputs.test_path:
            cmd[-1] += f"-Path {shlex.quote(inputs.test_path)} "
            
        # Run the PowerShell command
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        
        stdout, stderr = await process.communicate()
        stdout_text = stdout.decode("utf-8")
        stderr_text = stderr.decode("utf-8")
        
        # Parse the test results
        success = process.returncode == 0
        
        # Default values in case parsing fails
        total_tests = 0
        passed_tests = 0
        failed_tests = 0
        skipped_tests = 0
        pass_rate = 0.0
        report_path = None
        failed_test_details = []
        issues_fixed = False
        fix_details = None
        
        # Extract test results from stdout
        for line in stdout_text.splitlines():
            if "Total Tests:" in line:
                try:
                    total_tests = int(line.split(":")[-1].strip())
                except ValueError:
                    pass
            elif "Passed:" in line:
                try:
                    passed_tests = int(line.split(":")[-1].strip())
                except ValueError:
                    pass
            elif "Failed:" in line:
                try:
                    failed_tests = int(line.split(":")[-1].strip())
                except ValueError:
                    pass
            elif "Skipped:" in line:
                try:
                    skipped_tests = int(line.split(":")[-1].strip())
                except ValueError:
                    pass
            elif "Report generated at:" in line:
                # Handle paths with colons (e.g., C:\path\to\report.html)
                report_path = line.split("Report generated at:", 1)[-1].strip()
        
        # Extract failed test details
        failed_tests_section = False
        current_test = None
        current_error = ""
        
        for line in stdout_text.splitlines():
            if "Failed Tests:" in line:
                failed_tests_section = True
                continue
                
            if failed_tests_section:
                if line.strip().startswith("-") and ": " in line:
                    # Save previous test if there was one
                    if current_test:
                        failed_test_details.append(FailedTest(
                            name=current_test,
                            error_message=current_error.strip()
                        ))
                    
                    # Start new test
                    parts = line.strip().split(": ", 1)
                    current_test = parts[0].strip("- ")
                    current_error = parts[1] if len(parts) > 1 else ""
                elif current_test and line.strip():
                    current_error += "\n" + line.strip()
        
        # Add the last test if there was one
        if current_test:
            failed_test_details.append(FailedTest(
                name=current_test,
                error_message=current_error.strip()
            ))
        
        # Look for CommandNotFoundException errors
        command_not_found_match = re.search(r"CommandNotFoundException: Could not find Command ([\w-]+)", stdout_text)
        if command_not_found_match and inputs.fix_issues:
            missing_command = command_not_found_match.group(1)
            fix_details = f"Attempted to fix missing command: {missing_command}\n"
            
            # Try to fix the issue
            if missing_command == "Get-CertificatePath":
                # Create the missing function
                fix_cmd = [
                    "pwsh",
                    "-Command",
                    f"$functionContent = @'"
                    f"function Get-CertificatePath {{"
                    f"    [CmdletBinding()]"
                    f"    param()"
                    f"    "
                    f"    # Check if the VpnCertificatesPath variable is defined"
                    f"    if (Get-Variable -Name VpnCertificatesPath -ErrorAction SilentlyContinue) {{"
                    f"        return $VpnCertificatesPath"
                    f"    }}"
                    f"    "
                    f"    # Default path if variable is not set"
                    f"    $defaultPath = Join-Path -Path $env:USERPROFILE -ChildPath \"HomeLab\\Certificates\""
                    f"    "
                    f"    # Create the directory if it doesn't exist"
                    f"    if (-not (Test-Path -Path $defaultPath)) {{"
                    f"        New-Item -Path $defaultPath -ItemType Directory -Force | Out-Null"
                    f"    }}"
                    f"    "
                    f"    return $defaultPath"
                    f"}}"
                    f"'@"
                    f"$publicPath = Join-Path -Path $env:GITHUB_WORKSPACE -ChildPath 'HomeLab\\modules\\HomeLab.Security\\Public'"
                    f"$filePath = Join-Path -Path $publicPath -ChildPath 'Get-CertificatePath.ps1'"
                    f"Set-Content -Path $filePath -Value $functionContent"
                    f"Write-Host \"Created missing function: Get-CertificatePath at $filePath\""
                ]
                
                fix_process = await asyncio.create_subprocess_exec(
                    *fix_cmd,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE,
                )
                
                fix_stdout, fix_stderr = await fix_process.communicate()
                fix_stdout_text = fix_stdout.decode("utf-8")
                fix_stderr_text = fix_stderr.decode("utf-8")
                
                if fix_process.returncode == 0:
                    issues_fixed = True
                    fix_details += fix_stdout_text
                else:
                    fix_details += f"Failed to fix issue: {fix_stderr_text}"
        
        # Calculate pass rate
        if total_tests > 0:
            pass_rate = (passed_tests / total_tests) * 100
        
        # Combine stdout and stderr for the test_results
        test_results = stdout_text
        if stderr_text:
            test_results += f"\n\nErrors:\n{stderr_text}"
        
        return Outputs(
            success=success,
            total_tests=total_tests,
            passed_tests=passed_tests,
            failed_tests=failed_tests,
            skipped_tests=skipped_tests,
            pass_rate=pass_rate,
            test_results=test_results,
            report_path=report_path,
            failed_test_details=failed_test_details,
            issues_fixed=issues_fixed,
            fix_details=fix_details
        )


# When you run this file
if __name__ == "__main__":
    from ..tests.utils import run_action_manually  # type: ignore
    asyncio.run(
        # Run the action manually
        run_action_manually(
            action=RunHomelabTests,
            inputs=Inputs(
                test_type="Unit",
                coverage=True,
                generate_report=True,
                fix_issues=True
            ),
        )
    )