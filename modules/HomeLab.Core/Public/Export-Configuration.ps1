function Export-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "XML", "YAML")]
        [string]$Format = "JSON",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeTimestamp,
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeKeys = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$AsTemplate
    )
    
    # Generate default path if not specified
    if ([string]::IsNullOrEmpty($Path)) {
        $configDir = Split-Path -Path $Global:Config.ConfigFile -Parent
        $fileName = "config_export"
        
        if ($IncludeTimestamp) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $fileName = "${fileName}_${timestamp}"
        }
        
        $extension = switch ($Format.ToLower()) {
            "json" { ".json" }
            "csv"  { ".csv" }
            "xml"  { ".xml" }
            "yaml" { ".yaml" }
            default { ".json" }
        }
        
        $Path = Join-Path -Path $configDir -ChildPath "${fileName}${extension}"
    }
    
    try {
        # Create a copy of the configuration to modify
        $exportConfig = $Global:Config.Clone()
        
        # Remove excluded keys
        foreach ($key in $ExcludeKeys) {
            if ($exportConfig.ContainsKey($key)) {
                $exportConfig.Remove($key)
            }
        }
        
        # If creating a template, remove environment-specific values
        if ($AsTemplate) {
            $templateExcludeKeys = @('LastSetup', 'LogFile', 'ConfigFile')
            foreach ($key in $templateExcludeKeys) {
                if ($exportConfig.ContainsKey($key)) {
                    $exportConfig.Remove($key)
                }
            }
            
            # Reset environment-specific values to placeholders
            if ($exportConfig.ContainsKey('env')) {
                $exportConfig['env'] = "{{environment}}"
            }
            if ($exportConfig.ContainsKey('project')) {
                $exportConfig['project'] = "{{project_name}}"
            }
        }
        
        # Create directory if it doesn't exist
        $exportDir = Split-Path -Path $Path -Parent
        if (-not (Test-Path -Path $exportDir)) {
            New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
        }
        
        # Export based on format
        switch ($Format.ToLower()) {
            "json" {
                $exportConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Force
            }
            "csv" {
                # Convert hashtable to PSObject for CSV export
                $csvObject = New-Object PSObject
                foreach ($key in $exportConfig.Keys) {
                    # Handle nested objects by converting them to JSON strings
                    if ($exportConfig[$key] -is [System.Collections.IDictionary] -or $exportConfig[$key] -is [Array]) {
                        $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value (ConvertTo-Json -InputObject $exportConfig[$key] -Compress)
                    }
                    else {
                        $csvObject | Add-Member -MemberType NoteProperty -Name $key -Value $exportConfig[$key]
                    }
                }
                $csvObject | Export-Csv -Path $Path -NoTypeInformation -Force
            }
            "xml" {
                # Convert hashtable to PSObject for XML export
                $xmlObject = New-Object PSObject
                foreach ($key in $exportConfig.Keys) {
                    $xmlObject | Add-Member -MemberType NoteProperty -Name $key -Value $exportConfig[$key]
                }
                $xmlObject | Export-Clixml -Path $Path -Force
            }
            "yaml" {
                # Check if PowerShell-YAML module is installed
                if (-not (Get-Module -ListAvailable -Name PowerShell-YAML)) {
                    Write-SafeLog -Message "PowerShell-YAML module not found. Please install it using 'Install-Module -Name PowerShell-YAML'." -Level Error
                    return $false
                }
                
                # Import the module
                Import-Module -Name PowerShell-YAML
                
                # Convert to YAML and export
                $yamlContent = $exportConfig | ConvertTo-Yaml
                Set-Content -Path $Path -Value $yamlContent -Force
            }
        }
        
        Write-SafeLog -Message "Configuration exported to $Path in $Format format." -Level Success
        return $Path
    }
    catch {
        Write-SafeLog -Message "Failed to export configuration: $_" -Level Error
        return $false
    }
}
