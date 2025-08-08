function Deploy-AzureCognitiveServices {
    <#
    .SYNOPSIS
        Deploys Azure Cognitive Services.
    
    .DESCRIPTION
        Deploys Azure Cognitive Services with configurable parameters including
        service types, pricing tiers, and regional settings.
    
    .PARAMETER ResourceGroup
        The resource group name where the Cognitive Services will be deployed.
    
    .PARAMETER Location
        The Azure location for the deployment.
    
    .PARAMETER AccountName
        The name of the Cognitive Services account.
    
    .PARAMETER ServiceType
        The type of Cognitive Service (ComputerVision, TextAnalytics, SpeechServices, etc.).
    
    .PARAMETER Sku
        The SKU for the Cognitive Service (F0, S0, S1, etc.).
    
    .PARAMETER EnableCustomSubdomain
        Whether to enable custom subdomain.
    
    .PARAMETER CustomSubdomainName
        The custom subdomain name (if enabled).
    
    .PARAMETER EnableNetworkAcls
        Whether to enable network access control lists.
    
    .PARAMETER AllowedIpRanges
        Array of allowed IP ranges for network access.
    
    .EXAMPLE
        Deploy-AzureCognitiveServices -ResourceGroup "my-rg" -Location "southafricanorth" -AccountName "my-cognitive-account"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$Location,
        
        [Parameter(Mandatory = $true)]
        [string]$AccountName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("ComputerVision", "TextAnalytics", "SpeechServices", "LanguageUnderstanding", "ContentModerator", "Face", "FormRecognizer", "Personalizer", "QnAMaker", "AnomalyDetector", "Translator", "Search")]
        [string]$ServiceType = "ComputerVision",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("F0", "S0", "S1", "S2", "S3", "S4")]
        [string]$Sku = "S0",
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableCustomSubdomain = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$CustomSubdomainName,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnableNetworkAcls = $false,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AllowedIpRanges = @()
    )
    
    try {
        Write-ColorOutput "Starting Azure Cognitive Services deployment..." -ForegroundColor Cyan
        
        # Check if resource group exists
        $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
        if ($rgExists -ne "true") {
            Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
            az group create --name $ResourceGroup --location $Location
        }
        
        # Determine the kind parameter for Azure CLI
        $kind = switch ($ServiceType) {
            "ComputerVision" { "ComputerVision" }
            "TextAnalytics" { "TextAnalytics" }
            "SpeechServices" { "SpeechServices" }
            "LanguageUnderstanding" { "LUIS" }
            "ContentModerator" { "ContentModerator" }
            "Face" { "Face" }
            "FormRecognizer" { "FormRecognizer" }
            "Personalizer" { "Personalizer" }
            "QnAMaker" { "QnAMaker" }
            "AnomalyDetector" { "AnomalyDetector" }
            "Translator" { "TextTranslation" }
            "Search" { "Bing.Search.v7" }
        }
        
        # Build deployment parameters
        $createParams = @(
            "cognitiveservices", "account", "create",
            "--name", $AccountName,
            "--resource-group", $ResourceGroup,
            "--location", $Location,
            "--kind", $kind,
            "--sku", $Sku
        )
        
        # Add custom subdomain if enabled
        if ($EnableCustomSubdomain -and $CustomSubdomainName) {
            $createParams += "--custom-subdomain-name"
            $createParams += $CustomSubdomainName
        }
        
        # Create Cognitive Services account
        Write-ColorOutput "Creating Cognitive Services account: $AccountName" -ForegroundColor Yellow
        try {
            az $createParams
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create Cognitive Services account '$AccountName'. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully created Cognitive Services account: $AccountName" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error creating Cognitive Services account '$AccountName': $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to create Cognitive Services account '$AccountName': $($_.Exception.Message)"
        }
        
        # Configure network access if enabled
        if ($EnableNetworkAcls -and $AllowedIpRanges.Count -gt 0) {
            Write-ColorOutput "Configuring network access control..." -ForegroundColor Yellow
            try {
                foreach ($ipRange in $AllowedIpRanges) {
                    Write-ColorOutput "Adding IP range: $ipRange" -ForegroundColor Gray
                    az cognitiveservices account network-rule add `
                        --name $AccountName `
                        --resource-group $ResourceGroup `
                        --ip-address $ipRange
                    
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to add IP range '$ipRange'. Exit code: $LASTEXITCODE"
                    }
                }
                Write-ColorOutput "Successfully configured network access control" -ForegroundColor Green
            }
            catch {
                Write-ColorOutput "Error configuring network access control: $($_.Exception.Message)" -ForegroundColor Red
                throw "Failed to configure network access control: $($_.Exception.Message)"
            }
        }
        
        # Get account keys
        Write-ColorOutput "Getting account keys..." -ForegroundColor Yellow
        try {
            $key1 = az cognitiveservices account keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --query "key1" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve key1. Exit code: $LASTEXITCODE"
            }
            
            $key2 = az cognitiveservices account keys list `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --query "key2" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve key2. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully retrieved account keys" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving account keys: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve account keys for '$AccountName': $($_.Exception.Message)"
        }
        
        # Helper function to mask sensitive keys
        function Get-MaskedKey {
            param([string]$Key, [int]$VisibleChars = 4)
            if ([string]::IsNullOrEmpty($Key)) {
                return "[NOT SET]"
            }
            if ($Key.Length -le $VisibleChars) {
                return "*" * $Key.Length
            }
            return "*" * ($Key.Length - $VisibleChars) + $Key.Substring($Key.Length - $VisibleChars)
        }
        
        # Get account endpoint
        try {
            $endpoint = az cognitiveservices account show `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --query "properties.endpoint" `
                --output tsv
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve account endpoint. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully retrieved account endpoint" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving account endpoint: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve account endpoint for '$AccountName': $($_.Exception.Message)"
        }
        
        # Get account details
        try {
            $accountDetails = az cognitiveservices account show `
                --name $AccountName `
                --resource-group $ResourceGroup `
                --output json | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to retrieve account details. Exit code: $LASTEXITCODE"
            }
            
            Write-ColorOutput "Successfully retrieved account details" -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Error retrieving account details: $($_.Exception.Message)" -ForegroundColor Red
            throw "Failed to retrieve account details for '$AccountName': $($_.Exception.Message)"
        }
        
        # Display deployment summary
        Write-ColorOutput "`nAzure Cognitive Services deployment completed successfully!" -ForegroundColor Green
        Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
        Write-ColorOutput "Account Name: $AccountName" -ForegroundColor Gray
        Write-ColorOutput "Service Type: $ServiceType" -ForegroundColor Gray
        Write-ColorOutput "SKU: $Sku" -ForegroundColor Gray
        Write-ColorOutput "Endpoint: $endpoint" -ForegroundColor Gray
        Write-ColorOutput "Key 1: $(Get-MaskedKey -Key $key1)" -ForegroundColor Gray
        Write-ColorOutput "Key 2: $(Get-MaskedKey -Key $key2)" -ForegroundColor Gray
        
        if ($EnableCustomSubdomain -and $CustomSubdomainName) {
            Write-ColorOutput "Custom Subdomain: $CustomSubdomainName" -ForegroundColor Gray
        }
        
        # Security warning for sensitive data
        Write-ColorOutput "`n⚠️  SECURITY WARNING ⚠️" -ForegroundColor Red
        Write-ColorOutput "The returned object contains sensitive Cognitive Services API keys." -ForegroundColor Yellow
        Write-ColorOutput "Please ensure this data is:" -ForegroundColor Yellow
        Write-ColorOutput "  • Not logged or written to files" -ForegroundColor Yellow
        Write-ColorOutput "  • Not committed to version control" -ForegroundColor Yellow
        Write-ColorOutput "  • Stored securely in production environments" -ForegroundColor Yellow
        Write-ColorOutput "  • Considered for Azure Key Vault integration" -ForegroundColor Yellow
        
        # Return deployment info
        return @{
            ResourceGroup       = $ResourceGroup
            AccountName         = $AccountName
            ServiceType         = $ServiceType
            Sku                 = $Sku
            Endpoint            = $endpoint
            Key1                = $key1
            Key2                = $key2
            CustomSubdomainName = $CustomSubdomainName
            AccountDetails      = $accountDetails
        }
    }
    catch {
        Write-ColorOutput "Error deploying Azure Cognitive Services: $_" -ForegroundColor Red
        throw
    }
} 