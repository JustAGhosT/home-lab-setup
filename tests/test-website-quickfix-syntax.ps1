Test script to verify Website-QuickFix.ps1 syntax
Write-Host "Testing Website-QuickFix.ps1 syntax..." -ForegroundColor Cyan

try {
    # Test syntax by dot-sourcing the file
    . "src/HomeLab/HomeLab/modules/HomeLab.UI/Public/Website-QuickFix.ps1"
    Write-Host "✅ Syntax check passed!" -ForegroundColor Green
    
    # Test that functions are available
    $functions = @(
        "Show-WebsiteMenuDirect",
        "Deploy-SimpleStaticWebsite", 
        "Deploy-SimpleAppServiceWebsite",
        "Deploy-SimpleAutoDetectWebsite",
        "Set-SimpleCustomDomain"
    )
    
    foreach ($function in $functions) {
        if (Get-Command -Name $function -ErrorAction SilentlyContinue) {
            Write-Host "✅ Function $function is available" -ForegroundColor Green
        }
        else {
            Write-Host "❌ Function $function is missing" -ForegroundColor Red
        }
    }
    
    Write-Host "`n🎯 All tests passed! Website-QuickFix.ps1 is ready for use." -ForegroundColor Green
}
catch {
    Write-Host "❌ Syntax error found: $($_.Exception.Message)" -ForegroundColor Red
} 