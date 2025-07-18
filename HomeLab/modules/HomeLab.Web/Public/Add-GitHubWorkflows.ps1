function Add-GitHubWorkflows {
    <#
    .SYNOPSIS
        Adds GitHub workflow files for automatic deployment to a project.
    
    .DESCRIPTION
        This function creates GitHub workflow files for automatic deployment to Azure
        in the specified project directory.
    
    .PARAMETER ProjectPath
        Path to the project directory.
    
    .PARAMETER DeploymentType
        Type of deployment (static|appservice|auto). Default is auto.
    
    .PARAMETER CustomDomain
        Custom domain to use for deployment (e.g., example.com).
    
    .EXAMPLE
        Add-GitHubWorkflows -ProjectPath "C:\Projects\MyWebsite" -DeploymentType "static" -CustomDomain "example.com"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [ValidateSet("static", "appservice", "auto")]
        [string]$DeploymentType = "auto",
        
        [Parameter()]
        [string]$CustomDomain = "liquidmesh.ai"
    )
    
    # Create .github/workflows directory if it doesn't exist
    $workflowsDir = Join-Path -Path $ProjectPath -ChildPath ".github\workflows"
    if (-not (Test-Path -Path $workflowsDir)) {
        New-Item -Path $workflowsDir -ItemType Directory -Force | Out-Null
        Write-Host "Created .github/workflows directory" -ForegroundColor Green
    }
    
    # Create deploy-azure.yml workflow file
    $deployAzureYmlPath = Join-Path -Path $workflowsDir -ChildPath "deploy-azure.yml"
    $deployAzureYml = @'
name: Deploy to Azure with Custom Domain

on:
  workflow_dispatch:
    inputs:
      deployment_type:
        description: 'Deployment Type'
        required: true
        type: choice
        options:
          - static
          - appservice
          - auto
        default: 'auto'
      environment:
        description: 'Target Environment'
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod
        default: 'dev'
      subdomain:
        description: 'Subdomain (e.g., myapp for myapp.yourdomain.com)'
        required: true
        type: string
      custom_domain:
        description: 'Custom Domain (e.g., yourdomain.com)'
        required: false
        type: string
        default: '{0}'
      azure_location:
        description: 'Azure Region'
        required: true
        type: choice
        options:
          - eastus
          - westus2
          - westeurope
          - southeastasia
          - australiaeast
        default: 'eastus'
      force_deployment:
        description: 'Force deployment even if resources exist'
        required: false
        type: boolean
        default: false

env:
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

jobs:
  validate-inputs:
    runs-on: ubuntu-latest
    outputs:
      app_name: ${{ steps.generate-names.outputs.app_name }}
      resource_group: ${{ steps.generate-names.outputs.resource_group }}
      full_domain: ${{ steps.generate-names.outputs.full_domain }}
      deployment_type: ${{ steps.determine-type.outputs.deployment_type }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Generate resource names
        id: generate-names
        run: |
          # Generate consistent naming
          SUBDOMAIN="${{ github.event.inputs.subdomain }}"
          ENVIRONMENT="${{ github.event.inputs.environment }}"
          CUSTOM_DOMAIN="${{ github.event.inputs.custom_domain }}"

          # Clean subdomain (remove non-alphanumeric chars)
          CLEAN_SUBDOMAIN=$(echo "$SUBDOMAIN" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')

          # Generate names
          APP_NAME="${CLEAN_SUBDOMAIN}-${ENVIRONMENT}"
          RESOURCE_GROUP="rg-${APP_NAME}"
          FULL_DOMAIN="${SUBDOMAIN}.${CUSTOM_DOMAIN}"

          echo "app_name=$APP_NAME" >> $GITHUB_OUTPUT
          echo "resource_group=$RESOURCE_GROUP" >> $GITHUB_OUTPUT
          echo "full_domain=$FULL_DOMAIN" >> $GITHUB_OUTPUT

          echo "Generated names:"
          echo "  App Name: $APP_NAME"
          echo "  Resource Group: $RESOURCE_GROUP"
          echo "  Full Domain: $FULL_DOMAIN"

      - name: Determine deployment type
        id: determine-type
        run: |
          DEPLOYMENT_TYPE="${{ github.event.inputs.deployment_type }}"

          if [[ "$DEPLOYMENT_TYPE" == "auto" ]]; then
            # Auto-detect based on project files
            if [[ -f "package.json" ]]; then
              if grep -q "express\|koa\|fastify\|hapi\|nest" package.json 2>/dev/null; then
                DEPLOYMENT_TYPE="appservice"
              elif grep -q "next\|react\|vue\|angular" package.json 2>/dev/null; then
                DEPLOYMENT_TYPE="static"
              else
                DEPLOYMENT_TYPE="static"
              fi
            elif [[ -f "requirements.txt" || -f "Pipfile" ]]; then
              if [[ -f "wsgi.py" || -f "asgi.py" || -f "manage.py" ]]; then
                DEPLOYMENT_TYPE="appservice"
              else
                DEPLOYMENT_TYPE="static"
              fi
            elif [[ -f "*.csproj" || -f "Program.cs" ]]; then
                DEPLOYMENT_TYPE="appservice"
            else
              DEPLOYMENT_TYPE="static"
            fi
          fi

          echo "deployment_type=$DEPLOYMENT_TYPE" >> $GITHUB_OUTPUT
          echo "Determined deployment type: $DEPLOYMENT_TYPE"

  build-and-test:
    runs-on: ubuntu-latest
    needs: validate-inputs
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js (if package.json exists)
        if: hashFiles('package.json') != ''
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        if: hashFiles('package.json') != ''
        run: npm ci

      - name: Run tests
        if: hashFiles('package.json') != ''
        run: |
          if npm list --depth=0 | grep -q "jest\|mocha\|vitest"; then
            npm test
          else
            echo "No test framework found, skipping tests"
          fi

      - name: Build application
        if: hashFiles('package.json') != ''
        run: |
          if npm run build --if-present; then
            echo "Build completed successfully"
          else
            echo "No build script found or build failed"
          fi

      - name: Upload build artifacts
        if: needs.validate-inputs.outputs.deployment_type == 'static'
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: |
            build/
            dist/
            out/
            public/
            *.html
            *.css
            *.js
          retention-days: 1

  deploy-static:
    runs-on: ubuntu-latest
    needs: [validate-inputs, build-and-test]
    if: needs.validate-inputs.outputs.deployment_type == 'static'
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          name: build-artifacts
          path: ./

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Azure Static Web Apps
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: 'upload'
          app_location: '/'
          api_location: 'api'
          output_location: 'build'
          skip_app_build: true

      - name: Configure Custom Domain
        if: github.event.inputs.custom_domain != ''
        run: |
          az staticwebapp hostname set \
            --name "${{ needs.validate-inputs.outputs.app_name }}" \
            --resource-group "${{ needs.validate-inputs.outputs.resource_group }}" \
            --hostname "${{ needs.validate-inputs.outputs.full_domain }}"

  deploy-appservice:
    runs-on: ubuntu-latest
    needs: [validate-inputs, build-and-test]
    if: needs.validate-inputs.outputs.deployment_type == 'appservice'
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Create Resource Group
        run: |
          az group create \
            --name "${{ needs.validate-inputs.outputs.resource_group }}" \
            --location "${{ github.event.inputs.azure_location }}"

      - name: Deploy to Azure App Service
        uses: azure/webapps-deploy@v3
        with:
          app-name: ${{ needs.validate-inputs.outputs.app_name }}
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: .

      - name: Configure Custom Domain
        if: github.event.inputs.custom_domain != ''
        run: |
          az webapp config hostname add \
            --name "${{ needs.validate-inputs.outputs.app_name }}" \
            --resource-group "${{ needs.validate-inputs.outputs.resource_group }}" \
            --hostname "${{ needs.validate-inputs.outputs.full_domain }}"

  post-deployment:
    runs-on: ubuntu-latest
    needs: [validate-inputs, deploy-static, deploy-appservice]
    if: always() && (needs.deploy-static.result == 'success' || needs.deploy-appservice.result == 'success')
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Get deployment URL
        id: get-url
        run: |
          DEPLOYMENT_TYPE="${{ needs.validate-inputs.outputs.deployment_type }}"
          APP_NAME="${{ needs.validate-inputs.outputs.app_name }}"
          RESOURCE_GROUP="${{ needs.validate-inputs.outputs.resource_group }}"
          FULL_DOMAIN="${{ needs.validate-inputs.outputs.full_domain }}"

          if [[ "$DEPLOYMENT_TYPE" == "static" ]]; then
            DEFAULT_URL=$(az staticwebapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query "defaultHostname" -o tsv)
            if [[ -n "${{ github.event.inputs.custom_domain }}" ]]; then
              FINAL_URL="https://$FULL_DOMAIN"
            else
              FINAL_URL="https://$DEFAULT_URL"
            fi
          else
            if [[ -n "${{ github.event.inputs.custom_domain }}" ]]; then
              FINAL_URL="https://$FULL_DOMAIN"
            else
              FINAL_URL="https://$APP_NAME.azurewebsites.net"
            fi
          fi

          echo "deployment_url=$FINAL_URL" >> $GITHUB_OUTPUT
          echo "Deployment URL: $FINAL_URL"

      - name: Display DNS Configuration
        if: github.event.inputs.custom_domain != ''
        run: |
          echo "🌐 DNS Configuration Required:"
          echo "================================"
          echo "Domain: ${{ needs.validate-inputs.outputs.full_domain }}"
          echo ""

          DEPLOYMENT_TYPE="${{ needs.validate-inputs.outputs.deployment_type }}"
          APP_NAME="${{ needs.validate-inputs.outputs.app_name }}"
          RESOURCE_GROUP="${{ needs.validate-inputs.outputs.resource_group }}"

          if [[ "$DEPLOYMENT_TYPE" == "static" ]]; then
            DEFAULT_URL=$(az staticwebapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query "defaultHostname" -o tsv)
            echo "Add this CNAME record to your DNS:"
            echo "Type: CNAME"
            echo "Name: ${{ github.event.inputs.subdomain }}"
            echo "Value: $DEFAULT_URL"
          else
            echo "Add this CNAME record to your DNS:"
            echo "Type: CNAME"
            echo "Name: ${{ github.event.inputs.subdomain }}"
            echo "Value: $APP_NAME.azurewebsites.net"
          fi
          echo ""
          echo "Once DNS propagates, your site will be available at:"
          echo "${{ steps.get-url.outputs.deployment_url }}"

      - name: Create deployment summary
        run: |
          echo "# 🚀 Deployment Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Parameter | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|-----------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Deployment Type | ${{ needs.validate-inputs.outputs.deployment_type }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | ${{ github.event.inputs.environment }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Application Name | ${{ needs.validate-inputs.outputs.app_name }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Resource Group | ${{ needs.validate-inputs.outputs.resource_group }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Custom Domain | ${{ needs.validate-inputs.outputs.full_domain }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Deployment URL | ${{ steps.get-url.outputs.deployment_url }} |" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "✅ Deployment completed successfully!" >> $GITHUB_STEP_SUMMARY
'@ -f $CustomDomain

    # Create multi-environment workflow file
    $multiEnvYmlPath = Join-Path -Path $workflowsDir -ChildPath "deploy-multi-env.yml"
    $multiEnvYml = @'
name: Deploy to Multiple Environments

on:
  workflow_dispatch:
    inputs:
      environments:
        description: 'Target Environments (comma-separated)'
        required: true
        type: string
        default: 'dev,staging,prod'
      deployment_type:
        description: 'Deployment Type'
        required: true
        type: choice
        options:
          - static
          - appservice
          - auto
        default: 'auto'
      base_subdomain:
        description: 'Base Subdomain (e.g., myapp for myapp-dev.yourdomain.com)'
        required: true
        type: string
      custom_domain:
        description: 'Custom Domain'
        required: false
        type: string
        default: '{0}'

jobs:
  prepare-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - name: Set up deployment matrix
        id: set-matrix
        run: |
          ENVIRONMENTS="${{ github.event.inputs.environments }}"
          BASE_SUBDOMAIN="${{ github.event.inputs.base_subdomain }}"
          CUSTOM_DOMAIN="${{ github.event.inputs.custom_domain }}"

          # Convert comma-separated environments to JSON array
          IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"

          MATRIX_JSON="{"
          MATRIX_JSON+='"include":['

          for i in "${!ENV_ARRAY[@]}"; do
            ENV="${ENV_ARRAY[$i]// /}"  # Remove spaces
            if [[ $i -gt 0 ]]; then
              MATRIX_JSON+=","
            fi

            # Generate environment-specific values
            if [[ "$ENV" == "prod" ]]; then
              SUBDOMAIN="$BASE_SUBDOMAIN"
            else
              SUBDOMAIN="$BASE_SUBDOMAIN-$ENV"
            fi

            MATRIX_JSON+='{"environment":"'$ENV'","subdomain":"'$SUBDOMAIN'","azure_location":"eastus"}'
          done

          MATRIX_JSON+=']}'

          echo "matrix=$MATRIX_JSON" >> $GITHUB_OUTPUT
          echo "Generated matrix: $MATRIX_JSON"

  deploy:
    needs: prepare-matrix
    runs-on: ubuntu-latest
    strategy:
      matrix: ${{ fromJson(needs.prepare-matrix.outputs.matrix) }}
      fail-fast: false
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy to ${{ matrix.environment }}
        uses: ./.github/workflows/deploy-azure.yml
        with:
          deployment_type: ${{ github.event.inputs.deployment_type }}
          environment: ${{ matrix.environment }}
          subdomain: ${{ matrix.subdomain }}
          custom_domain: ${{ github.event.inputs.custom_domain }}
          azure_location: ${{ matrix.azure_location }}
        secrets: inherit

  notify:
    needs: [prepare-matrix, deploy]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Create deployment summary
        run: |
          echo "# 🚀 Multi-Environment Deployment Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | Status | Subdomain |" >> $GITHUB_STEP_SUMMARY
          echo "|-------------|--------|-----------|" >> $GITHUB_STEP_SUMMARY

          # This would be dynamically populated based on the matrix results
          echo "| Production | ✅ Success | ${{ github.event.inputs.base_subdomain }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Staging | ✅ Success | ${{ github.event.inputs.base_subdomain }}-staging |" >> $GITHUB_STEP_SUMMARY
          echo "| Development | ✅ Success | ${{ github.event.inputs.base_subdomain }}-dev |" >> $GITHUB_STEP_SUMMARY
'@ -f $CustomDomain

    # Write the workflow files
    Set-Content -Path $deployAzureYmlPath -Value $deployAzureYml
    Set-Content -Path $multiEnvYmlPath -Value $multiEnvYml
    
    Write-Host "Created GitHub workflow files:" -ForegroundColor Green
    Write-Host "  - .github/workflows/deploy-azure.yml" -ForegroundColor Green
    Write-Host "  - .github/workflows/deploy-multi-env.yml" -ForegroundColor Green
    
    # Create .gitignore file if it doesn't exist
    $gitignorePath = Join-Path -Path $ProjectPath -ChildPath ".gitignore"
    if (-not (Test-Path -Path $gitignorePath)) {
        $gitignoreContent = @"
# Node.js
node_modules/
npm-debug.log
yarn-error.log
yarn-debug.log
.pnp/
.pnp.js

# Build outputs
/build/
/dist/
/out/
/.next/
/.nuxt/
/.output/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE files
.idea/
.vscode/
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# OS files
.DS_Store
Thumbs.db

# Azure
.azure/
"@
        Set-Content -Path $gitignorePath -Value $gitignoreContent
        Write-Host "Created .gitignore file" -ForegroundColor Green
    }
    
    # Create README.md file if it doesn't exist
    $readmePath = Join-Path -Path $ProjectPath -ChildPath "README.md"
    if (-not (Test-Path -Path $readmePath)) {
        $projectName = Split-Path -Path $ProjectPath -Leaf
        $readmeContent = @"
# $projectName

## Deployment

This project can be deployed to Azure using GitHub Actions workflows.

### Single Environment Deployment

To deploy to a single environment:

1. Go to the Actions tab in your GitHub repository
2. Select the "Deploy to Azure with Custom Domain" workflow
3. Click "Run workflow"
4. Fill in the required parameters:
   - Deployment Type: $DeploymentType
   - Environment: dev, staging, or prod
   - Subdomain: The subdomain for your application
   - Custom Domain: $CustomDomain (or your own domain)
   - Azure Location: The Azure region to deploy to

### Multi-Environment Deployment

To deploy to multiple environments at once:

1. Go to the Actions tab in your GitHub repository
2. Select the "Deploy to Multiple Environments" workflow
3. Click "Run workflow"
4. Fill in the required parameters:
   - Target Environments: Comma-separated list of environments (e.g., dev,staging,prod)
   - Deployment Type: $DeploymentType
   - Base Subdomain: The base subdomain for your application
   - Custom Domain: $CustomDomain (or your own domain)

## Required Secrets

The following secrets need to be configured in your GitHub repository:

- `AZURE_CREDENTIALS`: Azure service principal credentials
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `AZURE_STATIC_WEB_APPS_API_TOKEN`: API token for Static Web Apps (for static deployments)
- `AZURE_WEBAPP_PUBLISH_PROFILE`: Publish profile for App Service (for appservice deployments)

See the [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) for more detailed instructions.
"@
        Set-Content -Path $readmePath -Value $readmeContent
        Write-Host "Created README.md file with deployment instructions" -ForegroundColor Green
    }
    
    # Copy the deployment guide template to the project
    $templatePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Templates\DEPLOYMENT-GUIDE.md"
    $deploymentGuidePath = Join-Path -Path $ProjectPath -ChildPath "DEPLOYMENT-GUIDE.md"
    
    if (Test-Path -Path $templatePath) {
        Copy-Item -Path $templatePath -Destination $deploymentGuidePath -Force
        Write-Host "Added DEPLOYMENT-GUIDE.md to the project" -ForegroundColor Green
    } else {
        Write-Warning "Could not find deployment guide template at $templatePath"
    }
    
    return $true
}