function Configure-SQLDatabaseConnections {
    <#
    .SYNOPSIS
        Configures SQL Database connection strings and settings.
    
    .DESCRIPTION
        Configures connection strings and settings for SQL Database deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER ServerName
        The SQL Server name.
    
    .PARAMETER DatabaseName
        The database name.
    
    .PARAMETER AdminUsername
        The admin username.
    
    .PARAMETER AdminPassword
        The admin password.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-SQLDatabaseConnections -ResourceGroup "my-rg" -ServerName "my-sql-server" -DatabaseName "my-database"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$ServerName,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $true)]
        [string]$AdminUsername,
        
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$AdminPassword,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring SQL Database connections..." -ForegroundColor Cyan
        
        # Helper function to mask sensitive connection strings
        function Get-MaskedConnectionString {
            param([string]$ConnectionString)
            if ([string]::IsNullOrEmpty($ConnectionString)) {
                return "[NOT SET]"
            }
            if ($ConnectionString.Length -le 8) {
                return "*" * $ConnectionString.Length
            }
            return "*" * ($ConnectionString.Length - 8) + $ConnectionString.Substring($ConnectionString.Length - 8)
        }
        
        # Convert SecureString to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        # Build connection string
        $connectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUsername;Password=$plainPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        # Clear plain text password from memory
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        $plainPassword = $null
        [System.GC]::Collect()
        
        # Display connection information
        Write-ColorOutput "`nSQL Database Connection Information:" -ForegroundColor Green
        Write-ColorOutput "Server: $ServerName.database.windows.net" -ForegroundColor Gray
        Write-ColorOutput "Database: $DatabaseName" -ForegroundColor Gray
        Write-ColorOutput "Username: $AdminUsername" -ForegroundColor Gray
        Write-ColorOutput "Connection String: $(Get-MaskedConnectionString $connectionString)" -ForegroundColor Gray
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                try {
                    $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                    if (-not $appSettings.ConnectionStrings) {
                        $appSettings | Add-Member -MemberType NoteProperty -Name "ConnectionStrings" -Value @{}
                    }
                
                    $appSettings.ConnectionStrings.DefaultConnection = $connectionString
                
                    $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                    Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
                    Write-ColorOutput "⚠️  Note: appsettings.json contains sensitive SQL connection strings - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    Write-ColorOutput "Error updating appsettings.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update appsettings.json: $($_.Exception.Message)"
                }
            }
            
            # Update web.config for .NET Framework projects
            $webConfigPath = Join-Path -Path $ProjectPath -ChildPath "web.config"
            if (Test-Path -Path $webConfigPath) {
                Write-ColorOutput "Updating web.config..." -ForegroundColor Gray
                $webConfig = [xml](Get-Content -Path $webConfigPath)
                
                $connectionStringsNode = $webConfig.SelectSingleNode("//connectionStrings")
                if (-not $connectionStringsNode) {
                    $connectionStringsNode = $webConfig.CreateElement("connectionStrings")
                    $webConfig.configuration.AppendChild($connectionStringsNode)
                }
                
                # Check if DefaultConnection already exists
                $existingNode = $connectionStringsNode.SelectSingleNode("add[@name='DefaultConnection']")
                if ($existingNode) {
                    # Update existing connection string
                    $existingNode.SetAttribute("connectionString", $connectionString)
                    $existingNode.SetAttribute("providerName", "System.Data.SqlClient")
                    Write-ColorOutput "Updated existing DefaultConnection in web.config" -ForegroundColor Green
                }
                else {
                    # Create new connection string entry
                    $addNode = $webConfig.CreateElement("add")
                    $addNode.SetAttribute("name", "DefaultConnection")
                    $addNode.SetAttribute("connectionString", $connectionString)
                    $addNode.SetAttribute("providerName", "System.Data.SqlClient")
                    
                    $connectionStringsNode.AppendChild($addNode)
                    Write-ColorOutput "Added new DefaultConnection to web.config" -ForegroundColor Green
                }
                
                $webConfig.Save($webConfigPath)
                Write-ColorOutput "Updated web.config" -ForegroundColor Green
                Write-ColorOutput "⚠️  Note: web.config contains sensitive SQL connection strings - ensure it's not committed to version control" -ForegroundColor Yellow
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                try {
                    $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                    if (-not $packageJson.config) {
                        $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                    }
                
                    $packageJson.config.sqlConnectionString = $connectionString
                
                    $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                    Write-ColorOutput "Updated package.json" -ForegroundColor Green
                    Write-ColorOutput "⚠️  Note: package.json contains sensitive SQL connection strings - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    Write-ColorOutput "Error updating package.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update package.json: $($_.Exception.Message)"
                }
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            
            # Security warning for sensitive data
            Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
            Write-ColorOutput "The .env file contains sensitive SQL Database connection strings." -ForegroundColor Yellow
            Write-ColorOutput "Please ensure this file is:" -ForegroundColor Yellow
            Write-ColorOutput "  • Added to .gitignore to prevent accidental commit to version control" -ForegroundColor Yellow
            Write-ColorOutput "  • Protected with appropriate file permissions" -ForegroundColor Yellow
            Write-ColorOutput "  • Not shared or exposed in public repositories" -ForegroundColor Yellow
            Write-ColorOutput "  • Considered for secure secret management in production environments" -ForegroundColor Yellow
            Write-ColorOutput "  • For production, use Azure Key Vault to store sensitive credentials" -ForegroundColor Yellow
            
            @"
# SQL Database Configuration
# Note: For production, use Azure Key Vault to store sensitive credentials
SQL_CONNECTION_STRING=$connectionString
SQL_SERVER=$ServerName.database.windows.net
SQL_DATABASE=$DatabaseName
SQL_USERNAME=$AdminUsername
# SQL_PASSWORD should be retrieved from Azure Key Vault at runtime
# Example: SQL_PASSWORD_KEY_VAULT_REF=https://your-keyvault.vault.azure.net/secrets/sql-password
"@ | Set-Content -Path $envPath
            Write-ColorOutput "Created .env file" -ForegroundColor Green
        }
        
        # Save connection information to a configuration file
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\sql-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup    = $ResourceGroup
            ServerName       = $ServerName
            DatabaseName     = $DatabaseName
            AdminUsername    = $AdminUsername
            ConnectionString = $connectionString
            CreatedAt        = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains sensitive SQL connection strings - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nSQL Database connection configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring SQL Database connections: $_" -ForegroundColor Red
        throw
    }
} 