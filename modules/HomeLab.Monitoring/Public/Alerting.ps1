<#
.SYNOPSIS
    Sets up an alert rule.
.DESCRIPTION
    Sets up an alert rule for monitoring resources.
.PARAMETER Name
    The name of the alert rule.
.PARAMETER ResourceGroup
    The name of the resource group. If not specified, the resource group from the configuration will be used.
.PARAMETER ResourceType
    The type of resource to monitor.
.PARAMETER ResourceName
    The name of the resource to monitor. If not specified, all resources of the specified type will be monitored.
.PARAMETER Metric
    The metric to monitor.
.PARAMETER Operator
    The operator to use for comparison. Valid values are 'GreaterThan', 'GreaterThanOrEqual', 'LessThan', 'LessThanOrEqual', 'Equal'.
.PARAMETER Threshold
    The threshold value for the alert.
.PARAMETER WindowSize
    The time window for the alert. Default is 5 minutes.
.PARAMETER Frequency
    The frequency of evaluation. Default is 1 minute.
.PARAMETER Severity
    The severity of the alert. Valid values are 0, 1, 2, 3, 4. Default is 2.
.PARAMETER ActionGroupName
    The name of the action group to use for the alert. If not specified, no action group will be used.
.EXAMPLE
    Set-AlertRule -Name "HighCPU" -ResourceType "Microsoft.Compute/virtualMachines" -Metric "Percentage CPU" -Operator "GreaterThan" -Threshold 90
#>
function Set-AlertRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup,
        
        [Parameter(Mandatory = $true)]
        [string]$ResourceType,
        
        [Parameter(Mandatory = $false)]
        [string]$ResourceName,
        
        [Parameter(Mandatory = $true)]
        [string]$Metric,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('GreaterThan', 'GreaterThanOrEqual', 'LessThan', 'LessThanOrEqual', 'Equal')]
        [string]$Operator,
        
        [Parameter(Mandatory = $true)]
        [double]$Threshold,
        
        [Parameter(Mandatory = $false)]
        [string]$WindowSize = "00:05:00",
        
        [Parameter(Mandatory = $false)]
        [string]$Frequency = "00:01:00",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 4)]
        [int]$Severity = 2,
        
        [Parameter(Mandatory = $false)]
        [string]$ActionGroupName
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Setting up alert rule '$Name'" -Level INFO
        
        # If no resource group is specified, use the one from config
        if (-not $ResourceGroup) {
            $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
        }
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # Check if the resource group exists
            $rgExists = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
            if (-not $rgExists) {
                throw "Resource group $ResourceGroup does not exist"
            }
            
            # Get resources based on the specified filters
            $resourceFilter = @{
                ResourceGroupName = $ResourceGroup
                ResourceType = $ResourceType
            }
            
            if ($ResourceName) {
                $resourceFilter.Name = $ResourceName
            }
            
            $resources = Get-AzResource @resourceFilter
            
            if ($resources.Count -eq 0) {
                throw "No resources found matching the specified criteria"
            }
            
            # Create alert rule for each resource or create a single alert rule for all resources
            $createdRules = @()
            
            if ($ResourceName) {
                # Create alert rule for a specific resource
                $resource = $resources[0]
                
                # Create alert criteria
                $criteria = New-AzMetricAlertRuleV2Criteria -MetricName $Metric -TimeAggregation Average -Operator $Operator -Threshold $Threshold
                
                # Create alert rule
                $alertName = "$Name-$($resource.Name)"
                $alertRuleResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/metricAlerts/$alertName"
                
                $actionGroupId = $null
                if ($ActionGroupName) {
                    # Get action group
                    $actionGroup = Get-AzActionGroup -ResourceGroupName $ResourceGroup -Name $ActionGroupName -ErrorAction SilentlyContinue
                    if ($actionGroup) {
                        $actionGroupId = $actionGroup.Id
                    }
                    else {
                        Write-Log -Message "Action group $ActionGroupName not found. Alert will be created without actions." -Level WARNING
                    }
                }
                
                # Create alert rule parameters
                $alertRuleParams = @{
                    Name = $alertName
                    ResourceGroupName = $ResourceGroup
                    WindowSize = $WindowSize
                    Frequency = $Frequency
                    TargetResourceId = $resource.Id
                    Condition = $criteria
                    Severity = $Severity
                    Description = "Alert when $Metric $Operator $Threshold for $($resource.Name)"
                }
                
                if ($actionGroupId) {
                    $alertRuleParams.ActionGroupId = $actionGroupId
                }
                
                # Create the alert rule
                $alertRule = Add-AzMetricAlertRuleV2 @alertRuleParams
                
                $createdRules += $alertRule
                Write-Log -Message "Created alert rule '$alertName' for resource $($resource.Name)" -Level INFO
            }
            else {
                # Create a single alert rule for all resources of the specified type
                # Create alert criteria
                $criteria = New-AzMetricAlertRuleV2Criteria -MetricName $Metric -TimeAggregation Average -Operator $Operator -Threshold $Threshold
                
                # Create alert rule
                $alertName = "$Name-$ResourceType".Replace('/', '-')
                $alertRuleResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$ResourceGroup/providers/Microsoft.Insights/metricAlerts/$alertName"
                
                $actionGroupId = $null
                if ($ActionGroupName) {
                    # Get action group
                    $actionGroup = Get-AzActionGroup -ResourceGroupName $ResourceGroup -Name $ActionGroupName -ErrorAction SilentlyContinue
                    if ($actionGroup) {
                        $actionGroupId = $actionGroup.Id
                    }
                    else {
                        Write-Log -Message "Action group $ActionGroupName not found. Alert will be created without actions." -Level WARNING
                    }
                }
                
                # Create scope array
                $scopes = $resources | ForEach-Object { $_.Id }
                
                # Create alert rule parameters
                $alertRuleParams = @{
                    Name = $alertName
                    ResourceGroupName = $ResourceGroup
                    WindowSize = $WindowSize
                    Frequency = $Frequency
                    TargetResourceScope = $scopes
                    Condition = $criteria
                    Severity = $Severity
                    Description = "Alert when $Metric $Operator $Threshold for all $ResourceType resources"
                }
                
                if ($actionGroupId) {
                    $alertRuleParams.ActionGroupId = $actionGroupId
                }
                
                # Create the alert rule
                $alertRule = Add-AzMetricAlertRuleV2 @alertRuleParams
                
                $createdRules += $alertRule
                Write-Log -Message "Created alert rule '$alertName' for all $ResourceType resources" -Level INFO
            }
            
            # Save alert rule information to config
            if (-not $config.alertRules) {
                $config.alertRules = @{}
            }
            
            foreach ($rule in $createdRules) {
                $config.alertRules[$rule.Name] = @{
                    Id = $rule.Id
                    ResourceGroup = $ResourceGroup
                    ResourceType = $ResourceType
                    Metric = $Metric
                    Operator = $Operator
                    Threshold = $Threshold
                    Severity = $Severity
                    CreatedDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }
            }
            
            Save-Configuration
            
            return $createdRules
        }
        catch {
            Write-Log -Message "Failed to set up alert rule: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Alert rule setup completed" -Level INFO
    }
}

<#
.SYNOPSIS
    Gets the current alert rules.
.DESCRIPTION
    Gets the current alert rules for the specified resource group.
.PARAMETER ResourceGroup
    The name of the resource group. If not specified, the resource group from the configuration will be used.
.EXAMPLE
    Get-AlertRules -ResourceGroup "HomeLab-RG"
#>
function Get-AlertRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Getting alert rules" -Level INFO
        
        # If no resource group is specified, use the one from config
        if (-not $ResourceGroup) {
            $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
        }
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # Check if the resource group exists
            $rgExists = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
            if (-not $rgExists) {
                throw "Resource group $ResourceGroup does not exist"
            }
            
            # Get alert rules from Azure
            $alertRules = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroup
            
            # Enrich with information from config
            $enrichedRules = @()
            
            foreach ($rule in $alertRules) {
                $enrichedRule = [PSCustomObject]@{
                    Name = $rule.Name
                    Id = $rule.Id
                    Description = $rule.Description
                    Severity = $rule.Severity
                    Enabled = $rule.Enabled
                    Frequency = $rule.EvaluationFrequency
                    WindowSize = $rule.WindowSize
                    TargetResourceType = $null
                    TargetResourceIds = $rule.Scopes
                    Criteria = $rule.Criteria
                    ActionGroups = $rule.Actions.ActionGroupId
                    ConfigInfo = $null
                }
                
                # Add info from config if available
                if ($config.alertRules -and $config.alertRules[$rule.Name]) {
                    $enrichedRule.ConfigInfo = $config.alertRules[$rule.Name]
                }
                
                # Try to determine target resource type
                if ($rule.Scopes -and $rule.Scopes.Count -gt 0) {
                    $resourceId = $rule.Scopes[0]
                    $resourceTypePattern = '/providers/([^/]+/[^/]+)/'
                    if ($resourceId -match $resourceTypePattern) {
                        $enrichedRule.TargetResourceType = $matches[1]
                    }
                }
                
                $enrichedRules += $enrichedRule
            }
            
            return $enrichedRules
        }
        catch {
            Write-Log -Message "Failed to get alert rules: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Alert rules retrieved successfully" -Level INFO
    }
}

<#
.SYNOPSIS
    Removes an alert rule.
.DESCRIPTION
    Removes an alert rule with the specified name.
.PARAMETER Name
    The name of the alert rule to remove.
.PARAMETER ResourceGroup
    The name of the resource group. If not specified, the resource group from the configuration will be used.
.EXAMPLE
    Remove-AlertRule -Name "HighCPU-vm1"
#>
function Remove-AlertRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Removing alert rule '$Name'" -Level INFO
        
        # If no resource group is specified, use the one from config
        if (-not $ResourceGroup) {
            $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
        }
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # Check if the resource group exists
            $rgExists = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
            if (-not $rgExists) {
                throw "Resource group $ResourceGroup does not exist"
            }
            
            # Check if the alert rule exists
            $alertRule = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroup -Name $Name -ErrorAction SilentlyContinue
            
            if (-not $alertRule) {
                throw "Alert rule '$Name' not found in resource group '$ResourceGroup'"
            }
            
            # Remove the alert rule
            Remove-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroup -Name $Name
            
            # Remove from config
            if ($config.alertRules -and $config.alertRules[$Name]) {
                $config.alertRules.Remove($Name)
                Save-Configuration
            }
            
            Write-Log -Message "Alert rule '$Name' removed successfully" -Level INFO
            return $true
        }
        catch {
            Write-Log -Message "Failed to remove alert rule: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Alert rule removal completed" -Level INFO
    }
}

<#
.SYNOPSIS
    Tests an alert rule.
.DESCRIPTION
    Tests an alert rule by simulating a condition that would trigger the alert.
.PARAMETER Name
    The name of the alert rule to test.
.PARAMETER ResourceGroup
    The name of the resource group. If not specified, the resource group from the configuration will be used.
.EXAMPLE
    Test-AlertRule -Name "HighCPU-vm1"
#>
function Test-AlertRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$ResourceGroup
    )
    
    begin {
        # Import required modules
        Import-Module HomeLab.Core
        Import-Module HomeLab.Azure
        
        # Get configuration
        $config = Get-Configuration
        
        # Log function start
        Write-Log -Message "Testing alert rule '$Name'" -Level INFO
        
        # If no resource group is specified, use the one from config
        if (-not $ResourceGroup) {
            $ResourceGroup = "$($config.projectName)-$($config.env)-$($config.locationCode)-rg"
        }
    }
    
    process {
        try {
            # Check if Azure is connected
            if (-not (Test-AzureConnection)) {
                Connect-AzureAccount
            }
            
            # Check if the resource group exists
            $rgExists = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
            if (-not $rgExists) {
                throw "Resource group $ResourceGroup does not exist"
            }
            
            # Check if the alert rule exists
            $alertRule = Get-AzMetricAlertRuleV2 -ResourceGroupName $ResourceGroup -Name $Name -ErrorAction SilentlyContinue
            
            if (-not $alertRule) {
                throw "Alert rule '$Name' not found in resource group '$ResourceGroup'"
            }
            
            # Get alert rule details
            $alertDetails = [PSCustomObject]@{
                Name = $alertRule.Name
                Description = $alertRule.Description
                Severity = $alertRule.Severity
                Enabled = $alertRule.Enabled
                Frequency = $alertRule.EvaluationFrequency
                WindowSize = $alertRule.WindowSize
                TargetResourceIds = $alertRule.Scopes
                Criteria = $alertRule.Criteria
                ActionGroups = $alertRule.Actions.ActionGroupId
                TestResult = "Cannot test alert rule directly. Please check the following information to verify the alert rule is configured correctly."
                Recommendations = @()
            }
            
            # Check if the alert rule is enabled
            if (-not $alertRule.Enabled) {
                $alertDetails.Recommendations += "Alert rule is disabled. Enable it to receive alerts."
            }
            
            # Check if the alert rule has action groups
            if (-not $alertRule.Actions -or $alertRule.Actions.Count -eq 0) {
                $alertDetails.Recommendations += "No action groups configured. Add an action group to receive notifications."
            }
            
            # Check if the target resources exist
            foreach ($scope in $alertRule.Scopes) {
                $resource = Get-AzResource -ResourceId $scope -ErrorAction SilentlyContinue
                if (-not $resource) {
                    $alertDetails.Recommendations += "Target resource with ID '$scope' does not exist."
                }
            }
            
            # Check if the metric exists for the target resources
            if ($alertRule.Criteria.GetType().Name -eq "MetricAlertRuleV2Criteria") {
                $metricName = $alertRule.Criteria.MetricName
                
                foreach ($scope in $alertRule.Scopes) {
                    $metricDefinitions = Get-AzMetricDefinition -ResourceId $scope -ErrorAction SilentlyContinue
                    $metricExists = $metricDefinitions | Where-Object { $_.Name.Value -eq $metricName }
                    
                    if (-not $metricExists) {
                        $alertDetails.Recommendations += "Metric '$metricName' does not exist for resource with ID '$scope'."
                    }
                }
            }
            
            # Add information from config if available
            if ($config.alertRules -and $config.alertRules[$Name]) {
                $alertDetails | Add-Member -MemberType NoteProperty -Name "ConfigInfo" -Value $config.alertRules[$Name]
            }
            
            return $alertDetails
        }
        catch {
            Write-Log -Message "Failed to test alert rule: $_" -Level ERROR
            throw $_
        }
    }
    
    end {
        # Log function end
        Write-Log -Message "Alert rule test completed" -Level INFO
    }
}
