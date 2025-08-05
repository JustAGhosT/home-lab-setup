function Configure-CognitiveServicesEndpoints {
    <#
    .SYNOPSIS
        Configures Cognitive Services endpoints and settings.
    
    .DESCRIPTION
        Configures endpoints and settings for Cognitive Services deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER AccountName
        The Cognitive Services account name.
    
    .PARAMETER ServiceType
        The type of Cognitive Service.
    
    .PARAMETER Endpoint
        The service endpoint.
    
    .PARAMETER Key1
        The primary key.
    
    .PARAMETER Key2
        The secondary key.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-CognitiveServicesEndpoints -ResourceGroup "my-rg" -AccountName "my-cognitive-account"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$AccountName,
        
        [Parameter(Mandatory = $false)]
        [string]$ServiceType,
        
        [Parameter(Mandatory = $false)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $false)]
        [string]$Key1,
        
        [Parameter(Mandatory = $false)]
        [string]$Key2,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring Cognitive Services endpoints..." -ForegroundColor Cyan
        
        # Helper function to mask sensitive keys
        function Get-MaskedKey {
            param([string]$Key)
            if ([string]::IsNullOrEmpty($Key)) {
                return "[NOT SET]"
            }
            if ($Key.Length -le 4) {
                return "*" * $Key.Length
            }
            return "*" * ($Key.Length - 4) + $Key.Substring($Key.Length - 4)
        }
        
        # Get endpoint and keys if not provided
        if (-not $Endpoint) {
            $Endpoint = az cognitiveservices account show `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --query "properties.endpoint" `
                --output tsv
        }
        
        if (-not $Key1) {
            $Key1 = az cognitiveservices account keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --query "key1" `
                --output tsv
        }
        
        if (-not $Key2) {
            $Key2 = az cognitiveservices account keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --query "key2" `
                --output tsv
        }
        
        # Get service type if not provided
        if (-not $ServiceType) {
            $ServiceType = az cognitiveservices account show `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --query "kind" `
                --output tsv
        }
        
        # Display connection information
        Write-ColorOutput "`nCognitive Services Connection Information:" -ForegroundColor Green
        Write-ColorOutput "Account: $AccountName" -ForegroundColor Gray
        Write-ColorOutput "Service Type: $ServiceType" -ForegroundColor Gray
        Write-ColorOutput "Endpoint: $Endpoint" -ForegroundColor Gray
        Write-ColorOutput "Key 1: $(Get-MaskedKey -Key $Key1)" -ForegroundColor Gray
        Write-ColorOutput "Key 2: $(Get-MaskedKey -Key $Key2)" -ForegroundColor Gray
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                if (-not $appSettings.CognitiveServices) {
                    $appSettings | Add-Member -MemberType NoteProperty -Name "CognitiveServices" -Value @{}
                }
                
                $appSettings.CognitiveServices.AccountName = $AccountName
                $appSettings.CognitiveServices.ServiceType = $ServiceType
                $appSettings.CognitiveServices.Endpoint = $Endpoint
                $appSettings.CognitiveServices.Key1 = $Key1
                $appSettings.CognitiveServices.Key2 = $Key2
                
                $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
                Write-ColorOutput "⚠️  Note: appsettings.json contains sensitive API keys - ensure it's not committed to version control" -ForegroundColor Yellow
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                if (-not $packageJson.config) {
                    $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                }
                
                $packageJson.config.cognitiveServicesAccountName = $AccountName
                $packageJson.config.cognitiveServicesType = $ServiceType
                $packageJson.config.cognitiveServicesEndpoint = $Endpoint
                $packageJson.config.cognitiveServicesKey1 = $Key1
                $packageJson.config.cognitiveServicesKey2 = $Key2
                
                $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                Write-ColorOutput "Updated package.json" -ForegroundColor Green
                Write-ColorOutput "⚠️  Note: package.json contains sensitive API keys - ensure it's not committed to version control" -ForegroundColor Yellow
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            try {
                @"
# Azure Cognitive Services Configuration
AZURE_COGNITIVE_SERVICES_ACCOUNT_NAME=$AccountName
AZURE_COGNITIVE_SERVICES_TYPE=$ServiceType
AZURE_COGNITIVE_SERVICES_ENDPOINT=$Endpoint
AZURE_COGNITIVE_SERVICES_KEY1=$Key1
AZURE_COGNITIVE_SERVICES_KEY2=$Key2
"@ | Set-Content -Path $envPath -ErrorAction Stop
                Write-ColorOutput "Created .env file" -ForegroundColor Green
                
                # Security warning for .env file
                Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
                Write-ColorOutput "The .env file contains sensitive Azure Cognitive Services API keys." -ForegroundColor Yellow
                Write-ColorOutput "Please ensure this file is:" -ForegroundColor Yellow
                Write-ColorOutput "  • Added to .gitignore to prevent accidental commit to version control" -ForegroundColor Yellow
                Write-ColorOutput "  • Protected with appropriate file permissions" -ForegroundColor Yellow
                Write-ColorOutput "  • Not shared or exposed in public repositories" -ForegroundColor Yellow
                Write-ColorOutput "  • Considered for secure secret management in production environments" -ForegroundColor Yellow
                Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
            }
            catch {
                Write-ColorOutput "Error creating .env file: $($_.Exception.Message)" -ForegroundColor Red
                Write-ColorOutput "This may be due to file permissions or disk space issues." -ForegroundColor Yellow
                throw "Failed to create .env file: $($_.Exception.Message)"
            }
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\cognitive-services-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup = $ResourceGroup
            AccountName   = $AccountName
            ServiceType   = $ServiceType
            Endpoint      = $Endpoint
            Key1          = $Key1
            Key2          = $Key2
            CreatedAt     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains sensitive API keys - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nCognitive Services endpoint configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring Cognitive Services endpoints: $_" -ForegroundColor Red
        throw
    }
} 