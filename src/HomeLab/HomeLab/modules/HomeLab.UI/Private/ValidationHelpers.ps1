<#
.SYNOPSIS
    Validation helper functions for HomeLab.UI module.
.DESCRIPTION
    Contains reusable validation functions for user input validation.
.NOTES
    Author: HomeLab Support
    Date: November 17, 2025
#>

function Test-AzureSubscriptionId {
    <#
    .SYNOPSIS
        Validates an Azure Subscription ID (GUID format).
    .PARAMETER SubscriptionId
        The subscription ID to validate.
    .EXAMPLE
        Test-AzureSubscriptionId -SubscriptionId "12345678-1234-1234-1234-123456789012"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId
    )
    
    # Validate GUID format - case insensitive
    return $SubscriptionId -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
}

function Test-AzureResourceGroupName {
    <#
    .SYNOPSIS
        Validates an Azure Resource Group name.
    .PARAMETER ResourceGroupName
        The resource group name to validate.
    .EXAMPLE
        Test-AzureResourceGroupName -ResourceGroupName "my-resource-group"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )
    
    # Azure Resource Group validation: alphanumeric, hyphens, underscores, periods, parentheses
    # 1-90 characters, cannot end with period
    $pattern = '^[a-zA-Z0-9_\-\(\)\.]{1,90}$'
    
    if ($ResourceGroupName -notmatch $pattern) {
        return $false
    }
    
    # Cannot end with period
    if ($ResourceGroupName.EndsWith('.')) {
        return $false
    }
    
    return $true
}

function Test-AzureAppName {
    <#
    .SYNOPSIS
        Validates an Azure App Name.
    .PARAMETER AppName
        The app name to validate.
    .EXAMPLE
        Test-AzureAppName -AppName "my-web-app"
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName
    )
    
    # Azure App Name validation: alphanumeric and hyphens, 1-60 characters
    # Cannot start or end with hyphen
    $pattern = '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,58}[a-zA-Z0-9])?$'
    
    return $AppName -match $pattern
}

function Get-SafePath {
    <#
    .SYNOPSIS
        Sanitizes and validates a file path to prevent path traversal attacks.
    .PARAMETER Path
        The path to sanitize.
    .PARAMETER AllowRelative
        If specified, allows relative paths. Otherwise, only absolute paths are accepted.
    .EXAMPLE
        Get-SafePath -Path "C:\Projects\MyApp"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowRelative
    )
    
    # Remove null characters
    $Path = $Path -replace '\0', ''
    
    # Convert to absolute path if not already
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        if (-not $AllowRelative) {
            throw "Path must be absolute: $Path"
        }
        $Path = Join-Path -Path $PWD.Path -ChildPath $Path
    }
    
    # Resolve to full path (normalizes .. and . components)
    try {
        $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        throw "Invalid path: $Path"
    }
    
    # Prevent path traversal by checking if resolved path starts with expected base
    # (This is a basic check; in production, you'd compare with allowed base directories)
    if ($resolvedPath -match '\.\.' -or $resolvedPath -match '\.\/') {
        throw "Path traversal detected: $Path"
    }
    
    return $resolvedPath
}

function Read-ValidatedInput {
    <#
    .SYNOPSIS
        Prompts for user input with validation.
    .PARAMETER Prompt
        The prompt message to display.
    .PARAMETER Validator
        A scriptblock that returns $true if input is valid, $false otherwise.
    .PARAMETER ErrorMessage
        Error message to display when validation fails.
    .PARAMETER AllowEmpty
        If specified, allows empty input.
    .EXAMPLE
        $subId = Read-ValidatedInput -Prompt "Enter Subscription ID" -Validator {Test-AzureSubscriptionId $_} -ErrorMessage "Invalid GUID format"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Validator,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = "Invalid input. Please try again.",
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowEmpty
    )
    
    do {
        $input = Read-Host $Prompt
        
        # Check for empty input
        if ([string]::IsNullOrWhiteSpace($input)) {
            if ($AllowEmpty) {
                return $input
            }
            Write-Host "Input cannot be empty. Please try again." -ForegroundColor Red
            continue
        }
        
        # Run validator if provided
        if ($Validator) {
            $isValid = & $Validator $input
            if (-not $isValid) {
                Write-Host $ErrorMessage -ForegroundColor Red
                continue
            }
        }
        
        return $input
    } while ($true)
}
