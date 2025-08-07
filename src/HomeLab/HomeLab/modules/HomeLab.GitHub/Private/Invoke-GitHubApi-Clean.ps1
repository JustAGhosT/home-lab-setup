function Invoke-GitHubApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'GET',
        
        [Parameter(Mandatory = $false)]
        [object]$Body,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{}
    )
    
    try {
        # Get the stored GitHub token
        $token = Get-GitHubToken
        if (-not $token) {
            throw "GitHub authentication required. Please run Connect-GitHub first."
        }
        
        # Prepare the request URI
        $uri = if ($Endpoint.StartsWith('http')) {
            $Endpoint
        } else {
            "$script:GitHubApiBaseUrl$Endpoint"
        }
        
        # Prepare headers
        $requestHeaders = @{
            'Authorization' = "Bearer $token"
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'HomeLab-PowerShell/1.0'
        }
        
        # Add any additional headers
        foreach ($key in $Headers.Keys) {
            $requestHeaders[$key] = $Headers[$key]
        }
        
        # Prepare the request parameters
        $requestParams = @{
            Uri = $uri
            Method = $Method
            Headers = $requestHeaders
            ContentType = 'application/json'
        }
        
        # Add body if provided
        if ($Body) {
            if ($Body -is [string]) {
                $requestParams.Body = $Body
            } else {
                $requestParams.Body = $Body | ConvertTo-Json -Depth 10
            }
        }
        
        Write-Verbose "Making GitHub API call: $Method $uri"
        
        # Make the API call
        $response = Invoke-RestMethod @requestParams
        
        Write-Verbose "GitHub API call successful"
        return $response
    }
    catch {
        $errorMessage = "GitHub API call failed: $($_.Exception.Message)"
        Write-Error $errorMessage
        throw
    }
}

function Get-GitHubToken {
    [CmdletBinding()]
    param()
    
    try {
        # For simplicity, use environment variable for now
        $token = $env:GITHUB_TOKEN
        if ($token) {
            return $token
        }
        
        return $null
    }
    catch {
        Write-Verbose "Failed to retrieve GitHub token: $($_.Exception.Message)"
        return $null
    }
}

function Set-GitHubToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token
    )
    
    try {
        # For simplicity, use environment variable for now
        $env:GITHUB_TOKEN = $Token
        Write-Verbose "GitHub token set in environment variable"
    }
    catch {
        Write-Error "Failed to store GitHub token: $($_.Exception.Message)"
        throw
    }
}

function Remove-GitHubToken {
    [CmdletBinding()]
    param()
    
    try {
        # Remove from environment variable
        Remove-Item -Path "env:GITHUB_TOKEN" -ErrorAction SilentlyContinue
        Write-Verbose "GitHub token removed from environment variable"
    }
    catch {
        Write-Verbose "Failed to remove GitHub token: $($_.Exception.Message)"
    }
}
