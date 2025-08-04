function Get-AIMLDeploymentParameters {
    <#
    .SYNOPSIS
        Gets AI/ML deployment parameters from user input.
    
    .DESCRIPTION
        Prompts the user for AI/ML deployment parameters and returns them as a hashtable.
    
    .PARAMETER DeploymentType
        The type of AI/ML deployment (azurecognitive, azureml, azurestreamanalytics, etc.).
    
    .PARAMETER Config
        The configuration object containing default values.
    
    .EXAMPLE
        Get-AIMLDeploymentParameters -DeploymentType "azurecognitive" -Config $config
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DeploymentType,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )
    
    try {
        Write-ColorOutput "`nCollecting AI/ML deployment parameters..." -ForegroundColor Cyan
        
        # Get basic parameters
        $resourceGroup = Read-Host "Resource Group Name (default: $($config.env)-$($config.loc)-rg-$($config.project))"
        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
            $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
        }
        
        $location = Read-Host "Location (default: $($config.location))"
        if ([string]::IsNullOrWhiteSpace($location)) {
            $location = $config.location
        }
        
        switch ($DeploymentType) {
            "azurecognitive" {
                $accountName = Read-Host "Cognitive Services Account Name (default: $($config.env)-$($config.loc)-cognitive-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($accountName)) {
                    $accountName = "$($config.env)-$($config.loc)-cognitive-$($config.project)"
                }
                
                $serviceType = Read-Host "Service Type (ComputerVision/TextAnalytics/SpeechServices/LanguageUnderstanding/ContentModerator/Face/FormRecognizer/Personalizer/QnAMaker/AnomalyDetector/Translator/Search) (default: ComputerVision)"
                if ([string]::IsNullOrWhiteSpace($serviceType)) {
                    $serviceType = "ComputerVision"
                }
                
                $sku = Read-Host "SKU (F0/S0/S1/S2/S3/S4) (default: S0)"
                if ([string]::IsNullOrWhiteSpace($sku)) {
                    $sku = "S0"
                }
                
                $enableCustomSubdomain = Read-Host "Enable Custom Subdomain (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableCustomSubdomain) -or $enableCustomSubdomain -eq "n") {
                    $enableCustomSubdomain = $false
                }
                else {
                    $enableCustomSubdomain = $true
                }
                
                $customSubdomainName = $null
                if ($enableCustomSubdomain) {
                    $customSubdomainName = Read-Host "Custom Subdomain Name"
                }
                
                $enableNetworkAcls = Read-Host "Enable Network ACLs (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableNetworkAcls) -or $enableNetworkAcls -eq "n") {
                    $enableNetworkAcls = $false
                }
                else {
                    $enableNetworkAcls = $true
                }
                
                $allowedIpRanges = @()
                if ($enableNetworkAcls) {
                    $ipRanges = Read-Host "Allowed IP Ranges (comma-separated, e.g., 192.168.1.0/24,10.0.0.0/8)"
                    if (-not [string]::IsNullOrWhiteSpace($ipRanges)) {
                        $allowedIpRanges = $ipRanges.Split(",") | ForEach-Object { $_.Trim() }
                    }
                }
                
                return @{
                    ResourceGroup         = $resourceGroup
                    Location              = $location
                    AccountName           = $accountName
                    ServiceType           = $serviceType
                    Sku                   = $sku
                    EnableCustomSubdomain = $enableCustomSubdomain
                    CustomSubdomainName   = $customSubdomainName
                    EnableNetworkAcls     = $enableNetworkAcls
                    AllowedIpRanges       = $allowedIpRanges
                }
            }
            
            "azureml" {
                $workspaceName = Read-Host "ML Workspace Name (default: $($config.env)-$($config.loc)-ml-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($workspaceName)) {
                    $workspaceName = "$($config.env)-$($config.loc)-ml-$($config.project)"
                }
                
                $storageAccountName = Read-Host "Storage Account Name (leave empty for auto-generation)"
                if ([string]::IsNullOrWhiteSpace($storageAccountName)) {
                    $storageAccountName = $null
                }
                
                $applicationInsightsName = Read-Host "Application Insights Name (leave empty for auto-generation)"
                if ([string]::IsNullOrWhiteSpace($applicationInsightsName)) {
                    $applicationInsightsName = $null
                }
                
                $keyVaultName = Read-Host "Key Vault Name (leave empty for auto-generation)"
                if ([string]::IsNullOrWhiteSpace($keyVaultName)) {
                    $keyVaultName = $null
                }
                
                $containerRegistryName = Read-Host "Container Registry Name (optional, leave empty to skip)"
                if ([string]::IsNullOrWhiteSpace($containerRegistryName)) {
                    $containerRegistryName = $null
                }
                
                $enableHbiWorkspace = Read-Host "Enable High Business Impact Workspace (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableHbiWorkspace) -or $enableHbiWorkspace -eq "n") {
                    $enableHbiWorkspace = $false
                }
                else {
                    $enableHbiWorkspace = $true
                }
                
                $enableSoftDelete = Read-Host "Enable Soft Delete for Key Vault (y/n) (default: y)"
                if ([string]::IsNullOrWhiteSpace($enableSoftDelete) -or $enableSoftDelete -eq "y") {
                    $enableSoftDelete = $true
                }
                else {
                    $enableSoftDelete = $false
                }
                
                $enablePublicAccess = Read-Host "Enable Public Access (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enablePublicAccess) -or $enablePublicAccess -eq "n") {
                    $enablePublicAccess = $false
                }
                else {
                    $enablePublicAccess = $true
                }
                
                return @{
                    ResourceGroup           = $resourceGroup
                    Location                = $location
                    WorkspaceName           = $workspaceName
                    StorageAccountName      = $storageAccountName
                    ApplicationInsightsName = $applicationInsightsName
                    KeyVaultName            = $keyVaultName
                    ContainerRegistryName   = $containerRegistryName
                    EnableHbiWorkspace      = $enableHbiWorkspace
                    EnableSoftDelete        = $enableSoftDelete
                    EnablePublicAccess      = $enablePublicAccess
                }
            }
            
            "azurestreamanalytics" {
                $jobName = Read-Host "Stream Analytics Job Name (default: $($config.env)-$($config.loc)-stream-$($config.project))"
                if ([string]::IsNullOrWhiteSpace($jobName)) {
                    $jobName = "$($config.env)-$($config.loc)-stream-$($config.project)"
                }
                
                $streamingUnits = Read-Host "Streaming Units (1-192) (default: 1)"
                if ([string]::IsNullOrWhiteSpace($streamingUnits)) {
                    $streamingUnits = 1
                }
                else {
                    $streamingUnits = [int]$streamingUnits
                }
                
                $inputType = Read-Host "Input Type (EventHub/IoTHub/Blob/PowerBI/DataLake) (default: EventHub)"
                if ([string]::IsNullOrWhiteSpace($inputType)) {
                    $inputType = "EventHub"
                }
                
                $inputName = Read-Host "Input Name (leave empty for auto-generation)"
                if ([string]::IsNullOrWhiteSpace($inputName)) {
                    $inputName = $null
                }
                
                $outputType = Read-Host "Output Type (EventHub/Blob/SQL/CosmosDB/PowerBI/DataLake) (default: Blob)"
                if ([string]::IsNullOrWhiteSpace($outputType)) {
                    $outputType = "Blob"
                }
                
                $outputName = Read-Host "Output Name (leave empty for auto-generation)"
                if ([string]::IsNullOrWhiteSpace($outputName)) {
                    $outputName = $null
                }
                
                $query = Read-Host "Stream Analytics Query (optional, leave empty to skip)"
                if ([string]::IsNullOrWhiteSpace($query)) {
                    $query = $null
                }
                
                $enableJobStart = Read-Host "Start Job After Creation (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableJobStart) -or $enableJobStart -eq "n") {
                    $enableJobStart = $false
                }
                else {
                    $enableJobStart = $true
                }
                
                $enableContentLogging = Read-Host "Enable Content Logging (y/n) (default: n)"
                if ([string]::IsNullOrWhiteSpace($enableContentLogging) -or $enableContentLogging -eq "n") {
                    $enableContentLogging = $false
                }
                else {
                    $enableContentLogging = $true
                }
                
                return @{
                    ResourceGroup        = $resourceGroup
                    Location             = $location
                    JobName              = $jobName
                    StreamingUnits       = $streamingUnits
                    InputType            = $inputType
                    InputName            = $inputName
                    OutputType           = $outputType
                    OutputName           = $outputName
                    Query                = $query
                    EnableJobStart       = $enableJobStart
                    EnableContentLogging = $enableContentLogging
                }
            }
            
            default {
                Write-ColorOutput "Unsupported deployment type: $DeploymentType" -ForegroundColor Red
                return $null
            }
        }
    }
    catch {
        Write-ColorOutput "Error getting AI/ML deployment parameters: $_" -ForegroundColor Red
        return $null
    }
} 