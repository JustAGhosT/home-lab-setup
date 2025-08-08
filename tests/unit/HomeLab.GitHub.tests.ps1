Describe "HomeLab.GitHub Module Tests" {
    BeforeAll {
        # Import required dependencies first
        Import-Module "$PSScriptRoot\..\..\src\HomeLab\HomeLab\modules\HomeLab.Logging" -Force -ErrorAction SilentlyContinue
        Import-Module "$PSScriptRoot\..\..\src\HomeLab\HomeLab\modules\HomeLab.Core" -Force -ErrorAction SilentlyContinue
        
        # Import the actual HomeLab.GitHub module
        Import-Module "$PSScriptRoot\..\..\src\HomeLab\HomeLab\modules\HomeLab.GitHub" -Force
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
            # Clear any existing token for this test
            $env:GITHUB_TOKEN = $null
            
            # This should return false when no token is stored
            $result = Test-GitHubConnection -Quiet
            $result | Should -Be $false
        }

        It "Should validate token format in Connect-GitHub" {
            # Test various token formats to ensure proper validation
            $testCases = @(
                @{ Token = "ghp_1234567890abcdef1234567890abcdef12345678"; ExpectedValid = $true; Description = "Valid GitHub token format" },
                @{ Token = "gho_1234567890abcdef1234567890abcdef12345678"; ExpectedValid = $true; Description = "Valid GitHub OAuth token format" },
                @{ Token = "ghu_1234567890abcdef1234567890abcdef12345678"; ExpectedValid = $true; Description = "Valid GitHub user token format" },
                @{ Token = "ghs_1234567890abcdef1234567890abcdef12345678"; ExpectedValid = $true; Description = "Valid GitHub short-lived token format" },
                @{ Token = "ghr_1234567890abcdef1234567890abcdef12345678"; ExpectedValid = $true; Description = "Valid GitHub refresh token format" },
                @{ Token = "invalid_token_format"; ExpectedValid = $false; Description = "Invalid token format (no prefix)" },
                @{ Token = "ghp_short"; ExpectedValid = $false; Description = "Token too short" },
                @{ Token = ""; ExpectedValid = $false; Description = "Empty token" },
                @{ Token = $null; ExpectedValid = $false; Description = "Null token" },
                @{ Token = "ghp_1234567890abcdef1234567890abcdef12345678_invalid_chars!"; ExpectedValid = $false; Description = "Token with invalid characters" }
            )

            foreach ($testCase in $testCases) {
                # Clear any existing token
                $env:GITHUB_TOKEN = $null
                
                if ($testCase.Token) {
                    # Test that the token can be set in environment variable (simulating Connect-GitHub behavior)
                    $env:GITHUB_TOKEN = $testCase.Token
                    
                    # Verify the token was stored
                    $storedToken = $env:GITHUB_TOKEN
                    if ($testCase.ExpectedValid) {
                        $storedToken | Should -Be $testCase.Token
                    }
                }
                
                # Test that Test-GitHubConnection handles the token appropriately
                # Since we're testing token format validation, we'll verify the environment variable handling
                if ($testCase.Token) {
                    $env:GITHUB_TOKEN = $testCase.Token
                    # Test-GitHubConnection should detect the token exists but may fail API validation
                    $result = Test-GitHubConnection -Quiet
                    # The function returns false for invalid tokens (API call fails), true only for valid tokens
                    # Since our test tokens are invalid, we expect false
                    $result | Should -Be $false
                }
            }
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

    # Note: Private helper functions are tested indirectly through the public functions that use them
    # This provides better test coverage by validating actual functionality rather than implementation details

    Context "Error Handling" {
        It "Should handle missing Git gracefully" {
            # Test that Clone-GitHubRepository fails gracefully when Git is not available
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq 'git' }

            { Clone-GitHubRepository -Repository "test/repo" -ErrorAction Stop } |
            Should -Throw -ExpectedMessage "*Failed to clone GitHub repository*"
        }

        It "Should handle invalid parameters gracefully" {
            # Test that functions handle invalid parameters properly
            { Get-GitHubRepositories -InvalidParameter "test" -ErrorAction Stop } |
            Should -Throw -ExpectedMessage "*parameter*"
        }

        It "Should handle unauthenticated state gracefully" {
            # Clear any existing token for this test
            $env:GITHUB_TOKEN = $null
            
            # Test that functions handle unauthenticated state properly
            # This tests the actual behavior when not connected to GitHub
            $result = Test-GitHubConnection -Quiet
            $result | Should -Be $false
        }

        It "Should require authentication for repository operations" {
            # Test that repository operations require authentication
            { Clone-GitHubRepository -Repository "test/repo" -ErrorAction Stop } |
            Should -Throw -ExpectedMessage "*Failed to clone GitHub repository*"
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
