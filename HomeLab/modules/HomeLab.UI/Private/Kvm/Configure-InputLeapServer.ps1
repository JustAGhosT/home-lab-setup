<#
.SYNOPSIS
    Configures Input Leap in server mode.
.DESCRIPTION
    Helper function to configure Input Leap as a server.
#>
function Configure-InputLeapServer {
    Write-Host "`nConfiguring Input Leap Server..." -ForegroundColor Cyan
    
    # Get computer name for reference
    $computerName = $env:COMPUTERNAME
    Write-Host "This computer's name: $computerName" -ForegroundColor Green
    
    # Get client computer names
    Write-Host "`nEnter the names of client computers (comma-separated):" -ForegroundColor Yellow
    $clientNames = Read-Host
    $clients = $clientNames -split ',' | ForEach-Object { $_.Trim() }
    
    # Create basic configuration - using string concatenation instead of here-strings
    $configContent = "section: screens`r`n"
    $configContent += "    $($computerName):`r`n"
    
    foreach ($client in $clients) {
        if ($client) {
            $configContent += "    $($client):`r`n"
        }
    }
    
    $configContent += "`r`nsection: links`r`n"
    $configContent += "    $($computerName):`r`n"
    
    # Ask for screen arrangement
    Write-Host "`nHow are your screens arranged?" -ForegroundColor Yellow
    
    foreach ($client in $clients) {
        if ($client) {
            Write-Host "Where is $client relative to $computerName?" -ForegroundColor Yellow
            Write-Host "  1. Right" -ForegroundColor White
            Write-Host "  2. Left" -ForegroundColor White
            Write-Host "  3. Above" -ForegroundColor White
            Write-Host "  4. Below" -ForegroundColor White
            $direction = Read-Host "Select an option (1-4)"
            
            switch ($direction) {
                "1" { $configContent += "        right = $client`r`n" }
                "2" { $configContent += "        left = $client`r`n" }
                "3" { $configContent += "        up = $client`r`n" }
                "4" { $configContent += "        down = $client`r`n" }
                default { 
                    Write-Host "Invalid selection. Defaulting to right." -ForegroundColor Yellow
                    $configContent += "        right = $client`r`n" 
                }
            }
        }
    }
    
    # Add reverse links
    foreach ($client in $clients) {
        if ($client) {
            $configContent += "    $($client):`r`n"
            
            # Find the direction from main to this client and reverse it
            if ($configContent -match "\s+right = $client") {
                $configContent += "        left = $computerName`r`n"
            } elseif ($configContent -match "\s+left = $client") {
                $configContent += "        right = $computerName`r`n"
            } elseif ($configContent -match "\s+up = $client") {
                $configContent += "        down = $computerName`r`n"
            } elseif ($configContent -match "\s+down = $client") {
                $configContent += "        up = $computerName`r`n"
            }
        }
    }
    
    # Add options section
    $configContent += "`r`nsection: options`r`n"
    $configContent += "    heartbeat = 5000`r`n"
    $configContent += "    switchDelay = 500`r`n"
    $configContent += "    switchDoubleTap = 250`r`n"
    $configContent += "    screenSaverSync = true`r`n"
    $configContent += "    clipboardSharing = true`r`n"
    
    # Save configuration
    $configPath = "$env:APPDATA\Input Leap\input-leap.conf"
    $configDir = Split-Path -Parent $configPath
    
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    $configContent | Out-File -FilePath $configPath -Encoding utf8 -Force
    
    Write-Host "`nConfiguration saved to: $configPath" -ForegroundColor Green
    Write-Host "To use this configuration:" -ForegroundColor Yellow
    Write-Host "1. Start Input Leap" -ForegroundColor White
    Write-Host "2. Select 'Server' mode" -ForegroundColor White
    Write-Host "3. Use the configuration file you just created" -ForegroundColor White
    Write-Host "4. Start the server" -ForegroundColor White
    Write-Host "`nMake sure to allow Input Leap through your firewall." -ForegroundColor Yellow
}
