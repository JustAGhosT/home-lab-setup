<#
.SYNOPSIS
    Quick entry point for deploying websites to Azure using HomeLab
.DESCRIPTION
    This script provides a streamlined entry point for deploying websites to Azure
    using the HomeLab environment. It automatically imports the necessary modules
    and starts the website deployment process with minimal setup.
.NOTES
    Author: Jurie Smit
    Version: 1.0.0
    Date: June 5, 2024
.EXAMPLE
    # Basic usage - will prompt for all required information
    .\Deploy-Website.ps1
.EXAMPLE
    # Deploy a static website with parameters
    .\Deploy-Website.ps1 -DeploymentType static -ResourceGroup "rg-portfolio" -AppName "portfolio-prod" -SubscriptionId "abc123" -CustomDomain "example.com" -Subdomain "portfolio"
.EXAMPLE
    # Deploy an app service with parameters
    .\Deploy-Website.ps1 -DeploymentType appservice -ResourceGroup "rg-api" -AppName "backend-api" -SubscriptionId "abc123"
.EXAMPLE
    # Auto-detect website type and deploy
    .\Deploy-Website.ps1 -DeploymentType auto -ResourceGroup "rg-myapp" -AppName "myapp" -SubscriptionId "abc123" -ProjectPath "C:\Projects\MyWebApp"
#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("static", "appservice", "auto")]
    [string]$DeploymentType,
    
    [Parameter()]
    [string]$Subdomain,
    
    [Parameter()]
    [string]$ResourceGroup,
    
    [Parameter()]
    [string]$Location = "westeurope",
    
    [Parameter()]
    [string]$AppName,
    
    [Parameter()]
    [string]$SubscriptionId,
    
    [Parameter()]
    [string]$CustomDomain,
    
    [Parameter()]
    [string]$RepoUrl,
    
    [Parameter()]
    [string]$Branch = "main",
    
    [Parameter()]
    [string]$ProjectPath,
    
    [Parameter()]
    [switch]$ShowHelp
)

# Show help if requested
if ($ShowHelp) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    return
}

# Function to check and install the Az PowerShell module if needed
function Ensure-AzModule {
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Host "The Az PowerShell module is required but not installed." -ForegroundColor Yellow
        $installPrompt = Read-Host "Would you like to install it now? (y/n)"
        
        if ($installPrompt -eq "y") {
            Write-Host "Installing Az PowerShell module. This may take a few minutes..." -ForegroundColor Cyan
            Install-Module -Name Az -AllowClobber -Force
            return $true
        }
        else {
            Write-Host "Az module installation declined. Cannot proceed without the Az module." -ForegroundColor Red
            return $false
        }
    }
    return $true
}

# Function to check if user is logged in to Azure
function Ensure-AzureLogin {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "You are not logged in to Azure. Initiating login process..." -ForegroundColor Yellow
            Connect-AzAccount
            return $?  # Return success/failure of Connect-AzAccount
        }
        return $true
    }
    catch {
        Write-Host "You are not logged in to Azure. Initiating login process..." -ForegroundColor Yellow
        Connect-AzAccount
        return $?  # Return success/failure of Connect-AzAccount
    }
}

# Function to import the HomeLab module
function Import-HomeLabModule {
    try {
        # Try to import the HomeLab module
        $moduleBasePath = Join-Path -Path $PSScriptRoot -ChildPath "HomeLab"
        $modulePath = Join-Path -Path $moduleBasePath -ChildPath "HomeLab.psd1"
        
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            Write-Host "HomeLab module imported successfully." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "HomeLab module not found at expected path: $modulePath" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error importing HomeLab module: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to get GitHub repositories for the authenticated user
function Get-GitHubRepositories {
    param(
        [string]$GitHubToken
    )
    
    if (-not $GitHubToken) {
        return @()
    }
    
    try {
        $headers = @{
            'Authorization' = "token $GitHubToken"
            'Accept'        = 'application/vnd.github.v3+json'
            'User-Agent'    = 'HomeLab-PowerShell'
        }
        
        $repos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?sort=updated&per_page=50" -Headers $headers -Method Get
        return $repos | Where-Object { -not $_.fork } | Sort-Object updated_at -Descending
    }
    catch {
        Write-Warning "Failed to fetch GitHub repositories: $($_.Exception.Message)"
        return @()
    }
}

# Function to get current Azure subscription info
function Get-CurrentAzureSubscription {
    try {
        $context = Get-AzContext
        if ($context) {
            return @{
                SubscriptionId   = $context.Subscription.Id
                SubscriptionName = $context.Subscription.Name
                TenantId         = $context.Tenant.Id
            }
        }
    }
    catch {
        Write-Verbose "No Azure context available"
    }
    return $null
}

# Function to get GitHub token from various sources
function Get-GitHubToken {
    # Try environment variable first
    $token = $env:GITHUB_TOKEN
    if ($token) {
        return $token
    }
    
    # Try git credential manager
    try {
        $gitConfig = git config --global credential.helper 2>$null
        if ($gitConfig -like "*manager*") {
            # Could potentially extract from credential manager, but for security, we'll skip this
            Write-Verbose "Git credential manager detected but token extraction skipped for security"
        }
    }
    catch {
        Write-Verbose "Git not available or no credential manager configured"
    }
    
    return $null
}

# Function to display a simple form for collecting missing parameters
function Show-DeploymentForm {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Get current Azure subscription info
    $azureInfo = Get-CurrentAzureSubscription
    
    # Get GitHub token and repositories
    $githubToken = Get-GitHubToken
    $repositories = @()
    if ($githubToken) {
        Write-Host "Fetching GitHub repositories..." -ForegroundColor Yellow
        $repositories = Get-GitHubRepositories -GitHubToken $githubToken
    }
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Website Deployment"
    $form.Size = New-Object System.Drawing.Size(600, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    
    $title = New-Object System.Windows.Forms.Label
    $title.Text = "HomeLab Website Deployment"
    $title.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $title.Location = New-Object System.Drawing.Point(150, 20)
    $title.Size = New-Object System.Drawing.Size(300, 30)
    $form.Controls.Add($title)
    
    $yPos = 70
    $labelWidth = 150
    $controlWidth = 300
    $height = 25
    $padding = 10
    
    # Deployment Type
    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Text = "Deployment Type:"
    $typeLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $typeLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($typeLabel)
    
    $typeComboBox = New-Object System.Windows.Forms.ComboBox
    $typeComboBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $typeComboBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
    $typeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    [void]$typeComboBox.Items.Add("static")
    [void]$typeComboBox.Items.Add("appservice")
    [void]$typeComboBox.Items.Add("auto")
    if ($DeploymentType) {
        $typeComboBox.SelectedItem = $DeploymentType
    }
    else {
        $typeComboBox.SelectedItem = "static"
    }
    $form.Controls.Add($typeComboBox)
    $yPos += $height + $padding
    
    # Resource Group
    $rgLabel = New-Object System.Windows.Forms.Label
    $rgLabel.Text = "Resource Group:"
    $rgLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $rgLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($rgLabel)
    
    $rgTextBox = New-Object System.Windows.Forms.TextBox
    $rgTextBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $rgTextBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
    if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        $rgTextBox.Text = "rg-myapp-prod"
        $rgTextBox.ForeColor = [System.Drawing.Color]::Gray
        $rgTextBox.Add_GotFocus({
                if ($rgTextBox.Text -eq "rg-myapp-prod") {
                    $rgTextBox.Text = ""
                    $rgTextBox.ForeColor = [System.Drawing.Color]::Black
                }
            })
        $rgTextBox.Add_LostFocus({
                if ([string]::IsNullOrWhiteSpace($rgTextBox.Text)) {
                    $rgTextBox.Text = "rg-myapp-prod"
                    $rgTextBox.ForeColor = [System.Drawing.Color]::Gray
                }
            })
    }
    else {
        $rgTextBox.Text = $ResourceGroup
    }
    $form.Controls.Add($rgTextBox)
    $yPos += $height + $padding
    
    # App Name
    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = "App Name:"
    $nameLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $nameLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($nameLabel)
    
    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $nameTextBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
    if ([string]::IsNullOrWhiteSpace($AppName)) {
        $nameTextBox.Text = "myapp-prod"
        $nameTextBox.ForeColor = [System.Drawing.Color]::Gray
        $nameTextBox.Add_GotFocus({
                if ($nameTextBox.Text -eq "myapp-prod") {
                    $nameTextBox.Text = ""
                    $nameTextBox.ForeColor = [System.Drawing.Color]::Black
                }
            })
        $nameTextBox.Add_LostFocus({
                if ([string]::IsNullOrWhiteSpace($nameTextBox.Text)) {
                    $nameTextBox.Text = "myapp-prod"
                    $nameTextBox.ForeColor = [System.Drawing.Color]::Gray
                }
            })
    }
    else {
        $nameTextBox.Text = $AppName
    }
    $form.Controls.Add($nameTextBox)
    $yPos += $height + $padding
    
    # Subscription ID
    $subLabel = New-Object System.Windows.Forms.Label
    $subLabel.Text = "Subscription ID:"
    $subLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $subLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($subLabel)
    
    $subTextBox = New-Object System.Windows.Forms.TextBox
    $subTextBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $subTextBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
    # Prepopulate with current Azure subscription if available
    if ($azureInfo -and -not $SubscriptionId) {
        $subTextBox.Text = $azureInfo.SubscriptionId
    }
    else {
        $subTextBox.Text = $SubscriptionId
    }
    $form.Controls.Add($subTextBox)
    $yPos += $height + $padding
    
    # Add subscription info label if available
    if ($azureInfo) {
        $subInfoLabel = New-Object System.Windows.Forms.Label
        $subInfoLabel.Text = "Current: $($azureInfo.SubscriptionName)"
        $subInfoLabel.Location = New-Object System.Drawing.Point(180, $yPos)
        $subInfoLabel.Size = New-Object System.Drawing.Size($controlWidth, 15)
        $subInfoLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Italic)
        $subInfoLabel.ForeColor = [System.Drawing.Color]::Gray
        $form.Controls.Add($subInfoLabel)
        $yPos += 20
    }
    
    # Location
    $locLabel = New-Object System.Windows.Forms.Label
    $locLabel.Text = "Location:"
    $locLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $locLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($locLabel)
    
    $locComboBox = New-Object System.Windows.Forms.ComboBox
    $locComboBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $locComboBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
    $locComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    [void]$locComboBox.Items.Add("westeurope")
    [void]$locComboBox.Items.Add("eastus")
    [void]$locComboBox.Items.Add("westus")
    [void]$locComboBox.Items.Add("northeurope")
    [void]$locComboBox.Items.Add("centralus")
    [void]$locComboBox.Items.Add("eastasia")
    $locComboBox.SelectedItem = $Location
    $form.Controls.Add($locComboBox)
    $yPos += $height + $padding
    
    # Custom Domain
    $domainLabel = New-Object System.Windows.Forms.Label
    $domainLabel.Text = "Custom Domain:"
    $domainLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $domainLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($domainLabel)
    
    $domainTextBox = New-Object System.Windows.Forms.TextBox
    $domainTextBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $domainTextBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
    $domainTextBox.Text = $CustomDomain
    $form.Controls.Add($domainTextBox)
    $yPos += $height + $padding
    
    # Subdomain
    $subdomainLabel = New-Object System.Windows.Forms.Label
    $subdomainLabel.Text = "Subdomain:"
    $subdomainLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $subdomainLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($subdomainLabel)
    
    $subdomainTextBox = New-Object System.Windows.Forms.TextBox
    $subdomainTextBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $subdomainTextBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
    $subdomainTextBox.Text = $Subdomain
    $form.Controls.Add($subdomainTextBox)
    $yPos += $height + $padding# GitHub Repository Selection (if available)
    if ($repositories.Count -gt 0) {
        $githubLabel = New-Object System.Windows.Forms.Label
        $githubLabel.Text = "GitHub Repository:"
        $githubLabel.Location = New-Object System.Drawing.Point(20, $yPos)
        $githubLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
        $form.Controls.Add($githubLabel)
        
        $repoComboBox = New-Object System.Windows.Forms.ComboBox
        $repoComboBox.Location = New-Object System.Drawing.Point(180, $yPos)
        $repoComboBox.Size = New-Object System.Drawing.Size($controlWidth, $height)
        $repoComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
        
        # Add "None - Use Local Path" option
        [void]$repoComboBox.Items.Add("(Use Local Path)")
        
        # Add repositories
        foreach ($repo in $repositories) {
            $displayName = "$($repo.name) - $($repo.description)"
            if ($displayName.Length -gt 60) {
                $displayName = $displayName.Substring(0, 57) + "..."
            }
            [void]$repoComboBox.Items.Add($displayName)
        }
        
        $repoComboBox.SelectedIndex = 0
        $form.Controls.Add($repoComboBox)
        $yPos += $height + $padding
        
        # Add event handler to populate repo URL when selection changes
        $repoComboBox.Add_SelectedIndexChanged({
                if ($repoComboBox.SelectedIndex -gt 0) {
                    $selectedRepo = $repositories[$repoComboBox.SelectedIndex - 1]
                    $script:SelectedRepoUrl = $selectedRepo.clone_url
                    $script:SelectedRepoName = $selectedRepo.name
                    # Auto-populate app name if empty
                    if ([string]::IsNullOrWhiteSpace($nameTextBox.Text)) {
                        $nameTextBox.Text = $selectedRepo.name -replace '[^a-zA-Z0-9-]', '-'
                    }
                }
                else {
                    $script:SelectedRepoUrl = $null
                    $script:SelectedRepoName = $null
                }
            })
    }
    
    # Project Path
    $pathLabel = New-Object System.Windows.Forms.Label
    if ($repositories.Count -gt 0) {
        $pathLabel.Text = "Local Project Path:"
    }
    else {
        $pathLabel.Text = "Project Path:"
    }
    $pathLabel.Location = New-Object System.Drawing.Point(20, $yPos)
    $pathLabel.Size = New-Object System.Drawing.Size($labelWidth, $height)
    $form.Controls.Add($pathLabel)
    
    $pathTextBox = New-Object System.Windows.Forms.TextBox
    $pathTextBox.Location = New-Object System.Drawing.Point(180, $yPos)
    $pathTextBox.Size = New-Object System.Drawing.Size(250, $height)
    $pathTextBox.Text = $ProjectPath
    $form.Controls.Add($pathTextBox)
    
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(440, $yPos)
    $browseButton.Size = New-Object System.Drawing.Size(40, $height)
    $browseButton.Text = "..."
    $browseButton.Add_Click({
            $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowser.Description = "Select the project folder to deploy"
            $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
            if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $pathTextBox.Text = $folderBrowser.SelectedPath
                # If we have a path, reset GitHub selection
                if ($repositories.Count -gt 0) {
                    $repoComboBox.SelectedIndex = 0
                }
            }
        })
    $form.Controls.Add($browseButton)
    $yPos += $height + $padding
    
    # Add a note about deployment source
    $sourceNoteLabel = New-Object System.Windows.Forms.Label
    if ($repositories.Count -gt 0) {
        $sourceNoteLabel.Text = "Choose either GitHub repository OR local path (not both)"
    }
    else {
        $sourceNoteLabel.Text = "Specify local project path for deployment"
    }
    $sourceNoteLabel.Location = New-Object System.Drawing.Point(180, $yPos)
    $sourceNoteLabel.Size = New-Object System.Drawing.Size($controlWidth, 15)
    $sourceNoteLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Italic)
    $sourceNoteLabel.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($sourceNoteLabel)
    $yPos += 25
    
    # Deploy Button
    $deployButton = New-Object System.Windows.Forms.Button
    $deployButton.Location = New-Object System.Drawing.Point(180, $yPos)
    $deployButton.Size = New-Object System.Drawing.Size(120, 30)
    $deployButton.Text = "Deploy"
    $deployButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#0078D4")
    $deployButton.ForeColor = [System.Drawing.Color]::White
    $deployButton.Add_Click({ # Validate required fields
            $errors = @()
        
            $rgValue = $rgTextBox.Text
            if ([string]::IsNullOrWhiteSpace($rgValue) -or $rgValue -eq "rg-myapp-prod") {
                $errors += "Resource Group is required"
            }
        
            $nameValue = $nameTextBox.Text
            if ([string]::IsNullOrWhiteSpace($nameValue) -or $nameValue -eq "myapp-prod") {
                $errors += "App Name is required"
            }
        
            if ([string]::IsNullOrWhiteSpace($subTextBox.Text)) {
                $errors += "Subscription ID is required"
            }
        
            # Check that either GitHub repo is selected OR local path is provided
            $hasGitHubRepo = $repositories.Count -gt 0 -and $repoComboBox.SelectedIndex -gt 0
            $hasLocalPath = -not [string]::IsNullOrWhiteSpace($pathTextBox.Text)
        
            if (-not $hasGitHubRepo -and -not $hasLocalPath) {
                $errors += "Either select a GitHub repository or provide a local project path"
            }
        
            if ($errors.Count -gt 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    ($errors -join "`n"), 
                    "Validation Error", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, 
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                return
            }
            
            # Get actual values (not placeholder text)
            $finalRgValue = if ($rgTextBox.Text -eq "rg-myapp-prod" -and $rgTextBox.ForeColor -eq [System.Drawing.Color]::Gray) { "" } else { $rgTextBox.Text }
            $finalNameValue = if ($nameTextBox.Text -eq "myapp-prod" -and $nameTextBox.ForeColor -eq [System.Drawing.Color]::Gray) { "" } else { $nameTextBox.Text }
        
            $script:formValues = @{
                DeploymentType = $typeComboBox.SelectedItem
                ResourceGroup  = $finalRgValue
                AppName        = $finalNameValue
                SubscriptionId = $subTextBox.Text
                Location       = $locComboBox.SelectedItem
                CustomDomain   = $domainTextBox.Text
                Subdomain      = $subdomainTextBox.Text
                ProjectPath    = $pathTextBox.Text
                RepoUrl        = $script:SelectedRepoUrl
                RepoName       = $script:SelectedRepoName
                GitHubToken    = $githubToken
            }
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        })
    $form.Controls.Add($deployButton)
    
    # Cancel Button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(310, $yPos)
    $cancelButton.Size = New-Object System.Drawing.Size(120, 30)
    $cancelButton.Text = "Cancel"
    $cancelButton.Add_Click({
            $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
            $form.Close()
        })
    $form.Controls.Add($cancelButton)
    
    # Display the form
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $script:formValues
    }
    else {
        return $null
    }
}

# Main script execution
Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                        HomeLab Website Deployment                           ║" -ForegroundColor Cyan  
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "This utility will help you deploy websites to Azure using either:" -ForegroundColor White
Write-Host "  • Azure Static Web Apps (for static sites, SPAs)" -ForegroundColor Green
Write-Host "  • Azure App Service (for dynamic web applications)" -ForegroundColor Green
Write-Host ""

# 1. Check and install Az module if needed
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
if (-not (Ensure-AzModule)) {
    Write-Host "❌ Az PowerShell module is required but not available." -ForegroundColor Red
    Write-Host "   Please install it and run this script again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✅ Az PowerShell module is available" -ForegroundColor Green

# 2. Import HomeLab module
if (-not (Import-HomeLabModule)) {
    Write-Host "❌ Failed to import HomeLab module." -ForegroundColor Red
    Write-Host "   Please ensure the repository is correctly cloned and you're running from the root directory." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✅ HomeLab module imported successfully" -ForegroundColor Green

# 3. Ensure Azure login
if (-not (Ensure-AzureLogin)) {
    Write-Host "❌ Azure authentication failed." -ForegroundColor Red
    Write-Host "   Please ensure you can login to Azure and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✅ Azure authentication verified" -ForegroundColor Green
Write-Host ""

# 4. Check if we need to collect missing parameters
$missingParams = @()
if (-not $ResourceGroup) { $missingParams += "ResourceGroup" }
if (-not $AppName) { $missingParams += "AppName" }
if (-not $SubscriptionId) { $missingParams += "SubscriptionId" }

if ($missingParams.Count -gt 0) {
    Write-Host "Missing required parameters: $($missingParams -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    
    # Ask user preference for input method
    Write-Host "How would you like to provide the missing parameters?" -ForegroundColor Cyan
    Write-Host "1. Interactive form (GUI)" -ForegroundColor White  
    Write-Host "2. Command line prompts" -ForegroundColor White
    Write-Host "3. Cancel deployment" -ForegroundColor Gray
    Write-Host ""
    
    do {
        $choice = Read-Host "Please select an option (1-3)"
    } while ($choice -notin @('1', '2', '3'))
    
    switch ($choice) {
        '1' {
            # Use GUI form
            Write-Host "Opening deployment form..." -ForegroundColor Green
            try {
                $formValues = Show-DeploymentForm
                
                if (-not $formValues) {
                    Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
                    exit 0
                }
                
                # Update parameters with form values
                $DeploymentType = $formValues.DeploymentType
                $ResourceGroup = $formValues.ResourceGroup
                $AppName = $formValues.AppName
                $SubscriptionId = $formValues.SubscriptionId
                $Location = $formValues.Location
                $CustomDomain = $formValues.CustomDomain
                $Subdomain = $formValues.Subdomain
                $ProjectPath = $formValues.ProjectPath
                $RepoUrl = $formValues.RepoUrl
                
                # Store GitHub token securely if provided
                if ($formValues.GitHubToken) {
                    $GitHubToken = $formValues.GitHubToken
                }
            }
            catch {
                Write-Host "GUI form failed to load. Falling back to command line prompts..." -ForegroundColor Yellow
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                $choice = '2'  # Fall back to command line
            }
        }
        '2' {
            # Use command line prompts
            Write-Host "Please provide the following information:" -ForegroundColor Green
            Write-Host ""
            
            # Get current Azure subscription info for defaults
            $azureInfo = Get-CurrentAzureSubscription
            
            if (-not $DeploymentType) {
                Write-Host "Deployment Types:" -ForegroundColor Cyan
                Write-Host "  static     - Static websites, SPAs, JAMstack apps" -ForegroundColor White
                Write-Host "  appservice - Dynamic web apps with server-side logic" -ForegroundColor White
                Write-Host "  auto       - Auto-detect based on project structure" -ForegroundColor White
                do {
                    $DeploymentType = Read-Host "Deployment Type [static]"
                    if ([string]::IsNullOrWhiteSpace($DeploymentType)) { $DeploymentType = "static" }
                } while ($DeploymentType -notin @('static', 'appservice', 'auto'))
            }
            
            if (-not $ResourceGroup) {
                $ResourceGroup = Read-Host "Resource Group name (e.g., rg-myapp)"
                while ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
                    Write-Host "Resource Group is required." -ForegroundColor Red
                    $ResourceGroup = Read-Host "Resource Group name"
                }
            }
            
            if (-not $AppName) {
                $AppName = Read-Host "App Name (e.g., myapp-prod)"
                while ([string]::IsNullOrWhiteSpace($AppName)) {
                    Write-Host "App Name is required." -ForegroundColor Red
                    $AppName = Read-Host "App Name"
                }
            }
            
            if (-not $SubscriptionId) {
                if ($azureInfo) {
                    $defaultSub = $azureInfo.SubscriptionId
                    $SubscriptionId = Read-Host "Subscription ID [$($azureInfo.SubscriptionName): $defaultSub]"
                    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) { $SubscriptionId = $defaultSub }
                }
                else {
                    $SubscriptionId = Read-Host "Subscription ID"
                    while ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
                        Write-Host "Subscription ID is required." -ForegroundColor Red
                        $SubscriptionId = Read-Host "Subscription ID"
                    }
                }
            }
            
            if (-not $Location) {
                $Location = Read-Host "Azure Location [westeurope]"
                if ([string]::IsNullOrWhiteSpace($Location)) { $Location = "westeurope" }
            }
            
            if (-not $CustomDomain) {
                $CustomDomain = Read-Host "Custom Domain (optional, e.g., example.com)"
            }
            
            if (-not $Subdomain -and $CustomDomain) {
                $Subdomain = Read-Host "Subdomain (optional, e.g., www for www.example.com)"
            }
            
            if (-not $ProjectPath -and -not $RepoUrl) {
                Write-Host ""
                Write-Host "Project Source:" -ForegroundColor Cyan
                Write-Host "You can deploy from either a local path or GitHub repository." -ForegroundColor White
                $ProjectPath = Read-Host "Local Project Path (leave empty if using GitHub)"
                
                if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
                    $RepoUrl = Read-Host "GitHub Repository URL (e.g., https://github.com/user/repo.git)"
                    if (-not [string]::IsNullOrWhiteSpace($RepoUrl)) {
                        if (-not $Branch) {
                            $Branch = Read-Host "Git Branch [main]"
                            if ([string]::IsNullOrWhiteSpace($Branch)) { $Branch = "main" }
                        }
                        
                        # Prompt for GitHub token if needed
                        $tokenInput = Read-Host "GitHub Personal Access Token (optional, for private repos)"
                        if (-not [string]::IsNullOrWhiteSpace($tokenInput)) {
                            $GitHubToken = $tokenInput
                        }
                    }
                }
            }
        }
        '3' {
            Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
            exit 0
        }
    }
}

# 5. Build deployment parameters
$deployParams = @{
    DeploymentType = $DeploymentType
    ResourceGroup  = $ResourceGroup
    AppName        = $AppName
    SubscriptionId = $SubscriptionId
    Location       = $Location
}

if ($CustomDomain) {
    $deployParams.CustomDomain = $CustomDomain
}

if ($Subdomain) {
    $deployParams.Subdomain = $Subdomain
}

if ($RepoUrl) {
    $deployParams.RepoUrl = $RepoUrl
}

if ($Branch) {
    $deployParams.Branch = $Branch
}

if ($ProjectPath) {
    $deployParams.ProjectPath = $ProjectPath
}

# 6. Display deployment summary
Write-Host "`nDeployment Summary:" -ForegroundColor Cyan
Write-Host "Deployment Type: $DeploymentType" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor White
Write-Host "App Name: $AppName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White
if ($CustomDomain) { Write-Host "Custom Domain: $CustomDomain" -ForegroundColor White }
if ($Subdomain) { Write-Host "Subdomain: $Subdomain" -ForegroundColor White }
if ($RepoUrl) { 
    Write-Host "GitHub Repository: $RepoUrl" -ForegroundColor White 
    Write-Host "Branch: $Branch" -ForegroundColor White
}
elseif ($ProjectPath) { 
    Write-Host "Project Path: $ProjectPath" -ForegroundColor White 
}

# 7. Confirm and execute deployment
$confirmation = Read-Host "`nDo you want to proceed with deployment? (y/n)"

if ($confirmation -eq "y") {
    Write-Host "Starting deployment..." -ForegroundColor Green
    
    try {
        # Execute the deployment
        Deploy-Website @deployParams
        
        Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
        Write-Host "You can now access your website at:" -ForegroundColor Cyan
        
        if ($CustomDomain -and $Subdomain) {
            Write-Host "https://$Subdomain.$CustomDomain" -ForegroundColor White
        }
        else {
            if ($DeploymentType -eq "static") {
                Write-Host "https://$AppName.azurestaticapps.net" -ForegroundColor White
            }
            else {
                Write-Host "https://$AppName.azurewebsites.net" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "For more details, see HomeLab logs." -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
    exit 0
}