# Unit tests for HomeLab.Core module

Describe "HomeLab.Core Module Tests" {
    BeforeAll {
        # Import the mock module
        $mockPath = "$PSScriptRoot\HomeLab.Core.Mock.ps1"
        if (Test-Path $mockPath) {
            . $mockPath
        } else {
            Write-Warning "Mock module not found at path: $mockPath"
        }
        
        # Create test directory for file operations
        $script:TestDir = "$env:TEMP\HomeLab-Tests"
        New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
        $script:TestConfigPath = Join-Path $script:TestDir "config.json"
    }
    
    Context "Configuration Management" {
        BeforeEach {
            # Reset the mock configuration before each test
            Reset-Configuration
            Initialize-Configuration
        }
        
        It "Should initialize configuration with default values" {
            $config = Get-Configuration
            $config.Environment | Should -Be "dev"
            $config.AzureLocation | Should -Be "eastus"
            $config.ProjectName | Should -Be "homelab"
        }
        
        It "Should get configuration values correctly" {
            $value = Get-ConfigValue -Key "Environment"
            $value | Should -Be "dev"
            
            $value = Get-ConfigValue -Key "ProjectName"
            $value | Should -Be "homelab"
        }
        
        It "Should update configuration values correctly" {
            Set-ConfigValue -Key "Environment" -Value "prod"
            Set-ConfigValue -Key "AzureLocation" -Value "westus2"
            
            $config = Get-Configuration
            $config.Environment | Should -Be "prod"
            $config.AzureLocation | Should -Be "westus2"
        }
        
        It "Should remove configuration values correctly" {
            Set-ConfigValue -Key "TestKey" -Value "TestValue"
            Get-ConfigValue -Key "TestKey" | Should -Be "TestValue"
            
            Remove-ConfigValue -Key "TestKey" | Should -Be $true
            Get-ConfigValue -Key "TestKey" | Should -BeNullOrEmpty
        }
        
        It "Should backup and restore configuration" {
            # Set initial values
            Set-ConfigValue -Key "Environment" -Value "dev"
            Set-ConfigValue -Key "TestKey" -Value "TestValue"
            
            # Backup config
            $backupPath = Backup-Configuration
            
            # Modify config
            Set-ConfigValue -Key "Environment" -Value "changed"
            Get-ConfigValue -Key "Environment" | Should -Be "changed"
            
            # Restore config
            Restore-Configuration
            Get-ConfigValue -Key "Environment" | Should -Be "dev"
        }
    }
    
    Context "Path Validation" {
        It "Should validate correct paths" {
            # The mock function is set up to return true for paths without special characters
            $result = Test-ValidPath -Path "C:\valid\path"
            $result | Should -Be $true
        }
        
        It "Should reject invalid paths with special characters" {
            $result = Test-ValidPath -Path "C:\invalid\path:with*chars"
            $result | Should -Be $false
        }
    }
    
    Context "Module Version" {
        It "Should return a valid version" {
            $version = Get-ModuleVersion
            $version | Should -Be "1.0.0"
        }
    }
    
    Context "Utility Functions" {
        It "Should convert PSCustomObject to hashtable" {
            $obj = [PSCustomObject]@{
                Name = "Test"
                Value = 123
            }
            
            $result = ConvertTo-Hashtable -InputObject $obj
            $result | Should -BeOfType [Hashtable]
            $result.Name | Should -Be "Test"
            $result.Value | Should -Be 123
        }
        
        It "Should write log messages safely" {
            $result = Write-SafeLog -Message "Test message" -Level "Info"
            $result | Should -Be "Info - Test message"
            
            $result = Write-SafeLog -Message "Error occurred" -Level "Error"
            $result | Should -Be "Error - Error occurred"
        }
    }
    
    AfterAll {
        # Clean up test directory if it exists
        if (Test-Path -Path $script:TestDir) {
            Remove-Item -Path $script:TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}