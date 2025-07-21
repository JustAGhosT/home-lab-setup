import pytest
import asyncio
from unittest.mock import AsyncMock, patch, MagicMock

from autopr.actions.run_homelab_tests import RunHomelabTests, Inputs, Outputs


@pytest.mark.asyncio
async def test_run_homelab_tests_success():
    # Mock the subprocess
    mock_process = AsyncMock()
    mock_process.returncode = 0
    mock_process.communicate.return_value = (
        b"""
        Running Unit Tests...
        Test Results Summary:
        Total Tests: 42
        Passed: 42
        Failed: 0
        Skipped: 0
        
        Report generated at: C:\\tests\\TestReport.html
        
        All tests passed!
        """,
        b""
    )
    
    # Create the action
    action = RunHomelabTests()
    
    # Mock the subprocess creation
    with patch('asyncio.create_subprocess_exec', return_value=mock_process):
        # Run the action
        result = await action.run(Inputs(
            test_type="Unit",
            coverage=True,
            generate_report=True
        ))
    
    # Verify the results
    assert result.success is True
    assert result.total_tests == 42
    assert result.passed_tests == 42
    assert result.failed_tests == 0
    assert result.skipped_tests == 0
    assert result.pass_rate == 100.0
    assert "C:\\tests\\TestReport.html" in result.report_path


@pytest.mark.asyncio
async def test_run_homelab_tests_failure():
    # Mock the subprocess
    mock_process = AsyncMock()
    mock_process.returncode = 1
    mock_process.communicate.return_value = (
        b"""
        Running Unit Tests...
        Test Results Summary:
        Total Tests: 42
        Passed: 40
        Failed: 2
        Skipped: 0
        
        Failed Tests:
        - Test1: Error message
        - Test2: Another error message
        """,
        b"Error: Test execution failed"
    )
    
    # Create the action
    action = RunHomelabTests()
    
    # Mock the subprocess creation
    with patch('asyncio.create_subprocess_exec', return_value=mock_process):
        # Run the action
        result = await action.run(Inputs(
            test_type="All",
            coverage=False,
            generate_report=False
        ))
    
    # Verify the results
    assert result.success is False
    assert result.total_tests == 42
    assert result.passed_tests == 40
    assert result.failed_tests == 2
    assert result.skipped_tests == 0
    assert result.pass_rate == 95.23809523809524  # 40/42 * 100
    assert "Error: Test execution failed" in result.test_results