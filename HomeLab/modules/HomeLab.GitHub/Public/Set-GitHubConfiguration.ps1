<#
.SYNOPSIS
    Sets GitHub configuration settings.

.DESCRIPTION
    Stores GitHub-related configuration settings such as user information,
    selected repository, and other preferences.

.PARAMETER Configuration
    A hashtable containing configuration settings.

.PARAMETER SelectedRepository
    The currently selected repository object.

.PARAMETER DefaultClonePath
    The default path where repositories should be cloned.

.EXAMPLE
    Set-GitHubConfiguration -Configuration @{ Username = "user"; ConnectedAt = (Get-Date) }

.EXAMPLE
    Set-GitHubConfiguration -SelectedRepository $repo

.EXAMPLE
    Set-GitHubConfiguration -DefaultClonePath "C:\Source\GitHub"
#>
function Set-GitHubConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$SelectedRepository,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultClonePath
    )
    
    try {
        # Get existing configuration
        $config = Get-GitHubConfiguration
        
        # Update with new values
        if ($Configuration) {
            foreach ($key in $Configuration.Keys) {
                $config[$key] = $Configuration[$key]
            }
        }
        
        if ($SelectedRepository) {
            $config.SelectedRepository = $SelectedRepository
        }
        
        if ($DefaultClonePath) {
            $config.DefaultClonePath = $DefaultClonePath
        }
        
        # Store configuration
        $configPath = Get-GitHubConfigPath
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        
        Write-Verbose "GitHub configuration saved to $configPath"
    }
    catch {
        Write-Error "Failed to set GitHub configuration: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Gets GitHub configuration settings.

.DESCRIPTION
    Retrieves stored GitHub configuration settings.

.OUTPUTS
    Hashtable containing configuration settings.
#>
function Get-GitHubConfiguration {
    [CmdletBinding()]
    param()
    
    try {
        $configPath = Get-GitHubConfigPath
        
        if (Test-Path $configPath) {
            $configJson = Get-Content -Path $configPath -Raw -Encoding UTF8
            $configObject = $configJson | ConvertFrom-Json

            # Convert PSCustomObject to hashtable for compatibility
            $config = @{}
            $configObject.PSObject.Properties | ForEach-Object {
                $config[$_.Name] = $_.Value
            }
            return $config
        }
        else {
            # Return default configuration
            return @{
                Username           = $null
                Name               = $null
                Email              = $null
                ConnectedAt        = $null
                SelectedRepository = $null
                DefaultClonePath   = Join-Path $env:USERPROFILE "Source\GitHub"
            }
        }
    }
    catch {
        Write-Verbose "Failed to get GitHub configuration: $($_.Exception.Message)"
        # Return default configuration on error
        return @{
            Username           = $null
            Name               = $null
            Email              = $null
            ConnectedAt        = $null
            SelectedRepository = $null
            DefaultClonePath   = Join-Path $env:USERPROFILE "Source\GitHub"
        }
    }
}

<#
.SYNOPSIS
    Gets the path to the GitHub configuration file.

.DESCRIPTION
    Returns the full path to the GitHub configuration file, creating the directory if needed.

.OUTPUTS
    String. The path to the configuration file.
#>
function Get-GitHubConfigPath {
    [CmdletBinding()]
    param()
    
    # Use the same config directory as other HomeLab modules
    $configDir = Join-Path $env:USERPROFILE ".homelab"
    
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    return Join-Path $configDir "github-config.json"
}
