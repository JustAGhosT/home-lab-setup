# Repository Restructuring Script
# This script implements the improved repository structure
# Run with: .\scripts\restructure-repository.ps1

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$BackupOnly,
    [switch]$ValidateOnly,
    [string]$BackupPath = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)

# Import required modules
Import-Module -Name PSScriptAnalyzer -ErrorAction SilentlyContinue

# Configuration
$config = @{
    SourceRoot = "."
    BackupPath = $BackupPath
    LogPath    = "logs\restructure-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    WhatIf     = $WhatIf
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    Add-Content -Path $config.LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

# Create log directory
New-Item -Path "logs" -ItemType Directory -Force | Out-Null

Write-Log "Starting repository restructuring process" "INFO"
Write-Log "Configuration: $($config | ConvertTo-Json -Compress)" "DEBUG"

# Phase 1: Backup Current State
function Backup-CurrentState {
    Write-Log "Phase 1: Creating backup of current state" "INFO"
    
    if ($BackupOnly) {
        Write-Log "Backup-only mode - creating backup and exiting" "INFO"
    }
    
    try {
        # Create backup directory
        New-Item -Path $config.BackupPath -ItemType Directory -Force | Out-Null
        
        # Copy current structure (excluding git, node_modules, artifacts)
        $excludeItems = @(
            ".git",
            "node_modules", 
            "artifacts",
            "logs",
            "TestResults",
            $config.BackupPath
        )
        
        Write-Log "Creating backup to: $($config.BackupPath)" "INFO"
        
        if (-not $WhatIf) {
            Copy-Item -Path $config.SourceRoot -Destination $config.BackupPath -Recurse -Exclude $excludeItems
            Write-Log "Backup completed successfully" "SUCCESS"
        }
        else {
            Write-Log "WhatIf: Would create backup to $($config.BackupPath)" "INFO"
        }
        
        if ($BackupOnly) {
            Write-Log "Backup completed. Exiting due to -BackupOnly flag" "INFO"
            exit 0
        }
    }
    catch {
        Write-Log "Error creating backup: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Phase 2: Create New Directory Structure
function Create-NewStructure {
    Write-Log "Phase 2: Creating new directory structure" "INFO"
    
    $newDirectories = @(
        "src",
        "src\HomeLab",
        "src\HomeLab\Public",
        "src\HomeLab\Private", 
        "src\HomeLab\Classes",
        "src\HomeLab\Types",
        "src\HomeLab\Formats",
        "src\HomeLab\Resources",
        "src\HomeLab\Templates",
        "src\HomeLab\Config",
        "modules",
        "tests\unit\HomeLab",
        "tests\unit\modules",
        "tests\unit\shared",
        "tests\integration",
        "tests\performance",
        "tests\security",
        "tests\e2e",
        "scripts\build",
        "scripts\deploy",
        "scripts\ci",
        "scripts\maintenance",
        "config\environments",
        "config\quality",
        "config\security",
        "pipelines",
        "pipelines\templates",
        "quality\artifacts",
        "quality\reports",
        "quality\tools",
        "tools\powershell",
        "tools\automation",
        "samples\quickstart",
        "samples\scenarios",
        "samples\templates",
        "artifacts\build",
        "artifacts\test-results",
        "artifacts\logs"
    )
    
    foreach ($dir in $newDirectories) {
        try {
            if (-not $WhatIf) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                Write-Log "Created directory: $dir" "INFO"
            }
            else {
                Write-Log "WhatIf: Would create directory: $dir" "INFO"
            }
        }
        catch {
            Write-Log "Error creating directory $dir : $($_.Exception.Message)" "ERROR"
        }
    }
}

# Phase 3: Move Files to New Structure
function Move-FilesToNewStructure {
    Write-Log "Phase 3: Moving files to new structure" "INFO"
    
    $fileMoves = @(
        @{
            Source      = "HomeLab"
            Destination = "src\HomeLab"
            Description = "Main HomeLab module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.Azure"
            Destination = "modules\HomeLab.Azure"
            Description = "Azure module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.Security"
            Destination = "modules\HomeLab.Security"
            Description = "Security module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.Monitoring"
            Destination = "modules\HomeLab.Monitoring"
            Description = "Monitoring module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.Logging"
            Destination = "modules\HomeLab.Logging"
            Description = "Logging module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.DNS"
            Destination = "modules\HomeLab.DNS"
            Description = "DNS module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.GitHub"
            Destination = "modules\HomeLab.GitHub"
            Description = "GitHub module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.Web"
            Destination = "modules\HomeLab.Web"
            Description = "Web module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.UI"
            Destination = "modules\HomeLab.UI"
            Description = "UI module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.Utils"
            Destination = "modules\HomeLab.Utils"
            Description = "Utils module"
        },
        @{
            Source      = "HomeLab\modules\HomeLab.Core"
            Destination = "modules\HomeLab.Core"
            Description = "Core module"
        },
        @{
            Source      = "tests\HomeLab"
            Destination = "tests\unit\HomeLab"
            Description = "HomeLab unit tests"
        },
        @{
            Source      = "CI-CD-Quality-Gates.yml"
            Destination = "pipelines\azure-pipelines.yml"
            Description = "Azure DevOps pipeline"
        },
        @{
            Source      = "deploy-azure.yml"
            Destination = "pipelines\github-actions.yml"
            Description = "GitHub Actions workflow"
        },
        @{
            Source      = "Enterprise-Logging-Framework.ps1"
            Destination = "quality\artifacts\Enterprise-Logging-Framework.ps1"
            Description = "Enterprise logging framework"
        },
        @{
            Source      = "Refactored-Deploy-Azure-Example.ps1"
            Destination = "samples\scenarios\Refactored-Deploy-Azure-Example.ps1"
            Description = "Refactored Azure deployment example"
        },
        @{
            Source      = "PowerShell-Enterprise-Quality-Remediation.md"
            Destination = "quality\reports\PowerShell-Enterprise-Quality-Remediation.md"
            Description = "Quality remediation report"
        },
        @{
            Source      = "PowerShell-Enterprise-Quality-Summary.md"
            Destination = "quality\reports\PowerShell-Enterprise-Quality-Summary.md"
            Description = "Quality summary report"
        },
        @{
            Source      = "Repository-Structure-Improvement-Plan.md"
            Destination = "quality\reports\Repository-Structure-Improvement-Plan.md"
            Description = "Structure improvement plan"
        },
        @{
            Source      = "PSScriptAnalyzerSettings.psd1"
            Destination = "config\quality\PSScriptAnalyzerSettings.psd1"
            Description = "PSScriptAnalyzer settings"
        },
        @{
            Source      = "tools\markdown_lint"
            Destination = "tools\markdown_lint"
            Description = "Markdown linting tools"
        },
        @{
            Source      = "Start.ps1"
            Destination = "scripts\quickstart\Start.ps1"
            Description = "Quick start script"
        },
        @{
            Source      = "Deploy-Website.ps1"
            Destination = "scripts\deploy\Deploy-Website.ps1"
            Description = "Website deployment script"
        }
    )
    
    foreach ($move in $fileMoves) {
        try {
            if (Test-Path $move.Source) {
                if (-not $WhatIf) {
                    # Create destination directory if it doesn't exist
                    $destDir = Split-Path $move.Destination -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                    }
                    
                    Move-Item -Path $move.Source -Destination $move.Destination -Force
                    Write-Log "Moved: $($move.Source) -> $($move.Destination) ($($move.Description))" "INFO"
                }
                else {
                    Write-Log "WhatIf: Would move $($move.Source) -> $($move.Destination) ($($move.Description))" "INFO"
                }
            }
            else {
                Write-Log "Source not found, skipping: $($move.Source)" "WARNING"
            }
        }
        catch {
            Write-Log "Error moving $($move.Source): $($_.Exception.Message)" "ERROR"
        }
    }
}

# Phase 4: Update Module Manifests
function Update-ModuleManifests {
    Write-Log "Phase 4: Updating module manifests" "INFO"
    
    $moduleManifests = @(
        "src\HomeLab\HomeLab.psd1",
        "modules\HomeLab.Azure\HomeLab.Azure.psd1",
        "modules\HomeLab.Security\HomeLab.Security.psd1",
        "modules\HomeLab.Monitoring\HomeLab.Monitoring.psd1",
        "modules\HomeLab.Logging\HomeLab.Logging.psd1",
        "modules\HomeLab.DNS\HomeLab.DNS.psd1",
        "modules\HomeLab.GitHub\HomeLab.GitHub.psd1",
        "modules\HomeLab.Web\HomeLab.Web.psd1",
        "modules\HomeLab.UI\HomeLab.UI.psd1",
        "modules\HomeLab.Utils\HomeLab.Utils.psd1",
        "modules\HomeLab.Core\HomeLab.Core.psd1"
    )
    
    foreach ($manifest in $moduleManifests) {
        if (Test-Path $manifest) {
            try {
                Write-Log "Updating module manifest: $manifest" "INFO"
                
                if (-not $WhatIf) {
                    # Update module manifest with new paths
                    $manifestContent = Get-Content $manifest -Raw
                    
                    # Update common paths
                    $manifestContent = $manifestContent -replace '\.\.\\', '..\..\'
                    $manifestContent = $manifestContent -replace '\.\\', '.\'
                    
                    Set-Content -Path $manifest -Value $manifestContent -Encoding UTF8
                    Write-Log "Updated manifest: $manifest" "INFO"
                }
                else {
                    Write-Log "WhatIf: Would update manifest: $manifest" "INFO"
                }
            }
            catch {
                Write-Log "Error updating manifest $manifest - $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# Phase 5: Update CI/CD Pipeline Paths
function Update-PipelinePaths {
    Write-Log "Phase 5: Updating CI/CD pipeline paths" "INFO"
    
    $pipelines = @(
        "pipelines\azure-pipelines.yml",
        "pipelines\github-actions.yml"
    )
    
    foreach ($pipeline in $pipelines) {
        if (Test-Path $pipeline) {
            try {
                Write-Log "Updating pipeline paths: $pipeline" "INFO"
                
                if (-not $WhatIf) {
                    $pipelineContent = Get-Content $pipeline -Raw
                    
                    # Update paths to match new structure
                    $pipelineContent = $pipelineContent -replace 'HomeLab\\', 'src\HomeLab\'
                    $pipelineContent = $pipelineContent -replace 'tests\\', 'tests\unit\'
                    $pipelineContent = $pipelineContent -replace 'PSScriptAnalyzerSettings\.psd1', 'config\quality\PSScriptAnalyzerSettings.psd1'
                    
                    Set-Content -Path $pipeline -Value $pipelineContent -Encoding UTF8
                    Write-Log "Updated pipeline: $pipeline" "INFO"
                }
                else {
                    Write-Log "WhatIf: Would update pipeline: $pipeline" "INFO"
                }
            }
            catch {
                Write-Log "Error updating pipeline $pipeline - $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

# Phase 6: Create New Configuration Files
function Create-NewConfigFiles {
    Write-Log "Phase 6: Creating new configuration files" "INFO"
    
    # Create .editorconfig
    $editorConfig = @"
# EditorConfig for HomeLab PowerShell Module
root = true

[*]
charset = utf-8
end_of_line = crlf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.ps1]
indent_size = 4

[*.psd1]
indent_size = 4

[*.psm1]
indent_size = 4

[*.yml]
indent_size = 2

[*.yaml]
indent_size = 2

[*.json]
indent_size = 2

[*.md]
trim_trailing_whitespace = false
"@

    if (-not $WhatIf) {
        Set-Content -Path ".editorconfig" -Value $editorConfig -Encoding UTF8
        Write-Log "Created .editorconfig" "INFO"
    }
    else {
        Write-Log "WhatIf: Would create .editorconfig" "INFO"
    }
    
    # Create CODE_OF_CONDUCT.md
    $codeOfConduct = @"
# Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

## Our Standards

Examples of behavior that contributes to a positive environment for our
community include:

* Demonstrating empathy and kindness toward other people
* Being respectful of differing opinions, viewpoints, and experiences
* Giving and gracefully accepting constructive feedback
* Accepting responsibility and apologizing to those affected by our mistakes
* Focusing on what is best for the overall community

Examples of unacceptable behavior include:

* The use of sexualized language or imagery, and sexual attention or advances
* Trolling, insulting or derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information without explicit permission
* Other conduct which could reasonably be considered inappropriate

## Enforcement Responsibilities

Community leaders are responsible for clarifying and enforcing our standards of
acceptable behavior and will take appropriate and fair corrective action in
response to any behavior that they deem inappropriate, threatening, offensive,
or harmful.

## Scope

This Code of Conduct applies within all community spaces, and also applies when
an individual is officially representing the community in public spaces.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to the community leaders responsible for enforcement. All complaints
will be reviewed and investigated promptly and fairly.
"@

    if (-not $WhatIf) {
        Set-Content -Path "CODE_OF_CONDUCT.md" -Value $codeOfConduct -Encoding UTF8
        Write-Log "Created CODE_OF_CONDUCT.md" "INFO"
    }
    else {
        Write-Log "WhatIf: Would create CODE_OF_CONDUCT.md" "INFO"
    }
}

# Phase 7: Update .gitignore
function Update-Gitignore {
    Write-Log "Phase 7: Updating .gitignore" "INFO"
    
    $gitignoreAdditions = @"

# Build artifacts
artifacts/
logs/
TestResults/

# PowerShell
*.ps1.log
*.psm1.log
*.psd1.log

# IDE
.vscode/settings.json
.idea/

# OS
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.temp
*.bak
*.backup
"@

    if (-not $WhatIf) {
        Add-Content -Path ".gitignore" -Value $gitignoreAdditions
        Write-Log "Updated .gitignore" "INFO"
    }
    else {
        Write-Log "WhatIf: Would update .gitignore" "INFO"
    }
}

# Phase 8: Validation
function Test-NewStructure {
    Write-Log "Phase 8: Validating new structure" "INFO"
    
    $validationChecks = @(
        @{ Path = "src\HomeLab"; Description = "Main module directory" },
        @{ Path = "modules"; Description = "Sub-modules directory" },
        @{ Path = "tests\unit"; Description = "Unit tests directory" },
        @{ Path = "pipelines"; Description = "CI/CD pipelines directory" },
        @{ Path = "quality"; Description = "Quality artifacts directory" },
        @{ Path = "config\quality"; Description = "Quality configuration directory" }
    )
    
    $validationResults = @()
    
    foreach ($check in $validationChecks) {
        if (Test-Path $check.Path) {
            Write-Log "✅ $($check.Description): $($check.Path)" "SUCCESS"
            $validationResults += @{ Success = $true; Path = $check.Path; Description = $check.Description }
        }
        else {
            Write-Log "❌ $($check.Description): $($check.Path) - NOT FOUND" "ERROR"
            $validationResults += @{ Success = $false; Path = $check.Path; Description = $check.Description }
        }
    }
    
    # Test PowerShell module structure
    if (Test-Path "src\HomeLab\HomeLab.psd1") {
        try {
            $module = Import-Module "src\HomeLab\HomeLab.psd1" -PassThru -Force
            Write-Log "✅ Main module loads successfully: $($module.Version)" "SUCCESS"
        }
        catch {
            Write-Log "❌ Main module failed to load: $($_.Exception.Message)" "ERROR"
        }
    }
    
    return $validationResults
}

# Main execution
try {
    Write-Log "Repository restructuring script started" "INFO"
    Write-Log "WhatIf mode: $WhatIf" "INFO"
    Write-Log "Backup path: $($config.BackupPath)" "INFO"
    
    if ($ValidateOnly) {
        Write-Log "Validation-only mode - testing current structure" "INFO"
        Test-NewStructure
        exit 0
    }
    
    # Execute phases
    Backup-CurrentState
    Create-NewStructure
    Move-FilesToNewStructure
    Update-ModuleManifests
    Update-PipelinePaths
    Create-NewConfigFiles
    Update-Gitignore
    
    # Final validation
    Write-Log "Running final validation..." "INFO"
    $validationResults = Test-NewStructure
    
    $successCount = ($validationResults | Where-Object { $_.Success }).Count
    $totalCount = $validationResults.Count
    
    Write-Log "Restructuring completed!" "SUCCESS"
    Write-Log "Validation results: $successCount/$totalCount checks passed" "INFO"
    
    if ($successCount -eq $totalCount) {
        Write-Log "🎉 All validation checks passed! Repository restructuring successful." "SUCCESS"
    }
    else {
        Write-Log "⚠️ Some validation checks failed. Please review the structure manually." "WARNING"
    }
    
    Write-Log "Backup available at: $($config.BackupPath)" "INFO"
    Write-Log "Log file: $($config.LogPath)" "INFO"
}
catch {
    Write-Log "Fatal error during restructuring: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
