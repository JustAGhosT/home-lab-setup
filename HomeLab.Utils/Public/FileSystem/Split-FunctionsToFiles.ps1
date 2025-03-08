<#
.SYNOPSIS
    Extracts functions from PS1 files and creates separate files for each function.
.DESCRIPTION
    This function analyzes PS1 files in a specified folder, extracts all functions along
    with their comment-based help, and creates separate PS1 files for each function.
    It preserves the synopsis, description, parameters, and other help elements.
.PARAMETER SourceFolder
    The folder containing PS1 files to analyze.
.PARAMETER DestinationFolder
    The folder where individual function files will be created.
.PARAMETER CreateSubfolders
    If specified, creates subfolders based on function categories (verbs).
.EXAMPLE
    Split-FunctionsToFiles -SourceFolder "C:\Projects\MyModule" -DestinationFolder "C:\Projects\MyModule\Functions"
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>
function Split-FunctionsToFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFolder,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationFolder,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateSubfolders
    )

    # Ensure the destination folder exists
    if (-not (Test-Path -Path $DestinationFolder)) {
        New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
        Write-Host "Created destination folder: $DestinationFolder" -ForegroundColor Green
    }

    # Get all PS1 files in the source folder
    $psFiles = Get-ChildItem -Path $SourceFolder -Filter "*.ps1" -Recurse

    # Counter for statistics
    $totalFunctionsFound = 0
    $totalFunctionsExtracted = 0
    $filesProcessed = 0

    # Regular expression patterns
    $functionPattern = '(?sm)(<#(?:.*?)#>)?\s*function\s+([A-Za-z0-9\-_]+)\s*\{(.*?)(?=\s*function|\s*$)'

    foreach ($file in $psFiles) {
        Write-Host "Processing file: $($file.FullName)" -ForegroundColor Cyan
        $filesProcessed++
        
        # Read the file content
        $content = Get-Content -Path $file.FullName -Raw
        
        # Find all functions in the file
        $matches = [regex]::Matches($content, $functionPattern)
        
        Write-Host "  Found $($matches.Count) functions" -ForegroundColor Yellow
        $totalFunctionsFound += $matches.Count
        
        foreach ($match in $matches) {
            # Extract function components
            $commentBlock = $match.Groups[1].Value.Trim()
            $functionName = $match.Groups[2].Value.Trim()
            $functionBody = $match.Groups[3].Value.Trim()
            
            Write-Host "  Extracting function: $functionName" -ForegroundColor White
            
            # Determine the destination subfolder if needed
            $targetFolder = $DestinationFolder
            if ($CreateSubfolders) {
                # Get the verb from the function name
                $verbNoun = $functionName -split '-'
                if ($verbNoun.Count -gt 1) {
                    $verb = $verbNoun[0]
                    $targetFolder = Join-Path -Path $DestinationFolder -ChildPath $verb
                    if (-not (Test-Path -Path $targetFolder)) {
                        New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
                    }
                }
            }
            
            # Create the function file
            $functionFilePath = Join-Path -Path $targetFolder -ChildPath "$functionName.ps1"
            
            # Construct the function content with comment block
            $functionContent = ""
            if ($commentBlock) {
                $functionContent += "$commentBlock`n`n"
            }
            $functionContent += "function $functionName {`n$functionBody`n}"
            
            # Write to file
            Set-Content -Path $functionFilePath -Value $functionContent
            
            $totalFunctionsExtracted++
        }
    }

    # Print summary
    Write-Host "`n===== Summary =====" -ForegroundColor Magenta
    Write-Host "Files processed: $filesProcessed" -ForegroundColor Magenta
    Write-Host "Functions found: $totalFunctionsFound" -ForegroundColor Magenta
    Write-Host "Functions extracted: $totalFunctionsExtracted" -ForegroundColor Magenta
    Write-Host "Destination folder: $DestinationFolder" -ForegroundColor Magenta

    # Check for functions that might have been missed
    if ($totalFunctionsFound -ne $totalFunctionsExtracted) {
        Write-Warning "Some functions may not have been extracted correctly. Please check the source files."
    }
}
