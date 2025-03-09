function Show-HomeLabLogo {
    [CmdletBinding()]
    param()
    
    Write-Host @"
    
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║   █  █ █▀█ █▄ ▄█ █▀▀   █   █▀█ █▀▀█                   ║
    ║   █▀▀█ █ █ █ ▀ █ █▀▀   █   █▀█ █▀▀▄                   ║
    ║   █  █ ▀▀▀ ▀   ▀ ▀▀▀   ▀▀▀ ▀ ▀ ▀▀▀▀                   ║
    ║                                                       ║
    ║   Your Home Lab Infrastructure Management Tool        ║
    ║   Version 1.0.0                                       ║
    ║                                                       ║
    ╚═══════════════════════════════════════════════════════╝
    
"@ -ForegroundColor Cyan
}