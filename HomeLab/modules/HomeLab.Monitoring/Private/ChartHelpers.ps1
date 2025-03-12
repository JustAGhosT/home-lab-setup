<#
.SYNOPSIS
    Creates a cost chart for the specified time period.
.DESCRIPTION
    Creates a cost chart for the specified time period using the specified time grain.
.PARAMETER CostData
    The cost data to create the chart from.
.PARAMETER TimeGrain
    The time grain for the chart. Valid values are 'Daily', 'Monthly', 'Yearly'. Default is 'Daily'.
.PARAMETER OutputPath
    The path where the chart will be saved. If not specified, a temporary file will be created.
.EXAMPLE
    New-CostChart -CostData $costData -TimeGrain 'Monthly' -OutputPath "C:\Reports\CostChart.png"
#>
function New-CostChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$CostData,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Daily', 'Monthly', 'Yearly')]
        [string]$TimeGrain = 'Daily',
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # If no output path is specified, create a temporary file
    if (-not $OutputPath) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $OutputPath = Join-Path -Path $tempDir -ChildPath "CostChart_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
    }
    
    # Prepare data for chart
    $chartData = @()
    
    switch ($TimeGrain) {
        'Daily' {
            foreach ($item in $CostData.CostBreakdown) {
                $chartData += [PSCustomObject]@{
                    Date = [datetime]$item.Date
                    Cost = $item.TotalCost
                }
            }
            
            # Sort by date
            $chartData = $chartData | Sort-Object -Property Date
            
            # Create chart
            $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
            $chart.Width = 800
            $chart.Height = 600
            
            $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
            $chart.ChartAreas.Add($chartArea)
            
            $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
            $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
            $series.Name = "Daily Cost"
            
            foreach ($item in $chartData) {
                $series.Points.AddXY($item.Date.ToString("yyyy-MM-dd"), $item.Cost)
            }
            
            $chart.Series.Add($series)
            
            # Set chart title
            $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
            $title.Text = "Daily Cost ($($CostData.Currency))"
            $chart.Titles.Add($title)
            
            # Set axis labels
            $chartArea.AxisX.Title = "Date"
            $chartArea.AxisY.Title = "Cost ($($CostData.Currency))"
            
            # Set axis formats
            $chartArea.AxisX.LabelStyle.Format = "yyyy-MM-dd"
            $chartArea.AxisY.LabelStyle.Format = "N2"
            
            # Save chart
            $chart.SaveImage($OutputPath, [System.Windows.Forms.DataVisualization.Charting.ChartImageFormat]::Png)
        }
        'Monthly' {
            foreach ($item in $CostData.CostBreakdown) {
                $chartData += [PSCustomObject]@{
                    Month = $item.Month
                    Cost = $item.TotalCost
                }
            }
            
            # Sort by month
            $chartData = $chartData | Sort-Object -Property Month
            
            # Create chart
            $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
            $chart.Width = 800
            $chart.Height = 600
            
            $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
            $chart.ChartAreas.Add($chartArea)
            
            $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
            $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
            $series.Name = "Monthly Cost"
            
            foreach ($item in $chartData) {
                $series.Points.AddXY($item.Month, $item.Cost)
            }
            
            $chart.Series.Add($series)
            
            # Set chart title
            $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
            $title.Text = "Monthly Cost ($($CostData.Currency))"
            $chart.Titles.Add($title)
            
            # Set axis labels
            $chartArea.AxisX.Title = "Month"
            $chartArea.AxisY.Title = "Cost ($($CostData.Currency))"
            
            # Set axis formats
            $chartArea.AxisY.LabelStyle.Format = "N2"
            
            # Save chart
            $chart.SaveImage($OutputPath, [System.Windows.Forms.DataVisualization.Charting.ChartImageFormat]::Png)
        }
        'Yearly' {
            foreach ($item in $CostData.CostBreakdown) {
                $chartData += [PSCustomObject]@{
                    Year = $item.Year
                    Cost = $item.TotalCost
                }
            }
            
            # Sort by year
            $chartData = $chartData | Sort-Object -Property Year
            
            # Create chart
            $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
            $chart.Width = 800
            $chart.Height = 600
            
            $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
            $chart.ChartAreas.Add($chartArea)
            
            $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
            $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
            $series.Name = "Yearly Cost"
            
            foreach ($item in $chartData) {
                $series.Points.AddXY($item.Year, $item.Cost)
            }
            
            $chart.Series.Add($series)
            
            # Set chart title
            $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
            $title.Text = "Yearly Cost ($($CostData.Currency))"
            $chart.Titles.Add($title)
            
            # Set axis labels
            $chartArea.AxisX.Title = "Year"
            $chartArea.AxisY.Title = "Cost ($($CostData.Currency))"
            
            # Set axis formats
            $chartArea.AxisY.LabelStyle.Format = "N2"
            
            # Save chart
            $chart.SaveImage($OutputPath, [System.Windows.Forms.DataVisualization.Charting.ChartImageFormat]::Png)
        }
    }
    
    return $OutputPath
}

<#
.SYNOPSIS
    Creates a resource metrics chart.
.DESCRIPTION
    Creates a chart for resource metrics.
.PARAMETER MetricsData
    The metrics data to create the chart from.
.PARAMETER ResourceName
    The name of the resource.
.PARAMETER MetricName
    The name of the metric.
.PARAMETER OutputPath
    The path where the chart will be saved. If not specified, a temporary file will be created.
.EXAMPLE
    New-ResourceMetricsChart -MetricsData $metricsData -ResourceName "vm1" -MetricName "Percentage CPU" -OutputPath "C:\Reports\CPUChart.png"
#>
function New-ResourceMetricsChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$MetricsData,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceName,
        
        [Parameter(Mandatory = $true)]
        [string]$MetricName,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # If no output path is specified, create a temporary file
    if (-not $OutputPath) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $OutputPath = Join-Path -Path $tempDir -ChildPath "MetricsChart_${ResourceName}_${MetricName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
    }
    
    # Find the resource in the metrics data
    $resourceMetrics = $MetricsData | Where-Object { $_.ResourceName -eq $ResourceName }
    
    if (-not $resourceMetrics) {
        throw "Resource '$ResourceName' not found in metrics data"
    }
    
    # Find the metric in the resource metrics
    $metric = $resourceMetrics.Metrics[$MetricName]
    
    if (-not $metric) {
        throw "Metric '$MetricName' not found for resource '$ResourceName'"
    }
    
    # Prepare data for chart
    $chartData = @()
    
    foreach ($dataPoint in $metric.Data) {
        $chartData += [PSCustomObject]@{
            TimeStamp = $dataPoint.TimeStamp
            Average = $dataPoint.Average
            Minimum = $dataPoint.Minimum
            Maximum = $dataPoint.Maximum
        }
    }
    
    # Sort by timestamp
    $chartData = $chartData | Sort-Object -Property TimeStamp
    
    # Create chart
    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Width = 800
    $chart.Height = 600
    
    $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $chart.ChartAreas.Add($chartArea)
    
    # Add average series
    $avgSeries = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $avgSeries.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $avgSeries.Name = "Average"
    $avgSeries.Color = [System.Drawing.Color]::Blue
    
    foreach ($item in $chartData) {
        $avgSeries.Points.AddXY($item.TimeStamp, $item.Average)
    }
    
    $chart.Series.Add($avgSeries)
    
    # Add minimum series
    $minSeries = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $minSeries.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $minSeries.Name = "Minimum"
    $minSeries.Color = [System.Drawing.Color]::Green
    
    foreach ($item in $chartData) {
        $minSeries.Points.AddXY($item.TimeStamp, $item.Minimum)
    }
    
    $chart.Series.Add($minSeries)
    
    # Add maximum series
    $maxSeries = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $maxSeries.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
    $maxSeries.Name = "Maximum"
    $maxSeries.Color = [System.Drawing.Color]::Red
    
    foreach ($item in $chartData) {
        $maxSeries.Points.AddXY($item.TimeStamp, $item.Maximum)
    }
    
    $chart.Series.Add($maxSeries)
    
    # Set chart title
    $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $title.Text = "$MetricName for $ResourceName"
    $chart.Titles.Add($title)
    
    # Set axis labels
    $chartArea.AxisX.Title = "Time"
    $chartArea.AxisY.Title = "$MetricName ($($metric.Unit))"
    
    # Set axis formats
    $chartArea.AxisX.LabelStyle.Format = "yyyy-MM-dd HH:mm"
    
    # Add legend
    $legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
    $legend.Name = "Legend"
    $chart.Legends.Add($legend)
    
    # Save chart
    $chart.SaveImage($OutputPath, [System.Windows.Forms.DataVisualization.Charting.ChartImageFormat]::Png)
    
    return $OutputPath
}

<#
.SYNOPSIS
    Creates a health status chart.
.DESCRIPTION
    Creates a pie chart showing the health status of resources.
.PARAMETER HealthData
    The health data to create the chart from.
.PARAMETER OutputPath
    The path where the chart will be saved. If not specified, a temporary file will be created.
.EXAMPLE
    New-HealthStatusChart -HealthData $healthData -OutputPath "C:\Reports\HealthChart.png"
#>
function New-HealthStatusChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$HealthData,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # If no output path is specified, create a temporary file
    if (-not $OutputPath) {
        $tempDir = [System.IO.Path]::GetTempPath()
        $OutputPath = Join-Path -Path $tempDir -ChildPath "HealthChart_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"
    }
    
    # Count resources by health status
    $healthyCounts = @{
        "Healthy" = 0
        "Warning" = 0
        "Unhealthy" = 0
        "Unknown" = 0
        "Error" = 0
    }
    
    foreach ($check in $HealthData.Checks) {
        if ($check.Name -eq "Resource Health" -and $check.Resources) {
            foreach ($resource in $check.Resources) {
                $status = $resource.HealthStatus
                if ($healthyCounts.ContainsKey($status)) {
                    $healthyCounts[$status]++
                }
                else {
                    $healthyCounts["Unknown"]++
                }
            }
        }
    }
    
    # Create chart
    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Width = 800
    $chart.Height = 600
    
    $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $chart.ChartAreas.Add($chartArea)
    
    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
    $series.Name = "Health Status"
    
    # Add data points
    $series.Points.AddXY("Healthy", $healthyCounts["Healthy"])
    $series.Points[0].Color = [System.Drawing.Color]::Green
    
    $series.Points.AddXY("Warning", $healthyCounts["Warning"])
    $series.Points[1].Color = [System.Drawing.Color]::Yellow
    
    $series.Points.AddXY("Unhealthy", $healthyCounts["Unhealthy"])
    $series.Points[2].Color = [System.Drawing.Color]::Red
    
    $series.Points.AddXY("Unknown", $healthyCounts["Unknown"])
    $series.Points[3].Color = [System.Drawing.Color]::Gray
    
    $series.Points.AddXY("Error", $healthyCounts["Error"])
    $series.Points[4].Color = [System.Drawing.Color]::DarkRed
    
    # Set data point labels
    $series.IsValueShownAsLabel = $true
    $series.LabelFormat = "#"
    
    $chart.Series.Add($series)
    
    # Set chart title
    $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $title.Text = "Resource Health Status"
    $chart.Titles.Add($title)
    
    # Add legend
    $legend = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
    $legend.Name = "Legend"
    $chart.Legends.Add($legend)
    
    # Save chart
    $chart.SaveImage($OutputPath, [System.Windows.Forms.DataVisualization.Charting.ChartImageFormat]::Png)
    
    return $OutputPath
}
