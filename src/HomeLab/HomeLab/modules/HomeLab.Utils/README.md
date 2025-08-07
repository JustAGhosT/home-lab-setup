# HomeLab.Utils

PowerShell utility module for HomeLab environment.

## Installation

```powershell
# Clone the repository
git clone <repository-url>

# Import the module
Import-Module ./HomeLab.Utils -Force
```

## Available Functions

- `Get-Configuration`: Returns the current global configuration object.
- `Split-FunctionsToFiles`: Extracts functions from PS1 files and creates separate files for each function.

## Usage Examples

### Split-FunctionsToFiles

```powershell
# Extract functions from a module to individual files
Split-FunctionsToFiles -SourceFolder "C:\Projects\MyOldModule" -DestinationFolder "C:\Projects\MyNewModule\Functions" -CreateSubfolders
```

## Adding New Functions

1. Create a new PS1 file in the appropriate category folder under Public or Private
2. Add the function with proper comment-based help
3. Update the module manifest (psd1) to export the function if it's public

## License

Copyright (c) 2025 Jurie Smit. All rights reserved.
