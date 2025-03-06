#Requires -Version 5.1
#Requires -Modules @{ ModuleName="HomeLab.Core"; ModuleVersion="0.1.0" }
#Requires -Modules @{ ModuleName="HomeLab.Azure"; ModuleVersion="0.1.0" }
#Requires -Modules @{ ModuleName="Az"; ModuleVersion="9.0.0" }

# Get the directory where this script is located
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load all function files
$PublicFunctions = @(Get-ChildItem -Path "$ScriptPath\Public\*.ps1" -Recurse -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path "$ScriptPath\Private\*.ps1" -Recurse -ErrorAction SilentlyContinue)

# Dot source the function files
foreach ($FunctionFile in ($PublicFunctions + $PrivateFunctions)) {
    try {
        . $FunctionFile.FullName
    } catch {
        Write-Error -Message "Failed to import function $($FunctionFile.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName
