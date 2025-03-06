<#
.SYNOPSIS
    Gets the current cost of Azure resources.
.DESCRIPTION
    Gets the current cost of Azure resources for the specified time period.
.PARAMETER TimeGrain
    The time grain for the cost data. Valid values are 'Daily', 'Monthly', 'Yearly'. Default is 'Daily'.
.PARAMETER StartDate
    The start date for the cost data. Default is the first day of the current month.
.PARAMETER EndDate
    The end date for the cost data. Default is the current date.
.EXAMPLE
    Get-CurrentCosts -TimeGrain 'Monthly' -StartDate (Get-Date).AddMonths(-3) -EndDate (Get-Date)
#>
function Get-CurrentCosts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('Daily', 'Monthly', 'Yearly')]
        [string]$TimeGrain = 'Daily',
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartDate = (Get-Date -Day 1),
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndDate = (Get-Date)
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Getting current costs" -Level INFO
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # Format dates for the API
            $startDateStr = $StartDate.ToString("yyyy-MM-dd")
            $endDateStr = $EndDate.ToString("yyyy-MM-dd")
            
            # Get cost data
            $costData = Get-AzConsumptionUsageDetail -StartDate $startDateStr -EndDate $endDateStr
            
            # Process cost data based on time grain
            $groupedCosts = @()
            
            switch ($TimeGrain) {
                'Daily' {
                    $groupedCosts = $costData | Group-Object -Property { $_.UsageStart.Date } | ForEach-Object {
                        [PSCustomObject]@{
                            Date = $_.Name
                            TotalCost = ($_.Group | Measure-Object -Property PretaxCost -Sum).Sum
                            Currency = $_.Group[0].Currency
                            Details = $_.Group | Group-Object -Property InstanceName | ForEach-Object {
                                [PSCustomObject]@{
                                    ResourceName = $_.Name
                                    Cost = ($_.Group | Measure-Object -Property PretaxCost -Sum).Sum
                                }
                            }
                        }
                    }
                }
                'Monthly' {
                    $groupedCosts = $costData | Group-Object -Property { $_.UsageStart.ToString("yyyy-MM") } | ForEach-Object {
                        [PSCustomObject]@{
                            Month = $_.Name
                            TotalCost = ($_.Group | Measure-Object -Property PretaxCost -Sum).Sum
                            Currency = $_.Group[0].Currency
                            Details = $_.Group | Group-Object -Property InstanceName | ForEach-Object {
                                [PSCustomObject]@{
                                    ResourceName = $_.Name
                                    Cost = ($_.Group | Measure-Object -Property PretaxCost -Sum).Sum
                                }
                            }
                        }
                    }
                }
                'Yearly' {
                    $groupedCosts = $costData | Group-Object -Property { $_.UsageStart.Year } | ForEach-Object {
                        [PSCustomObject]@{
                            Year = $_.Name
                            TotalCost = ($_.Group | Measure-Object -Property PretaxCost -Sum).Sum
                            Currency = $_.Group[0].Currency
                            Details = $_.Group | Group-Object -Property InstanceName | ForEach-Object {
                                [PSCustomObject]@{
                                    ResourceName = $_.Name
                                    Cost = ($_.Group | Measure-Object -Property PretaxCost -Sum).Sum
                                }
                            }
                        }
                    }
                }
            }
            
            # Calculate total cost
            $totalCost = ($costData | Measure-Object -Property PretaxCost -Sum).Sum
            $currency = $costData[0].Currency
            
            # Create result object
            $result = [PSCustomObject]@{
                TimeGrain = $TimeGrain
                StartDate = $StartDate
                EndDate = $EndDate
                TotalCost = $totalCost
                Currency = $currency
                CostBreakdown = $groupedCosts
                ResourceCosts = $costData | Group-Object -Property InstanceName | ForEach-Object {
                    [PSCustomObject]@{
                        ResourceName = $_.Name
                        Cost = ($_.Group | Measure-Object -Property PretaxCost -Sum).Sum
                    }
                } | Sort-Object -Property Cost -Descending
            }
            
            return $result
        }
        catch {
            Write-Log -Message "Failed to get current costs: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Current costs retrieved successfully" -Level INFO
    }
}

<#
.SYNOPSIS
    Gets a forecast of future costs.
.DESCRIPTION
    Gets a forecast of future costs based on historical usage.
.PARAMETER Months
    The number of months to forecast. Default is 3.
.EXAMPLE
    Get-CostForecast -Months 6
#>
function Get-CostForecast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Months = 3
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Getting cost forecast" -Level INFO
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # Get historical cost data for the past 3 months
            $endDate = Get-Date
            $startDate = $endDate.AddMonths(-3)
            
            $historicalCosts = Get-CurrentCosts -TimeGrain 'Monthly' -StartDate $startDate -EndDate $endDate
            
            # Calculate average monthly cost
            $averageMonthlyCost = ($historicalCosts.CostBreakdown | Measure-Object -Property TotalCost -Average).Average
            
            # Generate forecast
            $forecastStartDate = $endDate.AddDays(1)
            $forecastEndDate = $forecastStartDate.AddMonths($Months)
            
            $forecastData = @()
            $currentDate = $forecastStartDate
            
            while ($currentDate -le $forecastEndDate) {
                $monthStart = Get-Date -Year $currentDate.Year -Month $currentDate.Month -Day 1
                $monthEnd = $monthStart.AddMonths(1).AddDays(-1)
                
                # Apply some variation to make the forecast more realistic
                $variation = Get-Random -Minimum 0.9 -Maximum 1.1
                $forecastCost = $averageMonthlyCost * $variation
                
                $forecastData += [PSCustomObject]@{
                    Month = $monthStart.ToString("yyyy-MM")
                    StartDate = $monthStart
                    EndDate = $monthEnd
                    ForecastCost = $forecastCost
                    Currency = $historicalCosts.Currency
                }
                
                $currentDate = $currentDate.AddMonths(1)
            }
            
            # Create result object
            $result = [PSCustomObject]@{
                ForecastMonths = $Months
                StartDate = $forecastStartDate
                EndDate = $forecastEndDate
                TotalForecastCost = ($forecastData | Measure-Object -Property ForecastCost -Sum).Sum
                Currency = $historicalCosts.Currency
                MonthlyForecast = $forecastData
                AverageHistoricalCost = $averageMonthlyCost
                HistoricalData = $historicalCosts.CostBreakdown
            }
            
            return $result
        }
        catch {
            Write-Log -Message "Failed to get cost forecast: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Cost forecast generated successfully" -Level INFO
    }
}

<#
.SYNOPSIS
    Exports a cost report to a file.
.DESCRIPTION
    Exports a cost report to a file in the specified format.
.PARAMETER Path
    The path where the report will be saved. If not specified, the report will be saved to the user's Documents folder.
.PARAMETER Format
    The format of the report. Valid values are 'CSV', 'JSON', 'HTML'. Default is 'CSV'.
.PARAMETER TimeGrain
    The time grain for the cost data. Valid values are 'Daily', 'Monthly', 'Yearly'. Default is 'Monthly'.
.PARAMETER StartDate
    The start date for the cost data. Default is the first day of the current month.
.PARAMETER EndDate
    The end date for the cost data. Default is the current date.
.EXAMPLE
    Export-CostReport -Path "C:\Reports" -Format "HTML" -TimeGrain "Monthly" -StartDate (Get-Date).AddMonths(-6) -EndDate (Get-Date)
#>
function Export-CostReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('CSV', 'JSON', 'HTML')]
        [string]$Format = 'CSV',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Daily', 'Monthly', 'Yearly')]
        [string]$TimeGrain = 'Monthly',
        
        [Parameter(Mandatory = $false)]
        [datetime]$StartDate = (Get-Date -Day 1),
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndDate = (Get-Date)
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Exporting cost report" -Level INFO
        
        # Set default path if not specified
        if (-not $Path) {
            $Path = [System.IO.Path]::Combine([Environment]::GetFolderPath('MyDocuments'), 'HomeLab', 'Reports')
        }
        
        # Create directory if it doesn't exist
        if (-not (Test-Path -Path $Path -PathType Container)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
    }
    
    process {
        try {
            # Get cost data
            $costData = Get-CurrentCosts -TimeGrain $TimeGrain -StartDate $StartDate -EndDate $EndDate
            
            # Generate filename
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = "CostReport_${TimeGrain}_${timestamp}"
            
            # Export based on format
            switch ($Format) {
                'CSV' {
                    $filePath = [System.IO.Path]::Combine($Path, "$fileName.csv")
                    
                    # Export cost breakdown
                    $costData.CostBreakdown | Export-Csv -Path $filePath -NoTypeInformation
                    
                    # Export resource costs to a separate file
                    $resourceCostsPath = [System.IO.Path]::Combine($Path, "${fileName}_ResourceCosts.csv")
                    $costData.ResourceCosts | Export-Csv -Path $resourceCostsPath -NoTypeInformation
                }
                'JSON' {
                    $filePath = [System.IO.Path]::Combine($Path, "$fileName.json")
                    $costData | ConvertTo-Json -Depth 5 | Out-File -FilePath $filePath -Encoding utf8
                }
                'HTML' {
                    $filePath = [System.IO.Path]::Combine($Path, "$fileName.html")
                    
                    # Create HTML report
                    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>HomeLab Cost Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0078d4; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .summary { background-color: #e6f2ff; padding: 10px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>HomeLab Cost Report</h1>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Time Period:</strong> $($StartDate.ToString("yyyy-MM-dd")) to $($EndDate.ToString("yyyy-MM-dd"))</p>
        <p><strong>Time Grain:</strong> $TimeGrain</p>
        <p><strong>Total Cost:</strong> $($costData.TotalCost.ToString("F2")) $($costData.Currency)</p>
    </div>
    
    <h2>Cost Breakdown</h2>
    <table>
        <tr>
"@

                    # Add headers based on time grain
                    switch ($TimeGrain) {
                        'Daily' { $html += "<th>Date</th>" }
                        'Monthly' { $html += "<th>Month</th>" }
                        'Yearly' { $html += "<th>Year</th>" }
                    }
                    
                    $html += @"
            <th>Total Cost</th>
            <th>Currency</th>
        </tr>
"@

                    # Add rows for cost breakdown
                    foreach ($item in $costData.CostBreakdown) {
                        $html += "<tr>"
                        
                        switch ($TimeGrain) {
                            'Daily' { $html += "<td>$($item.Date)</td>" }
                            'Monthly' { $html += "<td>$($item.Month)</td>" }
                            'Yearly' { $html += "<td>$($item.Year)</td>" }
                        }
                        
                        $html += @"
            <td>$($item.TotalCost.ToString("F2"))</td>
            <td>$($item.Currency)</td>
        </tr>
"@
                    }
                    
                    $html += @"
    </table>
    
    <h2>Resource Costs</h2>
    <table>
        <tr>
            <th>Resource Name</th>
            <th>Cost</th>
        </tr>
"@

                    # Add rows for resource costs
                    foreach ($item in $costData.ResourceCosts) {
                        $html += @"
        <tr>
            <td>$($item.ResourceName)</td>
            <td>$($item.Cost.ToString("F2")) $($costData.Currency)</td>
        </tr>
"@
                    }
                    
                    $html += @"
    </table>
    
    <p><em>Report generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</em></p>
</body>
</html>
"@
                    
                    # Save HTML to file
                    $html | Out-File -FilePath $filePath -Encoding utf8
                }
            }
            
            Write-Log -Message "Cost report exported to $filePath" -Level INFO
            return $filePath
        }
        catch {
            Write-Log -Message "Failed to export cost report: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Cost report export completed" -Level INFO
    }
}
