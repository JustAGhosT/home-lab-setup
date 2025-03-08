<#
.SYNOPSIS
    VPN Client Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the VPN client menu using the new modular structure.
    Options include adding a computer to the VPN, connecting, disconnecting, and checking VPN connection status.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu and performing operations.
.EXAMPLE
    Invoke-VpnClientMenu
.EXAMPLE
    Invoke-VpnClientMenu -ShowProgress
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Invoke-VpnClientMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress
    )
    
    # Check if required functions exist
    $requiredFunctions = @(
        "Show-VpnClientMenu",
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
        Write-Log -Message "Entering VPN Client Menu" -Level INFO
    }
    
    $selection = 0
    do {
        try {
            Show-VpnClientMenu -ShowProgress:$ShowProgress
        }
        catch {
            Write-Host "Error displaying VPN Client Menu: $_" -ForegroundColor Red
            if ($canLog) { Write-Log -Message "Error displaying VPN Client Menu: $_" -Level ERROR }
            break
        }
        
        $selection = Read-Host "Select an option"
        $config = Get-Configuration
        
        switch ($selection) {
            "1" {
                Write-Host "Adding computer to VPN..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Add computer to VPN" -Level INFO }
                
                if ($ShowProgress) {
                    # Create a progress task for adding computer to VPN
                    $task = Start-ProgressTask -Activity "Adding Computer to VPN" -TotalSteps 3 -ScriptBlock {
                        # Step 1: Checking for required functions
                        $syncHash.Status = "Checking for required functions..."
                        $syncHash.CurrentStep = 1
                        
                        $useFunction = Get-Command VpnAddComputer -ErrorAction SilentlyContinue
                        
                        # Step 2: Preparing VPN configuration
                        $syncHash.Status = "Preparing VPN configuration..."
                        $syncHash.CurrentStep = 2
                        
                        # Step 3: Adding computer to VPN
                        $syncHash.Status = "Adding computer to VPN..."
                        $syncHash.CurrentStep = 3
                        
                        if ($useFunction) {
                            try {
                                VpnAddComputer
                                return @{
                                    Success = $true
                                    UsedFunction = $true
                                }
                            }
                            catch {
                                return @{
                                    Success = $false
                                    ErrorMessage = "Error adding computer to VPN: $_"
                                    UsedFunction = $true
                                }
                            }
                        }
                        else {
                            return @{
                                Success = $false,
                                UsedFunction = $false
                            }
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        Write-Host "Computer added to VPN successfully." -ForegroundColor Green
                        if ($canLog) { Write-Log -Message "Computer added to VPN successfully" -Level INFO }
                    }
                    else {
                        if (-not $result.UsedFunction) {
                            Write-Host "Function VpnAddComputer not found. Make sure the required module is imported." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "Function VpnAddComputer not found" -Level ERROR }
                            
                            # Fallback to manual instructions
                            Write-Host "Manual steps to add computer to VPN:" -ForegroundColor Yellow
                            Write-Host "1. Extract the VPN client configuration ZIP file" -ForegroundColor White
                            Write-Host "2. Run the VPN client installer (usually in the WindowsAmd64 folder)" -ForegroundColor White
                            Write-Host "3. Follow the installation prompts" -ForegroundColor White
                            if ($canLog) { Write-Log -Message "Displayed manual VPN setup instructions" -Level INFO }
                        }
                        else {
                            Write-Host $result.ErrorMessage -ForegroundColor Red
                            if ($canLog) { Write-Log -Message $result.ErrorMessage -Level ERROR }
                        }
                    }
                }
                else {
                    # Original implementation without progress bar
                    # Assuming VpnAddComputer is defined in another module
                    if (Get-Command VpnAddComputer -ErrorAction SilentlyContinue) {
                        VpnAddComputer
                        if ($canLog) { Write-Log -Message "Called VpnAddComputer function" -Level INFO }
                    }
                    else {
                        Write-Host "Function VpnAddComputer not found. Make sure the required module is imported." -ForegroundColor Red
                        if ($canLog) { Write-Log -Message "Function VpnAddComputer not found" -Level ERROR }
                        
                        # Fallback to manual instructions
                        Write-Host "Manual steps to add computer to VPN:" -ForegroundColor Yellow
                        Write-Host "1. Extract the VPN client configuration ZIP file" -ForegroundColor White
                        Write-Host "2. Run the VPN client installer (usually in the WindowsAmd64 folder)" -ForegroundColor White
                        Write-Host "3. Follow the installation prompts" -ForegroundColor White
                        if ($canLog) { Write-Log -Message "Displayed manual VPN setup instructions" -Level INFO }
                    }
                }
                
                Pause
            }
            "2" {
                Write-Host "Connecting to VPN..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Connect to VPN" -Level INFO }
                
                if ($ShowProgress) {
                    # Create a progress task for connecting to VPN
                    $task = Start-ProgressTask -Activity "Connecting to VPN" -TotalSteps 4 -ScriptBlock {
                        # Step 1: Checking for required functions
                        $syncHash.Status = "Checking for required functions..."
                        $syncHash.CurrentStep = 1
                        
                        $useFunction = Get-Command VpnConnectDisconnect -ErrorAction SilentlyContinue
                        
                        # Step 2: Finding VPN connection
                        $syncHash.Status = "Finding VPN connection..."
                        $syncHash.CurrentStep = 2
                        
                        $vpnName = "$($config.env)-$($config.project)-vpn"
                        $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                        
                        # Step 3: Preparing connection
                        $syncHash.Status = "Preparing connection..."
                        $syncHash.CurrentStep = 3
                        
                        # Step 4: Connecting to VPN
                        $syncHash.Status = "Connecting to VPN..."
                        $syncHash.CurrentStep = 4
                        
                        if ($useFunction) {
                            try {
                                VpnConnectDisconnect -Connect
                                return @{
                                    Success = $true
                                    UsedFunction = $true
                                }
                            }
                            catch {
                                return @{
                                    Success = $false
                                    ErrorMessage = "Error connecting to VPN: $_"
                                    UsedFunction = $true
                                }
                            }
                        }
                        else {
                            if ($connections) {
                                $vpnName = $connections[0].Name
                                try {
                                    $connectResult = rasdial $vpnName 2>&1
                                    if ($LASTEXITCODE -eq 0) {
                                        return @{
                                            Success = $true
                                            UsedFunction = $false
                                            VpnName = $vpnName
                                        }
                                    }
                                    else {
                                        return @{
                                            Success = $false
                                            ErrorMessage = "Failed to connect to VPN: $connectResult"
                                            UsedFunction = $false
                                        }
                                    }
                                }
                                catch {
                                    return @{
                                        Success = $false
                                        ErrorMessage = "Error connecting to VPN: $_"
                                        UsedFunction = $false
                                    }
                                }
                            }
                            else {
                                return @{
                                    Success = $false
                                    ErrorMessage = "No VPN connections found for project $($config.project)."
                                    UsedFunction = $false
                                }
                            }
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        if ($result.UsedFunction) {
                            Write-Host "Connected to VPN successfully." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "Connected to VPN successfully using VpnConnectDisconnect" -Level INFO }
                        }
                        else {
                            Write-Host "Connected to VPN '$($result.VpnName)' successfully." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "Connected to VPN '$($result.VpnName)' using rasdial" -Level INFO }
                        }
                    }
                    else {
                        if (-not $result.UsedFunction) {
                            Write-Host "Function VpnConnectDisconnect not found. Make sure the required module is imported." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "Function VpnConnectDisconnect not found" -Level ERROR }
                        }
                        Write-Host $result.ErrorMessage -ForegroundColor Red
                        if ($canLog) { Write-Log -Message $result.ErrorMessage -Level ERROR }
                    }
                }
                else {
                    # Original implementation without progress bar
                    # Assuming VpnConnectDisconnect is defined in another module
                    if (Get-Command VpnConnectDisconnect -ErrorAction SilentlyContinue) {
                        VpnConnectDisconnect -Connect
                        if ($canLog) { Write-Log -Message "Called VpnConnectDisconnect -Connect" -Level INFO }
                    }
                    else {
                        Write-Host "Function VpnConnectDisconnect not found. Make sure the required module is imported." -ForegroundColor Red
                        if ($canLog) { Write-Log -Message "Function VpnConnectDisconnect not found" -Level ERROR }
                        
                        # Fallback to direct PowerShell command
                        $vpnName = "$($config.env)-$($config.project)-vpn"
                        $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                        
                        if ($connections) {
                            $vpnName = $connections[0].Name
                            Write-Host "Attempting to connect to VPN '$vpnName'..." -ForegroundColor Yellow
                            if ($canLog) { Write-Log -Message "Attempting to connect to VPN '$vpnName' using rasdial" -Level INFO }
                            rasdial $vpnName
                        }
                        else {
                            Write-Host "No VPN connections found for project $($config.project)." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "No VPN connections found for project $($config.project)" -Level ERROR }
                        }
                    }
                }
                
                Pause
            }
            "3" {
                Write-Host "Disconnecting from VPN..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Disconnect from VPN" -Level INFO }
                
                if ($ShowProgress) {
                    # Create a progress task for disconnecting from VPN
                    $task = Start-ProgressTask -Activity "Disconnecting from VPN" -TotalSteps 3 -ScriptBlock {
                        # Step 1: Checking for required functions
                        $syncHash.Status = "Checking for required functions..."
                        $syncHash.CurrentStep = 1
                        
                        $useFunction = Get-Command VpnConnectDisconnect -ErrorAction SilentlyContinue
                        
                        # Step 2: Finding VPN connection
                        $syncHash.Status = "Finding VPN connection..."
                        $syncHash.CurrentStep = 2
                        
                        $vpnName = "$($config.env)-$($config.project)-vpn"
                        $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                        
                        # Step 3: Disconnecting from VPN
                        $syncHash.Status = "Disconnecting from VPN..."
                        $syncHash.CurrentStep = 3
                        
                        if ($useFunction) {
                            try {
                                VpnConnectDisconnect -Disconnect
                                return @{
                                    Success = $true
                                    UsedFunction = $true
                                }
                            }
                            catch {
                                return @{
                                    Success = $false
                                    ErrorMessage = "Error disconnecting from VPN: $_"
                                    UsedFunction = $true
                                }
                            }
                        }
                        else {
                            if ($connections) {
                                $vpnName = $connections[0].Name
                                try {
                                    $disconnectResult = rasdial $vpnName /disconnect 2>&1
                                    return @{
                                        Success = $true
                                        UsedFunction = $false
                                        VpnName = $vpnName
                                    }
                                }
                                catch {
                                    return @{
                                        Success = $false
                                        ErrorMessage = "Error disconnecting from VPN: $_"
                                        UsedFunction = $false
                                    }
                                }
                            }
                            else {
                                return @{
                                    Success = $false
                                    ErrorMessage = "No VPN connections found for project $($config.project)."
                                    UsedFunction = $false
                                }
                            }
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Success) {
                        if ($result.UsedFunction) {
                            Write-Host "Disconnected from VPN successfully." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "Disconnected from VPN successfully using VpnConnectDisconnect" -Level INFO }
                        }
                        else {
                            Write-Host "Disconnected from VPN '$($result.VpnName)' successfully." -ForegroundColor Green
                            if ($canLog) { Write-Log -Message "Disconnected from VPN '$($result.VpnName)' using rasdial" -Level INFO }
                        }
                    }
                    else {
                        if (-not $result.UsedFunction) {
                            Write-Host "Function VpnConnectDisconnect not found. Make sure the required module is imported." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "Function VpnConnectDisconnect not found" -Level ERROR }
                        }
                        Write-Host $result.ErrorMessage -ForegroundColor Red
                        if ($canLog) { Write-Log -Message $result.ErrorMessage -Level ERROR }
                    }
                }
                else {
                    # Original implementation without progress bar
                    # Assuming VpnConnectDisconnect is defined in another module
                    if (Get-Command VpnConnectDisconnect -ErrorAction SilentlyContinue) {
                        VpnConnectDisconnect -Disconnect
                        if ($canLog) { Write-Log -Message "Called VpnConnectDisconnect -Disconnect" -Level INFO }
                    }
                    else {
                        Write-Host "Function VpnConnectDisconnect not found. Make sure the required module is imported." -ForegroundColor Red
                        if ($canLog) { Write-Log -Message "Function VpnConnectDisconnect not found" -Level ERROR }
                        
                        # Fallback to direct PowerShell command
                        $vpnName = "$($config.env)-$($config.project)-vpn"
                        $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                        
                        if ($connections) {
                            $vpnName = $connections[0].Name
                            Write-Host "Attempting to disconnect from VPN '$vpnName'..." -ForegroundColor Yellow
                            if ($canLog) { Write-Log -Message "Attempting to disconnect from VPN '$vpnName' using rasdial" -Level INFO }
                            rasdial $vpnName /disconnect
                        }
                        else {
                            Write-Host "No VPN connections found for project $($config.project)." -ForegroundColor Red
                            if ($canLog) { Write-Log -Message "No VPN connections found for project $($config.project)" -Level ERROR }
                        }
                    }
                }
                
                Pause
            }
            "4" {
                Write-Host "Checking VPN connection status..." -ForegroundColor Cyan
                if ($canLog) { Write-Log -Message "User selected: Check VPN connection status" -Level INFO }
                
                if ($ShowProgress) {
                    # Create a progress task for checking VPN status
                    $task = Start-ProgressTask -Activity "Checking VPN Connection Status" -TotalSteps 2 -ScriptBlock {
                        # Step 1: Finding VPN connections
                        $syncHash.Status = "Finding VPN connections..."
                        $syncHash.CurrentStep = 1
                        
                        # Step 2: Retrieving connection details
                        $syncHash.Status = "Retrieving connection details..."
                        $syncHash.CurrentStep = 2
                        
                        $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                        
                        return @{
                            Connections = $connections
                        }
                    }
                    
                    $result = $task.Complete()
                    
                    if ($result.Connections -and $result.Connections.Count -gt 0) {
                        $result.Connections | Format-Table -Property Name, ServerAddress, ConnectionStatus, AuthenticationMethod
                        if ($canLog) { Write-Log -Message "Found $($result.Connections.Count) VPN connections" -Level INFO }
                    }
                    else {
                        Write-Host "No VPN connections found for project $($config.project)." -ForegroundColor Yellow
                        if ($canLog) { Write-Log -Message "No VPN connections found for project $($config.project)" -Level INFO }
                    }
                }
                else {
                    # Original implementation without progress bar
                    $connections = Get-VpnConnection | Where-Object { $_.Name -like "*$($config.project)*" }
                    if ($connections) {
                        $connections | Format-Table -Property Name, ServerAddress, ConnectionStatus, AuthenticationMethod
                        if ($canLog) { Write-Log -Message "Found $($connections.Count) VPN connections" -Level INFO }
                    }
                    else {
                        Write-Host "No VPN connections found for project $($config.project)." -ForegroundColor Yellow
                        if ($canLog) { Write-Log -Message "No VPN connections found for project $($config.project)" -Level INFO }
                    }
                }
                
                Pause
            }
            "0" {
                # Return to main menu
                if ($canLog) { Write-Log -Message "User exited VPN Client Menu" -Level INFO }
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                if ($canLog) { Write-Log -Message "User selected invalid option: $selection" -Level WARN }
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
