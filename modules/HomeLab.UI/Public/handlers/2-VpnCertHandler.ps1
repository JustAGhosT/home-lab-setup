<#
.SYNOPSIS
    VPN Certificate menu handler for HomeLab setup
.DESCRIPTION
    Processes user selections in the VPN certificate menu using the new VPN certificate management functions.
    Displays progress bars for certificate operations.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu.
.EXAMPLE
    Invoke-VpnCertMenu
.EXAMPLE
    Invoke-VpnCertMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Invoke-VpnCertMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    # Check if required functions exist
    $requiredFunctions = @(
        "Show-VpnCertMenu",
        "Get-Configuration",
        "Pause"
    )
    
    foreach ($function in $requiredFunctions) {
        if (-not (Get-Command -Name $function -ErrorAction SilentlyContinue)) {
            Write-Error "Required function '$function' not found. Make sure all required modules are imported."
            return
        }
    }
    
    # Check if logging is available
    $canLog = Get-Command -Name "Write-Log" -ErrorAction SilentlyContinue
    
    if ($canLog) {
        Write-Log -Message "Entering VPN Certificate Menu" -Level INFO
    }
    
    # Validate configuration
    try {
        $config = Get-Configuration
        
        # Verify required configuration properties
        $requiredProps = @('env', 'project', 'loc')
        $missingProps = $requiredProps | Where-Object { -not $config.PSObject.Properties.Name.Contains($_) -or [string]::IsNullOrWhiteSpace($config.$_) }
        
        if ($missingProps.Count -gt 0) {
            $message = "Configuration is missing required properties: $($missingProps -join ', ')"
            Write-Host $message -ForegroundColor Red
            if ($canLog) { Write-Log -Message $message -Level ERROR }
            
            $confirmContinue = Get-UserConfirmation -Message "Continue anyway?" -DefaultYes:$false
            if (-not $confirmContinue) {
                return
            }
        }
    }
    catch {
        Write-Host "Failed to load configuration: $_" -ForegroundColor Red
        if ($canLog) { Write-Log -Message "Failed to load configuration: $_" -Level ERROR }
        
        $confirmContinue = Get-UserConfirmation -Message "Continue without configuration?" -DefaultYes:$false
        if (-not $confirmContinue) {
            return
        }
        
        # Create minimal default configuration
        $config = [PSCustomObject]@{
            env = "dev"
            project = "homelab"
            loc = "westus"
        }
        
        Write-Host "Using default configuration values." -ForegroundColor Yellow
        if ($canLog) { Write-Log -Message "Using default configuration values" -Level WARN }
    }
    
    # Define certificate store path with a default that can be overridden
    $certStorePath = "Cert:\CurrentUser\My"
    if ($config.PSObject.Properties.Name.Contains('CertStorePath') -and -not [string]::IsNullOrWhiteSpace($config.CertStorePath)) {
        $certStorePath = $config.CertStorePath
    }
    
    # Helper function to validate certificate name
    function Test-CertificateName {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Name
        )
        
        # Basic validation - no special characters except hyphen and underscore
        return $Name -match '^[a-zA-Z0-9\-_]+$'
    }
    
    # Main menu loop
    $selection = 0
    do {
        try {
            Show-VpnCertMenu -ShowProgress:$ShowProgress
        }
        catch {
            Write-Host "Error displaying VPN Certificate Menu: $_" -ForegroundColor Red
            if ($canLog) { Write-Log -Message "Error displaying VPN Certificate Menu: $_" -Level ERROR }
            break
        }
        
        $selection = Read-Host "Select an option"
        
        switch ($selection) {
            "1" {
                Write-Host "Creating new root certificate..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Create new root certificate" -Level INFO }
                
                $rootCertName = "$($config.env)-$($config.project)-vpn-root"
                $clientCertName = "$($config.env)-$($config.project)-vpn-client"
                
                # Validate certificate names
                if (-not (Test-CertificateName -Name $rootCertName)) {
                    Write-Host "Invalid root certificate name: $rootCertName" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Invalid root certificate name: $rootCertName" -Level ERROR }
                    Pause
                    continue
                }
                
                if (-not (Test-CertificateName -Name $clientCertName)) {
                    Write-Host "Invalid client certificate name: $clientCertName" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Invalid client certificate name: $clientCertName" -Level ERROR }
                    Pause
                    continue
                }
                
                # Check if function exists
                if (Get-Command New-VpnRootCertificate -ErrorAction SilentlyContinue) {
                    # Create a progress task for certificate creation
                    $task = Start-ProgressTask -Activity "Creating Root Certificate" -TotalSteps 3 -ScriptBlock {
                        # Step 1: Creating root certificate
                        $syncHash.Status = "Creating root certificate..."
                        $syncHash.CurrentStep = 1
                        
                        # Step 2: Configuring certificate properties
                        $syncHash.Status = "Configuring certificate properties..."
                        $syncHash.CurrentStep = 2
                        
                        # Step 3: Finalizing certificate
                        $syncHash.Status = "Finalizing certificate..."
                        $syncHash.CurrentStep = 3
                        
                        try {
                            # Call the actual function
                            New-VpnRootCertificate -RootCertName $rootCertName -ClientCertName $clientCertName -CreateNewRoot
                            return "Root certificate created successfully."
                        }
                        catch {
                            return "Error creating root certificate: $_"
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result -like "Error*") {
                        Write-Host $result -ForegroundColor Red
                        if ($canLog) { Write-Log -Message $result -Level ERROR }
                    } else {
                        Write-Host $result -ForegroundColor Green
                        if ($canLog) { Write-Log -Message "Root certificate created: $rootCertName" -Level INFO }
                    }
                }
                else {
                    Write-Host "Function New-VpnRootCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Function New-VpnRootCertificate not found" -Level ERROR }
                }
                
                Pause
            }
            "2" {
                Write-Host "Creating client certificate..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Create client certificate" -Level INFO }
                
                $rootCertName = "$($config.env)-$($config.project)-vpn-root"
                $clientCertName = Read-Host "Enter client certificate name"
                
                if ([string]::IsNullOrWhiteSpace($clientCertName)) {
                    $clientCertName = "$($config.env)-$($config.project)-vpn-client"
                    Write-Host "Using default client certificate name: $clientCertName" -ForegroundColor Yellow
                    if ($canLog) { Write-Log -Message "Using default client certificate name: $clientCertName" -Level INFO }
                }
                
                # Validate certificate names
                if (-not (Test-CertificateName -Name $rootCertName)) {
                    Write-Host "Invalid root certificate name: $rootCertName" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Invalid root certificate name: $rootCertName" -Level ERROR }
                    Pause
                    continue
                }
                
                if (-not (Test-CertificateName -Name $clientCertName)) {
                    Write-Host "Invalid client certificate name: $clientCertName" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Invalid client certificate name: $clientCertName" -Level ERROR }
                    Pause
                    continue
                }
                
                # Check if function exists
                if (Get-Command New-VpnClientCertificate -ErrorAction SilentlyContinue) {
                    # Create a progress task for client certificate creation
                    $task = Start-ProgressTask -Activity "Creating Client Certificate" -TotalSteps 4 -ScriptBlock {
                        # Step 1: Locating root certificate
                        $syncHash.Status = "Locating root certificate..."
                        $syncHash.CurrentStep = 1
                        
                        # Step 2: Validating root certificate
                        $syncHash.Status = "Validating root certificate..."
                        $syncHash.CurrentStep = 2
                        
                        # Step 3: Creating client certificate
                        $syncHash.Status = "Creating client certificate..."
                        $syncHash.CurrentStep = 3
                        
                        # Step 4: Finalizing client certificate
                        $syncHash.Status = "Finalizing client certificate..."
                        $syncHash.CurrentStep = 4
                        
                        try {
                            # Call the actual function
                            New-VpnClientCertificate -RootCertName $rootCertName -ClientCertName $clientCertName
                            return "Client certificate created successfully."
                        }
                        catch {
                            return "Error creating client certificate: $_"
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result -like "Error*") {
                        Write-Host $result -ForegroundColor Red
                        if ($canLog) { Write-Log -Message $result -Level ERROR }
                    } else {
                        Write-Host $result -ForegroundColor Green
                        if ($canLog) { Write-Log -Message "Client certificate created: $clientCertName" -Level INFO }
                    }
                }
                else {
                    Write-Host "Function New-VpnClientCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Function New-VpnClientCertificate not found" -Level ERROR }
                }
                
                Pause
            }
            "3" {
                Write-Host "Adding client certificate to existing root..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Add client certificate to existing root" -Level INFO }
                
                $newClientName = Read-Host "Enter new client name"
                
                if ([string]::IsNullOrWhiteSpace($newClientName)) {
                    Write-Host "Client name cannot be empty." -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "User provided empty client name" -Level WARN }
                    Pause
                    continue
                }
                
                # Validate client name
                if (-not (Test-CertificateName -Name $newClientName)) {
                    Write-Host "Invalid client name: $newClientName" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Invalid client name: $newClientName" -Level ERROR }
                    Pause
                    continue
                }
                
                # Check if function exists
                if (Get-Command Add-AdditionalClientCertificate -ErrorAction SilentlyContinue) {
                    # Create a progress task for adding client certificate
                    $task = Start-ProgressTask -Activity "Adding Client Certificate" -TotalSteps 3 -ScriptBlock {
                        # Step 1: Finding existing root certificate
                        $syncHash.Status = "Finding existing root certificate..."
                        $syncHash.CurrentStep = 1
                        
                        # Step 2: Creating new client certificate
                        $syncHash.Status = "Creating new client certificate..."
                        $syncHash.CurrentStep = 2
                        
                        # Step 3: Linking to root certificate
                        $syncHash.Status = "Linking to root certificate..."
                        $syncHash.CurrentStep = 3
                        
                        try {
                            # Call the actual function
                            Add-AdditionalClientCertificate -NewClientName $newClientName
                            return "Additional client certificate added successfully."
                        }
                        catch {
                            return "Error adding additional client certificate: $_"
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result -like "Error*") {
                        Write-Host $result -ForegroundColor Red
                        if ($canLog) { Write-Log -Message $result -Level ERROR }
                    } else {
                        Write-Host $result -ForegroundColor Green
                        if ($canLog) { Write-Log -Message "Additional client certificate added: $newClientName" -Level INFO }
                    }
                }
                else {
                    Write-Host "Function Add-AdditionalClientCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Function Add-AdditionalClientCertificate not found" -Level ERROR }
                }
                
                Pause
            }
            "4" {
                Write-Host "Uploading certificate to VPN Gateway..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Upload certificate to VPN Gateway" -Level INFO }
                
                $resourceGroup = "$($config.env)-$($config.loc)-rg-$($config.project)"
                $gatewayName = "$($config.env)-$($config.loc)-vpng-$($config.project)"
                $certName = "$($config.env)-$($config.project)-vpn-root"
                
                Write-Host "Select the Base64 encoded certificate file (.txt)..." -ForegroundColor Yellow
                $certFile = Read-Host "Enter path to certificate file"
                
                if ([string]::IsNullOrWhiteSpace($certFile)) {
                    Write-Host "Certificate file path cannot be empty." -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "User provided empty certificate file path" -Level WARN }
                    Pause
                    continue
                }
                
                # Validate and read certificate file
                if (Test-Path $certFile) {
                    # Check if it's a text file
                    $extension = [System.IO.Path]::GetExtension($certFile)
                    if ($extension -ne ".txt" -and $extension -ne ".cer" -and $extension -ne ".pem") {
                        Write-Host "Warning: File does not have a standard certificate extension (.txt, .cer, .pem)" -ForegroundColor Yellow
                        if ($canLog) { Write-Log -Message "Non-standard certificate file extension: $extension" -Level WARN }
                        
                        $confirmContinue = Get-UserConfirmation -Message "Continue anyway?" -DefaultYes:$false
                        if (-not $confirmContinue) {
                            Pause
                            continue
                        }
                    }
                    
                    try {
                        $certData = Get-Content $certFile -Raw -ErrorAction Stop
                        
                        # Basic validation that it looks like a Base64 certificate
                        if (-not ($certData -match "-----BEGIN CERTIFICATE-----" -or $certData -match "^[A-Za-z0-9+/=]+$")) {
                            Write-Host "Warning: File does not appear to contain a valid Base64 certificate" -ForegroundColor Yellow
                            if ($canLog) { Write-Log -Message "File does not appear to contain a valid Base64 certificate" -Level WARN }
                            
                            $confirmContinue = Get-UserConfirmation -Message "Continue anyway?" -DefaultYes:$false
                            if (-not $confirmContinue) {
                                Pause
                                continue
                            }
                        }
                        
                        # Check if function exists
                        if (Get-Command Add-VpnGatewayCertificate -ErrorAction SilentlyContinue) {
                            # Create a progress task for certificate upload
                            $task = Start-ProgressTask -Activity "Uploading Certificate to VPN Gateway" -TotalSteps 4 -ScriptBlock {
                                # Step 1: Validating certificate data
                                $syncHash.Status = "Validating certificate data..."
                                $syncHash.CurrentStep = 1
                                
                                # Step 2: Connecting to Azure
                                $syncHash.Status = "Connecting to Azure..."
                                $syncHash.CurrentStep = 2
                                
                                # Step 3: Locating VPN Gateway
                                $syncHash.Status = "Locating VPN Gateway..."
                                $syncHash.CurrentStep = 3
                                
                                # Step 4: Uploading certificate
                                $syncHash.Status = "Uploading certificate..."
                                $syncHash.CurrentStep = 4
                                
                                try {
                                    # Call the actual function
                                    Add-VpnGatewayCertificate -ResourceGroupName $resourceGroup -GatewayName $gatewayName -CertificateName $certName -CertificateData $certData
                                    return "Certificate uploaded to VPN Gateway successfully."
                                }
                                catch {
                                    return "Error uploading certificate to VPN Gateway: $_"
                                }
                            }
                            
                            $result = $task.Complete()
                            
                            if ($result -like "Error*") {
                                Write-Host $result -ForegroundColor Red
                                if ($canLog) { Write-Log -Message $result -Level ERROR }
                            } else {
                                Write-Host $result -ForegroundColor Green
                                if ($canLog) { Write-Log -Message "Certificate uploaded to VPN Gateway: $gatewayName" -Level INFO }
                            }
                        }
                        else {
                            Write-Host "Function Add-VpnGatewayCertificate not found. Make sure the required module is imported." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "Function Add-VpnGatewayCertificate not found" -Level ERROR }
                        }
                    }
                    catch {
                        Write-Host "Error reading certificate file: $_" -ForegroundColor Red
                        if ($canLog) { Write-Log -Message "Error reading certificate file: $_" -Level ERROR }
                    }
                } 
                else {
                    Write-Host "Certificate file not found: $certFile" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Certificate file not found: $certFile" -Level ERROR }
                }
                
                Pause
            }
            "5" {
                Write-Host "Listing all certificates..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: List all certificates" -Level INFO }
                
                $rootCertName = "$($config.env)-$($config.project)-vpn-root"
                $clientCertPrefix = "$($config.env)-$($config.project)-vpn-client"
                
                # Check if certificate store exists
                if (-not (Test-Path -Path $certStorePath)) {
                    Write-Host "Certificate store path not found: $certStorePath" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Certificate store path not found: $certStorePath" -Level ERROR }
                    Pause
                    continue
                }
                
                # Create a progress task for listing certificates
                $task = Start-ProgressTask -Activity "Listing Certificates" -TotalSteps 2 -ScriptBlock {
                    # Step 1: Finding root certificates
                    $syncHash.Status = "Finding root certificates..."
                    $syncHash.CurrentStep = 1
                    
                    $rootCerts = Get-ChildItem -Path $certStorePath | Where-Object { $_.Subject -like "CN=$rootCertName*" }
                    
                    # Step 2: Finding client certificates
                    $syncHash.Status = "Finding client certificates..."
                    $syncHash.CurrentStep = 2
                    
                    $clientCerts = Get-ChildItem -Path $certStorePath | Where-Object { $_.Subject -like "CN=$clientCertPrefix*" }
                    
                    # Return the results
                    return @{
                        RootCerts = $rootCerts
                        ClientCerts = $clientCerts
                    }
                }
                
                try {
                    $results = $task.Complete()
                    
                    Write-Host "Root Certificates:" -ForegroundColor Yellow
                    if ($results.RootCerts.Count -eq 0) {
                        Write-Host "No root certificates found." -ForegroundColor Yellow
                        if ($canLog) { Write-Log -Message "No root certificates found" -Level INFO }
                    }
                    else {
                        $results.RootCerts | Format-Table -Property Subject, Thumbprint, NotBefore, NotAfter
                        if ($canLog) { Write-Log -Message "Found $($results.RootCerts.Count) root certificates" -Level INFO }
                    }
                    
                    Write-Host "Client Certificates:" -ForegroundColor Yellow
                    if ($results.ClientCerts.Count -eq 0) {
                        Write-Host "No client certificates found." -ForegroundColor Yellow
                        if ($canLog) { Write-Log -Message "No client certificates found" -Level INFO }
                    }
                    else {
                        $results.ClientCerts | Format-Table -Property Subject, Thumbprint, NotBefore, NotAfter
                        if ($canLog) { Write-Log -Message "Found $($results.ClientCerts.Count) client certificates" -Level INFO }
                    }
                }
                catch {
                    Write-Host "Error listing certificates: $_" -ForegroundColor Red
                    if ($canLog) { Write-Log -Message "Error listing certificates: $_" -Level ERROR }
                }
                
                Pause
            }
            "0" {
                Write-Host "Returning to main menu..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User exited VPN Certificate Menu" -Level INFO }
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                if ($canLog) { Write-Log -Message "User selected invalid option: $selection" -Level WARN }
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
