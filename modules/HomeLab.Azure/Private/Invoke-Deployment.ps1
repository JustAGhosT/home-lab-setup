function Invoke-Deployment {
    param(
        [string]$TemplateFile,
        [string]$ComponentName,
        [string]$ResourceType,
        [string]$ResourceName,
        [int]$PollIntervalSeconds = 10,
        [int]$TimeoutMinutes = 30
    )
    Write-Log -Message "=== Deploying $ComponentName ===" -Level Info
    Write-Log -Message "Using template: $TemplateFile" -Level Debug
    Write-Log -Message "Resource parameters: ResourceType=$ResourceType, ResourceName=$ResourceName" -Level Debug

    $deployCmd = @("az", "deployment", "group", "create", "--template-file", $TemplateFile) + $commonParams
    Write-Log -Message "Constructed deploy command: $($deployCmd -join ' ')" -Level Debug

    try {
        & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
    }
    catch {
        Write-Log -Message "$ComponentName deployment encountered an error: $($_.Exception.Message)" -Level Error
        return $false
    }

    if (-not $Monitor -and ($LASTEXITCODE -ne 0)) {
        Write-Log -Message "$ComponentName deployment failed with exit code $LASTEXITCODE" -Level Error
        return $false
    }

    # If Monitor is enabled, do foreground monitoring via a runspace.
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