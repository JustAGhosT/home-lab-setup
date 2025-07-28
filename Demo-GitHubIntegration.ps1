# HomeLab GitHub Integration Demo - Enhanced Azure Deployment
# This script demonstrates the complete GitHub integration with Azure deployment capabilities

Write-Host "=== HomeLab GitHub Integration Demo - Enhanced Azure Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Import the module
Write-Host "1. Loading HomeLab.GitHub module..." -ForegroundColor Yellow
Import-Module .\HomeLab\modules\HomeLab.GitHub -Force

# Show available functions
Write-Host ""
Write-Host "2. Available GitHub functions:" -ForegroundColor Yellow
Get-Command -Module HomeLab.GitHub | Format-Table Name, CommandType -AutoSize

# Test connection status
Write-Host ""
Write-Host "3. Testing GitHub connection..." -ForegroundColor Yellow
$connected = Test-GitHubConnection -Quiet
if ($connected) {
    Write-Host "   SUCCESS: Connected to GitHub!" -ForegroundColor Green
}
else {
    Write-Host "   INFO: Not connected to GitHub" -ForegroundColor Gray
    Write-Host "   To connect, run: Connect-GitHub" -ForegroundColor Cyan
}

# Show current configuration
Write-Host ""
Write-Host "4. Current GitHub configuration:" -ForegroundColor Yellow
$config = Get-GitHubConfiguration
$config | Format-Table -AutoSize

# Demonstrate repository listing (will show error if not connected)
Write-Host ""
Write-Host "5. Testing repository listing..." -ForegroundColor Yellow
try {
    $repos = Get-GitHubRepositories -Limit 5 -ErrorAction Stop
    Write-Host "   SUCCESS: Found $($repos.Count) repositories" -ForegroundColor Green
    if ($repos.Count -gt 0) {
        Write-Host "   Sample repositories:" -ForegroundColor Gray
        $repos | Select-Object Name, Language, Private | Format-Table -AutoSize
    }
}
catch {
    Write-Host "   INFO: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host "   This is expected if not connected to GitHub" -ForegroundColor Gray
}

# Show enhanced deployment capabilities
Write-Host ""
Write-Host "6. Enhanced Azure Deployment Capabilities:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Available Deployment Types:" -ForegroundColor Cyan
Write-Host "   - Infrastructure    : Deploy Bicep/ARM templates to Azure" -ForegroundColor Gray
Write-Host "   - WebApp           : Deploy web applications to Azure App Service" -ForegroundColor Gray
Write-Host "   - StaticSite       : Deploy static sites to Azure Static Web Apps" -ForegroundColor Gray
Write-Host "   - ContainerApp     : Deploy containerized apps to Azure Container Apps" -ForegroundColor Gray
Write-Host ""
Write-Host "   Supported Platforms:" -ForegroundColor Cyan
Write-Host "   - Azure (default)  : Microsoft Azure cloud platform" -ForegroundColor Gray
Write-Host ""
Write-Host "   Auto-Detection Features:" -ForegroundColor Cyan
Write-Host "   - Detects Bicep files for Infrastructure deployment" -ForegroundColor Gray
Write-Host "   - Detects Dockerfile for Container deployment" -ForegroundColor Gray
Write-Host "   - Detects web frameworks (React, Vue, Angular, Next.js)" -ForegroundColor Gray
Write-Host "   - Detects static content for Static Site deployment" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Demo Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Enhanced GitHub to Azure Deployment Workflow:" -ForegroundColor White
Write-Host ""
Write-Host "1. Authentication & Repository Selection:" -ForegroundColor Cyan
Write-Host "   Connect-GitHub                                    # Authenticate with GitHub" -ForegroundColor Gray
Write-Host "   Get-GitHubRepositories -Language PowerShell      # List repositories" -ForegroundColor Gray
Write-Host "   Select-GitHubRepository                          # Interactive selection" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Azure Deployment Options:" -ForegroundColor Cyan
Write-Host "   # Auto-detect deployment type" -ForegroundColor Gray
Write-Host "   Deploy-GitHubRepository -ResourceGroup 'my-rg'" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Specify deployment type explicitly" -ForegroundColor Gray
Write-Host "   Deploy-GitHubRepository -DeploymentType Infrastructure -ResourceGroup 'infra-rg'" -ForegroundColor Gray
Write-Host "   Deploy-GitHubRepository -DeploymentType WebApp -ResourceGroup 'web-rg'" -ForegroundColor Gray
Write-Host "   Deploy-GitHubRepository -DeploymentType StaticSite -ResourceGroup 'static-rg'" -ForegroundColor Gray
Write-Host "   Deploy-GitHubRepository -DeploymentType ContainerApp -ResourceGroup 'container-rg'" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Deploy with monitoring" -ForegroundColor Gray
Write-Host "   Deploy-GitHubRepository -Monitor -BackgroundMonitor" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Repository Management:" -ForegroundColor Cyan
Write-Host "   Clone-GitHubRepository -Branch 'main' -Force     # Clone locally" -ForegroundColor Gray
Write-Host "   Test-GitHubConnection                            # Verify connection" -ForegroundColor Gray
Write-Host "   Disconnect-GitHub                                # Clean disconnect" -ForegroundColor Gray
Write-Host ""
Write-Host "For detailed help: Get-Help Deploy-GitHubRepository -Full" -ForegroundColor Cyan
