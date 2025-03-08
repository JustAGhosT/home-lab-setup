flowchart TD
  subgraph "Client Side"
      Client["Client Computer"]
      VPNClient["VPN Client Software"]
  end
  
  subgraph "Azure Cloud"
      VPNGw["VPN Gateway"]
      
      subgraph "Virtual Network"
          RouteTable["Route Table"]
          
          subgraph "Subnets"
              ManagementSubnet["Management Subnet"]
              WorkloadSubnet["Workload Subnet"]
              DataSubnet["Data Subnet"]
          end
          
          VM1["Jump Box VM<br>10.0.2.4"]
          VM2["App Server VM<br>10.0.1.4"]
          VM3["Database VM<br>10.0.3.4"]
      end
      
      NATGw["NAT Gateway"]
      Internet((Internet))
  end
  
  Client --> VPNClient
  VPNClient -- "Encrypted Traffic" --> VPNGw
  
  VPNGw --> RouteTable
  RouteTable -- "10.0.2.0/24" --> ManagementSubnet
  RouteTable -- "10.0.1.0/24" --> WorkloadSubnet
  RouteTable -- "10.0.3.0/24" --> DataSubnet
  
  ManagementSubnet --> VM1
  WorkloadSubnet --> VM2
  DataSubnet --> VM3
  
  VM1 -- "RDP/SSH Access" --> VM2
  VM2 -- "Database Queries" --> VM3
  
  VM1 -- "Outbound Traffic" --> NATGw
  VM2 -- "Outbound Traffic" --> NATGw
  VM3 -- "Outbound Traffic" --> NATGw
  
  NATGw --> Internet
  
  %% Add styling
  classDef vpn fill:#f9f,stroke:#333,stroke-width:2px
  classDef management fill:#bfb,stroke:#333,stroke-width:2px
  classDef workload fill:#bbf,stroke:#333,stroke-width:2px
  classDef data fill:#fbb,stroke:#333,stroke-width:2px
  
  class VPNGw,VPNClient vpn
  class ManagementSubnet,VM1 management
  class WorkloadSubnet,VM2 workload
  class DataSubnet,VM3 data