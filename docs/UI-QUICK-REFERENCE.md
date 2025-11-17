# HomeLab UI Quick Reference Guide

## New Features & Keyboard Shortcuts

### Keyboard Shortcuts

When navigating HomeLab menus, you can now use the following shortcuts:

| Shortcut | Action |
|----------|--------|
| `?` | Show help and navigation guide |
| `h` | View recent menu history |
| `/` | Search menu items (when supported) |
| `0` | Return to previous menu / Exit |
| `Ctrl+C` | Emergency exit |

### Menu Navigation Help

Press `?` in any menu to display:
- Available keyboard shortcuts
- Navigation tips
- Color coding explanation
- Usage examples

Example:
```
Select an option: ?
```

### Menu History

Press `h` to view your last 10 menu selections:

```
Select an option: h

=== RECENT MENU HISTORY ===

  [2 min ago] Main Menu: Deploy Website
  [5 min ago] Main Menu: VPN Management
  [10 min ago] Website Menu: Static Website
```

### Enhanced Progress Bars

Progress bars now show:
- Visual progress indicator
- Percentage complete
- Estimated time remaining (ETA)
- Current status message

Example output:
```
Deploying [████████████████░░░░░░] 75% ETA: 02:30 - Creating resources...
```

### Better Error Messages

Errors now include:
1. **What happened**: Clear error description
2. **Why it happened**: Possible causes
3. **What to do**: Suggested actions

Example:
```
═══ ERROR ═══
Deployment failed: Resource group not found

Possible causes:
  • Resource group name is incorrect
  • You don't have permission to access the resource group
  • Resource group was deleted

Suggested actions:
  → Verify the resource group name in Azure Portal
  → Check your Azure permissions
  → Create a new resource group if needed
```

## New Validation Features

### Input Validation

All inputs are now validated before processing:

- **Subscription ID**: Must be valid GUID format
- **Resource Group**: 1-90 characters, alphanumeric with hyphens, underscores, periods, parentheses
- **App Name**: 1-60 characters, alphanumeric with hyphens, cannot start/end with hyphen
- **File Paths**: Protected against directory traversal attacks

### Safe Path Handling

File paths are automatically:
- Sanitized for security
- Converted to absolute paths
- Validated for existence
- Protected against traversal attacks

## Menu Improvements

### Consistent Back Navigation

All sub-menus now include a consistent "Back" option:
```
  [0] ← Back to Previous Menu
```

### Search Functionality

In menus with many options, use `/` to search:
```
Select an option: /
Search term: deploy
```

### Visual Indicators

Menu items use consistent colors:
- **Cyan/Blue**: Navigation and action options
- **Yellow**: Back/Return options
- **Green**: Success messages
- **Red**: Errors and warnings
- **White**: Normal text

## Usage Examples

### Example 1: Deploying a Website with Help

```powershell
# Start HomeLab
.\Start.ps1

# In the main menu, press ? to see help
Select an option: ?

# Navigate to website deployment
Select an option: 9

# View history to see what you've done
Select an option: h

# Deploy your website
Select an option: 1
```

### Example 2: Using Progress with ETA

When deploying, you'll see:
```
Step 1/4 [██████████░░░░░░░░░░░░░░] 40% ETA: 03:15 - Validating configuration...
Step 2/4 [████████████████░░░░░░░░] 60% ETA: 02:00 - Creating resources...
Step 3/4 [████████████████████░░░░] 85% ETA: 00:45 - Deploying application...
Step 4/4 [████████████████████████] 100% - Complete!
```

### Example 3: Handling Errors

If an error occurs:
```
═══ ERROR ═══
Invalid Subscription ID format

Possible causes:
  • Subscription ID is not in GUID format
  • Copy-paste error with extra spaces

Suggested actions:
  → Verify format: 12345678-1234-1234-1234-123456789012
  → Get your subscription ID from Azure Portal
  → Remove any leading/trailing spaces
```

## Tips and Tricks

### 1. Default Options

Some menus have default options marked with `*`:
```
  [1]* Deploy Static Website
```
Just press Enter to select the default.

### 2. Quick Exit

To quickly exit from anywhere:
- Press `0` repeatedly to go back through menus
- Or press `Ctrl+C` for emergency exit

### 3. History Navigation

Use `h` to review your actions and see patterns in your workflow.

### 4. Search in Long Menus

When a menu has many options, use `/` to filter:
```
Select an option: /
Search term: azure
```
Only Azure-related options will be shown.

### 5. Understanding Progress

When operations take time:
- Watch the percentage to know overall progress
- Use ETA to plan your time
- Read status messages for current activity

## Troubleshooting

### Common Issues

#### "Command not found" errors
- Make sure you've imported the HomeLab module
- Try reloading: `Import-Module .\HomeLab.psd1 -Force`

#### Validation errors
- Check the error message for specific format requirements
- Use the suggested actions to resolve
- Press `?` for help if available

#### Progress bar not showing
- Ensure your terminal supports Unicode characters
- Try resizing your terminal window
- Check if console output is being redirected

### Getting Help

1. **In-app help**: Press `?` in any menu
2. **Documentation**: See `/docs` folder
3. **History**: Press `h` to review your actions
4. **Error messages**: Read all three sections (what, why, how to fix)

## Security Notes

### Input Validation and Security

All inputs are validated for:
- Format correctness
- Length limits
- Character restrictions
- Path traversal attempts

### Safe Operations

The UI ensures:
- No path traversal attacks
- No command injection
- Validated Azure resource names
- Safe file operations

## Feedback

If you encounter issues or have suggestions for UI improvements:
1. Check the error message carefully
2. Review recent history with `h`
3. Consult documentation
4. Report issues with specific error messages

## Version History

### v1.1 (November 2025)
- Added keyboard shortcuts (?, h, /)
- Implemented menu history tracking
- Enhanced progress bars with ETA
- Improved error messages
- Added input validation helpers
- Created consistent navigation
- Added search functionality

### v1.0 (Initial Release)
- Basic menu system
- Simple progress bars
- Standard error handling

---

Happy HomeLab Management! 🚀
