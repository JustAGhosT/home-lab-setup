# Contributing to Azure HomeLab Setup

Thank you for your interest in contributing to the Azure HomeLab Setup project! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Process](#contributing-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow. Please be respectful and constructive in all interactions.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up the development environment
4. Create a feature branch for your changes
5. Make your changes and test them
6. Submit a pull request

## Development Setup

### Prerequisites

- PowerShell 7.2 or higher
- Azure PowerShell module (`Install-Module -Name Az`)
- Pester testing framework (`Install-Module -Name Pester`)
- Git for version control
- Visual Studio Code (recommended) with PowerShell extension

### Local Setup

```powershell
# Clone your fork
git clone https://github.com/yourusername/home-lab-setup.git
cd home-lab-setup

# Install required modules
Install-Module -Name Az -AllowClobber -Force
Install-Module -Name Pester -Force
Install-Module -Name PowerShell-Yaml -Force

# Run tests to verify setup
cd tests
.\Run-HomeLab-Tests.ps1 -TestType All
```

## Contributing Process

1. **Check existing issues** - Look for existing issues or create a new one
2. **Discuss major changes** - For significant changes, discuss in an issue first
3. **Create a branch** - Use descriptive branch names (e.g., `feature/add-terraform-support`)
4. **Make changes** - Follow coding standards and include tests
5. **Test thoroughly** - Ensure all tests pass and add new tests for new features
6. **Update documentation** - Update relevant documentation and README files
7. **Submit pull request** - Provide clear description of changes

## Coding Standards

### PowerShell Guidelines

- Use approved PowerShell verbs for function names
- Follow PascalCase for function names and parameters
- Use descriptive parameter names with proper types
- Include comprehensive help documentation for all functions
- Use proper error handling with try/catch blocks
- Follow the module structure pattern used in the project

### Example Function Template

```powershell
<#
.SYNOPSIS
    Brief description of what the function does.
.DESCRIPTION
    Detailed description of the function's purpose and behavior.
.PARAMETER ParameterName
    Description of the parameter.
.EXAMPLE
    Example-Function -ParameterName "value"
    Description of what this example does.
.OUTPUTS
    Description of what the function returns.
#>
function Example-Function {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ParameterName
    )
    
    try {
        # Function implementation
        Write-Verbose "Processing $ParameterName"
        
        # Return result
        return $result
    }
    catch {
        Write-Error "Failed to process $ParameterName: $($_.Exception.Message)"
        throw
    }
}
```

### File Organization

- Place public functions in `Public/` directories
- Place private functions in `Private/` directories
- Use descriptive file names that match function names
- Group related functions in the same file when appropriate

## Testing Guidelines

### Test Structure

- Write unit tests for all public functions
- Create integration tests for cross-module functionality
- Add workflow tests for end-to-end scenarios
- Use descriptive test names that explain what is being tested

### Test Categories

1. **Unit Tests** (`tests/unit/`) - Test individual functions in isolation
2. **Integration Tests** (`tests/integration/`) - Test module interactions
3. **Workflow Tests** (`tests/workflow/`) - Test complete user scenarios

### Running Tests

```powershell
# Run all tests
.\Run-HomeLab-Tests.ps1 -TestType All

# Run specific test types
.\Run-HomeLab-Tests.ps1 -TestType Unit
.\Run-HomeLab-Tests.ps1 -TestType Integration
.\Run-HomeLab-Tests.ps1 -TestType Workflow
```

### Mock Guidelines

- Use mocks for Azure API calls to avoid costs and dependencies
- Create realistic mock responses that match Azure API behavior
- Store mocks in appropriate `*.Mock.ps1` files

## Documentation

### Required Documentation

- Update README.md for new features
- Add function documentation using PowerShell comment-based help
- Create or update architecture diagrams for infrastructure changes
- Update relevant guides in the `docs/` directory

### Documentation Standards

- Use clear, concise language
- Include practical examples
- Keep diagrams up to date with code changes
- Ensure all links work correctly

## Submitting Changes

### Pull Request Guidelines

1. **Clear title** - Use descriptive titles that explain the change
2. **Detailed description** - Explain what changes were made and why
3. **Link issues** - Reference any related issues
4. **Test results** - Include test results or screenshots if applicable
5. **Breaking changes** - Clearly mark any breaking changes

### Pull Request Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings or errors introduced
```

### Review Process

1. Automated tests must pass
2. Code review by maintainers
3. Documentation review
4. Final approval and merge

## Questions or Help

If you have questions or need help:

1. Check existing documentation
2. Search existing issues
3. Create a new issue with the "question" label
4. Join discussions in existing issues

Thank you for contributing to Azure HomeLab Setup!
