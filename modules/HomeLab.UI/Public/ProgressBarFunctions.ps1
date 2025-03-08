<#
.SYNOPSIS
    Progress bar functions for HomeLab.UI module.
.DESCRIPTION
    Provides functions for displaying and managing progress bars in the HomeLab UI.
.NOTES
    Author: Jurie Smit
    Date: March 8, 2025
#>

function Show-ProgressBar {
    <#
    .SYNOPSIS
        Displays a text-based progress bar in the console.
    .DESCRIPTION
        Creates and displays a customizable text-based progress bar in the console with optional status text.
    .PARAMETER PercentComplete
        The percentage of completion (0-100).
    .PARAMETER Width
        The width of the progress bar in characters. Default is 50.
    .PARAMETER Activity
        The activity description displayed before the progress bar. Default is "Progress".
    .PARAMETER Status
        Additional status text displayed after the progress bar.
    .PARAMETER ForegroundColor
        The color of the progress bar. Default is Green.
    .PARAMETER BackgroundColor
        The color of the empty part of the progress bar. Default is DarkGray.
    .PARAMETER NoPercentage
        If specified, hides the percentage display.
    .PARAMETER NoNewLine
        If specified, doesn't add a new line after the progress bar.
    .PARAMETER ReturnString
        If specified, returns the progress bar as a string instead of displaying it.
    .EXAMPLE
        Show-ProgressBar -PercentComplete 50 -Activity "Deploying" -Status "Creating resources..."
    .EXAMPLE
        Show-ProgressBar -PercentComplete 75 -Width 30 -ForegroundColor Cyan -NoPercentage
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$PercentComplete,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [string]$Activity = "Progress",
        
        [Parameter(Mandatory = $false)]
        [string]$Status = "",
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::Green,
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::DarkGray,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPercentage,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReturnString
    )
    
    # Ensure percent complete is within valid range
    $PercentComplete = [Math]::Max(0, [Math]::Min(100, $PercentComplete))
    
    # Calculate the number of blocks to display
    $numBlocks = [Math]::Round($Width * ($PercentComplete / 100))
    
    # Create the progress bar
    $progressBar = "["
    $progressBar += "█" * $numBlocks
    $progressBar += " " * ($Width - $numBlocks)
    $progressBar += "]"
    
    # Add percentage if requested
    if (-not $NoPercentage) {
        $progressBar += " {0,3:N0}%" -f $PercentComplete
    }
    
    # Add status if provided
    if ($Status) {
        $progressBar += " - $Status"
    }
    
    if ($ReturnString) {
        return $progressBar
    }
    else {
        # Clear the current line before writing the progress bar
        Clear-CurrentLine
        
        # Display the activity if provided
        if ($Activity -ne "Progress") {
            Write-Host "$Activity " -NoNewline
        }
        
        # Display the progress bar with colors
        $originalFg = [Console]::ForegroundColor
        $originalBg = [Console]::BackgroundColor
        
        try {
            [Console]::ForegroundColor = $ForegroundColor
            [Console]::BackgroundColor = $BackgroundColor
            Write-Host $progressBar -NoNewline:$NoNewLine
        }
        finally {
            [Console]::ForegroundColor = $originalFg
            [Console]::BackgroundColor = $originalBg
            
            if (-not $NoNewLine) {
                Write-Host ""
            }
        }
    }
}

function Start-ProgressTask {
    <#
    .SYNOPSIS
        Starts a task with a progress bar display.
    .DESCRIPTION
        Creates a background task that displays a progress bar while executing a script block.
    .PARAMETER Activity
        The activity description displayed before the progress bar.
    .PARAMETER ScriptBlock
        The script block to execute as a background task. The script block can update progress using $syncHash variables.
    .PARAMETER TotalSteps
        The total number of steps in the task. Default is 100.
    .PARAMETER Width
        The width of the progress bar in characters. Default is 50.
    .PARAMETER NoPercentage
        If specified, hides the percentage display.
    .PARAMETER DelayBetweenUpdates
        The delay in milliseconds between progress bar updates. Default is 200ms.
    .EXAMPLE
        $task = Start-ProgressTask -Activity "Deploying" -TotalSteps 5 -ScriptBlock {
            $syncHash.Status = "Step 1"
            $syncHash.CurrentStep = 1
            Start-Sleep -Seconds 1
            
            $syncHash.Status = "Step 2"
            $syncHash.CurrentStep = 2
            Start-Sleep -Seconds 1
            
            # More steps...
            
            return "Task completed successfully"
        }
        $result = $task.Complete()
    .EXAMPLE
        $task = Start-ProgressTask -Activity "Processing" -TotalSteps 10
        for ($i = 1; $i -le 10; $i++) {
            $task.UpdateStatus("Processing item $i")
            $task.UpdateProgress($i)
            Start-Sleep -Seconds 1
        }
        $task.Complete()
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$TotalSteps = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPercentage,
        
        [Parameter(Mandatory = $false)]
        [int]$DelayBetweenUpdates = 200
    )
    
    # Create a synchronized hashtable to share data between runspaces
    $syncHash = [hashtable]::Synchronized(@{
        Activity = $Activity
        CurrentStep = 0
        TotalSteps = $TotalSteps
        Status = ""
        IsComplete = $false
        Error = $null
        Result = $null
        Width = $Width
        NoPercentage = $NoPercentage
    })
    
    # Create and start the progress bar runspace
    $progressRunspace = [runspacefactory]::CreateRunspace()
    $progressRunspace.ApartmentState = "STA"
    $progressRunspace.ThreadOptions = "ReuseThread"
    $progressRunspace.Open()
    $progressRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
    
    $progressCmd = [PowerShell]::Create().AddScript({
        param($DelayBetweenUpdates)
        
        try {
            # Import required functions if they exist in the current session
            if (Get-Command -Name 'Show-ProgressBar' -ErrorAction SilentlyContinue) {
                $showProgressBarDef = (Get-Command -Name 'Show-ProgressBar').Definition
                Invoke-Expression $showProgressBarDef
            }
            
            if (Get-Command -Name 'Clear-CurrentLine' -ErrorAction SilentlyContinue) {
                $clearCurrentLineDef = (Get-Command -Name 'Clear-CurrentLine').Definition
                Invoke-Expression $clearCurrentLineDef
            }
            
            # Display progress until task is complete
            while (-not $syncHash.IsComplete) {
                $percentComplete = if ($syncHash.TotalSteps -gt 0) { 
                    [Math]::Min(100, [Math]::Max(0, ($syncHash.CurrentStep / $syncHash.TotalSteps) * 100)) 
                } else { 
                    0 
                }
                
                if (Get-Command -Name 'Show-ProgressBar' -ErrorAction SilentlyContinue) {
                    Show-ProgressBar -PercentComplete $percentComplete -Activity $syncHash.Activity -Status $syncHash.Status -Width $syncHash.Width -NoPercentage:$syncHash.NoPercentage -NoNewLine
                }
                else {
                    Write-Progress -Activity $syncHash.Activity -Status $syncHash.Status -PercentComplete $percentComplete
                }
                
                Start-Sleep -Milliseconds $DelayBetweenUpdates
            }
            
            # Show 100% complete when done
            if (Get-Command -Name 'Show-ProgressBar' -ErrorAction SilentlyContinue) {
                Show-ProgressBar -PercentComplete 100 -Activity $syncHash.Activity -Status "Complete" -Width $syncHash.Width -NoPercentage:$syncHash.NoPercentage
            }
            else {
                Write-Progress -Activity $syncHash.Activity -Status "Complete" -PercentComplete 100 -Completed
            }
        }
        catch {
            $syncHash.Error = $_
            Write-Error "Error in progress bar thread: $_"
        }
    }).AddArgument($DelayBetweenUpdates)
    
    $progressHandle = $progressCmd.BeginInvoke()
    
    # If a script block is provided, run it in a separate runspace
    if ($ScriptBlock) {
        $taskRunspace = [runspacefactory]::CreateRunspace()
        $taskRunspace.ApartmentState = "STA"
        $taskRunspace.ThreadOptions = "ReuseThread"
        $taskRunspace.Open()
        $taskRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
        
        $taskCmd = [PowerShell]::Create().AddScript({
            param($ScriptBlock)
            
            try {
                # Execute the script block
                $syncHash.Result = & $ScriptBlock
            }
            catch {
                $syncHash.Error = $_
                Write-Error "Error in task thread: $_"
            }
            finally {
                # Mark the task as complete
                $syncHash.IsComplete = $true
            }
        }).AddArgument($ScriptBlock)
        
        $taskHandle = $taskCmd.BeginInvoke()
        
        # Return an object that can be used to manage the task
        return [PSCustomObject]@{
            SyncHash = $syncHash
            ProgressRunspace = $progressRunspace
            ProgressCommand = $progressCmd
            ProgressHandle = $progressHandle
            TaskRunspace = $taskRunspace
            TaskCommand = $taskCmd
            TaskHandle = $taskHandle
            
            UpdateStatus = {
                param([string]$Status)
                $this.SyncHash.Status = $Status
            }
            
            UpdateProgress = {
                param([int]$Step)
                $this.SyncHash.CurrentStep = $Step
            }
            
            IncrementProgress = {
                param([int]$Increment = 1)
                $this.SyncHash.CurrentStep += $Increment
            }
            
            Complete = {
                $this.SyncHash.IsComplete = $true
                $this.ProgressCommand.EndInvoke($this.ProgressHandle)
                $this.ProgressRunspace.Close()
                $this.ProgressRunspace.Dispose()
                
                if ($this.TaskRunspace) {
                    $this.TaskCommand.EndInvoke($this.TaskHandle)
                    $this.TaskRunspace.Close()
                    $this.TaskRunspace.Dispose()
                }
                
                return $this.SyncHash.Result
            }
            
            GetResult = {
                return $this.SyncHash.Result
            }
            
            GetError = {
                return $this.SyncHash.Error
            }
        }
    }
    else {
        # Return an object that can be used to manage the progress bar
        return [PSCustomObject]@{
            SyncHash = $syncHash
            ProgressRunspace = $progressRunspace
            ProgressCommand = $progressCmd
            ProgressHandle = $progressHandle
            
            UpdateStatus = {
                param([string]$Status)
                $this.SyncHash.Status = $Status
            }
            
            UpdateProgress = {
                param([int]$Step)
                $this.SyncHash.CurrentStep = $Step
            }
            
            IncrementProgress = {
                param([int]$Increment = 1)
                $this.SyncHash.CurrentStep += $Increment
            }
            
            Complete = {
                $this.SyncHash.IsComplete = $true
                $this.ProgressCommand.EndInvoke($this.ProgressHandle)
                $this.ProgressRunspace.Close()
                $this.ProgressRunspace.Dispose()
            }
        }
    }
}

function Update-ProgressBar {
    <#
    .SYNOPSIS
        Updates an existing progress bar.
    .DESCRIPTION
        Updates the display of a progress bar with new percentage and status information.
    .PARAMETER PercentComplete
        The percentage of completion (0-100).
    .PARAMETER Status
        Additional status text displayed after the progress bar.
    .PARAMETER Width
        The width of the progress bar in characters. Default is 50.
    .PARAMETER Activity
        The activity description displayed before the progress bar. Default is "Progress".
    .PARAMETER NoPercentage
        If specified, hides the percentage display.
    .EXAMPLE
        Update-ProgressBar -PercentComplete 50 -Status "Processing..."
    .EXAMPLE
        Update-ProgressBar -PercentComplete 75 -Status "Uploading files..." -Activity "File Transfer"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$PercentComplete,
        
        [Parameter(Mandatory = $false)]
        [string]$Status = "",
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [string]$Activity = "Progress",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPercentage
    )
    
    # Clear the current line and show the updated progress bar
    Clear-CurrentLine
    Show-ProgressBar -PercentComplete $PercentComplete -Width $Width -Activity $Activity -Status $Status -NoPercentage:$NoPercentage -NoNewLine
}

# Export functions
Export-ModuleMember -Function Show-ProgressBar, Start-ProgressTask, Update-ProgressBar
