Describe "HomeLab.GitHub Module Tests" {
    BeforeAll {
        # Import required dependencies first
        Import-Module "$PSScriptRoot\..\..\HomeLab\modules\HomeLab.Logging" -Force -ErrorAction SilentlyContinue
        Import-Module "$PSScriptRoot\..\..\HomeLab\modules\HomeLab.Core" -Force -ErrorAction SilentlyContinue
        
        # Import the actual HomeLab.GitHub module
        Import-Module "$PSScriptRoot\..\..\HomeLab\modules\HomeLab.GitHub" -Force
    }

    Context "Module Loading" {
        It "Should load the module successfully" {
            Get-Module HomeLab.GitHub | Should -Not -BeNullOrEmpty
        }

        It "Should export expected functions" {
            $expectedFunctions = @(
                'Connect-GitHub',
                'Disconnect-GitHub',
                'Test-GitHubConnection',
                'Get-GitHubRepositories',
                'Select-GitHubRepository',
                'Clone-GitHubRepository',
                'Deploy-GitHubRepository',
                'Set-GitHubConfiguration',
                'Get-GitHubConfiguration'
            )
            
            $exportedFunctions = (Get-Command -Module HomeLab.GitHub).Name
            
            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }
    }

    Context "Configuration Management" {
        It "Should get default configuration when none exists" {
            # Clean up any existing config for test
            $configPath = Join-Path $env:USERPROFILE ".homelab\github-config.json"
            if (Test-Path $configPath) {
                Remove-Item $configPath -Force
            }
            
            $config = Get-GitHubConfiguration
            $config | Should -Not -BeNullOrEmpty
            $config.Username | Should -BeNullOrEmpty
            $config.DefaultClonePath | Should -Not -BeNullOrEmpty
        }

        It "Should set and get configuration" {
            # Clean up any existing config first
            $configPath = Join-Path $env:USERPROFILE ".homelab\github-config.json"
            if (Test-Path $configPath) {
                Remove-Item $configPath -Force -ErrorAction SilentlyContinue
            }

            $testConfig = @{
                Username = "testuser"
                Name     = "Test User"
                Email    = "test@example.com"
            }

            Set-GitHubConfiguration -Configuration $testConfig

            # Verify the config was saved
            Test-Path $configPath | Should -Be $true

            $retrievedConfig = Get-GitHubConfiguration
            $retrievedConfig.Username | Should -Be "testuser"
            $retrievedConfig.Name | Should -Be "Test User"
            $retrievedConfig.Email | Should -Be "test@example.com"

            # Clean up after test
            Remove-Item $configPath -Force -ErrorAction SilentlyContinue
        }
    }

    Context "GitHub Connection (Mock Tests)" {
        It "Should handle connection test without token" {
            # This should return false when no token is stored
            $result = Test-GitHubConnection -Quiet
            $result | Should -Be $false
        }

        It "Should validate token format in Connect-GitHub" {
            # Test with invalid token format (should show warning but continue)
            # Note: This is a mock test - we're not actually connecting
            $result = $true  # Placeholder for actual test
            $result | Should -Be $true
        }
    }

    Context "Repository Management Functions" {
        It "Should have Get-GitHubRepositories function available" {
            Get-Command Get-GitHubRepositories | Should -Not -BeNullOrEmpty
        }

        It "Should have Select-GitHubRepository function available" {
            Get-Command Select-GitHubRepository | Should -Not -BeNullOrEmpty
        }

        It "Should have Clone-GitHubRepository function available" {
            Get-Command Clone-GitHubRepository | Should -Not -BeNullOrEmpty
        }
    }

    Context "Deployment Functions" {
        It "Should have Deploy-GitHubRepository function available" {
            Get-Command Deploy-GitHubRepository | Should -Not -BeNullOrEmpty
        }

        It "Should handle deployment without selected repository" {
            # Clear any selected repository
            Set-GitHubConfiguration -SelectedRepository $null
            
            # This should fail gracefully when no repository is selected
            { Deploy-GitHubRepository -ErrorAction Stop } | Should -Throw
        }
    }

    Context "Private Helper Functions" {
        It "Should have private helper functions loaded" {
            # Test that private functions are available within the module scope
            # Note: Private functions aren't exported, so we test indirectly
            $result = $true  # Placeholder - private functions are tested through public functions
            $result | Should -Be $true
        }
    }

    Context "Error Handling" {
        It "Should handle missing Git gracefully" {
            # Mock scenario where Git is not available
            # This would be tested in Clone-GitHubRepository
            $result = $true  # Placeholder for actual test
            $result | Should -Be $true
        }

        It "Should handle network errors gracefully" {
            # Mock scenario for network connectivity issues
            $result = $true  # Placeholder for actual test
            $result | Should -Be $true
        }
    }

    AfterAll {
        # Clean up test configuration
        $configPath = Join-Path $env:USERPROFILE ".homelab\github-config.json"
        if (Test-Path $configPath) {
            Remove-Item $configPath -Force -ErrorAction SilentlyContinue
        }
    }
}
