<#
.SYNOPSIS
    Deploys an Azure infrastructure component using Bicep templates.
.DESCRIPTION
    This internal helper function handles the common logic for deploying infrastructure components,
    supporting both foreground and background deployment modes.
.PARAMETER ResourceGroup
    The name of the resource group to deploy to.
.PARAMETER TemplateFile
    The path to the Bicep template file.
.PARAMETER ResourceName
    The name of the resource to deploy.
.PARAMETER ResourceType
    The type of resource being deployed (e.g., "vnet", "vnet-gateway", "nat-gateway").
.PARAMETER ComponentName
    A friendly display name for the component (e.g., "Network", "VPN Gateway", "NAT Gateway").
.PARAMETER CommonParams
    An array of common parameters to pass to the deployment command.
.PARAMETER PollIntervalSeconds
    The interval in seconds between polling for deployment status.
.PARAMETER TimeoutMinutes
    The timeout in minutes for the deployment.
.PARAMETER Monitor
    If specified, monitors the deployment until completion.
.PARAMETER BackgroundMonitor
    If specified, starts background monitoring jobs instead of blocking the console.
.EXAMPLE
    Deploy-Component -ResourceGroup "my-rg" -TemplateFile "network.bicep" -ResourceName "my-vnet" -ResourceType "vnet" -ComponentName "Network" -CommonParams $params -BackgroundMonitor
.NOTES
    Author: Jurie Smit
    Date: March 10, 2025
#>
function Deploy-Component {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceName,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceType,
        
        [Parameter(Mandatory=$true)]
        [string]$ComponentName,
        
        [Parameter(Mandatory=$true)]
        [array]$CommonParams,
        
        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 30,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMinutes = 60,
        
        [Parameter(Mandatory=$false)]
        [switch]$Monitor,
        
        [Parameter(Mandatory=$false)]
        [switch]$BackgroundMonitor
    )

    # Verify template file exists
    if (-not (Test-Path -Path $TemplateFile)) {
        Write-Log -Message "Template file not found: $TemplateFile" -Level Error
        Write-Output $false
        return
    }
    
    if ($BackgroundMonitor) {
        Write-Log -Message "Launching $ComponentName deployment in background." -Level Info
        
        # Create a unique job name for better tracking
        $jobName = "Deploy_$($ComponentName.Replace(' ', ''))_$(Get-Random)"
        
        # Create the deployment job
        $deploymentScriptBlock = {
            param($ResourceGroup, $TemplateFile, $CommonParams, $ResourceName, $ResourceType, $ComponentName)
            
            # Define a simple logging function for the background job
            function Write-JobLog {
                param([string]$Message)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "[$timestamp] $Message"
            }
            
            Write-JobLog "Background job started for $ComponentName deployment..."
            
            # Convert commonParams array to a proper command line
            $deployCmd = @("az", "deployment", "group", "create", "--template-file", $TemplateFile)
            foreach ($param in $CommonParams) {
                $deployCmd += $param
            }
            
            Write-JobLog "Executing: $($deployCmd -join ' ')"
            
            try {
                # Execute the deployment command and capture output
                $result = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)] 2>&1
                $exitCode = $LASTEXITCODE
                
                Write-JobLog "Command output: $result"
                Write-JobLog "Deployment completed with exit code: $exitCode"
                
                return @{
                    Status = if ($exitCode -eq 0) { "DeploymentCompleted" } else { "Failed" }
                    ResourceGroup = $ResourceGroup
                    ResourceName = $ResourceName
                    ResourceType = $ResourceType
                    ExitCode = $exitCode
                    Output = $result
                    ComponentName = $ComponentName
                }
            }
            catch {
                Write-JobLog "Deployment failed: $_"
                return @{
                    Status = "Failed"
                    ResourceGroup = $ResourceGroup
                    ResourceName = $ResourceName
                    ResourceType = $ResourceType
                    Error = $_.Exception.Message
                    ComponentName = $ComponentName
                }
            }
        }
        
        # Start the deployment job
        $job = Start-Job -Name $jobName -ScriptBlock $deploymentScriptBlock -ArgumentList $ResourceGroup, $TemplateFile, $CommonParams, $ResourceName, $ResourceType, $ComponentName
        
        try {
            # Start monitoring in the main script after job creation
            $monitoringDetails = Start-ResourceMonitoring -ResourceGroup $ResourceGroup -ResourceType $ResourceType -ResourceName $ResourceName -PollIntervalSeconds $PollIntervalSeconds -TimeoutMinutes $TimeoutMinutes -BackgroundJob
            
            Write-Log -Message "Background deployment job started for $ComponentName (Job ID: $($job.Id))." -Level Info
            Write-Log -Message "Background monitoring started for $ComponentName." -Level Info
            
            # Prompt user to export job info
            $exportChoice = Read-Host "Do you want to export the background job info? (Y/N)"
            if ($exportChoice -match '^(Y|y)$') {
                # Create a hashtable with deployment info
                $deploymentInfo = @{
                    "Job ID" = $job.Id
                    "Job Name" = $job.Name
                    "Resource Group" = $ResourceGroup
                    "Resource Name" = $ResourceName
                    "Resource Type" = $ResourceType
                    "Component Name" = $ComponentName
                    "Template File" = $TemplateFile
                }

                # Use the fixed Export-JobInfo function
                try {
                    $exportPath = Export-JobInfo -DeploymentInfo $deploymentInfo -MonitoringInfo $monitoringDetails -Name $ComponentName.Replace(' ', '')
                }
                catch {
                    $errorMessage = $_.Exception.Message
                    Write-Log -Message "Failed to export job info: $errorMessage" -Level Error
                    # Continue execution even if export fails
                }

                Show-BackgroundJobInfo -Job $job -Detailed
            }
            
            # Don't return a hashtable directly, use Write-Output to avoid System.Object[] display
            Write-Output $true
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Log -Message "Error deploying $ComponentName`: $errorMessage" -Level Error
            Write-ColorOutput -Text "Error deploying $ComponentName`: $errorMessage" -ForegroundColor Red
            Read-Host -Prompt "Press Enter to continue..."
            Write-Output $false
        }
    }
    else {
        # If foreground monitoring is chosen, run the deployment and monitoring in the current session
        try {
            if (-not (Invoke-Deployment -TemplateFile $TemplateFile -ComponentName $ComponentName -ResourceType $ResourceType -ResourceName $ResourceName -ResourceGroup $ResourceGroup -DeploymentParams $CommonParams -Monitor:$Monitor -PollIntervalSeconds $PollIntervalSeconds -TimeoutMinutes $TimeoutMinutes)) {
                Write-Output $false
                return
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Log -Message "Error deploying $ComponentName`: $errorMessage" -Level Error
            Write-ColorOutput -Text "Error deploying $ComponentName`: $errorMessage" -ForegroundColor Red
            Read-Host -Prompt "Press Enter to continue..."
            Write-Output $false
            return
        }
    }
    
    Write-Output $true
}