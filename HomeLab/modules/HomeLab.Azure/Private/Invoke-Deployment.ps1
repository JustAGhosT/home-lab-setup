function Invoke-Deployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        
        [Parameter(Mandatory=$true)]
        [string]$ComponentName,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceType,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceName,
        
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory=$true)]
        [array]$DeploymentParams,
        
        [Parameter(Mandatory=$false)]
        [switch]$Monitor,
        
        [Parameter(Mandatory=$false)]
        [int]$PollIntervalSeconds = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMinutes = 30
    )
    
    Write-Log -Message "=== Deploying $ComponentName ===" -Level Info
    Write-Log -Message "Using template: $TemplateFile" -Level Debug
    Write-Log -Message "Resource parameters: ResourceType=$ResourceType, ResourceName=$ResourceName, ResourceGroup=$ResourceGroup" -Level Debug
    
    # Verify template file exists
    if (-not (Test-Path -Path $TemplateFile)) {
        Write-Log -Message "Template file not found: $TemplateFile" -Level Error
        return $false
    }

    # Construct the deployment command
    $deployCmd = @("az", "deployment", "group", "create", "--template-file", $TemplateFile) + $DeploymentParams
    Write-Log -Message "Final command: $($deployCmd -join ' ')" -Level Debug

    try {
        # Execute the deployment command and capture output
        $result = & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)] 2>&1
        Write-Log -Message "Command output: $result" -Level Debug
    }
    catch {
        Write-Log -Message "$ComponentName deployment encountered an error: $($_.Exception.Message)" -Level Error
        return $false
    }

    if (-not $Monitor -and ($LASTEXITCODE -ne 0)) {
        Write-Log -Message "$ComponentName deployment failed with exit code $LASTEXITCODE" -Level Error
        return $false
    }

    # If Monitor is enabled, do foreground monitoring via a runspace
    if ($Monitor) {
        Write-Log -Message "Starting foreground monitoring for $ComponentName deployment." -Level Info
        $monitorScript = {
            param($ResourceGroup, $ResourceType, $ResourceName, $PollIntervalSeconds, $TimeoutMinutes)
            $monitorInstance = [DeploymentMonitor]::new($ResourceGroup, $ResourceType, $ResourceName, $PollIntervalSeconds, $TimeoutMinutes)
            return $monitorInstance.Monitor()
        }
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
        $runspacePool.Open()
        $psInstance = [powershell]::Create()
        $psInstance.RunspacePool = $runspacePool
        $psInstance.AddScript($monitorScript).AddArgument($ResourceGroup).AddArgument($ResourceType).AddArgument($ResourceName).AddArgument($PollIntervalSeconds).AddArgument($TimeoutMinutes) | Out-Null
        $handle = $psInstance.BeginInvoke()
        $resultMonitor = $psInstance.EndInvoke($handle)
        $psInstance.Dispose()
        $runspacePool.Close()
        $runspacePool.Dispose()

        if (-not $resultMonitor) {
            Write-Log -Message "$ComponentName deployment monitoring failed or timed out" -Level Warning
            return $false
        }
    }

    Write-Log -Message "$ComponentName deployment completed successfully" -Level Success
    return $true
}
