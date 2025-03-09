# Import all function files
$functionFiles = Get-ChildItem -Path "$PSScriptRoot\Functions" -Filter "*.ps1" -Recurse

# Dot source each function file
foreach ($file in $functionFiles) {
    . $file.FullName
}

# Export all functions
Export-ModuleMember -Function Invoke-DeployMenu, 
                             Invoke-FullDeployment, 
                             Invoke-NetworkDeployment, 
                             Invoke-VPNGatewayDeployment, 
                             Invoke-NATGatewayDeployment, 
                             Show-DeploymentStatus, 
                             Show-BackgroundMonitoringStatus
