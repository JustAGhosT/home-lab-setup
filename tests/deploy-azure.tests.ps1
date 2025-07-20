BeforeAll {
    # Path to the workflow file
    $workflowPath = Join-Path -Path $PSScriptRoot -ChildPath "..\deploy-azure.yml"
    
    # Import the workflow file content
    $workflowContent = Get-Content -Path $workflowPath -Raw
}

Describe "Deploy Azure Workflow Tests" {
    Context "Workflow File Structure" {
        It "Workflow file should exist" {
            Test-Path $workflowPath | Should -Be $true
        }

        It "Should be valid YAML" {
            { ConvertFrom-Yaml -Yaml $workflowContent } | Should -Not -Throw
        }
    }

    Context "Workflow Configuration" {
        BeforeAll {
            $workflow = ConvertFrom-Yaml -Yaml $workflowContent
        }

        It "Should have the correct name" {
            $workflow.name | Should -Be "Deploy to Azure with Custom Domain"
        }

        It "Should be triggered by workflow_dispatch" {
            $workflow.on.workflow_dispatch | Should -Not -BeNullOrEmpty
        }

        It "Should have required input parameters" {
            $inputs = $workflow.on.workflow_dispatch.inputs
            $inputs.deployment_type | Should -Not -BeNullOrEmpty
            $inputs.environment | Should -Not -BeNullOrEmpty
            $inputs.subdomain | Should -Not -BeNullOrEmpty
            $inputs.custom_domain | Should -Not -BeNullOrEmpty
            $inputs.azure_location | Should -Not -BeNullOrEmpty
        }
    }

    Context "Jobs Configuration" {
        BeforeAll {
            $workflow = ConvertFrom-Yaml -Yaml $workflowContent
        }

        It "Should have validate-inputs job" {
            $workflow.jobs.'validate-inputs' | Should -Not -BeNullOrEmpty
        }

        It "Should have build-and-test job" {
            $workflow.jobs.'build-and-test' | Should -Not -BeNullOrEmpty
        }

        It "Should have deploy-static job" {
            $workflow.jobs.'deploy-static' | Should -Not -BeNullOrEmpty
        }

        It "Should have deploy-appservice job" {
            $workflow.jobs.'deploy-appservice' | Should -Not -BeNullOrEmpty
        }

        It "Should have post-deployment job" {
            $workflow.jobs.'post-deployment' | Should -Not -BeNullOrEmpty
        }
    }

    Context "Job Dependencies" {
        BeforeAll {
            $workflow = ConvertFrom-Yaml -Yaml $workflowContent
        }

        It "build-and-test should depend on validate-inputs" {
            $workflow.jobs.'build-and-test'.needs | Should -Contain 'validate-inputs'
        }

        It "deploy-static should depend on validate-inputs and build-and-test" {
            $workflow.jobs.'deploy-static'.needs | Should -Contain 'validate-inputs'
            $workflow.jobs.'deploy-static'.needs | Should -Contain 'build-and-test'
        }

        It "deploy-appservice should depend on validate-inputs and build-and-test" {
            $workflow.jobs.'deploy-appservice'.needs | Should -Contain 'validate-inputs'
            $workflow.jobs.'deploy-appservice'.needs | Should -Contain 'build-and-test'
        }

        It "post-deployment should depend on validate-inputs, deploy-static, and deploy-appservice" {
            $workflow.jobs.'post-deployment'.needs | Should -Contain 'validate-inputs'
            $workflow.jobs.'post-deployment'.needs | Should -Contain 'deploy-static'
            $workflow.jobs.'post-deployment'.needs | Should -Contain 'deploy-appservice'
        }
    }

    Context "Deployment Type Logic" {
        BeforeAll {
            $workflow = ConvertFrom-Yaml -Yaml $workflowContent
        }

        It "deploy-static should run only when deployment_type is static" {
            $workflow.jobs.'deploy-static'.if | Should -Match "needs.validate-inputs.outputs.deployment_type == 'static'"
        }

        It "deploy-appservice should run only when deployment_type is appservice" {
            $workflow.jobs.'deploy-appservice'.if | Should -Match "needs.validate-inputs.outputs.deployment_type == 'appservice'"
        }
    }

    Context "Azure Authentication" {
        BeforeAll {
            $workflow = ConvertFrom-Yaml -Yaml $workflowContent
        }

        It "Should use Azure login action in deployment jobs" {
            $staticDeploySteps = $workflow.jobs.'deploy-static'.steps
            $appServiceDeploySteps = $workflow.jobs.'deploy-appservice'.steps
            
            $staticLoginStep = $staticDeploySteps | Where-Object { $_.name -eq "Azure Login" }
            $appServiceLoginStep = $appServiceDeploySteps | Where-Object { $_.name -eq "Azure Login" }
            
            $staticLoginStep | Should -Not -BeNullOrEmpty
            $appServiceLoginStep | Should -Not -BeNullOrEmpty
        }
    }

    Context "Custom Domain Configuration" {
        BeforeAll {
            $workflow = ConvertFrom-Yaml -Yaml $workflowContent
        }

        It "Should configure custom domain for static web apps when provided" {
            $staticDeploySteps = $workflow.jobs.'deploy-static'.steps
            $customDomainStep = $staticDeploySteps | Where-Object { $_.name -eq "Configure Custom Domain" }
            
            $customDomainStep | Should -Not -BeNullOrEmpty
            $customDomainStep.if | Should -Match "github.event.inputs.custom_domain != ''"
        }

        It "Should configure custom domain for app service when provided" {
            $appServiceDeploySteps = $workflow.jobs.'deploy-appservice'.steps
            $customDomainStep = $appServiceDeploySteps | Where-Object { $_.name -eq "Configure Custom Domain" }
            
            $customDomainStep | Should -Not -BeNullOrEmpty
            $customDomainStep.if | Should -Match "github.event.inputs.custom_domain != ''"
        }
    }
}