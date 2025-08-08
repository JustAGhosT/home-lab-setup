function Deploy-MultiCloudInfrastructure {
  <#
    .SYNOPSIS
        Deploys multi-cloud infrastructure across multiple cloud providers.
    
    .DESCRIPTION
        Deploys infrastructure across multiple cloud providers including
        Azure, AWS, and Google Cloud with unified management.
    
    .PARAMETER ResourceGroup
        The primary resource group name for Azure resources.
    
    .PARAMETER Location
        The primary Azure location for the deployment.
    
    .PARAMETER ProjectName
        The name of the multi-cloud project.
    
    .PARAMETER CloudProviders
        Array of cloud providers to deploy to (Azure, AWS, GCP).
    
    .PARAMETER EnableAzure
        Whether to enable Azure deployment.
    
    .PARAMETER EnableAWS
        Whether to enable AWS deployment.
    
    .PARAMETER EnableGCP
        Whether to enable Google Cloud deployment.
    
    .PARAMETER InfrastructureType
        The type of infrastructure to deploy (compute, storage, networking, all).
    
    .PARAMETER EnableTerraform
        Whether to use Terraform for infrastructure as code.
    
    .PARAMETER EnableBicep
        Whether to use Bicep for Azure infrastructure.
    
    .PARAMETER EnableCloudFormation
        Whether to use CloudFormation for AWS infrastructure.
    
    .PARAMETER EnableKubernetes
        Whether to deploy Kubernetes clusters.
    
    .PARAMETER EnableMonitoring
        Whether to enable unified monitoring.
    
    .PARAMETER EnableSecurity
        Whether to enable unified security policies.
    
    .PARAMETER GCPProjectID
        The Google Cloud Platform project ID for GCP resources.
        Required when EnableGCP is set to true.
    
    .EXAMPLE
        Deploy-MultiCloudInfrastructure -ResourceGroup "my-rg" -Location "southafricanorth" -ProjectName "my-multicloud-project"
    
    .EXAMPLE
        Deploy-MultiCloudInfrastructure -ResourceGroup "my-rg" -Location "southafricanorth" -ProjectName "my-multicloud-project" -EnableGCP $true -GCPProjectID "my-gcp-project-id"
    
    .NOTES
        Author: HomeLab Team
        Date: March 2025
    #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
        
    [Parameter(Mandatory = $true)]
    [string]$Location,
        
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
        
    [Parameter(Mandatory = $false)]
    [ValidateSet("Azure", "AWS", "GCP")]
    [string[]]$CloudProviders = @("Azure"),
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableAzure = $true,
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableAWS = $false,
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableGCP = $false,
        
    [Parameter(Mandatory = $false)]
    [ValidateSet("compute", "storage", "networking", "all")]
    [string]$InfrastructureType = "all",
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableTerraform = $false,
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableBicep = $true,
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableCloudFormation = $false,
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableKubernetes = $false,
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableMonitoring = $true,
        
    [Parameter(Mandatory = $false)]
    [bool]$EnableSecurity = $true,
        
    [Parameter(Mandatory = $false)]
    [string]$GCPProjectID
  )
    
  try {
    Write-ColorOutput "Starting Multi-Cloud Infrastructure deployment..." -ForegroundColor Cyan
        
    # Validate GCP project ID if GCP is enabled
    if ($EnableGCP -and [string]::IsNullOrWhiteSpace($GCPProjectID)) {
      Write-ColorOutput "Error: GCP Project ID is required when EnableGCP is set to true." -ForegroundColor Red
      Write-ColorOutput "Please provide the GCPProjectID parameter with your actual GCP project ID." -ForegroundColor Yellow
      throw "GCPProjectID parameter is required when EnableGCP is true"
    }
        
    if ($EnableGCP -and $GCPProjectID) {
      Write-ColorOutput "Using GCP Project ID: $GCPProjectID" -ForegroundColor Green
    }
        
    # Update cloud providers based on enabled flags
    $CloudProviders = @()
    if ($EnableAzure) { $CloudProviders += "Azure" }
    if ($EnableAWS) { $CloudProviders += "AWS" }
    if ($EnableGCP) { $CloudProviders += "GCP" }
        
    Write-ColorOutput "Target Cloud Providers: $($CloudProviders -join ', ')" -ForegroundColor Yellow
        
    # Check if resource group exists
    $rgExists = az group exists --name $ResourceGroup --output tsv 2>$null
    if ($rgExists -ne "true") {
      Write-ColorOutput "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
      az group create --name $ResourceGroup --location $Location
    }
        
    # Create multi-cloud project configuration
    Write-ColorOutput "Creating multi-cloud project configuration..." -ForegroundColor Yellow
    $projectConfig = @{
      ProjectName          = $ProjectName
      ResourceGroup        = $ResourceGroup
      Location             = $Location
      CloudProviders       = $CloudProviders
      InfrastructureType   = $InfrastructureType
      EnableTerraform      = $EnableTerraform
      EnableBicep          = $EnableBicep
      EnableCloudFormation = $EnableCloudFormation
      EnableKubernetes     = $EnableKubernetes
      EnableMonitoring     = $EnableMonitoring
      EnableSecurity       = $EnableSecurity
      CreatedAt            = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
        
    # Deploy Azure infrastructure if enabled
    if ($EnableAzure) {
      Write-ColorOutput "Deploying Azure infrastructure..." -ForegroundColor Yellow
            
      # Create Azure Container Registry for multi-cloud images
      $acrName = "$($ProjectName.ToLower())acr$(Get-Random -Minimum 1000 -Maximum 9999)"
      Write-ColorOutput "Creating Azure Container Registry: $acrName" -ForegroundColor Gray
      az acr create `
        --name $acrName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard
            
      # Create Azure Key Vault for secrets management
      $keyVaultName = "$($ProjectName.ToLower())kv$(Get-Random -Minimum 1000 -Maximum 9999)"
      Write-ColorOutput "Creating Azure Key Vault: $keyVaultName" -ForegroundColor Gray
      az keyvault create `
        --name $keyVaultName `
        --resource-group $ResourceGroup `
        --location $Location `
        --enable-soft-delete
            
      # Create Log Analytics workspace for monitoring
      if ($EnableMonitoring) {
        $workspaceName = "$($ProjectName.ToLower())workspace$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-ColorOutput "Creating Log Analytics workspace: $workspaceName" -ForegroundColor Gray
        az monitor log-analytics workspace create `
          --workspace-name $workspaceName `
          --resource-group $ResourceGroup `
          --location $Location
      }
            
      # Create Azure Kubernetes Service if enabled
      if ($EnableKubernetes) {
        $aksName = "$($ProjectName.ToLower())aks$(Get-Random -Minimum 1000 -Maximum 9999)"
        Write-ColorOutput "Creating Azure Kubernetes Service: $aksName" -ForegroundColor Gray
        az aks create `
          --name $aksName `
          --resource-group $ResourceGroup `
          --location $Location `
          --node-count 2 `
          --node-vm-size Standard_DS2_v2 `
          --attach-acr $acrName `
          --enable-addons monitoring `
          --generate-ssh-keys
      }
            
      # Create Azure Storage Account for multi-cloud data
      $storageAccountName = "$($ProjectName.ToLower())storage$(Get-Random -Minimum 1000 -Maximum 9999)"
      Write-ColorOutput "Creating Azure Storage Account: $storageAccountName" -ForegroundColor Gray
      az storage account create `
        --name $storageAccountName `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2
            
      # Create containers for multi-cloud data
      try {
        $storageKey = az storage account keys list `
          --account-name $storageAccountName `
          --resource-group $ResourceGroup `
          --query "[0].value" `
          --output tsv
                
        if ($LASTEXITCODE -ne 0) {
          throw "Failed to retrieve storage account key. Exit code: $LASTEXITCODE"
        }
                
        if ([string]::IsNullOrWhiteSpace($storageKey)) {
          throw "Storage account key is empty or null"
        }
                
        Write-ColorOutput "Successfully retrieved storage account key" -ForegroundColor Green
      }
      catch {
        Write-ColorOutput "Error retrieving storage account key: $($_.Exception.Message)" -ForegroundColor Red
        throw "Failed to retrieve storage account key for '$storageAccountName': $($_.Exception.Message)"
      }
            
      $containers = @("multicloud-data", "terraform-state", "backup-data")
      foreach ($container in $containers) {
        try {
          az storage container create `
            --name $container `
            --account-name $storageAccountName `
            --account-key $storageKey
                    
          if ($LASTEXITCODE -ne 0) {
            throw "Failed to create storage container '$container'. Exit code: $LASTEXITCODE"
          }
                    
          Write-ColorOutput "Successfully created storage container: $container" -ForegroundColor Green
        }
        catch {
          Write-ColorOutput "Error creating storage container '$container': $($_.Exception.Message)" -ForegroundColor Red
          throw "Failed to create storage container '$container': $($_.Exception.Message)"
        }
      }
    }
        
    # Create Terraform configuration if enabled
    if ($EnableTerraform) {
      Write-ColorOutput "Creating Terraform configuration..." -ForegroundColor Yellow
            
      $terraformConfig = @"
# Multi-Cloud Infrastructure with Terraform
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "$ResourceGroup"
    storage_account_name = "$storageAccountName"
    container_name       = "terraform-state"
    key                  = "multicloud.tfstate"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
}

# AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Google Cloud Provider
provider "google" {
  project = "$(if ($GCPProjectID) { $GCPProjectID } else { 'your-gcp-project-id' })"
  region  = "us-central1"
}

# Multi-Cloud Variables
variable "project_name" {
  description = "Name of the multi-cloud project"
  type        = string
  default     = "$ProjectName"
}

variable "location" {
  description = "Primary location for resources"
  type        = string
  default     = "$Location"
}

# Azure Resources
resource "azurerm_resource_group" "multicloud" {
  name     = var.project_name
  location = var.location
}

# AWS Resources
resource "aws_vpc" "multicloud" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "\${var.project_name}-vpc"
  }
}

# Google Cloud Resources
resource "google_compute_network" "multicloud" {
  name                    = "\${var.project_name}-network"
  auto_create_subnetworks = false
}
"@
            
      $terraformPath = Join-Path -Path $env:TEMP -ChildPath "multicloud-terraform"
      if (-not (Test-Path -Path $terraformPath)) {
        New-Item -ItemType Directory -Path $terraformPath -Force | Out-Null
      }
            
      $terraformConfig | Set-Content -Path (Join-Path -Path $terraformPath -ChildPath "main.tf")
      Write-ColorOutput "Terraform configuration created: $terraformPath" -ForegroundColor Green
    }
        
    # Create Bicep configuration if enabled
    if ($EnableBicep) {
      Write-ColorOutput "Creating Bicep configuration..." -ForegroundColor Yellow
            
      # Generate dynamic resource names in PowerShell
      $storageAccountNameBicep = "$($ProjectName.ToLower())storage$(Get-Random -Minimum 100000 -Maximum 999999)"
      $keyVaultNameBicep = "$($ProjectName.ToLower())kv$(Get-Random -Minimum 100000 -Maximum 999999)"
      $workspaceNameBicep = "$($ProjectName.ToLower())workspace$(Get-Random -Minimum 100000 -Maximum 999999)"
            
      $bicepConfig = @"
// Multi-Cloud Infrastructure with Bicep
@description('Name of the multi-cloud project')
param projectName string = '$ProjectName'

@description('Primary location for resources')
param location string = '$Location'

@description('Enable monitoring')
param enableMonitoring bool = $($EnableMonitoring.ToString().ToLower())

@description('Enable security features')
param enableSecurity bool = $($EnableSecurity.ToString().ToLower())

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: projectName
  location: location
}

// Storage Account for multi-cloud data
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '$storageAccountNameBicep'
  location: location
  resourceGroup: rg.name
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Key Vault for secrets management
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: '$keyVaultNameBicep'
  location: location
  resourceGroup: rg.name
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
  }
}

// Log Analytics Workspace for monitoring
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: '$workspaceNameBicep'
  location: location
  resourceGroup: rg.name
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Outputs
output resourceGroupName string = rg.name
output storageAccountName string = storageAccount.name
output keyVaultName string = keyVault.name
output workspaceName string = enableMonitoring ? workspace.name : ''
"@
            
      $bicepPath = Join-Path -Path $env:TEMP -ChildPath "multicloud-bicep"
      if (-not (Test-Path -Path $bicepPath)) {
        New-Item -ItemType Directory -Path $bicepPath -Force | Out-Null
      }
            
      $bicepConfig | Set-Content -Path (Join-Path -Path $bicepPath -ChildPath "main.bicep")
      Write-ColorOutput "Bicep configuration created: $bicepPath" -ForegroundColor Green
    }
        
    # Create CloudFormation template if enabled
    if ($EnableCloudFormation) {
      Write-ColorOutput "Creating CloudFormation template..." -ForegroundColor Yellow
            
      $cloudFormationConfig = @"
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Multi-Cloud Infrastructure - AWS Resources'

Parameters:
  ProjectName:
    Type: String
    Default: '$ProjectName'
    Description: Name of the multi-cloud project

Resources:
  # VPC for multi-cloud connectivity
  MultiCloudVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-vpc'

  # Internet Gateway
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-igw'

  # Attach Internet Gateway to VPC
  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref MultiCloudVPC
      InternetGatewayId: !Ref InternetGateway

  # Public Subnet
  PublicSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref MultiCloudVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-public-subnet'

  # Route Table
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref MultiCloudVPC
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-public-routes'

  # Route to Internet Gateway
  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  # Associate Route Table with Subnet
  PublicSubnetRouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet
      RouteTableId: !Ref PublicRouteTable

  # S3 Bucket for multi-cloud data
  MultiCloudBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${ProjectName}-multicloud-data-${AWS::AccountId}'
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

Outputs:
  VPCId:
    Description: VPC ID
    Value: !Ref MultiCloudVPC
    Export:
      Name: !Sub '${ProjectName}-vpc-id'

  PublicSubnetId:
    Description: Public Subnet ID
    Value: !Ref PublicSubnet
    Export:
      Name: !Sub '${ProjectName}-public-subnet-id'

  MultiCloudBucketName:
    Description: S3 Bucket for multi-cloud data
    Value: !Ref MultiCloudBucket
    Export:
      Name: !Sub '${ProjectName}-bucket-name'
"@
            
      $cloudFormationPath = Join-Path -Path $env:TEMP -ChildPath "multicloud-cloudformation"
      if (-not (Test-Path -Path $cloudFormationPath)) {
        New-Item -ItemType Directory -Path $cloudFormationPath -Force | Out-Null
      }
            
      $cloudFormationConfig | Set-Content -Path (Join-Path -Path $cloudFormationPath -ChildPath "template.yaml")
      Write-ColorOutput "CloudFormation template created: $cloudFormationPath" -ForegroundColor Green
    }
        
    # Create multi-cloud configuration file
    $configPath = Join-Path -Path $env:TEMP -ChildPath "multicloud-config.json"
    $projectConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
        
    # Display deployment summary
    Write-ColorOutput "`nMulti-Cloud Infrastructure deployment completed successfully!" -ForegroundColor Green
    Write-ColorOutput "Project Name: $ProjectName" -ForegroundColor Gray
    Write-ColorOutput "Resource Group: $ResourceGroup" -ForegroundColor Gray
    Write-ColorOutput "Location: $Location" -ForegroundColor Gray
    Write-ColorOutput "Cloud Providers: $($CloudProviders -join ', ')" -ForegroundColor Gray
    Write-ColorOutput "Infrastructure Type: $InfrastructureType" -ForegroundColor Gray
        
    if ($EnableAzure) {
      Write-ColorOutput "Azure Resources:" -ForegroundColor Gray
      Write-ColorOutput "  - Container Registry: $acrName" -ForegroundColor Gray
      Write-ColorOutput "  - Key Vault: $keyVaultName" -ForegroundColor Gray
      Write-ColorOutput "  - Storage Account: $storageAccountName" -ForegroundColor Gray
      if ($EnableMonitoring) {
        Write-ColorOutput "  - Log Analytics Workspace: $workspaceName" -ForegroundColor Gray
      }
      if ($EnableKubernetes) {
        Write-ColorOutput "  - AKS Cluster: $aksName" -ForegroundColor Gray
      }
    }
        
    Write-ColorOutput "Configuration Files:" -ForegroundColor Gray
    if ($EnableTerraform) {
      Write-ColorOutput "  - Terraform: $terraformPath" -ForegroundColor Gray
    }
    if ($EnableBicep) {
      Write-ColorOutput "  - Bicep: $bicepPath" -ForegroundColor Gray
    }
    if ($EnableCloudFormation) {
      Write-ColorOutput "  - CloudFormation: $cloudFormationPath" -ForegroundColor Gray
    }
    Write-ColorOutput "  - Multi-Cloud Config: $configPath" -ForegroundColor Gray
        
    # Return deployment info
    return @{
      ProjectName        = $ProjectName
      ResourceGroup      = $ResourceGroup
      Location           = $Location
      CloudProviders     = $CloudProviders
      InfrastructureType = $InfrastructureType
      AzureResources     = if ($EnableAzure) {
        @{
          ContainerRegistry     = $acrName
          KeyVault              = $keyVaultName
          StorageAccount        = $storageAccountName
          LogAnalyticsWorkspace = if ($EnableMonitoring) { $workspaceName } else { $null }
          AKSCluster            = if ($EnableKubernetes) { $aksName } else { $null }
        }
      }
      else { $null }
      ConfigurationFiles = @{
        Terraform        = if ($EnableTerraform) { $terraformPath } else { $null }
        Bicep            = if ($EnableBicep) { $bicepPath } else { $null }
        CloudFormation   = if ($EnableCloudFormation) { $cloudFormationPath } else { $null }
        MultiCloudConfig = $configPath
      }
      ProjectConfig      = $projectConfig
    }
  }
  catch {
    Write-ColorOutput "Error deploying Multi-Cloud Infrastructure: $_" -ForegroundColor Red
    throw
  }
} 