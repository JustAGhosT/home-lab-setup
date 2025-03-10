function Deploy-NetworkComponent {
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

    Write-Log -Message "Deploying network resources using network.bicep" -Level Info
    $templateFile = Join-Path -Path $templatesPath -ChildPath "network.bicep"
    $resourceName = "$env-$loc-vnet-$project"
    
    # Use the shared Deploy-Component function and store the result
    $result = Deploy-Component -ResourceGroup $ResourceGroup `
                    -TemplateFile $templateFile `
                    -ResourceName $resourceName `
                    -ResourceType "vnet" `
                    -ComponentName "Network" `
                    -CommonParams $commonParams `
                    -PollIntervalSeconds 10 `
                    -TimeoutMinutes 30 `
                    -Monitor:$Monitor `
                    -BackgroundMonitor:$BackgroundMonitor
    
    # Return the result as a single value
    return $result
}
