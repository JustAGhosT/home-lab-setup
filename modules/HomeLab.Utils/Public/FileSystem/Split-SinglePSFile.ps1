function Split-SinglePSFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$OutputDir,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeComments,
        
        [Parameter(Mandatory = $false)]
        [string]$Prefix = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Suffix = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Verbose "Processing script file: $ScriptPath"
    
    # Read the script content
    try {
        $scriptContent = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to read script file '$ScriptPath': $_"
        return 0
    }
    
    # Parse the script to find functions
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)
        $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        
        Write-Verbose "Found $($functions.Count) functions in $ScriptPath"
        
        if ($functions.Count -eq 0) {
            Write-Warning "No functions found in script file: $ScriptPath"
            return 0
        }
    }
    catch {
        Write-Error "Failed to parse script content from '$ScriptPath': $_"
        return 0
    }
    
    $successCount = 0
    
    # Get all lines of the script for easier processing
    $scriptLines = $scriptContent -split "`n"
    
    foreach ($function in $functions) {
        $functionName = $function.Name
        $functionFileName = "$Prefix$functionName$Suffix.ps1"
        $outputPath = Join-Path -Path $OutputDir -ChildPath $functionFileName
        
        # Check if file already exists
        if ((Test-Path -Path $outputPath) -and -not $Force) {
            Write-Warning "File already exists: $outputPath. Use -Force to overwrite."
            continue
        }
        
        # Get the function's starting line number (0-based in the array)
        $functionStartLine = $function.Extent.StartLineNumber - 1
        $functionContent = $function.Extent.Text
        
        # If IncludeComments is specified, look for comment block before the function
        if ($IncludeComments) {
            # Find the comment block that precedes the function
            $commentLines = @()
            $lineIndex = $functionStartLine - 1
            $inCommentBlock = $false
            
            # Work backwards from the function to find the comment block
            while ($lineIndex -ge 0) {
                $line = $scriptLines[$lineIndex].Trim()
                
                # Check for comment block end
                if ($line -eq "#>") {
                    $inCommentBlock = $true
                    $commentLines = @($line) + $commentLines
                }
                # Check for comment block start
                elseif ($line -eq "<#") {
                    $commentLines = @($line) + $commentLines
                    break
                }
                # Regular comment line
                elseif ($inCommentBlock) {
                    $commentLines = @($line) + $commentLines
                }
                # Single-line comment
                elseif ($line -match "^#") {
                    $commentLines = @($line) + $commentLines
                }
                # If we hit a blank line outside a comment block, stop
                elseif ($line -eq "" -and -not $inCommentBlock) {
                    break
                }
                # If we hit any other code outside a comment block, stop
                elseif (-not $inCommentBlock -and $line -ne "") {
                    break
                }
                
                $lineIndex--
            }
            
            # If we found comments, prepend them to the function content
            if ($commentLines.Count -gt 0) {
                $commentText = $commentLines -join "`n"
                $functionContent = $commentText + "`n" + $functionContent
            }
        }
        
        # Write the function to a file
        if ($PSCmdlet.ShouldProcess($outputPath, "Create function file")) {
            try {
                Set-Content -Path $outputPath -Value $functionContent -Force:$Force -ErrorAction Stop
                Write-Verbose "Created function file: $outputPath"
                $successCount++
            }
            catch {
                Write-Error "Failed to create function file '$outputPath': $_"
            }
        }
    }
    
    return $successCount
}