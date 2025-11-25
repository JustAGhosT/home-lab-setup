<#
.SYNOPSIS
    Launches the HomeLab Tauri desktop application frontend.
.DESCRIPTION
    This script starts the HomeLab Tauri frontend application in development mode.
    It handles prerequisite checks, installs dependencies if needed, and launches
    the Tauri development server.
.NOTES
    Author: HomeLab Team
    Version: 1.0.0
.EXAMPLE
    # Start the Tauri frontend in development mode
    .\.start.ps1
.EXAMPLE
    # Start with verbose output
    .\.start.ps1 -Verbose
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$appPath = Join-Path -Path $scriptRoot -ChildPath 'app'

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "➡️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-ErrorMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Display banner
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                         HomeLab Tauri Frontend Launcher                      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Step "Checking prerequisites..."

# Check for Node.js
if (-not (Test-CommandExists 'node')) {
    Write-ErrorMessage "Node.js is not installed. Please install Node.js from https://nodejs.org/"
    exit 1
}

$nodeVersion = node --version
Write-Verbose "Node.js version: $nodeVersion"

# Check for pnpm (preferred) or npm
$packageManager = $null
if (Test-CommandExists 'pnpm') {
    $packageManager = 'pnpm'
    $pnpmVersion = pnpm --version
    Write-Verbose "pnpm version: $pnpmVersion"
}
elseif (Test-CommandExists 'npm') {
    $packageManager = 'npm'
    $npmVersion = npm --version
    Write-Verbose "npm version: $npmVersion"
}
else {
    Write-ErrorMessage "Neither pnpm nor npm is installed. Please install pnpm or npm."
    exit 1
}

Write-Success "Prerequisites check passed (Node.js: $nodeVersion, Package Manager: $packageManager)"

# Check for Rust (required for Tauri)
if (-not (Test-CommandExists 'cargo')) {
    Write-ErrorMessage "Rust is not installed. Please install Rust from https://rustup.rs/"
    exit 1
}

$rustVersion = rustc --version
Write-Success "Rust installed: $rustVersion"

# Navigate to app directory
Write-Step "Navigating to app directory..."

if (-not (Test-Path $appPath)) {
    Write-ErrorMessage "App directory not found at: $appPath"
    exit 1
}

Set-Location -Path $appPath
Write-Success "Changed to app directory: $appPath"

# Install dependencies if node_modules doesn't exist
$nodeModulesPath = Join-Path -Path $appPath -ChildPath 'node_modules'
if (-not (Test-Path $nodeModulesPath)) {
    Write-Step "Installing dependencies with $packageManager..."
    
    if ($packageManager -eq 'pnpm') {
        pnpm install
    }
    else {
        npm install
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorMessage "Failed to install dependencies"
        exit 1
    }
    
    Write-Success "Dependencies installed successfully"
}
else {
    Write-Success "Dependencies already installed"
}

# Start the Tauri development server
Write-Step "Starting Tauri development server..."
Write-Host ""
Write-Host "The HomeLab application is starting. A window should open shortly." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the development server." -ForegroundColor Yellow
Write-Host ""

if ($packageManager -eq 'pnpm') {
    pnpm tauri dev
}
else {
    npm run tauri dev
}

if ($LASTEXITCODE -ne 0) {
    Write-ErrorMessage "Tauri development server exited with an error"
    exit 1
}
