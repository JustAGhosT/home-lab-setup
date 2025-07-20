# HomeLab Unit Tests

This directory contains unit tests for the HomeLab PowerShell modules.

## Test Files

- **HomeLab.Azure.tests.ps1**: Tests for the Azure module functions
- **HomeLab.Core.tests.ps1**: Tests for the Core module functions
- **HomeLab.Azure.Mock.ps1**: Mock functions for the Azure module
- **HomeLab.Core.Mock.ps1**: Mock functions for the Core module
- **Run-UnitTests.ps1**: Script to run all unit tests

## Prerequisites

To run these tests, you need:

1. PowerShell 7.2 or higher
2. Pester module (will be installed automatically by Run-UnitTests.ps1 if not present)

## Running the Tests

To run all unit tests, execute the following command from the unit tests directory:

```powershell
.\Run-UnitTests.ps1
```

## Test Coverage

These tests cover:

1. **Azure Resource Deployment**: Tests for creating and managing Azure resources
2. **VPN Gateway Management**: Tests for enabling, disabling, and checking VPN Gateway state
3. **NAT Gateway Management**: Tests for enabling and disabling NAT Gateway
4. **Azure Resource Validation**: Tests for validating resource group existence and resource name format
5. **Configuration Management**: Tests for managing HomeLab configuration
6. **Path Validation**: Tests for validating file paths
7. **Utility Functions**: Tests for utility functions like logging and object conversion

## Mock Functions

The tests use mock functions to simulate the behavior of the actual HomeLab modules without requiring actual Azure resources. This allows the tests to run quickly and consistently without depending on external services.

## Adding New Tests

To add new tests:

1. Create a new PowerShell script with the `.tests.ps1` extension
2. Use the Pester testing framework syntax
3. Create mock functions if needed
4. Run the tests using `.\Run-UnitTests.ps1`

## Test Structure

Each test file follows the Pester testing framework structure:

```powershell
Describe "Test Suite Name" {
    BeforeAll {
        # Setup code
    }
    
    Context "Test Context" {
        It "Should do something" {
            # Test code
            $result | Should -Be $expected
        }
    }
    
    AfterAll {
        # Cleanup code
    }
}
```