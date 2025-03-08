flowchart TD
  subgraph "Azure Cloud"
      VNet["Azure Virtual Network<br>10.0.0.0/16"]
      
      subgraph "Network Components"
          VPNGw["VPN Gateway<br>Point-to-Site"]
          NATGw["NAT Gateway<br>Outbound Internet"]
          NSG["Network Security Groups"]
      end
      
      subgraph "Subnets"
          GwSubnet["GatewaySubnet<br>10.0.0.0/24"]
          WorkloadSubnet["Workload Subnet<br>10.0.1.0/24"]
          ManagementSubnet["Management Subnet<br>10.0.2.0/24"]
          DataSubnet["Data Subnet<br>10.0.3.0/24"]
      end
      
      VNet --> Network Components
      VNet --> Subnets
      
      VPNGw --> GwSubnet
      NATGw --> WorkloadSubnet
      NATGw --> ManagementSubnet
      NATGw --> DataSubnet
      
      NSG --> WorkloadSubnet
      NSG --> ManagementSubnet
      NSG --> DataSubnet
  end
  
  subgraph "On-Premises / Home"
      Client1["Client Computer 1"]
      Client2["Client Computer 2"]
      MobileDevice["Mobile Device"]
  end
  
  Client1 -- "VPN Connection<br>Certificate Auth" --> VPNGw
  Client2 -- "VPN Connection<br>Certificate Auth" --> VPNGw
  MobileDevice -- "VPN Connection<br>Certificate Auth" --> VPNGw
  
  Internet((Internet)) -- "Outbound Traffic" --> NATGw