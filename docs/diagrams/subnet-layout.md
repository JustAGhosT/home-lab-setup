graph TB
  VNet["Azure Virtual Network<br>10.0.0.0/16"]
  
  VNet --> GwSubnet["GatewaySubnet<br>10.0.0.0/24<br><i>Reserved for VPN Gateway</i>"]
  VNet --> WorkloadSubnet["Workload Subnet<br>10.0.1.0/24<br><i>Application VMs, Web Servers</i>"]
  VNet --> ManagementSubnet["Management Subnet<br>10.0.2.0/24<br><i>Jump Boxes, Admin Tools</i>"]
  VNet --> DataSubnet["Data Subnet<br>10.0.3.0/24<br><i>Databases, Storage</i>"]
  VNet --> FutureSubnet["Future Expansion<br>10.0.4.0/24<br><i>Reserved for future use</i>"]
  
  WorkloadVM1["VM: app-vm-01<br>10.0.1.4"] --> WorkloadSubnet
  WorkloadVM2["VM: web-vm-01<br>10.0.1.5"] --> WorkloadSubnet
  
  JumpBox["VM: jump-box-01<br>10.0.2.4"] --> ManagementSubnet
  AdminTools["VM: admin-tools-01<br>10.0.2.5"] --> ManagementSubnet
  
  Database["VM: sql-vm-01<br>10.0.3.4"] --> DataSubnet
  Storage["Storage Account<br>Private Endpoint: 10.0.3.5"] --> DataSubnet
  
  style GwSubnet fill:#f9f,stroke:#333,stroke-width:2px
  style WorkloadSubnet fill:#bbf,stroke:#333,stroke-width:2px
  style ManagementSubnet fill:#bfb,stroke:#333,stroke-width:2px
  style DataSubnet fill:#fbb,stroke:#333,stroke-width:2px
  style FutureSubnet fill:#ddd,stroke:#333,stroke-width:1px,stroke-dasharray: 5 5