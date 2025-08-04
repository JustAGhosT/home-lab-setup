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
        
        # Convert SecureString to plain text
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        # Build connection string
        $connectionString = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$AdminUsername;Password=$plainPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        
        # Display connection information
        Write-ColorOutput "`nSQL Database Connection Information:" -ForegroundColor Green
        Write-ColorOutput "Server: $ServerName.database.windows.net" -ForegroundColor Gray
        Write-ColorOutput "Database: $DatabaseName" -ForegroundColor Gray
        Write-ColorOutput "Username: $AdminUsername" -ForegroundColor Gray
        Write-ColorOutput "Connection String: $connectionString" -ForegroundColor Gray
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                
                if (-not $appSettings.ConnectionStrings) {
                    $appSettings | Add-Member -MemberType NoteProperty -Name "ConnectionStrings" -Value @{}
                }
                
                $appSettings.ConnectionStrings.DefaultConnection = $connectionString
                
                $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
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
                
                $addNode = $webConfig.CreateElement("add")
                $addNode.SetAttribute("name", "DefaultConnection")
                $addNode.SetAttribute("connectionString", $connectionString)
                $addNode.SetAttribute("providerName", "System.Data.SqlClient")
                
                $connectionStringsNode.AppendChild($addNode)
                
                $webConfig.Save($webConfigPath)
                Write-ColorOutput "Updated web.config" -ForegroundColor Green
            }
            
            # Update package.json for Node.js projects
            $packageJsonPath = Join-Path -Path $ProjectPath -ChildPath "package.json"
            if (Test-Path -Path $packageJsonPath) {
                Write-ColorOutput "Updating package.json..." -ForegroundColor Gray
                $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json
                
                if (-not $packageJson.config) {
                    $packageJson | Add-Member -MemberType NoteProperty -Name "config" -Value @{}
                }
                
                $packageJson.config.sqlConnectionString = $connectionString
                
                $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                Write-ColorOutput "Updated package.json" -ForegroundColor Green
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            @"
# SQL Database Configuration
SQL_CONNECTION_STRING=$connectionString
SQL_SERVER=$ServerName.database.windows.net
SQL_DATABASE=$DatabaseName
SQL_USERNAME=$AdminUsername
SQL_PASSWORD=$plainPassword
"@ | Set-Content -Path $envPath
            Write-ColorOutput "Created .env file" -ForegroundColor Green
        }
        
        # Save connection information to a configuration file
        $configPath = Join-Path -Path $env:USERPROFILE -ChildPath ".homelab\sql-connections.json"
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
        
        $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath
        Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
        
        Write-ColorOutput "`nSQL Database connection configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring SQL Database connections: $_" -ForegroundColor Red
        throw
    }
} 