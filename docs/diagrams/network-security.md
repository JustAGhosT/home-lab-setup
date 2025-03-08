# Network Security

## Overview
This document outlines the network security architecture implemented in our Azure environment, focusing on Network Security Groups (NSGs), traffic flow controls, and security best practices to protect resources across different subnets.

## Network Security Architecture

```mermaid
flowchart TD
  subgraph AzureVNet["Azure Virtual Network"]
      NSG1["Management Subnet NSG"]
      NSG2["Workload Subnet NSG"]
      NSG3["Data Subnet NSG"]
      
      subgraph ManagementSubnet["Management Subnet"]
          JumpBox["Jump Box VM"]
          AdminTools["Admin Tools VM"]
      end
      
      subgraph WorkloadSubnet["Workload Subnet"]
          AppServer1["Application Server 1"]
          AppServer2["Application Server 2"]
          WebServer["Web Server"]
      end
      
      subgraph DataSubnet["Data Subnet"]
          Database["Database Server"]
          Storage["Storage Account"]
      end
      
      NSG1 --> ManagementSubnet
      NSG2 --> WorkloadSubnet
      NSG3 --> DataSubnet
  end
  
  VPNGw["VPN Gateway"] -- "RDP (3389)<br>SSH (22)" --> NSG1
  VPNGw -- "HTTP(S) (80/443)<br>Custom App Ports" --> NSG2
  
  ManagementSubnet -- "Restricted Access<br>to Data Tier" --> NSG3
  WorkloadSubnet -- "SQL (1433)<br>Storage API" --> NSG3
  
  Internet((Internet)) -- "Blocked Direct Access" -.-> NSG1
  Internet -- "Blocked Direct Access" -.-> NSG2
  Internet -- "Blocked Direct Access" -.-> NSG3
  
  classDef blocked stroke:#f00,stroke-width:2px,color:#f00
  class "Blocked Direct Access" blocked
```

## Network Security Group Configurations

### Management Subnet NSG
| Priority | Name | Direction | Access | Protocol | Source | Destination | Ports | Description |
|----------|------|-----------|--------|----------|--------|-------------|-------|-------------|
| 100 | Allow_VPN_RDP | Inbound | Allow | TCP | VPN Gateway | Management Subnet | 3389 | Allow RDP from VPN clients |
| 110 | Allow_VPN_SSH | Inbound | Allow | TCP | VPN Gateway | Management Subnet | 22 | Allow SSH from VPN clients |
| 120 | Allow_ICMP | Inbound | Allow | ICMP | VirtualNetwork | Management Subnet | * | Allow ping within VNet |
| 4000 | Deny_All_Inbound | Inbound | Deny | * | * | * | * | Block all other inbound traffic |
| 100 | Allow_Outbound_HTTP | Outbound | Allow | TCP | Management Subnet | Internet | 80, 443 | Allow HTTP(S) outbound |
| 110 | Allow_Outbound_DNS | Outbound | Allow | * | Management Subnet | Internet | 53 | Allow DNS resolution |
| 120 | Allow_Workload_Management | Outbound | Allow | * | Management Subnet | Workload Subnet | * | Allow access to workload resources |
| 130 | Allow_Data_Management | Outbound | Allow | TCP | Management Subnet | Data Subnet | 1433, 445 | Allow SQL and SMB access to data tier |

### Workload Subnet NSG
| Priority | Name | Direction | Access | Protocol | Source | Destination | Ports | Description |
|----------|------|-----------|--------|----------|--------|-------------|-------|-------------|
| 100 | Allow_VPN_HTTP | Inbound | Allow | TCP | VPN Gateway | Workload Subnet | 80, 443 | Allow HTTP(S) from VPN clients |
| 110 | Allow_VPN_Custom | Inbound | Allow | TCP | VPN Gateway | Workload Subnet | 8080-8090 | Allow custom application ports |
| 120 | Allow_Management_Access | Inbound | Allow | * | Management Subnet | Workload Subnet | * | Allow management access |
| 4000 | Deny_All_Inbound | Inbound | Deny | * | * | * | * | Block all other inbound traffic |
| 100 | Allow_Outbound_HTTP | Outbound | Allow | TCP | Workload Subnet | Internet | 80, 443 | Allow HTTP(S) outbound |
| 110 | Allow_Outbound_DNS | Outbound | Allow | * | Workload Subnet | Internet | 53 | Allow DNS resolution |
| 120 | Allow_Data_Access | Outbound | Allow | TCP | Workload Subnet | Data Subnet | 1433, 445 | Allow SQL and SMB access to data tier |

### Data Subnet NSG
| Priority | Name | Direction | Access | Protocol | Source | Destination | Ports | Description |
|----------|------|-----------|--------|----------|--------|-------------|-------|-------------|
| 100 | Allow_Workload_SQL | Inbound | Allow | TCP | Workload Subnet | Data Subnet | 1433 | Allow SQL from workload tier |
| 110 | Allow_Workload_Storage | Inbound | Allow | TCP | Workload Subnet | Data Subnet | 445 | Allow SMB from workload tier |
| 120 | Allow_Management_Access | Inbound | Allow | * | Management Subnet | Data Subnet | * | Allow management access |
| 4000 | Deny_All_Inbound | Inbound | Deny | * | * | * | * | Block all other inbound traffic |
| 100 | Allow_Outbound_HTTP | Outbound | Allow | TCP | Data Subnet | Internet | 80, 443 | Allow HTTP(S) outbound |
| 110 | Allow_Outbound_DNS | Outbound | Allow | * | Data Subnet | Internet | 53 | Allow DNS resolution |

## Security Best Practices

### Zero Trust Principles
- No direct internet access to any resources
- All access requires VPN authentication
- Subnet isolation with explicit allow rules
- Principle of least privilege for all communications

### NSG Management
- Use service tags where applicable (e.g., VirtualNetwork, Internet)
- Document all custom rules with clear descriptions
- Implement NSG flow logs for traffic analysis
- Regular review of NSG rules to remove unnecessary access

### Additional Security Controls
- Just-in-time VM access for management VMs
- Azure Security Center integration for threat detection
- Regular security assessments and penetration testing
- Network Watcher packet capture for troubleshooting

## Monitoring and Compliance

### Monitoring Setup
- NSG flow logs sent to Log Analytics workspace
- Security alerts for suspicious activity
- Regular review of traffic patterns

### Compliance Requirements
- All internet-bound traffic routed through NAT Gateway
- No direct public IP addresses assigned to VMs
- All management access requires VPN authentication
- Data tier isolated from direct external access

## Implementation and Maintenance
- NSGs deployed and managed through Infrastructure as Code (ARM templates)
- Changes follow change management process with security review
- Regular testing of security controls through simulated attacks
- Documentation updated with each configuration change
