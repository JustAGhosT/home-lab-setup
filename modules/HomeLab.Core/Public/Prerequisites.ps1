<#
.SYNOPSIS
    Prerequisites functions for HomeLab environment.
.DESCRIPTION
    Provides functions for installing and checking prerequisites for the HomeLab environment.
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>

<#
.SYNOPSIS
    Installs the prerequisites for the HomeLab setup.
.DESCRIPTION
    Installs the required tools (Azure CLI and Az PowerShell module) if they are not already present.
.PARAMETER Force
    If specified, reinstalls prerequisites even if they are already installed.
.EXAMPLE
    Install-Prerequisites -Force
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Install-Prerequisites {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Log -Message "Installing prerequisites..." -Level Info
    
    # Install Azure CLI if not installed or Force is specified
    $azCliInstalled = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
    if (-not $azCliInstalled -or $Force) {
        if ($azCliInstalled -and $Force) {
            Write-Log -Message "Azure CLI is already installed, but Force parameter is specified. Reinstalling..." -Level Info
        }
        else {
            Write-Log -Message "Azure CLI not found. Installing Azure CLI..." -Level Info
        }
        
        try {
            # Use a temporary MSI path
            $msiFile = Join-Path -Path $env:TEMP -ChildPath "AzureCLI.msi"
            Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindows" -OutFile $msiFile
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/I `"$msiFile`" /quiet" -Wait
            Remove-Item -Path $msiFile -Force
            
            # Refresh PATH environment variable
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            Write-Log -Message "Azure CLI installed successfully." -Level Success
        }
        catch {
            Write-Log -Message "Failed to install Azure CLI: $_" -Level Error
            return $false
        }
    }
    else {
        Write-Log -Message "Azure CLI is already installed." -Level Info
    }
    
    # Install Az PowerShell module if not installed or Force is specified
    $azPowerShellInstalled = $null -ne (Get-Module -ListAvailable Az.Accounts)
    if (-not $azPowerShellInstalled -or $Force) {
        if ($azPowerShellInstalled -and $Force) {
            Write-Log -Message "Az PowerShell module is already installed, but Force parameter is specified. Reinstalling..." -Level Info
        }
        else {
            Write-Log -Message "Az PowerShell module not found. Installing Az PowerShell module..." -Level Info
        }
        
        try {
            Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
            Write-Log -Message "Az PowerShell module installed successfully." -Level Success
        }
        catch {
            Write-Log -Message "Failed to install Az PowerShell module: $_" -Level Error
            return $false
        }
    }
    else {
        Write-Log -Message "Az PowerShell module is already installed." -Level Info
    }
    
    Write-Log -Message "All prerequisites installed successfully." -Level Success
    return $true
}

<#
.SYNOPSIS
    Tests if the prerequisites for the HomeLab setup are installed.
.DESCRIPTION
    Checks if the required tools (Azure CLI and Az PowerShell module) are installed.
.PARAMETER Silent
    If specified, suppresses log messages.
.EXAMPLE
    if (-not (Test-Prerequisites)) { Install-Prerequisites }
.NOTES
    Author: Jurie Smit
    Date: March 6, 2025
#>
function Test-Prerequisites {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )
    
    if (-not $Silent) {
        Write-Log -Message "Checking prerequisites..." -Level Info
    }
    
    # Check if Azure CLI is installed
    $azCliInstalled = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
    if (-not $azCliInstalled -and -not $Silent) {
        Write-Log -Message "Azure CLI is not installed." -Level Warning
    }
    
    # Check if Az PowerShell module is installed
    $azPowerShellInstalled = $null -ne (Get-Module -ListAvailable Az.Accounts)
    if (-not $azPowerShellInstalled -and -not $Silent) {
        Write-Log -Message "Az PowerShell module is not installed." -Level Warning
    }
    
    $allInstalled = $azCliInstalled -and $azPowerShellInstalled
    
    if ($allInstalled -and -not $Silent) {
        Write-Log -Message "All prerequisites are installed." -Level Success
    }
    
    return $allInstalled
}
