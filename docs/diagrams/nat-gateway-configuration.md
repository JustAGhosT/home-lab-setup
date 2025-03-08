flowchart LR
  subgraph "Azure Virtual Network"
      subgraph "Subnets"
          WorkloadSubnet["Workload Subnet<br>10.0.1.0/24"]
          ManagementSubnet["Management Subnet<br>10.0.2.0/24"]
          DataSubnet["Data Subnet<br>10.0.3.0/24"]
      end
      
      NATGw["NAT Gateway"]
      PublicIP["Public IP Address<br>(Static)"]
      
      WorkloadSubnet --> NATGw
      ManagementSubnet --> NATGw
      DataSubnet --> NATGw
      NATGw --> PublicIP
  end
  
  VM1["VM in Workload<br>Private IP: 10.0.1.4"] --> WorkloadSubnet
  VM2["VM in Management<br>Private IP: 10.0.2.4"] --> ManagementSubnet
  VM3["VM in Data<br>Private IP: 10.0.3.4"] --> DataSubnet
  
  PublicIP --> Internet((Internet))
  
  %% Add notes about NAT Gateway
  note1["All outbound traffic uses<br>the same public IP"]
  note2["Inbound connections<br>are not supported"]
  note3["Can be disabled when<br>not needed to save costs"]
  
  NATGw --- note1
  PublicIP --- note2
  NATGw --- note3