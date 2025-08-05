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
            
            # Update web.config for .NET Framework projects with encryption
            $webConfigPath = Join-Path -Path $ProjectPath -ChildPath "web.config"
            if (Test-Path -Path $webConfigPath) {
                Write-ColorOutput "Updating web.config..." -ForegroundColor Gray
                
                # Create temporary file for atomic write
                $tempWebConfigPath = $webConfigPath + ".tmp"
                
                try {
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
                    
                    # Save to temporary file first
                    $webConfig.Save($tempWebConfigPath)
                    
                    # Atomic move to replace original file
                    Move-Item -Path $tempWebConfigPath -Destination $webConfigPath -Force
                    
                    Write-ColorOutput "Updated web.config" -ForegroundColor Green
                    
                    # Attempt to encrypt the connectionStrings section
                    try {
                        Write-ColorOutput "Attempting to encrypt connectionStrings section..." -ForegroundColor Yellow
                        
                        # Check if aspnet_regiis is available
                        $aspnetRegiisPath = "${env:windir}\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe"
                        if (Test-Path -Path $aspnetRegiisPath) {
                            $projectDir = Split-Path -Path $webConfigPath -Parent
                            & $aspnetRegiisPath -pef "connectionStrings" $projectDir -prov "DataProtectionConfigurationProvider"
                            Write-ColorOutput "Successfully encrypted connectionStrings section" -ForegroundColor Green
                        }
                        else {
                            Write-ColorOutput "⚠️  aspnet_regiis not found. Consider manually encrypting connectionStrings section." -ForegroundColor Yellow
                            Write-ColorOutput "For production, use Azure Key Vault to store connection strings securely." -ForegroundColor Yellow
                        }
                    }
                    catch {
                        Write-ColorOutput "⚠️  Could not encrypt connectionStrings section: $($_.Exception.Message)" -ForegroundColor Yellow
                        Write-ColorOutput "For production, use Azure Key Vault to store connection strings securely." -ForegroundColor Yellow
                    }
                    
                    Write-ColorOutput "⚠️  Note: web.config contains sensitive SQL connection strings - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    # Clean up temporary file if it exists
                    if (Test-Path -Path $tempWebConfigPath) {
                        Remove-Item -Path $tempWebConfigPath -Force -ErrorAction SilentlyContinue
                    }
                    throw
                }
            }
            
            # Note: package.json updates removed for security - connection strings should not be stored in version-controlled files
            Write-ColorOutput "⚠️  Security Note: package.json updates skipped to prevent storing sensitive connection strings in version control" -ForegroundColor Yellow
            Write-ColorOutput "Use environment variables or Azure Key Vault for secure connection string storage" -ForegroundColor Yellow
            
            # Create .env file for environment variables with enhanced security
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            
            # Enhanced security warning for sensitive data
            Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
            Write-ColorOutput "The .env file will contain sensitive SQL Database connection strings and credentials." -ForegroundColor Yellow
            Write-ColorOutput "These connection strings provide access to your database and should be protected." -ForegroundColor Yellow
            Write-ColorOutput "For production environments, consider using Azure Key Vault for secure storage." -ForegroundColor Yellow
            Write-ColorOutput "Ensure .env is added to .gitignore to prevent accidental commits to version control." -ForegroundColor Yellow
            Write-ColorOutput "File location: $envPath" -ForegroundColor Gray
            
            # Check if .gitignore exists and contains .env
            $gitignorePath = Join-Path -Path $ProjectPath -ChildPath ".gitignore"
            if (Test-Path -Path $gitignorePath) {
                $gitignoreContent = Get-Content -Path $gitignorePath
                if ($gitignoreContent -notcontains ".env") {
                    Write-ColorOutput "Adding .env to .gitignore for security..." -ForegroundColor Cyan
                    Add-Content -Path $gitignorePath -Value "`n# Environment variables with sensitive data`n.env"
                }
            }
            else {
                Write-ColorOutput "Creating .gitignore file with .env exclusion..." -ForegroundColor Cyan
                @"
# Environment variables with sensitive data
.env

# Other common exclusions
node_modules/
*.log
.DS_Store
"@ | Set-Content -Path $gitignorePath
            }
            
            # Create temporary file for atomic write
            $tempEnvPath = $envPath + ".tmp"
            
            try {
                @"
# SQL Database Configuration
# SECURITY WARNING: This file contains sensitive connection strings
# For production, use Azure Key Vault to store sensitive credentials
# Example: SQL_PASSWORD_KEY_VAULT_REF=https://your-keyvault.vault.azure.net/secrets/sql-password

# Database connection details (non-sensitive)
SQL_SERVER=$ServerName.database.windows.net
SQL_DATABASE=$DatabaseName
SQL_USERNAME=$AdminUsername

# Connection string (sensitive - consider using Azure Key Vault in production)
SQL_CONNECTION_STRING=$connectionString

# Azure Key Vault integration (recommended for production)
# AZURE_KEY_VAULT_URL=https://your-keyvault.vault.azure.net/
# AZURE_KEY_VAULT_SECRET_NAME=sql-connection-string
"@ | Set-Content -Path $tempEnvPath -ErrorAction Stop
                
                # Atomic move to replace original file
                Move-Item -Path $tempEnvPath -Destination $envPath -Force
                Write-ColorOutput "Created .env file with security protections" -ForegroundColor Green
            }
            catch {
                # Clean up temporary file if it exists
                if (Test-Path -Path $tempEnvPath) {
                    Remove-Item -Path $tempEnvPath -Force -ErrorAction SilentlyContinue
                }
                throw "Failed to create .env file: $($_.Exception.Message)"
            }
        }
        
        # Save connection information to a configuration file
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\sql-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup             = $ResourceGroup
            ServerName                = $ServerName
            DatabaseName              = $DatabaseName
            AdminUsername             = $AdminUsername
            # ConnectionString removed for security - use Azure Key Vault or environment variables
            ConnectionStringReference = "Use Azure Key Vault or environment variables for secure storage"
            SecurityNote              = "Sensitive connection strings should be stored in Azure Key Vault, not in configuration files"
            CreatedAt                 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
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