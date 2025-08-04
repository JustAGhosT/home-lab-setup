function Deploy-AWSECS {
    <#
    .SYNOPSIS
        Deploys applications to AWS ECS (Elastic Container Service) with Fargate.
    
    .DESCRIPTION
        This function deploys containerized applications to AWS ECS using Fargate, which provides
        serverless container orchestration with automatic scaling, load balancing, and service discovery.
    
    .PARAMETER AppName
        Application name for the ECS service.
    
    .PARAMETER ProjectPath
        Path to the project directory containing Dockerfile.
    
    .PARAMETER AwsRegion
        AWS region for deployment.
    
    .PARAMETER ClusterName
        ECS cluster name (will create if not exists).
    
    .PARAMETER TaskDefinitionName
        ECS task definition name.
    
    .PARAMETER ServiceName
        ECS service name.
    
    .PARAMETER ImageName
        Container image name.
    
    .PARAMETER ImageTag
        Container image tag (default: latest).
    
    .PARAMETER EcrRepositoryName
        ECR repository name (will create if not exists).
    
    .PARAMETER Cpu
        CPU units (256, 512, 1024, 2048, 4096).
    
    .PARAMETER Memory
        Memory in MiB (512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192).
    
    .PARAMETER Port
        Container port (default: 80).
    
    .PARAMETER DesiredCount
        Desired number of tasks (default: 1).
    
    .PARAMETER MinCount
        Minimum number of tasks for auto-scaling.
    
    .PARAMETER MaxCount
        Maximum number of tasks for auto-scaling.
    
    .PARAMETER LoadBalancerName
        Application Load Balancer name (will create if not exists).
    
    .PARAMETER TargetGroupName
        Target group name.
    
    .PARAMETER VpcId
        VPC ID (will create if not provided).
    
    .PARAMETER SubnetIds
        Subnet IDs for the service (will create if not provided).
    
    .PARAMETER SecurityGroupIds
        Security group IDs (will create if not provided).
    
    .PARAMETER EnvironmentVariables
        Hashtable of environment variables.
    
    .PARAMETER Secrets
        Hashtable of secrets (will be stored in AWS Secrets Manager).
    
    .PARAMETER BuildImage
        Build container image locally before deployment.
    
    .PARAMETER PushImage
        Push image to ECR.
    
    .PARAMETER EnableAutoScaling
        Enable auto-scaling for the service.
    
    .PARAMETER EnableServiceDiscovery
        Enable AWS Cloud Map service discovery.
    
    .PARAMETER CustomDomain
        Custom domain for the application.
    
    .PARAMETER CertificateArn
        SSL certificate ARN for HTTPS.
    
    .PARAMETER HealthCheckPath
        Health check path (default: /).
    
    .PARAMETER HealthCheckInterval
        Health check interval in seconds (default: 30).
    
    .PARAMETER HealthCheckTimeout
        Health check timeout in seconds (default: 5).
    
    .PARAMETER HealthCheckHealthyThreshold
        Healthy threshold count (default: 2).
    
    .PARAMETER HealthCheckUnhealthyThreshold
        Unhealthy threshold count (default: 2).
    
    .EXAMPLE
        Deploy-AWSECS -AppName "my-api" -ProjectPath "C:\Projects\my-api" -AwsRegion "us-east-1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter(Mandatory = $true)]
        [string]$AwsRegion,
        
        [Parameter()]
        [string]$ClusterName,
        
        [Parameter()]
        [string]$TaskDefinitionName,
        
        [Parameter()]
        [string]$ServiceName,
        
        [Parameter()]
        [string]$ImageName,
        
        [Parameter()]
        [string]$ImageTag = "latest",
        
        [Parameter()]
        [string]$EcrRepositoryName,
        
        [Parameter()]
        [ValidateSet("256", "512", "1024", "2048", "4096")]
        [string]$Cpu = "1024",
        
        [Parameter()]
        [ValidateSet("512", "1024", "2048", "3072", "4096", "5120", "6144", "7168", "8192")]
        [string]$Memory = "2048",
        
        [Parameter()]
        [int]$Port = 80,
        
        [Parameter()]
        [int]$DesiredCount = 1,
        
        [Parameter()]
        [int]$MinCount = 1,
        
        [Parameter()]
        [int]$MaxCount = 10,
        
        [Parameter()]
        [string]$LoadBalancerName,
        
        [Parameter()]
        [string]$TargetGroupName,
        
        [Parameter()]
        [string]$VpcId,
        
        [Parameter()]
        [string[]]$SubnetIds,
        
        [Parameter()]
        [string[]]$SecurityGroupIds,
        
        [Parameter()]
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter()]
        [hashtable]$Secrets = @{},
        
        [Parameter()]
        [switch]$BuildImage,
        
        [Parameter()]
        [switch]$PushImage,
        
        [Parameter()]
        [switch]$EnableAutoScaling,
        
        [Parameter()]
        [switch]$EnableServiceDiscovery,
        
        [Parameter()]
        [string]$CustomDomain,
        
        [Parameter()]
        [string]$CertificateArn,
        
        [Parameter()]
        [string]$HealthCheckPath = "/",
        
        [Parameter()]
        [int]$HealthCheckInterval = 30,
        
        [Parameter()]
        [int]$HealthCheckTimeout = 5,
        
        [Parameter()]
        [int]$HealthCheckHealthyThreshold = 2,
        
        [Parameter()]
        [int]$HealthCheckUnhealthyThreshold = 2
    )
    
    Write-Host "=== Deploying to AWS ECS Fargate ===" -ForegroundColor Cyan
    Write-Host "Project: $AppName" -ForegroundColor White
    Write-Host "Path: $ProjectPath" -ForegroundColor White
    Write-Host "Region: $AwsRegion" -ForegroundColor White
    Write-Host "CPU: $Cpu" -ForegroundColor White
    Write-Host "Memory: $Memory MiB" -ForegroundColor White
    Write-Host "Port: $Port" -ForegroundColor White
    Write-Host ""
    
    # Step 1: Check AWS CLI prerequisites
    Write-Host "Step 1/10: Checking AWS CLI prerequisites..." -ForegroundColor Cyan
    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI found: $awsVersion" -ForegroundColor Green
    }
    catch {
        throw "AWS CLI not found. Please install AWS CLI and configure credentials."
    }
    
    # Check AWS credentials
    try {
        $callerIdentity = aws sts get-caller-identity --region $AwsRegion --output json | ConvertFrom-Json
        Write-Host "AWS Account: $($callerIdentity.Account)" -ForegroundColor Green
        Write-Host "AWS User: $($callerIdentity.Arn)" -ForegroundColor Green
    }
    catch {
        throw "AWS credentials not configured. Please run 'aws configure' to set up credentials."
    }
    
    # Step 2: Set default values
    Write-Host "Step 2/10: Setting default values..." -ForegroundColor Cyan
    if (-not $ClusterName) { $ClusterName = "$AppName-cluster" }
    if (-not $TaskDefinitionName) { $TaskDefinitionName = "$AppName-task" }
    if (-not $ServiceName) { $ServiceName = "$AppName-service" }
    if (-not $ImageName) { $ImageName = $AppName.ToLower() }
    if (-not $EcrRepositoryName) { $EcrRepositoryName = $AppName.ToLower() }
    if (-not $LoadBalancerName) { $LoadBalancerName = "$AppName-alb" }
    if (-not $TargetGroupName) { $TargetGroupName = "$AppName-tg" }
    
    # Step 3: Build and push container image
    Write-Host "Step 3/10: Building and pushing container image..." -ForegroundColor Cyan
    if ($BuildImage) {
        if (-not (Test-Path -Path "$ProjectPath\Dockerfile")) {
            Write-Host "No Dockerfile found. Creating a basic Dockerfile..." -ForegroundColor Yellow
            $dockerfileContent = @"
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE $Port
CMD ["npm", "start"]
"@
            Set-Content -Path "$ProjectPath\Dockerfile" -Value $dockerfileContent
            Write-Host "Created basic Dockerfile." -ForegroundColor Green
        }
        
        # Create ECR repository if it doesn't exist
        try {
            $ecrRepo = aws ecr describe-repositories --repository-names $EcrRepositoryName --region $AwsRegion --output json 2>$null | ConvertFrom-Json
            Write-Host "ECR repository '$EcrRepositoryName' already exists." -ForegroundColor Green
        }
        catch {
            Write-Host "Creating ECR repository: $EcrRepositoryName" -ForegroundColor White
            aws ecr create-repository --repository-name $EcrRepositoryName --region $AwsRegion --output json | Out-Null
            Write-Host "ECR repository created successfully." -ForegroundColor Green
        }
        
        # Get ECR login token
        $ecrLoginToken = aws ecr get-login-password --region $AwsRegion
        $ecrRegistry = "$($callerIdentity.Account).dkr.ecr.$AwsRegion.amazonaws.com"
        
        # Login to ECR
        Write-Host "Logging in to ECR..." -ForegroundColor White
        echo $ecrLoginToken | docker login --username AWS --password-stdin $ecrRegistry
        
        # Build and tag image
        $fullImageName = "$ecrRegistry/$EcrRepositoryName:$ImageTag"
        Write-Host "Building container image: $fullImageName" -ForegroundColor White
        try {
            Push-Location -Path $ProjectPath
            docker build -t $fullImageName .
            Write-Host "Container image built successfully." -ForegroundColor Green
        }
        catch {
            throw "Failed to build container image: $($_.Exception.Message)"
        }
        finally {
            Pop-Location
        }
        
        # Push image if requested
        if ($PushImage) {
            Write-Host "Pushing container image to ECR..." -ForegroundColor White
            try {
                docker push $fullImageName
                Write-Host "Container image pushed successfully." -ForegroundColor Green
            }
            catch {
                throw "Failed to push container image: $($_.Exception.Message)"
            }
        }
    }
    
    # Step 4: Create VPC and networking if not provided
    Write-Host "Step 4/10: Setting up networking..." -ForegroundColor Cyan
    if (-not $VpcId) {
        Write-Host "Creating VPC for ECS cluster..." -ForegroundColor White
        $vpcResult = aws ec2 create-vpc --cidr-block "10.0.0.0/16" --region $AwsRegion --output json | ConvertFrom-Json
        $VpcId = $vpcResult.Vpc.VpcId
        
        # Create internet gateway
        $igwResult = aws ec2 create-internet-gateway --region $AwsRegion --output json | ConvertFrom-Json
        $igwId = $igwResult.InternetGateway.InternetGatewayId
        aws ec2 attach-internet-gateway --vpc-id $VpcId --internet-gateway-id $igwId --region $AwsRegion | Out-Null
        
        # Create subnets
        $subnet1Result = aws ec2 create-subnet --vpc-id $VpcId --cidr-block "10.0.1.0/24" --availability-zone "${AwsRegion}a" --region $AwsRegion --output json | ConvertFrom-Json
        $subnet2Result = aws ec2 create-subnet --vpc-id $VpcId --cidr-block "10.0.2.0/24" --availability-zone "${AwsRegion}b" --region $AwsRegion --output json | ConvertFrom-Json
        $SubnetIds = @($subnet1Result.Subnet.SubnetId, $subnet2Result.Subnet.SubnetId)
        
        # Create route table
        $rtResult = aws ec2 create-route-table --vpc-id $VpcId --region $AwsRegion --output json | ConvertFrom-Json
        $rtId = $rtResult.RouteTable.RouteTableId
        aws ec2 create-route --route-table-id $rtId --destination-cidr-block "0.0.0.0/0" --gateway-id $igwId --region $AwsRegion | Out-Null
        aws ec2 associate-route-table --subnet-id $SubnetIds[0] --route-table-id $rtId --region $AwsRegion | Out-Null
        aws ec2 associate-route-table --subnet-id $SubnetIds[1] --route-table-id $rtId --region $AwsRegion | Out-Null
        
        Write-Host "VPC and networking created successfully." -ForegroundColor Green
    }
    
    # Step 5: Create security groups if not provided
    Write-Host "Step 5/10: Creating security groups..." -ForegroundColor Cyan
    if (-not $SecurityGroupIds) {
        Write-Host "Creating security group for ECS service..." -ForegroundColor White
        $sgResult = aws ec2 create-security-group --group-name "$AppName-sg" --description "Security group for $AppName ECS service" --vpc-id $VpcId --region $AwsRegion --output json | ConvertFrom-Json
        $SecurityGroupIds = @($sgResult.GroupId)
        
        # Allow inbound traffic on the application port
        aws ec2 authorize-security-group-ingress --group-id $SecurityGroupIds[0] --protocol tcp --port $Port --cidr 0.0.0.0/0 --region $AwsRegion | Out-Null
        
        # Allow all outbound traffic
        aws ec2 authorize-security-group-egress --group-id $SecurityGroupIds[0] --protocol -1 --port -1 --cidr 0.0.0.0/0 --region $AwsRegion | Out-Null
        
        Write-Host "Security group created successfully." -ForegroundColor Green
    }
    
    # Step 6: Create ECS cluster
    Write-Host "Step 6/10: Creating ECS cluster..." -ForegroundColor Cyan
    try {
        $clusterResult = aws ecs describe-clusters --clusters $ClusterName --region $AwsRegion --output json 2>$null | ConvertFrom-Json
        if ($clusterResult.clusters.Count -eq 0) {
            Write-Host "Creating ECS cluster: $ClusterName" -ForegroundColor White
            aws ecs create-cluster --cluster-name $ClusterName --region $AwsRegion --output json | Out-Null
            Write-Host "ECS cluster created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "ECS cluster '$ClusterName' already exists." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create ECS cluster: $($_.Exception.Message)"
    }
    
    # Step 7: Create task definition
    Write-Host "Step 7/10: Creating ECS task definition..." -ForegroundColor Cyan
    $taskDefinitionJson = @{
        family                  = $TaskDefinitionName
        networkMode             = "awsvpc"
        requiresCompatibilities = @("FARGATE")
        cpu                     = $Cpu
        memory                  = $Memory
        executionRoleArn        = "ecsTaskExecutionRole"
        containerDefinitions    = @(
            @{
                name             = $AppName
                image            = if ($BuildImage) { "$ecrRegistry/$EcrRepositoryName:$ImageTag" } else { "$ImageName:$ImageTag" }
                portMappings     = @(
                    @{
                        containerPort = $Port
                        protocol      = "tcp"
                    }
                )
                essential        = $true
                logConfiguration = @{
                    logDriver = "awslogs"
                    options   = @{
                        "awslogs-group"         = "/ecs/$TaskDefinitionName"
                        "awslogs-region"        = $AwsRegion
                        "awslogs-stream-prefix" = "ecs"
                    }
                }
            }
        )
    }
    
    # Add environment variables
    if ($EnvironmentVariables.Count -gt 0) {
        $taskDefinitionJson.containerDefinitions[0].environment = @()
        foreach ($key in $EnvironmentVariables.Keys) {
            $taskDefinitionJson.containerDefinitions[0].environment += @{
                name  = $key
                value = $EnvironmentVariables[$key]
            }
        }
    }
    
    # Add secrets
    if ($Secrets.Count -gt 0) {
        $taskDefinitionJson.containerDefinitions[0].secrets = @()
        foreach ($key in $Secrets.Keys) {
            $taskDefinitionJson.containerDefinitions[0].secrets += @{
                name      = $key
                valueFrom = "arn:aws:secretsmanager:${AwsRegion}:$($callerIdentity.Account):secret:$key"
            }
        }
    }
    
    $taskDefinitionFile = "$env:TEMP\task-definition.json"
    $taskDefinitionJson | ConvertTo-Json -Depth 10 | Set-Content -Path $taskDefinitionFile
    
    try {
        Write-Host "Creating ECS task definition: $TaskDefinitionName" -ForegroundColor White
        $taskDefResult = aws ecs register-task-definition --cli-input-json file://$taskDefinitionFile --region $AwsRegion --output json | ConvertFrom-Json
        Write-Host "ECS task definition created successfully." -ForegroundColor Green
    }
    catch {
        throw "Failed to create ECS task definition: $($_.Exception.Message)"
    }
    finally {
        Remove-Item -Path $taskDefinitionFile -ErrorAction SilentlyContinue
    }
    
    # Step 8: Create Application Load Balancer
    Write-Host "Step 8/10: Creating Application Load Balancer..." -ForegroundColor Cyan
    try {
        $albResult = aws elbv2 describe-load-balancers --names $LoadBalancerName --region $AwsRegion --output json 2>$null | ConvertFrom-Json
        if ($albResult.LoadBalancers.Count -eq 0) {
            Write-Host "Creating Application Load Balancer: $LoadBalancerName" -ForegroundColor White
            $albResult = aws elbv2 create-load-balancer --name $LoadBalancerName --subnets $SubnetIds --security-groups $SecurityGroupIds --region $AwsRegion --output json | ConvertFrom-Json
            Write-Host "Application Load Balancer created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Application Load Balancer '$LoadBalancerName' already exists." -ForegroundColor Green
        }
        
        $albArn = $albResult.LoadBalancers[0].LoadBalancerArn
        $albDnsName = $albResult.LoadBalancers[0].DNSName
    }
    catch {
        throw "Failed to create Application Load Balancer: $($_.Exception.Message)"
    }
    
    # Step 9: Create target group
    Write-Host "Step 9/10: Creating target group..." -ForegroundColor Cyan
    try {
        $tgResult = aws elbv2 describe-target-groups --names $TargetGroupName --region $AwsRegion --output json 2>$null | ConvertFrom-Json
        if ($tgResult.TargetGroups.Count -eq 0) {
            Write-Host "Creating target group: $TargetGroupName" -ForegroundColor White
            $tgResult = aws elbv2 create-target-group --name $TargetGroupName --protocol HTTP --port $Port --vpc-id $VpcId --target-type ip --region $AwsRegion --output json | ConvertFrom-Json
            Write-Host "Target group created successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Target group '$TargetGroupName' already exists." -ForegroundColor Green
        }
        
        $tgArn = $tgResult.TargetGroups[0].TargetGroupArn
    }
    catch {
        throw "Failed to create target group: $($_.Exception.Message)"
    }
    
    # Step 10: Create ECS service
    Write-Host "Step 10/10: Creating ECS service..." -ForegroundColor Cyan
    try {
        $serviceResult = aws ecs describe-services --cluster $ClusterName --services $ServiceName --region $AwsRegion --output json 2>$null | ConvertFrom-Json
        if ($serviceResult.services.Count -eq 0) {
            Write-Host "Creating ECS service: $ServiceName" -ForegroundColor White
            $serviceParams = @{
                cluster              = $ClusterName
                serviceName          = $ServiceName
                taskDefinition       = $TaskDefinitionName
                desiredCount         = $DesiredCount
                launchType           = "FARGATE"
                networkConfiguration = @{
                    awsvpcConfiguration = @{
                        subnets        = $SubnetIds
                        securityGroups = $SecurityGroupIds
                        assignPublicIp = "ENABLED"
                    }
                }
                loadBalancers        = @(
                    @{
                        targetGroupArn = $tgArn
                        containerName  = $AppName
                        containerPort  = $Port
                    }
                )
            }
            
            $serviceFile = "$env:TEMP\service-definition.json"
            $serviceParams | ConvertTo-Json -Depth 10 | Set-Content -Path $serviceFile
            
            aws ecs create-service --cli-input-json file://$serviceFile --region $AwsRegion --output json | Out-Null
            Write-Host "ECS service created successfully!" -ForegroundColor Green
            
            Remove-Item -Path $serviceFile -ErrorAction SilentlyContinue
        }
        else {
            Write-Host "ECS service '$ServiceName' already exists." -ForegroundColor Green
        }
    }
    catch {
        throw "Failed to create ECS service: $($_.Exception.Message)"
    }
    
    # Configure auto-scaling if requested
    if ($EnableAutoScaling) {
        Write-Host "Configuring auto-scaling..." -ForegroundColor White
        try {
            # Create auto-scaling target
            aws application-autoscaling register-scalable-target --service-namespace ecs --scalable-dimension ecs:service:DesiredCount --resource-id "service/$ClusterName/$ServiceName" --min-capacity $MinCount --max-capacity $MaxCount --region $AwsRegion | Out-Null
            
            # Create scaling policy
            $scalingPolicy = @{
                PolicyName                               = "$ServiceName-scaling-policy"
                ServiceNamespace                         = "ecs"
                ResourceId                               = "service/$ClusterName/$ServiceName"
                ScalableDimension                        = "ecs:service:DesiredCount"
                PolicyType                               = "TargetTrackingScaling"
                TargetTrackingScalingPolicyConfiguration = @{
                    TargetValue                   = 70.0
                    PredefinedMetricSpecification = @{
                        PredefinedMetricType = "ECSServiceAverageCPUUtilization"
                    }
                }
            }
            
            $policyFile = "$env:TEMP\scaling-policy.json"
            $scalingPolicy | ConvertTo-Json -Depth 10 | Set-Content -Path $policyFile
            
            aws application-autoscaling put-scaling-policy --cli-input-json file://$policyFile --region $AwsRegion --output json | Out-Null
            Write-Host "Auto-scaling configured successfully." -ForegroundColor Green
            
            Remove-Item -Path $policyFile -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Failed to configure auto-scaling: $($_.Exception.Message)"
        }
    }
    
    # Return deployment information
    return @{
        Success            = $true
        DeploymentUrl      = "http://$albDnsName"
        AppName            = $AppName
        Platform           = "AWS"
        Service            = "ECS Fargate"
        Region             = $AwsRegion
        ClusterName        = $ClusterName
        ServiceName        = $ServiceName
        TaskDefinitionName = $TaskDefinitionName
        LoadBalancerName   = $LoadBalancerName
        TargetGroupName    = $TargetGroupName
        Cpu                = $Cpu
        Memory             = $Memory
        DesiredCount       = $DesiredCount
        AutoScaling        = $EnableAutoScaling
        CustomDomain       = $CustomDomain
    }
} 