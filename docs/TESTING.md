# Testing Guide

This guide explains how to run tests, understand test results, and contribute to the test suite for the HomeLab project.

## Overview

The HomeLab project uses **Pester 5.0+** as the testing framework with three types of tests:

- **Unit Tests**: Test individual functions and modules in isolation
- **Integration Tests**: Test interactions between components
- **Workflow Tests**: Test end-to-end scenarios and user workflows

## Quick Start

### Running All Tests

```powershell
cd tests
./Run-HomeLab-Tests.ps1
```

### Running Specific Test Types

```powershell
# Unit tests only (fastest)
./Run-HomeLab-Tests.ps1 -TestType Unit

# Integration tests only
./Run-HomeLab-Tests.ps1 -TestType Integration

# Workflow tests only
./Run-HomeLab-Tests.ps1 -TestType Workflow
```

### Generate HTML Report

```powershell
./Run-HomeLab-Tests.ps1 -GenerateReport
```

### Run with Code Coverage

```powershell
./Run-HomeLab-Tests.ps1 -Coverage -GenerateReport
```

## Test Structure

```
tests/
├── unit/                    # Unit tests
│   ├── HomeLab.Core.tests.ps1
│   ├── HomeLab.Azure.tests.ps1
│   └── ...
├── integration/             # Integration tests
│   ├── VPN-Integration.tests.ps1
│   ├── DNS-Integration.tests.ps1
│   └── ...
├── workflow/               # End-to-end workflow tests
│   ├── Website-Deployment.tests.ps1
│   ├── VPN-Setup.tests.ps1
│   └── ...
├── Run-HomeLab-Tests.ps1   # Main test runner
└── TestResults.xml         # Generated test results
```

## Test Categories

### Unit Tests
- Test individual PowerShell functions
- Mock external dependencies (Azure APIs, file system)
- Fast execution (< 1 second per test)
- No external dependencies required

### Integration Tests
- Test component interactions
- May require Azure resources or network access
- Moderate execution time (1-10 seconds per test)
- Use test-specific Azure resources when possible

### Workflow Tests
- Test complete user scenarios
- Simulate real-world usage patterns
- Longer execution time (10+ seconds per test)
- May use mocked services for consistency

## Writing Tests

### Unit Test Example

```powershell
Describe "Get-HomeLabConfiguration" {
    Context "When configuration file exists" {
        It "Should return valid configuration object" {
            # Arrange
            Mock Test-Path { $true }
            Mock Get-Content { '{"environment":"dev"}' }

            # Act
            $result = Get-HomeLabConfiguration
            
            # Assert
            $result.environment | Should -Be "dev"
        }
    }
}
```

### Integration Test Example

```powershell
Describe "VPN Gateway Integration" {
    Context "When deploying VPN Gateway" {
        It "Should create gateway successfully" {
            # Arrange
            $resourceGroup = "test-rg-$(Get-Random)"
            
            # Act
            $result = Deploy-VPNGateway -ResourceGroup $resourceGroup
            
            # Assert
            $result.Status | Should -Be "Succeeded"
            
            # Cleanup
            Remove-AzResourceGroup -Name $resourceGroup -Force
        }
    }
}
```

## Test Configuration

### Environment Variables

Set these environment variables for testing:

```powershell
$env:HOMELAB_TEST_MODE = "true"
$env:HOMELAB_TEST_SUBSCRIPTION = "your-test-subscription-id"
$env:HOMELAB_TEST_RESOURCE_GROUP = "homelab-test-rg"
```

### Test Settings

Configure test behavior in `tests/test-config.json`:

```json
{
    "skipIntegrationTests": false,
    "testSubscriptionId": "test-subscription-id",
    "testResourceGroupPrefix": "homelab-test",
    "cleanupAfterTests": true,
    "maxTestDuration": 300
}
```

## Continuous Integration

### GitHub Actions

Tests run automatically on:
- Pull requests to `main` branch
- Pushes to `main` branch
- Manual workflow dispatch

### Test Results

- Test results are uploaded as artifacts
- HTML reports are generated for failed runs
- Code coverage reports are available for coverage runs

## Troubleshooting Tests

### Common Issues

**Pester Module Not Found**
```powershell
Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck
```

**Azure Authentication Failures**
```powershell
Connect-AzAccount
Set-AzContext -SubscriptionId "your-subscription-id"
```

**Test Timeouts**
- Increase timeout values in test configuration
- Check Azure service availability
- Verify network connectivity

### Debug Mode

Run tests with verbose output:

```powershell
./Run-HomeLab-Tests.ps1 -Verbose
```

### Test Isolation

Each test should:
- Clean up resources it creates
- Not depend on other tests
- Use unique resource names
- Handle cleanup in `AfterEach` or `AfterAll` blocks

## Best Practices

### Test Naming
- Use descriptive test names
- Follow "Should [expected behavior] when [condition]" pattern
- Group related tests in `Context` blocks

### Mocking
- Mock external dependencies in unit tests
- Use `Mock` for PowerShell cmdlets
- Verify mock calls with `Should -Invoke`

### Assertions
- Use specific assertions (`Should -Be`, `Should -Contain`)
- Test both positive and negative cases
- Include edge cases and error conditions

### Performance
- Keep unit tests fast (< 1 second)
- Use `BeforeAll` for expensive setup
- Clean up resources promptly

## Contributing Tests

### Adding New Tests

1. Create test file in appropriate directory
2. Follow existing naming conventions
3. Include both positive and negative test cases
4. Add appropriate mocking for external dependencies
5. Update this documentation if needed

### Test Review Checklist

- [ ] Tests are in correct directory
- [ ] Test names are descriptive
- [ ] External dependencies are mocked
- [ ] Resources are cleaned up
- [ ] Edge cases are covered
- [ ] Tests run independently

## Test Metrics

Current test coverage targets:
- **Unit Tests**: > 80% code coverage
- **Integration Tests**: All major workflows covered
- **Workflow Tests**: All user scenarios tested

## Support

For testing issues:
1. Check this documentation
2. Review existing test examples
3. Open an issue in the GitHub repository
4. Contact the development team

## Related Documentation

- [Development Guide](DEVELOPMENT.md)
- [GitHub Integration](GITHUB-INTEGRATION.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)