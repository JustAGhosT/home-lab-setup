<#
.SYNOPSIS
    Documentation Menu Handler for HomeLab Setup
.DESCRIPTION
    Processes user selections in the documentation menu using the new modular structure.
    Options include:
      1. Viewing the Main README.
      2. Viewing VPN Gateway Documentation.
      3. Viewing the Client Certificate Management Guide.
      0. Return to the Main Menu.
.PARAMETER ShowProgress
    If specified, shows a progress bar while loading the menu and rendering documentation.
.PARAMETER UseMarkdownRendering
    If specified, attempts to render markdown with basic formatting (headers, lists, code blocks).
.EXAMPLE
    Invoke-DocumentationMenu
.EXAMPLE
    Invoke-DocumentationMenu -ShowProgress
.EXAMPLE
    Invoke-DocumentationMenu -UseMarkdownRendering
.EXAMPLE
    Invoke-DocumentationMenu -ShowProgress -UseMarkdownRendering
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Invoke-DocumentationMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseMarkdownRendering
    )
    
    # Check if required functions exist
    $requiredFunctions = @(
        "Show-DocumentationMenu",
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
        Write-Log -Message "Entering Documentation Menu" -Level INFO
    }
    
    # Determine the module root and docs path
    $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $docsPath = Join-Path -Path $moduleRoot -ChildPath "docs"
    
    if ($canLog) {
        Write-Log -Message "Module root path: $moduleRoot" -Level DEBUG
        Write-Log -Message "Documentation path: $docsPath" -Level DEBUG
    }
    
    # Function to render markdown with basic formatting
    function Format-Markdown {
        param (
            [Parameter(Mandatory = $true)]
            [string[]]$Content
        )
        
        $inCodeBlock = $false
        $codeBlockIndent = 0
        
        foreach ($line in $Content) {
            # Handle code blocks
            if ($line -match '^\s*```') {
                $inCodeBlock = -not $inCodeBlock
                if ($inCodeBlock) {
                    # Extract language if specified
                    $lang = $line -replace '^\s*```\s*', ''
                    if ($lang) {
                        Write-Host "[$lang]" -ForegroundColor DarkGray
                    }
                    $codeBlockIndent = ($line -match '^\s+') ? ($line.Length - $line.TrimStart().Length) : 0
                }
                continue
            }
            
            if ($inCodeBlock) {
                # In code block - show with different background
                Write-Host $line -ForegroundColor DarkYellow
                continue
            }
            
            # Handle headers
            if ($line -match '^#{1,6}\s+') {
                $level = $line.IndexOf(' ')
                $text = $line.Substring($level + 1)
                
                switch ($level) {
                    1 { Write-Host $text -ForegroundColor Cyan -BackgroundColor DarkBlue }
                    2 { Write-Host $text -ForegroundColor Cyan }
                    3 { Write-Host $text -ForegroundColor White -BackgroundColor DarkCyan }
                    4 { Write-Host $text -ForegroundColor White }
                    5 { Write-Host $text -ForegroundColor Gray }
                    6 { Write-Host $text -ForegroundColor DarkGray }
                }
                continue
            }
            
            # Handle lists
            if ($line -match '^\s*[\*\-\+]\s+') {
                $indent = $line.IndexOf($line -replace '^\s*', '')
                $text = $line -replace '^\s*[\*\-\+]\s+', ''
                $prefix = "  " * ($indent / 2) + "• "
                Write-Host "$prefix$text" -ForegroundColor Yellow
                continue
            }
            
            # Handle numbered lists
            if ($line -match '^\s*\d+\.\s+') {
                $indent = $line.IndexOf($line -replace '^\s*', '')
                $num = $line -replace '^\s*(\d+)\.\s+.*$', '$1'
                $text = $line -replace '^\s*\d+\.\s+', ''
                $prefix = "  " * ($indent / 2) + "$num. "
                Write-Host "$prefix$text" -ForegroundColor Yellow
                continue
            }
            
            # Handle emphasis and bold (basic)
            $line = $line -replace '\*\*([^\*]+)\*\*', ("`e[1m`$1`e[0m")  # Bold
            $line = $line -replace '\*([^\*]+)\*', ("`e[3m`$1`e[0m")      # Italic
            
            # Regular text
            Write-Host $line
        }
    }
    
    # Function to display a document with progress
    function Show-Document {
        param (
            [string]$Title,
            [string[]]$FilePaths,
            [switch]$UseMarkdownRendering,
            [switch]$ShowProgress
        )
        
        Clear-Host
        Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║             $($Title.PadRight(28))║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        $content = $null
        $foundFile = $false
        $foundPath = ""
        
        if ($ShowProgress) {
            # Create a progress task for loading documentation
            $task = Start-ProgressTask -Activity "Loading Documentation" -TotalSteps 3 -ScriptBlock {
                # Step 1: Searching for documentation files
                $syncHash.Status = "Searching for documentation files..."
                $syncHash.CurrentStep = 1
                
                foreach ($path in $FilePaths) {
                    if (Test-Path $path) {
                        $foundFile = $true
                        $foundPath = $path
                        break
                    }
                }
                
                if (-not $foundFile) {
                    return @{
                        Success = $false
                        ErrorMessage = "Documentation not found."
                        SearchedPaths = $FilePaths
                    }
                }
                
                # Step 2: Reading documentation content
                $syncHash.Status = "Reading documentation content..."
                $syncHash.CurrentStep = 2
                
                try {
                    $content = Get-Content -Path $foundPath -Raw
                    
                    # Step 3: Processing content
                    $syncHash.Status = "Processing content..."
                    $syncHash.CurrentStep = 3
                    
                    return @{
                        Success = $true
                        Content = $content -split "`n"
                        Path = $foundPath
                    }
                }
                catch {
                    return @{
                        Success = $false
                        ErrorMessage = "Error reading documentation: $_"
                        Path = $foundPath
                    }
                }
            }
            
            $result = $task.Complete()
            
            if ($result.Success) {
                if ($UseMarkdownRendering) {
                    Format-Markdown -Content $result.Content
                }
                else {
                    $result.Content | ForEach-Object { Write-Host $_ }
                }
                
                Write-Host ""
                Write-Host "Documentation loaded from: $($result.Path)" -ForegroundColor DarkGray
                
                if ($canLog) {
                    Write-Log -Message "Successfully displayed documentation from $($result.Path)" -Level INFO
                }
            }
            else {
                Write-Host $result.ErrorMessage -ForegroundColor Red
                
                if ($result.SearchedPaths) {
                    Write-Host "Searched locations:" -ForegroundColor Yellow
                    foreach ($path in $result.SearchedPaths) {
                        Write-Host "- $path" -ForegroundColor Yellow
                    }
                }
                
                if ($canLog) {
                    Write-Log -Message $result.ErrorMessage -Level ERROR
                    if ($result.SearchedPaths) {
                        Write-Log -Message "Searched paths: $($result.SearchedPaths -join ', ')" -Level DEBUG
                    }
                }
            }
        }
        else {
            # Original implementation without progress bar
            $foundFile = $false
            foreach ($path in $FilePaths) {
                if (Test-Path $path) {
                    $foundFile = $true
                    $foundPath = $path
                    
                    try {
                        $content = Get-Content -Path $path
                        
                        if ($UseMarkdownRendering) {
                            Format-Markdown -Content $content
                        }
                        else {
                            $content | ForEach-Object { Write-Host $_ }
                        }
                        
                        Write-Host ""
                        Write-Host "Documentation loaded from: $path" -ForegroundColor DarkGray
                        
                        if ($canLog) {
                            Write-Log -Message "Successfully displayed documentation from $path" -Level INFO
                        }
                    }
                    catch {
                        Write-Host "Error reading documentation: $_" -ForegroundColor Red
                        if ($canLog) {
                            Write-Log -Message ("Error reading documentation from $path" + ": $_") -Level ERROR
                        }
                    }
                    
                    break
                }
            }
            
            if (-not $foundFile) {
                Write-Host "Documentation not found." -ForegroundColor Red
                Write-Host "Searched locations:" -ForegroundColor Yellow
                foreach ($path in $FilePaths) {
                    Write-Host "- $path" -ForegroundColor Yellow
                }
                
                if ($canLog) {
                    Write-Log -Message "Documentation not found. Searched paths: $($FilePaths -join ', ')" -Level ERROR
                }
            }
        }
    }
    
    $selection = 0
    do {
        try {
            Show-DocumentationMenu -ShowProgress:$ShowProgress
        }
        catch {
            Write-Host "Error displaying Documentation Menu: $_" -ForegroundColor Red
            if ($canLog) { Write-Log -Message "Error displaying Documentation Menu: $_" -Level ERROR }
            break
        }
        
        $selection = Read-Host "Select an option"
        
        switch ($selection) {
            "1" {
                if ($canLog) { Write-Log -Message "User selected: View Main README" -Level INFO }
                
                $readmePaths = @(
                    (Join-Path -Path $moduleRoot -ChildPath "..\README.md"),
                    (Join-Path -Path $moduleRoot -ChildPath "README.md")
                )
                
                Show-Document -Title "MAIN README" -FilePaths $readmePaths -UseMarkdownRendering:$UseMarkdownRendering -ShowProgress:$ShowProgress
                
                Pause
            }
            "2" {
                if ($canLog) { Write-Log -Message "User selected: View VPN Gateway Documentation" -Level INFO }
                
                $vpnReadmePaths = @(
                    (Join-Path -Path $docsPath -ChildPath "VPN-GATEWAY.README.md"),
                    (Join-Path -Path $docsPath -ChildPath "vpn-gateway.md"),
                    (Join-Path -Path $docsPath -ChildPath "vpn-gateway-guide.md"),
                    (Join-Path -Path $docsPath -ChildPath "vpn-documentation.md")
                )
                
                Show-Document -Title "VPN GATEWAY DOCUMENTATION" -FilePaths $vpnReadmePaths -UseMarkdownRendering:$UseMarkdownRendering -ShowProgress:$ShowProgress
                
                Pause
            }
            "3" {
                if ($canLog) { Write-Log -Message "User selected: View Client Certificate Management Guide" -Level INFO }
                
                $certGuidePaths = @(
                    (Join-Path -Path $docsPath -ChildPath "client-certificate-management.md"),
                    (Join-Path -Path $docsPath -ChildPath "vpn-certificates.md"),
                    (Join-Path -Path $docsPath -ChildPath "certificate-guide.md"),
                    (Join-Path -Path $docsPath -ChildPath "cert-management.md")
                )
                
                Show-Document -Title "CLIENT CERTIFICATE MANAGEMENT GUIDE" -FilePaths $certGuidePaths -UseMarkdownRendering:$UseMarkdownRendering -ShowProgress:$ShowProgress
                
                Pause
            }
            "0" {
                # Return to main menu
                if ($canLog) { Write-Log -Message "User exited Documentation Menu" -Level INFO }
            }
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                if ($canLog) { Write-Log -Message "User selected invalid option: $selection" -Level WARN }
                Start-Sleep -Seconds 2
            }
        }
    } while ($selection -ne "0")
}
