flowchart TD
  subgraph "Azure Virtual Network"
      NSG1["Management Subnet NSG"]
      NSG2["Workload Subnet NSG"]
      NSG3["Data Subnet NSG"]
      
      subgraph "Management Subnet"
          JumpBox["Jump Box VM"]
          AdminTools["Admin Tools VM"]
      end
      
      subgraph "Workload Subnet"
          AppServer1["Application Server 1"]
          AppServer2["Application Server 2"]
          WebServer["Web Server"]
      end
      
      subgraph "Data Subnet"
          Database["Database Server"]
          Storage["Storage Account"]
      end
      
      NSG1 --> Management Subnet
      NSG2 --> Workload Subnet
      NSG3 --> Data Subnet
  end
  
  VPNGw["VPN Gateway"] -- "RDP (3389)<br>SSH (22)" --> NSG1
  VPNGw -- "HTTP(S) (80/443)<br>Custom App Ports" --> NSG2
  
  Management Subnet -- "Restricted Access<br>to Data Tier" --> NSG3
  Workload Subnet -- "SQL (1433)<br>Storage API" --> NSG3
  
  Internet((Internet)) -- "Blocked Direct Access" -.-> NSG1
  Internet -- "Blocked Direct Access" -.-> NSG2
  Internet -- "Blocked Direct Access" -.-> NSG3
  
  classDef blocked stroke:#f00,stroke-width:2px,color:#f00
  class "Blocked Direct Access" blocked