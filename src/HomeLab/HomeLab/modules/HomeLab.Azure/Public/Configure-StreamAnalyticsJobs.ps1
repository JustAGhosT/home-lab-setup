function Configure-StreamAnalyticsJobs {
    <#
    .SYNOPSIS
        Configures Stream Analytics jobs and settings.
    
    .DESCRIPTION
        Configures jobs and settings for Stream Analytics deployments,
        including updating application configuration files.
    
    .PARAMETER ResourceGroup
        The resource group name.
    
    .PARAMETER JobName
        The Stream Analytics job name.
    
    .PARAMETER JobId
        The job ID.
    
    .PARAMETER JobStatus
        The job status.
    
    .PARAMETER InputType
        The input type.
    
    .PARAMETER InputName
        The input name.
    
    .PARAMETER OutputType
        The output type.
    
    .PARAMETER OutputName
        The output name.
    
    .PARAMETER ProjectPath
        The path to the project to configure.
    
    .EXAMPLE
        Configure-StreamAnalyticsJobs -ResourceGroup "my-rg" -JobName "my-stream-job"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$JobName,
        
        [Parameter(Mandatory = $false)]
        [string]$JobId,
        
        [Parameter(Mandatory = $false)]
        [string]$JobStatus,
        
        [Parameter(Mandatory = $false)]
        [string]$InputType,
        
        [Parameter(Mandatory = $false)]
        [string]$InputName,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputType,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputName,
        
        [Parameter(Mandatory = $false)]
        [string]$ProjectPath
    )
    
    try {
        Write-ColorOutput "Configuring Stream Analytics jobs..." -ForegroundColor Cyan
        
        # Validate Azure CLI availability and authentication
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            throw "Azure CLI is not installed or not available in PATH. Please install Azure CLI from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        }
        
        # Check if user is authenticated
        try {
            $null = az account show --query id --output tsv 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "You are not logged in to Azure. Please run 'az login' to authenticate."
            }
        }
        catch {
            throw "Azure authentication failed. Please run 'az login' to authenticate with Azure."
        }
        
        # Get job details if not provided
        if (-not $JobId -or -not $JobStatus) {
            $jobDetails = az stream-analytics job show `
                --name $JobName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if (-not $JobId) {
                $JobId = $jobDetails.id
            }
            
            if (-not $JobStatus) {
                $JobStatus = $jobDetails.properties.jobState
            }
        }
        
        # Get input and output details if not provided
        if (-not $InputName -or -not $OutputName) {
            $inputs = az stream-analytics input list `
                --job-name $JobName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            $outputs = az stream-analytics output list `
                --job-name $JobName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if (-not $InputName -and $inputs.Count -gt 0) {
                $InputName = $inputs[0].name
                $InputType = $inputs[0].properties.datasource.type
            }
            
            if (-not $OutputName -and $outputs.Count -gt 0) {
                $OutputName = $outputs[0].name
                $OutputType = $outputs[0].properties.datasource.type
            }
        }
        
        # Display connection information
        Write-ColorOutput "`nStream Analytics Job Information:" -ForegroundColor Green
        Write-ColorOutput "Job Name: $JobName" -ForegroundColor Gray
        Write-ColorOutput "Job ID: $JobId" -ForegroundColor Gray
        Write-ColorOutput "Job Status: $JobStatus" -ForegroundColor Gray
        if ($InputName) {
            Write-ColorOutput "Input Name: $InputName" -ForegroundColor Gray
            Write-ColorOutput "Input Type: $InputType" -ForegroundColor Gray
        }
        if ($OutputName) {
            Write-ColorOutput "Output Name: $OutputName" -ForegroundColor Gray
            Write-ColorOutput "Output Type: $OutputType" -ForegroundColor Gray
        }
        
        # Update project configuration files if project path is provided
        if ($ProjectPath -and (Test-Path -Path $ProjectPath)) {
            Write-ColorOutput "`nUpdating project configuration files..." -ForegroundColor Yellow
            
            # Update appsettings.json for .NET projects
            $appSettingsPath = Join-Path -Path $ProjectPath -ChildPath "appsettings.json"
            if (Test-Path -Path $appSettingsPath) {
                Write-ColorOutput "Updating appsettings.json..." -ForegroundColor Gray
                try {
                    $appSettings = Get-Content -Path $appSettingsPath | ConvertFrom-Json
                    
                    if (-not $appSettings.StreamAnalytics) {
                        $appSettings | Add-Member -MemberType NoteProperty -Name "StreamAnalytics" -Value @{}
                    }
                    
                    $appSettings.StreamAnalytics.JobName = $JobName
                    $appSettings.StreamAnalytics.JobId = $JobId
                    $appSettings.StreamAnalytics.JobStatus = $JobStatus
                    $appSettings.StreamAnalytics.InputName = $InputName
                    $appSettings.StreamAnalytics.InputType = $InputType
                    $appSettings.StreamAnalytics.OutputName = $OutputName
                    $appSettings.StreamAnalytics.OutputType = $OutputType
                    
                    $appSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $appSettingsPath
                    Write-ColorOutput "Updated appsettings.json" -ForegroundColor Green
                    Write-ColorOutput "⚠️  Note: appsettings.json contains Stream Analytics configuration data - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    Write-ColorOutput "Error updating appsettings.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update appsettings.json: $($_.Exception.Message)"
                }
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
                    
                    $packageJson.config.streamAnalyticsJobName = $JobName
                    $packageJson.config.streamAnalyticsJobId = $JobId
                    $packageJson.config.streamAnalyticsJobStatus = $JobStatus
                    $packageJson.config.streamAnalyticsInputName = $InputName
                    $packageJson.config.streamAnalyticsInputType = $InputType
                    $packageJson.config.streamAnalyticsOutputName = $OutputName
                    $packageJson.config.streamAnalyticsOutputType = $OutputType
                    
                    $packageJson | ConvertTo-Json -Depth 10 | Set-Content -Path $packageJsonPath
                    Write-ColorOutput "Updated package.json" -ForegroundColor Green
                    Write-ColorOutput "⚠️  Note: package.json contains Stream Analytics configuration data - ensure it's not committed to version control" -ForegroundColor Yellow
                }
                catch {
                    Write-ColorOutput "Error updating package.json: $($_.Exception.Message)" -ForegroundColor Red
                    throw "Failed to update package.json: $($_.Exception.Message)"
                }
            }
            
            # Create .env file for environment variables
            $envPath = Join-Path -Path $ProjectPath -ChildPath ".env"
            Write-ColorOutput "Creating .env file..." -ForegroundColor Gray
            
            # Read existing .env content if it exists
            $existingEnvContent = @()
            if (Test-Path -Path $envPath) {
                $existingEnvContent = Get-Content -Path $envPath | Where-Object { 
                    $_ -notmatch '^AZURE_STREAM_ANALYTICS_' -and -not [string]::IsNullOrWhiteSpace($_) 
                }
            }
            
            # Create new Stream Analytics environment variables
            $newEnvContent = @(
                "# Azure Stream Analytics Configuration",
                "AZURE_STREAM_ANALYTICS_JOB_NAME=$JobName",
                "AZURE_STREAM_ANALYTICS_JOB_ID=$JobId",
                "AZURE_STREAM_ANALYTICS_JOB_STATUS=$JobStatus",
                "AZURE_STREAM_ANALYTICS_INPUT_NAME=$InputName",
                "AZURE_STREAM_ANALYTICS_INPUT_TYPE=$InputType",
                "AZURE_STREAM_ANALYTICS_OUTPUT_NAME=$OutputName",
                "AZURE_STREAM_ANALYTICS_OUTPUT_TYPE=$OutputType"
            )
            
            # Combine existing and new content
            $combinedContent = $existingEnvContent + "" + $newEnvContent
            try {
                $combinedContent | Set-Content -Path $envPath -ErrorAction Stop
                Write-ColorOutput "Created .env file" -ForegroundColor Green
            
                # Security warning for .env file
                Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
                Write-ColorOutput "The .env file contains Stream Analytics configuration data." -ForegroundColor Yellow
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
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        $configPath = Join-Path -Path $userProfile -ChildPath ".homelab\stream-analytics-connections.json"
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $connectionConfig = @{
            ResourceGroup = $ResourceGroup
            JobName       = $JobName
            JobId         = $JobId
            JobStatus     = $JobStatus
            InputName     = $InputName
            InputType     = $InputType
            OutputName    = $OutputName
            OutputType    = $OutputType
            CreatedAt     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        try {
            $connectionConfig | ConvertTo-Json | Set-Content -Path $configPath -ErrorAction Stop
            Write-ColorOutput "Saved connection configuration to: $configPath" -ForegroundColor Green
            Write-ColorOutput "⚠️  Note: Connection config contains Stream Analytics configuration data - ensure file is protected" -ForegroundColor Yellow
        }
        catch {
            Write-ColorOutput "Error saving connection configuration: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to save connection configuration: $($_.Exception.Message)"
        }
        
        Write-ColorOutput "`nStream Analytics job configuration completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error configuring Stream Analytics jobs: $_" -ForegroundColor Red
        throw
    }
} 