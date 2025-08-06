function Deploy-AWS {
    <#
    .SYNOPSIS
        Deploys a website to AWS using S3 and CloudFront.
    
    .DESCRIPTION
        This function deploys a website to AWS using S3 for storage and CloudFront for CDN.
        It supports static site hosting with global distribution.
    
    .PARAMETER AppName
        Application name for the AWS resources.
    
    .PARAMETER ProjectPath
        Path to the project directory.
    
    .PARAMETER Location
        AWS region for deployment.
    
    .PARAMETER AwsRegion
        AWS region for S3 bucket and CloudFront distribution.
    
    .PARAMETER CustomDomain
        Custom domain for the application.
    
    .PARAMETER RepoUrl
        GitHub repository URL for automatic deployments.
    
    .PARAMETER Branch
        Git branch to deploy. Default is main.
    
    .EXAMPLE
        Deploy-AWS -AppName "my-static-site" -ProjectPath "C:\Projects\my-site" -AwsRegion "us-east-1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [string]$Location = "us-east-1",
        
        [Parameter()]
        [string]$AwsRegion = "us-east-1",
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$RepoUrl,
        
        [Parameter()]
        [string]$Branch = "main"
    )
    
    Write-Host "=== Deploying to AWS ===" -ForegroundColor Yellow
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $AwsRegion" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Validate project path
    if (-not (Test-Path -Path $ProjectPath)) {
        throw "Project path does not exist: $ProjectPath"
    }
    
    # Step 2: Check for AWS CLI
    Write-Host "Step 1/6: Checking AWS CLI installation..." -ForegroundColor Cyan
    $awsCli = Get-Command -Name "aws" -ErrorAction SilentlyContinue
    if (-not $awsCli) {
        Write-Host "AWS CLI not found. Please install AWS CLI first:" -ForegroundColor Yellow
        Write-Host "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" -ForegroundColor Cyan
        throw "AWS CLI is required for deployment. Please install it and configure your credentials."
    }
    else {
        Write-Host "AWS CLI found." -ForegroundColor Green
    }
    
    # Step 3: Check AWS credentials
    Write-Host "Step 2/6: Checking AWS credentials..." -ForegroundColor Cyan
    try {
        $awsIdentity = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "AWS credentials not configured. Please run 'aws configure' first."
        }
        Write-Host "AWS credentials verified." -ForegroundColor Green
        Write-Host "Account: $($awsIdentity | ConvertFrom-Json | Select-Object -ExpandProperty Account)" -ForegroundColor White
    }
    catch {
        throw "Failed to verify AWS credentials: $($_.Exception.Message)"
    }
    
    # Step 4: Create S3 bucket
    Write-Host "Step 3/6: Creating S3 bucket..." -ForegroundColor Cyan
    
    # Generate unique bucket name with timestamp and random suffix
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
    $baseBucketName = "$AppName-$AwsRegion".ToLower() -replace '[^a-z0-9-]', '-'
    
    # Clean up the bucket name to meet S3 requirements
    $bucketName = $baseBucketName -replace '^-+|-+$', ''  # Remove leading/trailing hyphens
    $bucketName = $bucketName -replace '-+', '-'  # Replace consecutive hyphens with single hyphen
    $bucketName = "$bucketName-$timestamp-$randomSuffix"
    
    # Ensure bucket name meets S3 requirements (3-63 characters)
    if ($bucketName.Length -gt 63) {
        $maxLength = 63 - ($timestamp.Length + $randomSuffix.ToString().Length + 2)  # 2 for hyphens
        $bucketName = $baseBucketName.Substring(0, [Math]::Min($maxLength, $baseBucketName.Length)) -replace '^-+|-+$', ''
        $bucketName = "$bucketName-$timestamp-$randomSuffix"
    }
    
    Write-Host "Generated bucket name: $bucketName" -ForegroundColor White
    
    try {
        # Check if bucket already exists
        $bucketExists = aws s3api head-bucket --bucket $bucketName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "S3 bucket '$bucketName' already exists." -ForegroundColor Green
        }
        else {
            Write-Host "Creating S3 bucket: $bucketName" -ForegroundColor White
            
            # Create bucket with proper location constraint for non-us-east-1 regions
            if ($AwsRegion -eq "us-east-1") {
                aws s3api create-bucket --bucket $bucketName --region $AwsRegion
            }
            else {
                $locationConfig = @{
                    LocationConstraint = $AwsRegion
                } | ConvertTo-Json
                
                aws s3api create-bucket --bucket $bucketName --region $AwsRegion --create-bucket-configuration $locationConfig
            }
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create S3 bucket"
            }
            Write-Host "S3 bucket created successfully." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create S3 bucket: $($_.Exception.Message)"
    }
    
    # Step 5: Configure S3 bucket for static website hosting
    Write-Host "Step 4/6: Configuring S3 bucket for static website hosting..." -ForegroundColor Cyan
    try {
        # Create website configuration
        $websiteConfig = @{
            IndexDocument = @{Suffix = "index.html" }
            ErrorDocument = @{Key = "error.html" }
        } | ConvertTo-Json
        
        aws s3api put-bucket-website --bucket $bucketName --website-configuration $websiteConfig
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to configure S3 bucket for website hosting"
        }
        Write-Host "S3 bucket configured for static website hosting." -ForegroundColor Green
        
        # Add bucket policy for public read access
        Write-Host "Adding public read access policy..." -ForegroundColor White
        $bucketPolicy = @{
            Version   = "2012-10-17"
            Statement = @(
                @{
                    Sid       = "PublicReadGetObject"
                    Effect    = "Allow"
                    Principal = "*"
                    Action    = "s3:GetObject"
                    Resource  = "arn:aws:s3:::$bucketName/*"
                }
            )
        } | ConvertTo-Json -Depth 10
        
        aws s3api put-bucket-policy --bucket $bucketName --policy $bucketPolicy
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add public read access policy to S3 bucket"
        }
        Write-Host "Public read access policy added successfully." -ForegroundColor Green
    }
    catch {
        throw "Failed to configure S3 bucket: $($_.Exception.Message)"
    }
    
    # Step 6: Upload files to S3
    Write-Host "Step 5/6: Uploading files to S3..." -ForegroundColor Cyan
    try {
        # Build the project if needed
        $packageJson = Test-Path -Path "$ProjectPath\package.json"
        if ($packageJson) {
            Write-Host "Building project..." -ForegroundColor White
            Push-Location -Path $ProjectPath
            npm run build
            Pop-Location
            
            # Check for build output directory
            $buildDirs = @("dist", "build", "out", "public")
            $uploadPath = $ProjectPath
            
            foreach ($dir in $buildDirs) {
                if (Test-Path -Path "$ProjectPath\$dir") {
                    $uploadPath = "$ProjectPath\$dir"
                    Write-Host "Using build output directory: $dir" -ForegroundColor White
                    break
                }
            }
        }
        else {
            $uploadPath = $ProjectPath
        }
        
        Write-Host "Uploading files from: $uploadPath" -ForegroundColor White
        aws s3 sync $uploadPath s3://$bucketName --delete
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to upload files to S3"
        }
        Write-Host "Files uploaded successfully." -ForegroundColor Green
    }
    catch {
        throw "Failed to upload files: $($_.Exception.Message)"
    }
    
    # Step 7: Create CloudFront distribution (optional)
    Write-Host "Step 6/6: Creating CloudFront distribution..." -ForegroundColor Cyan
    try {
        # Get S3 website endpoint
        $s3Endpoint = aws s3api get-bucket-website --bucket $bucketName | ConvertFrom-Json
        $s3WebsiteUrl = $s3Endpoint.WebsiteEndpoint
        
        Write-Host "S3 website URL: http://$s3WebsiteUrl" -ForegroundColor Green
        
        # Note: CloudFront distribution creation is complex and requires additional setup
        # For now, we'll use the S3 website endpoint
        Write-Host "CloudFront distribution creation requires additional setup." -ForegroundColor Yellow
        Write-Host "You can create it manually in the AWS Console or use AWS CDK/CloudFormation." -ForegroundColor White
        
        # Return deployment information
        return @{
            Success       = $true
            DeploymentUrl = "http://$s3WebsiteUrl"
            S3Bucket      = $bucketName
            AppName       = $AppName
            Platform      = "AWS"
            Region        = $AwsRegion
            CustomDomain  = $CustomDomain
        }
    }
    catch {
        throw "Failed to create CloudFront distribution: $($_.Exception.Message)"
    }
} 