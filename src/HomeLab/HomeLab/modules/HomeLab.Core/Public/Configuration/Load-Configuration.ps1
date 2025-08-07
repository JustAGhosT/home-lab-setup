function Initialize-Configuration {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log -Message "Loading configuration from: $ConfigPath" -Level "Info"
        
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Log -Message "Configuration file not found: $ConfigPath" -Level "Warning"
            
            # Check if we should create a default config
            $createDefault = Read-Host "Configuration file not found. Create default configuration? (Y/N)"
            if ($createDefault -eq "Y" -or $createDefault -eq "y") {
                # Create config directory if it doesn't exist
                $configDir = Split-Path -Path $ConfigPath -Parent
                if (-not (Test-Path -Path $configDir)) {
                    New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                }
                
                # Create default config with customized settings for South Africa
                $defaultConfig = @{
                    General = @{
                        DefaultSubscription = ""
                        DefaultResourceGroup = "HomeLab-BelaBelaLab"
                        DefaultLocation = "southafricanorth"  # South Africa North region
                        DefaultVNetName = "BelaBelaLab-VNet"
                        DefaultVNetAddressPrefix = "10.0.0.0/16"
                        DefaultSubnetName = "default"
                        DefaultSubnetAddressPrefix = "10.0.0.0/24"
                        Owner = "Jurie Smit"
                        Environment = "Development"
                    }
                    VPN = @{
                        GatewayName = "BelaBelaLab-VPNGateway"
                        GatewaySku = "VpnGw1"
                        ClientAddressPool = "172.16.0.0/24"
                        EnableBgp = $false
                        IsEnabled = $true
                        P2SConfiguration = @{
                            TunnelType = "OpenVPN"
                            AuthenticationType = "CertificateAuthentication"
                            RootCertName = "BelaBelaLabRootCert"
                        }
                    }
                    NAT = @{
                        GatewayName = "BelaBelaLab-NATGateway"
                        IdleTimeoutMinutes = 15
                        PublicIpCount = 1
                        ZoneRedundant = $false
                    }
                    Network = @{
                        Subnets = @(
                            @{
                                Name = "default"
                                AddressPrefix = "10.0.0.0/24"
                                ServiceEndpoints = @()
                                NatGateway = $false
                            },
                            @{
                                Name = "GatewaySubnet"
                                AddressPrefix = "10.0.1.0/24"
                                ServiceEndpoints = @()
                                NatGateway = $false
                            },
                            @{
                                Name = "AzureBastionSubnet"
                                AddressPrefix = "10.0.2.0/24"
                                ServiceEndpoints = @()
                                NatGateway = $false
                            },
                            @{
                                Name = "servers"
                                AddressPrefix = "10.0.3.0/24"
                                ServiceEndpoints = @("Microsoft.Storage", "Microsoft.Sql")
                                NatGateway = $true
                            }
                        )
                        NSGs = @{
                            DefaultRules = $true
                            CustomRules = @(
                                @{
                                    Name = "AllowRDP"
                                    Priority = 100
                                    Direction = "Inbound"
                                    Access = "Allow"
                                    Protocol = "Tcp"
                                    SourceAddressPrefix = "*"
                                    SourcePortRange = "*"
                                    DestinationAddressPrefix = "10.0.3.0/24"
                                    DestinationPortRange = "3389"
                                    Description = "Allow RDP to server subnet"
                                },
                                @{
                                    Name = "AllowSSH"
                                    Priority = 110
                                    Direction = "Inbound"
                                    Access = "Allow"
                                    Protocol = "Tcp"
                                    SourceAddressPrefix = "*"
                                    SourcePortRange = "*"
                                    DestinationAddressPrefix = "10.0.3.0/24"
                                    DestinationPortRange = "22"
                                    Description = "Allow SSH to server subnet"
                                }
                            )
                        }
                    }
                    Compute = @{
                        DefaultVMSize = "Standard_B2s"
                        DefaultAdminUsername = "homelabadmin"
                        DefaultImagePublisher = "MicrosoftWindowsServer"
                        DefaultImageOffer = "WindowsServer"
                        DefaultImageSku = "2022-Datacenter"
                        DefaultImageVersion = "latest"
                        VMs = @(
                            @{
                                Name = "dc01"
                                Size = "Standard_B2s"
                                SubnetName = "servers"
                                StaticIP = "10.0.3.4"
                                OSType = "Windows"
                                Role = "DomainController"
                                AutoShutdown = $true
                                ShutdownTime = "1900"
                                ShutdownTimeZone = "South Africa Standard Time"
                            }
                        )
                    }
                    Storage = @{
                        DefaultStorageAccountType = "Standard_LRS"
                        DefaultStorageAccountSku = "Standard_LRS"
                        DefaultStorageAccountKind = "StorageV2"
                        EnableHierarchicalNamespace = $false
                    }
                    UI = @{
                        Theme = "Dark"
                        ShowSplashScreen = $true
                        AutoSaveConfig = $true
                        ConfirmDeployments = $true
                        DefaultMonitoringMode = "Background"
                    }
                    Logging = @{
                        DefaultLogLevel = "Info"
                        MaxLogAgeDays = 30
                        EnableConsoleLogging = $true
                        EnableFileLogging = $true
                        EnableAzureMonitoring = $false
                    }
                    Tags = @{
                        Owner = "Jurie Smit"
                        Environment = "Development"
                        Project = "HomeLab"
                        CreatedBy = "HomeLab-Manager"
                        CreatedOn = (Get-Date -Format "yyyy-MM-dd")
                    }
                    Monitoring = @{
                        BackgroundMonitoringRefreshSeconds = 15
                        EnableResourceHealthAlerts = $true
                        EnableCostAlerts = $true
                        CostThreshold = 50
                        NotificationEmail = ""
                    }
                }
                
                $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding utf8
                Write-Log -Message "Created default configuration file: $ConfigPath" -Level "Success"
            }
            else {
                Write-Log -Message "User chose not to create default configuration" -Level "Warning"
                return $false
            }
        }
        
        # Load config file
        $script:State.Config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        $script:ConfigLoaded = $true
        
        Write-Log -Message "Configuration loaded successfully" -Level "Success"
        return $true
    }
    catch {
        Write-Log -Message "Failed to load configuration: $_" -Level "Error"
        return $false
    }
}
