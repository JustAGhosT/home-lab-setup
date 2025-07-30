<#
.SYNOPSIS
    Diagnostic script to identify infinite loop in PowerShell modules
.DESCRIPTION
    This script helps identify which module or function is causing an infinite loop
    by instrumenting key PowerShell functions and tracking call stacks.
#>

# ===== CRITICAL SECTION: PREVENT INFINITE LOOPS =====
# Disable automatic module loading to prevent recursive loading
$PSModuleAutoLoadingPreference = 'None'
# Disable function discovery debugging which can cause infinite loops
$DebugPreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'

# Create a log file for diagnostics
$diagLogPath = "$env:TEMP\homelab_diagnostic_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$originalColor = [Console]::ForegroundColor
[Console]::ForegroundColor = [ConsoleColor]::Cyan
[Console]::WriteLine("Diagnostic log will be written to: $diagLogPath")
[Console]::ForegroundColor = $originalColor

<#
.SYNOPSIS
    Writes diagnostic log messages to console and file.
.DESCRIPTION
    Logs diagnostic messages with timestamps to both console and file output.
.PARAMETER Message
    The message to log.
.PARAMETER Level
    The log level (INFO, WARNING, ERROR, etc.).
#>
function Write-DiagLog {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    $originalColor = [Console]::ForegroundColor
    try {
        # Write to console with color using .NET methods
        switch ($Level) {
            "ERROR" { [Console]::ForegroundColor = [ConsoleColor]::Red }
            "Warning" { [Console]::ForegroundColor = [ConsoleColor]::Yellow }
            "DEBUG" { [Console]::ForegroundColor = [ConsoleColor]::Gray }
            default { [Console]::ForegroundColor = [ConsoleColor]::White }
        }
        [Console]::WriteLine($logMessage)
    }
    finally {
        [Console]::ForegroundColor = $originalColor
    }

    # Write to log file using .NET methods
    [System.IO.File]::AppendAllText($diagLogPath, "$logMessage`r`n")
}

# Create a hashtable to track function calls
$script:FunctionCallCounts = @{}
$script:ModuleLoadCounts = @{}
$script:LastStackTraces = @{}
$script:RecursionDetected = $false

# Function to get a simplified stack trace
<#
.SYNOPSIS
    Gets a simplified PowerShell call stack trace.
.DESCRIPTION
    Returns a formatted string representation of the current PowerShell call stack.
#>
function Get-SimpleStackTrace {
    $callStack = Get-PSCallStack | Select-Object -Skip 1
    $stackTrace = @()

    foreach ($frame in $callStack) {
        $stackTrace += "$($frame.Command) at $($frame.Location)"
    }

    return $stackTrace -join " -> "
}

# Store original commands for cleanup
$script:OriginalCommands = @{
    'Import-Module' = Get-Command Import-Module
    'Get-Command'   = Get-Command Get-Command
    'Get-ChildItem' = Get-Command Get-ChildItem
}

# Cleanup function
<#
.SYNOPSIS
    Restores original PowerShell commands that were overridden for diagnostics.
.DESCRIPTION
    Removes the global function overrides and restores the original PowerShell commands.
#>
function Restore-OriginalCommand {
    if ($script:OriginalCommands) {
        foreach ($cmdName in $script:OriginalCommands.Keys) {
            Remove-Item "function:global:$cmdName" -ErrorAction SilentlyContinue
        }
        Write-DiagLog -Message "Restored original PowerShell commands" -Level INFO
        $script:OriginalCommands = $null
    }
}

# Export cleanup function for manual use
<#
.SYNOPSIS
    Manually restores diagnostic command overrides.
.DESCRIPTION
    Provides a global function to manually restore original PowerShell commands.
#>
function global:Restore-DiagnosticCommand {
    Restore-OriginalCommand
}

# Register cleanup on exit
Register-EngineEvent PowerShell.Exiting -Action { Restore-OriginalCommand } | Out-Null

# Trap for unexpected errors to ensure cleanup
trap {
    Write-DiagLog -Message "Unexpected error occurred: $_" -Level ERROR
    Restore-OriginalCommand
    throw
}

# Create a wrapper for Import-Module to track module loading
function global:Import-Module {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [switch]$Global,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$DisableNameChecking
    )
    
    # Track module loading
    if (-not $script:ModuleLoadCounts[$Name]) {
        $script:ModuleLoadCounts[$Name] = 0
    }
    $script:ModuleLoadCounts[$Name]++
    
    # Check for excessive loading
    if ($script:ModuleLoadCounts[$Name] -gt 5) {
        $stackTrace = Get-SimpleStackTrace
        Write-DiagLog -Message "EXCESSIVE MODULE LOADING DETECTED: $Name (Count: $($script:ModuleLoadCounts[$Name]))" -Level ERROR
        Write-DiagLog -Message "Stack trace: $stackTrace" -Level ERROR
        
        if ($script:LastStackTraces[$Name] -eq $stackTrace) {
            Write-DiagLog -Message "RECURSIVE MODULE LOADING DETECTED: $Name" -Level ERROR
            $script:RecursionDetected = $true
            throw "Recursive module loading detected for $Name. Aborting to prevent infinite loop."
        }
        
        $script:LastStackTraces[$Name] = $stackTrace
    }
    
    Write-DiagLog -Message "Loading module: $Name (Count: $($script:ModuleLoadCounts[$Name]))" -Level DEBUG
    
    # Call original Import-Module using the module-qualified name to avoid recursion
    try {
        # Use the Microsoft.PowerShell.Core module qualified command name
        Microsoft.PowerShell.Core\Import-Module -Name $Name -Global:$Global -Force:$Force -DisableNameChecking:$DisableNameChecking -ErrorAction Continue
    }
    catch {
        Write-DiagLog -Message "Error loading module $Name`: $_" -Level ERROR
        throw $_
    }
}

# Create a wrapper for Get-Command to track command discovery
function global:Get-Command {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Name,

        [Parameter()]
        [string]$CommandType,

        [Parameter()]
        [string[]]$Module,

        [Parameter(ValueFromRemainingArguments)]
        [object[]]$RemainingArguments
    )
    
    $key = "GetCommand:$Name"
    if (-not $script:FunctionCallCounts[$key]) {
        $script:FunctionCallCounts[$key] = 0
    }
    $script:FunctionCallCounts[$key]++
    
    # Check for excessive calls
    if ($script:FunctionCallCounts[$key] -gt 20) {
        $stackTrace = Get-SimpleStackTrace
        Write-DiagLog -Message "EXCESSIVE COMMAND LOOKUP: $Name (Count: $($script:FunctionCallCounts[$key]))" -Level Warning
        Write-DiagLog -Message "Stack trace: $stackTrace" -Level Warning
        
        if ($script:LastStackTraces[$key] -eq $stackTrace) {
            Write-DiagLog -Message "RECURSIVE COMMAND LOOKUP DETECTED: $Name" -Level ERROR
            $script:RecursionDetected = $true
            throw "Recursive command lookup detected for $Name. Aborting to prevent infinite loop."
        }
        
        $script:LastStackTraces[$key] = $stackTrace
    }
    
    # Build parameters for the original command
    $params = @{}
    if ($Name) { $params['Name'] = $Name }
    if ($CommandType) { $params['CommandType'] = $CommandType }
    if ($Module) { $params['Module'] = $Module }

    # Call original Get-Command using the module-qualified name with all parameters
    Microsoft.PowerShell.Core\Get-Command @params -ErrorAction Continue
}

# Create a wrapper for Get-ChildItem to track file system operations
function global:Get-ChildItem {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path,

        [Parameter()]
        [string]$Filter,

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [switch]$Directory,

        [Parameter()]
        [switch]$File,

        [Parameter()]
        [string[]]$Include,

        [Parameter()]
        [string[]]$Exclude,

        [Parameter(ValueFromRemainingArguments)]
        [object[]]$RemainingArguments
    )
    
    $key = "GetChildItem:$Path"
    if (-not $script:FunctionCallCounts[$key]) {
        $script:FunctionCallCounts[$key] = 0
    }
    $script:FunctionCallCounts[$key]++
    
    # Check for excessive calls
    if ($script:FunctionCallCounts[$key] -gt 10) {
        $stackTrace = Get-SimpleStackTrace
        Write-DiagLog -Message "EXCESSIVE DIRECTORY LISTING: $Path (Count: $($script:FunctionCallCounts[$key]))" -Level Warning
        Write-DiagLog -Message "Stack trace: $stackTrace" -Level Warning
        
        if ($script:LastStackTraces[$key] -eq $stackTrace) {
            Write-DiagLog -Message "RECURSIVE DIRECTORY LISTING DETECTED: $Path" -Level ERROR
            $script:RecursionDetected = $true
            throw "Recursive directory listing detected for $Path. Aborting to prevent infinite loop."
        }
        
        $script:LastStackTraces[$key] = $stackTrace
    }
    
    # Build parameters for the original command
    $params = @{}
    if ($Path) { $params['Path'] = $Path }
    if ($Filter) { $params['Filter'] = $Filter }
    if ($Recurse) { $params['Recurse'] = $Recurse }
    if ($Directory) { $params['Directory'] = $Directory }
    if ($File) { $params['File'] = $File }
    if ($Include) { $params['Include'] = $Include }
    if ($Exclude) { $params['Exclude'] = $Exclude }

    # Call original Get-ChildItem using the module-qualified name with all parameters
    Microsoft.PowerShell.Management\Get-ChildItem @params -ErrorAction Continue
}

# Function to test module loading
function Test-ModuleLoading {
    param (
        [string]$ModulePath
    )
    
    Write-DiagLog -Message "Testing module loading: $ModulePath" -Level INFO
    
    try {
        # Set a timeout for module loading
        $jobScript = {
            param($ModulePath)
            
            # Disable automatic module loading to prevent recursive loading
            $PSModuleAutoLoadingPreference = 'None'
            
            # Ensure required modules are loaded in the job
            Import-Module Microsoft.PowerShell.Utility -Force -ErrorAction SilentlyContinue
            
            # Import the module
            Import-Module -Name $ModulePath -DisableNameChecking -Force
            
            # Return success
            return "Success"
        }
        
        # Create a job with proper initialization
        $job = Start-Job -InitializationScript {
            # Pre-load required modules in job
            Import-Module Microsoft.PowerShell.Utility -Force -ErrorAction SilentlyContinue
        } -ScriptBlock $jobScript -ArgumentList $ModulePath
        
        # Wait for the job to complete with a timeout
        if (-not (Wait-Job -Job $job -Timeout 30)) {
            Write-DiagLog -Message "MODULE LOADING TIMEOUT: $ModulePath - This indicates an infinite loop!" -Level ERROR
            Stop-Job -Job $job -Force
            return $false
        }
        
        # Get the job result
        $result = Receive-Job -Job $job
        Remove-Job -Job $job
        
        if ($result -eq "Success") {
            Write-DiagLog -Message "Module loaded successfully: $ModulePath" -Level INFO
            return $true
        }
        else {
            Write-DiagLog -Message "Module loading failed: $ModulePath" -Level ERROR
            return $false
        }
    }
    catch {
        Write-DiagLog -Message "Error testing module loading: $_" -Level ERROR
        return $false
    }
}

# Main diagnostic function
function Start-DiagnosticTest {
    Write-DiagLog -Message "Starting HomeLab diagnostic test" -Level INFO
    
    # Get the script directory
    $scriptDirectory = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        # Try to determine script location from MyInvocation
        if ($MyInvocation.MyCommand.Path) {
            $resolvedPath = Split-Path -Parent $MyInvocation.MyCommand.Path
            Write-DiagLog -Message "Script directory resolved from MyInvocation: $resolvedPath" -Level DEBUG
            $resolvedPath
        }
        else {
            $fallbackPath = (Get-Location).Path
            Write-DiagLog -Message "Script directory fallback to current location: $fallbackPath" -Level Warning
            $fallbackPath
        }
    }
    else {
        Write-DiagLog -Message "Script directory from PSScriptRoot: $PSScriptRoot" -Level DEBUG
        $PSScriptRoot
    }
    
    # Define module paths
    $modulesRoot = Join-Path -Path $scriptDirectory -ChildPath "modules"
    $coreModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Core\HomeLab.Core.psm1"
    $azureModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Azure\HomeLab.Azure.psm1"
    $securityModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.Security\HomeLab.Security.psm1"
    $uiModulePath = Join-Path -Path $modulesRoot -ChildPath "HomeLab.UI\HomeLab.UI.psm1"
    
    # Test each module individually
    Write-DiagLog -Message "Testing Core module..." -Level INFO
    $coreResult = Test-ModuleLoading -ModulePath $coreModulePath
    
    # Only test other modules if core succeeds
    if ($coreResult) {
        Write-DiagLog -Message "Testing Azure module..." -Level INFO
        $azureResult = Test-ModuleLoading -ModulePath $azureModulePath
        
        Write-DiagLog -Message "Testing Security module..." -Level INFO
        $securityResult = Test-ModuleLoading -ModulePath $securityModulePath
        
        Write-DiagLog -Message "Testing UI module..." -Level INFO
        $uiResult = Test-ModuleLoading -ModulePath $uiModulePath
    }
    
    # Report results
    Write-DiagLog -Message "Diagnostic test complete" -Level INFO
    Write-DiagLog -Message "Core module: $(if ($coreResult) {'SUCCESS'} else {'FAILED'})" -Level INFO
    
    if ($coreResult) {
        Write-DiagLog -Message "Azure module: $(if ($azureResult) {'SUCCESS'} else {'FAILED'})" -Level INFO
        Write-DiagLog -Message "Security module: $(if ($securityResult) {'SUCCESS'} else {'FAILED'})" -Level INFO
        Write-DiagLog -Message "UI module: $(if ($uiResult) {'SUCCESS'} else {'FAILED'})" -Level INFO
    }
    
    # Check for recursive patterns in the logs
    Write-DiagLog -Message "Analyzing logs for recursive patterns..." -Level INFO
    
    # Report top function calls
    $topCalls = $script:FunctionCallCounts.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    Select-Object -First 10

    Write-DiagLog -Message "Top function calls:" -Level INFO
    foreach ($call in $topCalls) {
        Write-DiagLog -Message "  $($call.Key): $($call.Value) calls" -Level INFO
    }

    # Report top module loads
    $topModules = $script:ModuleLoadCounts.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    Select-Object -First 10
    
    Write-DiagLog -Message "Top module loads:" -Level INFO
    foreach ($module in $topModules) {
        Write-DiagLog -Message "  $($module.Key): $($module.Value) loads" -Level INFO
    }
    
    Write-DiagLog -Message "Diagnostic results saved to: $diagLogPath" -Level INFO
}

# Define a custom error handler to avoid Write-Warning in script blocks
<#
.SYNOPSIS
    Gets error details from an exception object.
.DESCRIPTION
    Extracts error message details from exception objects, handling inner exceptions.
.PARAMETER Exception
    The exception object to extract details from.
#>
function global:Get-ErrorDetail {
    param($Exception)

    if ($Exception -and $Exception.InnerException) {
        try {
            return $Exception.InnerException.Message
        }
        catch {
            return $Exception.Message
        }
    }
    return $null
}

# Use -ErrorAction on specific commands instead of global suppression
# $ErrorActionPreference = 'SilentlyContinue'  # Removed to avoid hiding important errors

# Run the diagnostic test with cleanup protection
try {
    Start-DiagnosticTest
}
finally {
    # Ensure cleanup happens even if script fails
    Restore-OriginalCommands
}
