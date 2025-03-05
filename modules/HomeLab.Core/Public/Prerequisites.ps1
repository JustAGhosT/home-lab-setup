<#
.SYNOPSIS
    Installs the prerequisites for the HomeLab setup.
.DESCRIPTION
    Installs the required tools (Azure CLI and Az PowerShell module) if they are not already present.
    Provides a function to test whether these prerequisites are installed.
.NOTES
    Author: Jurie Smit
    Date: March 5, 2025
#>

function Install-Prerequisites {
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Installing prerequisites..." -Level INFO
    
    # Install Azure CLI if not installed
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Log -Message "Azure CLI not found. Installing Azure CLI..." -Level INFO
        
        try {
            # Use a temporary MSI path
            $msiFile = Join-Path -Path $env:TEMP -ChildPath "AzureCLI.msi"
            Invoke-WebRequest -Uri "https://aka.ms/installazurecliwindows" -OutFile $msiFile
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/I `"$msiFile`" /quiet" -Wait
            Remove-Item -Path $msiFile -Force
            
            # Refresh PATH environment variable
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            Write-Log -Message "Azure CLI installed successfully." -Level SUCCESS
        }
        catch {
            Write-Log -Message "Failed to install Azure CLI: $_" -Level ERROR
            return $false
        }
    }
    else {
        Write-Log -Message "Azure CLI is already installed." -Level INFO
    }
    
    # Install Az PowerShell module if not installed
    if (-not (Get-Module -ListAvailable Az.Accounts)) {
        Write-Log -Message "Az PowerShell module not found. Installing Az PowerShell module..." -Level INFO
        
        try {
            Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
            Write-Log -Message "Az PowerShell module installed successfully." -Level SUCCESS
        }
        catch {
            Write-Log -Message "Failed to install Az PowerShell module: $_" -Level ERROR
            return $false
        }
    }
    else {
        Write-Log -Message "Az PowerShell module is already installed." -Level INFO
    }
    
    Write-Log -Message "All prerequisites installed successfully." -Level SUCCESS
    return $true
}

function Test-Prerequisites {
    [CmdletBinding()]
    param()
    
    Write-Log -Message "Checking prerequisites..." -Level INFO
    
    # Check if Azure CLI is installed
    $azCliInstalled = $null -ne (Get-Command az -ErrorAction SilentlyContinue)
    if (-not $azCliInstalled) {
        Write-Log -Message "Azure CLI is not installed." -Level WARNING
        return $false
    }
    
    # Check if Az PowerShell module is installed
    $azPowerShellInstalled = $null -ne (Get-Module -ListAvailable Az.Accounts)
    if (-not $azPowerShellInstalled) {
        Write-Log -Message "Az PowerShell module is not installed." -Level WARNING
        return $false
    }
    
    Write-Log -Message "All prerequisites are installed." -Level SUCCESS
    return $true
}

Export-ModuleMember -Function Install-Prerequisites, Test-Prerequisites
