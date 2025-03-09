function Deploy-VPNGatewayComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [string]$location,
        
        [Parameter(Mandatory=$true)]
        [string]$env,
        
        [Parameter(Mandatory=$true)]
        [string]$loc,
        
        [Parameter(Mandatory=$true)]
        [string]$project,
        
        [Parameter(Mandatory=$true)]
        [array]$commonParams,
        
        [Parameter(Mandatory=$true)]
        [string]$templatesPath,
        
        [Parameter(Mandatory=$false)]
        [switch]$Monitor,
        
        [Parameter(Mandatory=$false)]
        [switch]$BackgroundMonitor
    )

    Write-Log -Message "Deploying VPN gateway using vpn-gateway.bicep" -Level Info
    $templateFile = Join-Path -Path $templatesPath -ChildPath "vpn-gateway.bicep"
    $resourceName = "$env-$loc-vpng-$project"

    if ($BackgroundMonitor) {
        Write-Log -Message "Launching VPN gateway deployment in background." -Level Info
        
        # Create a unique job name for better tracking
        $jobName = "Deploy_VpnGateway_$(Get-Random)"
        
        # Create the deployment job
        $deploymentScriptBlock = {
            param($ResourceGroup, $templateFile, $commonParams, $resourceName)
            
            # Define a simple logging function for the background job
            function Write-JobLog {
                param([string]$Message)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Output "[$timestamp] $Message"
            }
            
            Write-JobLog "Background job started for VPN Gateway deployment..."
            $deployCmd = @("az", "deployment", "group", "create", "--template-file", $templateFile) + $commonParams
            Write-JobLog "Executing: $($deployCmd -join ' ')"
            
            try {
                # Execute the deployment command
                & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)] | Out-Null
                Write-JobLog "Deployment completed successfully."
                
                return @{
                    Status = "DeploymentCompleted"
                    ResourceGroup = $ResourceGroup
                    ResourceName = $resourceName
                    ResourceType = "vnet-gateway"
                }
            }
            catch {
                Write-JobLog "Deployment failed: $_"
                return @{
                    Status = "Failed"
                    ResourceGroup = $ResourceGroup
                    ResourceName = $resourceName
                    ResourceType = "vnet-gateway"
                    Error = $_
                }
            }
        }
        
        # Start the deployment job
        $job = Start-Job -Name $jobName -ScriptBlock $deploymentScriptBlock -ArgumentList $ResourceGroup, $templateFile, $commonParams, $resourceName
        
        # Instead of trying to call Start-BackgroundMonitoring from the job,
        # we'll start monitoring here in the main script
        try {
            # Start monitoring in the main script after job creation
            $monitoringDetails = Start-ResourceMonitoring -ResourceGroup $ResourceGroup -ResourceType "vnet-gateway" -ResourceName $resourceName -PollIntervalSeconds 30 -TimeoutMinutes 60 -BackgroundJob
            
            Write-Log -Message "Background deployment job started for VPN Gateway (Job ID: $($job.Id))." -Level Info
            Write-Log -Message "Background monitoring started for VPN Gateway." -Level Info
            
            # Prompt user to export job info
            $exportChoice = Read-Host "Do you want to export the background job info? (Y/N)"
            if ($exportChoice -match '^(Y|y)$') {
                # Export deployment job info
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $exportPath = Join-Path -Path $env:TEMP -ChildPath "JobInfo_VpnGateway_$timestamp.txt"
                
                $jobInfo = @"
Deployment Job:
- Job ID: $($job.Id)
- Job Name: $($job.Name)
- Resource Group: $ResourceGroup
- Resource Name: $resourceName
- Resource Type: vnet-gateway

Monitoring Details:
$($monitoringDetails | Out-String)
"@
                
                $jobInfo | Out-File -FilePath $exportPath
                Write-Log -Message "Job info exported to $exportPath" -Level Info
            }
            
            return @{
                DeploymentJob = @{
                    JobName = $jobName
                    JobId = $job.Id
                }
                MonitoringDetails = $monitoringDetails
            }
        }
        catch {
            Write-Log -Message "Error deploying VPN Gateway: $_" -Level Error
            Write-ColorOutput -Text "Error deploying VPN Gateway: $_" -ForegroundColor Red
            Read-Host -Prompt "Press Enter to continue..."
            return $false
        }
    }
    else {
        # If foreground monitoring is chosen, run the deployment and monitoring in the current session
        try {
            if (-not (Invoke-Deployment -TemplateFile $templateFile -ComponentName "VPN Gateway" -ResourceType "vnet-gateway" -ResourceName $resourceName -PollIntervalSeconds 30 -TimeoutMinutes 60)) {
                return $false
            }
        }
        catch {
            Write-Log -Message "Error deploying VPN Gateway: $_" -Level Error
            Write-ColorOutput -Text "Error deploying VPN Gateway: $_" -ForegroundColor Red
            Read-Host -Prompt "Press Enter to continue..."
            return $false
        }
    }
    
    return $true
}