class DeploymentMonitor {
    [string]$ResourceGroup
    [string]$ResourceType
    [string]$ResourceName
    [int]$PollIntervalSeconds
    [int]$TimeoutMinutes

    DeploymentMonitor([string]$ResourceGroup, [string]$ResourceType, [string]$ResourceName, [int]$PollIntervalSeconds, [int]$TimeoutMinutes) {
        $this.ResourceGroup = $ResourceGroup
        $this.ResourceType  = $ResourceType
        $this.ResourceName  = $ResourceName
        $this.PollIntervalSeconds = $PollIntervalSeconds
        $this.TimeoutMinutes = $TimeoutMinutes
        Write-Log -Message "DeploymentMonitor created for $ResourceType '$ResourceName' in $ResourceGroup" -Level Debug
    }

    [bool] Monitor() {
        # Call the existing Monitor-AzureResourceDeployment function.
        $result = Monitor-AzureResourceDeployment -ResourceGroup $this.ResourceGroup `
                                                  -ResourceType $this.ResourceType `
                                                  -ResourceName $this.ResourceName `
                                                  -PollIntervalSeconds $this.PollIntervalSeconds `
                                                  -TimeoutMinutes $this.TimeoutMinutes
        Write-Log -Message "Monitoring result for $($this.ResourceType) '$($this.ResourceName)' is $result" -Level Debug
        return $result
    }
}