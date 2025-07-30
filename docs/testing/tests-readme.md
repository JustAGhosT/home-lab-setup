# Azure Deployment Workflow Tests

This directory contains tests for the Azure deployment workflow used in the HomeLab setup.

## Test Files

- **deploy-azure.tests.ps1**: Tests the structure and configuration of the GitHub Actions workflow file
- **workflow-inputs.tests.ps1**: Tests the input validation and resource name generation logic
- **azure-commands.tests.ps1**: Tests the Azure CLI commands used in the workflow
- **deploy-workflow.tests.ps1**: Tests the end-to-end deployment workflow
- **Run-Tests.ps1**: Script to run all tests

## Prerequisites

To run these tests, you need:

1. PowerShell 7.2 or higher
2. Pester module (will be installed automatically by Run-Tests.ps1 if not present)
3. PowerShell-Yaml module (will be installed automatically by Run-Tests.ps1 if not present)

## Running the Tests

To run all tests, execute the following command from the tests directory:

```powershell
.\Run-Tests.ps1
```

## Test Coverage

These tests cover:

1. **Workflow Structure**: Validates the GitHub Actions workflow file structure and configuration
2. **Input Validation**: Tests the input validation and resource name generation logic
3. **Deployment Type Detection**: Tests the auto-detection of deployment type based on project files
4. **Azure Commands**: Tests the Azure CLI commands used for resource creation and configuration
5. **End-to-End Flow**: Tests the complete deployment workflow for both static websites and app services

## Adding New Tests

To add new tests:

1. Create a new PowerShell script with the `.tests.ps1` extension
2. Use the Pester testing framework syntax
3. Run the tests using `.\Run-Tests.ps1`

## Test Structure

Each test file follows the Pester testing framework structure:

```powershell
Describe "Test Suite Name" {
    Context "Test Context" {
        BeforeAll {
            # Setup code
        }
        
        It "Should do something" {
            # Test code
            $result | Should -Be $expected
        }
        
        AfterAll {
            # Cleanup code
        }
    }
}
```