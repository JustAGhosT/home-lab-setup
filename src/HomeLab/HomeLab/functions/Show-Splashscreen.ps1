<#
.SYNOPSIS
    Displays the HomeLab splash screen
.DESCRIPTION
    Shows the HomeLab ASCII art logo and startup summary information
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: March 10, 2025
#>

function Show-SplashScreen {
    [CmdletBinding()]
    param()
    
    if ($NoSplashScreen) {
        return
    }

    # Ensure script variables are initialized
    if (-not $script:StartTime) {
        $script:StartTime = Get-Date
    }
    
    if (-not $script:Version) {
        $script:Version = '1.0.0'
    }

    # Clear the console
    Clear-Host
    
    # ASCII art for HomeLab
    $splashText = @"
    
    ██╗  ██╗ ██████╗ ███╗   ███╗███████╗██╗      █████╗ ██████╗ 
    ██║  ██║██╔═══██╗████╗ ████║██╔════╝██║     ██╔══██╗██╔══██╗
    ███████║██║   ██║██╔████╔██║█████╗  ██║     ███████║██████╔╝
    ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝  ██║     ██╔══██║██╔══██╗
    ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗███████╗██║  ██║██████╔╝
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ 
                                                                
    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗ 
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                  
    Version: $script:Version
    
"@
    
    # Display splash screen with cyan color
    Write-Host $splashText -ForegroundColor Cyan
    
    # Calculate startup time - with null check
    if ($script:StartTime) {
        $elapsedTime = (Get-Date) - $script:StartTime
        $formattedTime = "{0:mm}m {0:ss}s" -f $elapsedTime
    } else {
        $formattedTime = "N/A"
    }
    
     # Display startup summary
     Write-Host "HomeLab Startup Summary" -ForegroundColor Yellow
     Write-Host "------------------------" -ForegroundColor Yellow
     Write-Host "Version: $script:Version"
     Write-Host "Startup Time: $formattedTime"
     Write-Host "Configuration: $(if ($script:ConfigLoaded) { 'Loaded' } else { 'Not Loaded' })"
     Write-Host "Modules: $(if ($script:ModulesLoaded) { 'Loaded' } else { 'Not Loaded' })"
     
     # Safely access State properties with null checks
     if ($script:State) {
         Write-Host "Azure Connection: $($script:State.ConnectionStatus)"
         if ($script:State.User) {
             Write-Host "User: $($script:State.User)"
         }
     } else {
         Write-Host "Azure Connection: Not Connected"
         Write-Host "User: $env:USERNAME"
     }
     
     # Add logging configuration display with null checks
     Write-Host "Log File: $script:LogFile"
     if ($script:State -and $script:State.Config -and $script:State.Config.Logging) {
         # Display logging config...
         Write-Host "Console Logging: $($script:State.Config.Logging.EnableConsoleLogging)"
         Write-Host "File Logging: $($script:State.Config.Logging.EnableFileLogging)"
         
         # Handle Console Log Level with null checks
         $consoleLogLevel = if ($script:State.Config.Logging.ConsoleLogLevel) { 
             $script:State.Config.Logging.ConsoleLogLevel 
         } elseif ($script:State.Config.Logging.DefaultLogLevel) { 
             $script:State.Config.Logging.DefaultLogLevel 
         } else {
             "Info"
         }
         Write-Host "Console Log Level: $consoleLogLevel"
         
         # Handle File Log Level with null checks
         $fileLogLevel = if ($script:State.Config.Logging.FileLogLevel) { 
             $script:State.Config.Logging.FileLogLevel 
         } elseif ($script:State.Config.Logging.DefaultLogLevel) { 
             $script:State.Config.Logging.DefaultLogLevel 
         } else {
             "Info"
         }
         Write-Host "File Log Level: $fileLogLevel"
         
         # Display default log level if available
         if ($script:State.Config.Logging.DefaultLogLevel) {
             Write-Host "Default Log Level: $($script:State.Config.Logging.DefaultLogLevel)"
         }
     } else {
         # Use local variable if available, otherwise default to Info
         $displayLogLevel = if ($LogLevel) { $LogLevel } else { "Info" }
         Write-Host "Log Level: $displayLogLevel"
     }
     Write-Host "------------------------" -ForegroundColor Yellow
     
     # Wait for user input before continuing
     Write-Host ""
     Write-Host "Press any key to continue..." -ForegroundColor Green
     $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
     
     # Clear the console before proceeding to main menu
     Clear-Host
 }