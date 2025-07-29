# HomeLab Testing Implementation

This document describes the implementation of the HomeLab testing strategy as outlined in [TESTING-STRATEGY-DETAILED.md](../TESTING-STRATEGY-DETAILED.md).

## Test Structure

The HomeLab testing implementation follows a three-tier approach:

1. **Unit Tests**: Testing individual PowerShell functions in isolation
2. **Integration Tests**: Testing interactions between modules and with Azure APIs
3. **Workflow Tests**: Testing end-to-end workflows and user scenarios

## Test Files

### Main Test Runner

- **Run-HomeLab-Tests.ps1**: Main test runner script that implements the testing strategy

### Unit Tests

- **HomeLab.Core.tests.ps1**: Tests for the Core module functions
- **HomeLab.Azure.tests.ps1**: Tests for the Azure module functions
- **HomeLab.Security.tests.ps1**: Tests for the Security module functions
- **HomeLab.Web.tests.ps1**: Tests for the Web module functions (to be implemented)
- **HomeLab.DNS.tests.ps1**: Tests for the DNS module functions (to be implemented)

### Integration Tests

- **Module-Integration.tests.ps1**: Tests for interactions between modules
- **Azure-Integration.tests.ps1**: Tests for interactions with Azure APIs (to be implemented)
- **Certificate-Integration.tests.ps1**: Tests for certificate management (to be implemented)

### Workflow Tests

- **VPN-Setup.tests.ps1**: Tests for the VPN setup workflow
- **Website-Deployment.tests.ps1**: Tests for the website deployment workflow
- **DNS-Management.tests.ps1**: Tests for the DNS management workflow

## Running Tests

### Running All Tests

```powershell
cd tests
.\Run-HomeLab-Tests.ps1 -TestType All
```

### Running Specific Test Types

```powershell
# Run only unit tests
.\Run-HomeLab-Tests.ps1 -TestType Unit

# Run only integration tests
.\Run-HomeLab-Tests.ps1 -TestType Integration

# Run only workflow tests
.\Run-HomeLab-Tests.ps1 -TestType Workflow
```

### Running with Code Coverage

```powershell
.\Run-HomeLab-Tests.ps1 -TestType All -Coverage
```

### Generating HTML Report

```powershell
.\Run-HomeLab-Tests.ps1 -TestType All -GenerateReport
```

## Continuous Integration

The testing strategy is implemented in CI using GitHub Actions. The workflow is defined in `.github/workflows/run-tests.yml` and runs automatically on:

- Push to main branch
- Pull requests to main branch
- Manual trigger with test type selection

## Test Data

Test data is generated dynamically during test execution using mocks and stubs. No actual Azure resources are created during tests.

## Mocking Strategy

The tests use Pester's mocking capabilities to simulate Azure API calls and module interactions. This allows tests to run quickly and consistently without requiring actual Azure resources.

## Test Coverage

Code coverage is tracked using Pester's built-in coverage capabilities. The coverage report is generated when running tests with the `-Coverage` parameter.

## Test Reports

Test reports are generated in two formats:

1. **XML**: Standard Pester XML report format (TestResults.xml)
2. **HTML**: Custom HTML report generated using PScribo (TestReport.html)

## Next Steps

1. Implement remaining unit tests for all modules
2. Implement additional integration tests
3. Implement additional workflow tests
4. Set up scheduled test runs
5. Implement test result tracking and trending

## References

- [Testing Strategy](../TESTING-STRATEGY-DETAILED.md)
- [Main Testing Guide](../TESTING.md)
- [Development Documentation](../DEVELOPMENT.md)
