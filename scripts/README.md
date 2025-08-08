# Repository Restructuring Scripts

This directory contains scripts for improving the repository structure and maintaining code quality.

## Quick Start

### 1. Preview the Restructuring (Recommended First Step)

```powershell
# See what changes would be made without actually making them
.\scripts\restructure-repository.ps1 -WhatIf
```

### 2. Create a Backup Only

```powershell
# Create a backup of the current structure
.\scripts\restructure-repository.ps1 -BackupOnly
```

### 3. Validate Current Structure

```powershell
# Check if the current structure meets standards
.\scripts\restructure-repository.ps1 -ValidateOnly
```

### 4. Perform Full Restructuring

```powershell
# Execute the complete restructuring process
.\scripts\restructure-repository.ps1
```

## Script Options

| Parameter       | Description                         | Example                                                |
| --------------- | ----------------------------------- | ------------------------------------------------------ |
| `-WhatIf`       | Preview changes without making them | `.\restructure-repository.ps1 -WhatIf`                 |
| `-BackupOnly`   | Create backup and exit              | `.\restructure-repository.ps1 -BackupOnly`             |
| `-ValidateOnly` | Test current structure              | `.\restructure-repository.ps1 -ValidateOnly`           |
| `-BackupPath`   | Custom backup location              | `.\restructure-repository.ps1 -BackupPath "my-backup"` |

## What the Script Does

### Phase 1: Backup
- Creates a timestamped backup of the current repository
- Excludes git, node_modules, and artifacts directories
- Provides rollback capability

### Phase 2: Create New Structure
- Creates the improved directory structure
- Organizes files into logical groups
- Follows PowerShell module best practices

### Phase 3: Move Files
- Relocates files to their new locations
- Maintains file relationships
- Updates references where needed

### Phase 4: Update Manifests
- Updates PowerShell module manifests
- Fixes path references
- Ensures proper module loading

### Phase 5: Update Pipelines
- Updates CI/CD pipeline paths
- Maintains build functionality
- Preserves quality gates

### Phase 6: Create Config Files
- Adds `.editorconfig` for consistent formatting
- Creates `CODE_OF_CONDUCT.md`
- Sets up development standards

### Phase 7: Update Gitignore
- Adds new artifact directories
- Excludes build outputs
- Improves repository cleanliness

### Phase 8: Validation
- Tests the new structure
- Validates module loading
- Confirms functionality

## New Repository Structure

After restructuring, your repository will have this improved organization:

```
home-lab-setup/
├── src/HomeLab/                    # Main PowerShell module
├── modules/                        # Sub-modules (Azure, Security, etc.)
├── tests/                          # Organized test structure
├── scripts/                        # Build and deployment scripts
├── config/                         # Configuration files
├── pipelines/                      # CI/CD pipelines
├── quality/                        # Quality artifacts and reports
├── tools/                          # Development tools
├── samples/                        # Example scripts and templates
└── artifacts/                      # Build outputs (gitignored)
```

## Benefits

### 🎯 **Improved Organization**
- Clear separation of concerns
- Logical file grouping
- Easier navigation

### 🔧 **Better Maintainability**
- Standardized module structure
- Consistent naming conventions
- Reduced complexity

### 🚀 **Enhanced Development Experience**
- Faster onboarding
- Better tooling support
- Improved debugging

### 🛡️ **Enterprise Standards**
- PowerShell module best practices
- Security-first approach
- Quality-driven development

## Safety Features

### ✅ **Backup Creation**
- Automatic timestamped backups
- Complete repository state preservation
- Easy rollback capability

### ✅ **WhatIf Mode**
- Preview all changes before execution
- No risk of data loss
- Detailed change logging

### ✅ **Validation**
- Comprehensive structure validation
- Module loading tests
- Functionality verification

### ✅ **Error Handling**
- Graceful error recovery
- Detailed logging
- Rollback instructions

## Troubleshooting

### Common Issues

**Q: The script fails with permission errors**
A: Run PowerShell as Administrator or check file permissions

**Q: Module imports fail after restructuring**
A: Check that all module manifests were updated correctly

**Q: CI/CD pipelines break**
A: Verify pipeline paths were updated in Phase 5

**Q: Tests fail in new structure**
A: Update test paths to match new directory structure

### Recovery

If something goes wrong:

1. **Use the backup**: The script creates a timestamped backup
2. **Check logs**: Review the log file for detailed error information
3. **Manual rollback**: Restore from the backup directory
4. **Partial fixes**: Run the script with `-ValidateOnly` to identify issues

## Log Files

The script creates detailed logs in the `logs/` directory:

- `restructure-YYYYMMDD-HHMMSS.log` - Main execution log
- Contains timestamps, error details, and validation results
- Useful for troubleshooting and audit trails

## Next Steps

After successful restructuring:

1. **Review the new structure** - Familiarize yourself with the organization
2. **Update documentation** - Update any documentation that references old paths
3. **Test functionality** - Run all tests to ensure everything works
4. **Update CI/CD** - Verify pipelines work with the new structure
5. **Team communication** - Inform team members of the new structure

## Support

For issues or questions:

1. Check the log files for detailed error information
2. Review the main restructuring plan document
3. Use the `-WhatIf` mode to preview changes
4. Create an issue with detailed error information

---

*This restructuring transforms your repository into a professional, enterprise-grade PowerShell module that follows industry best practices.*
