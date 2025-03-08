# High-Level Architecture

## Overview
This document outlines the high-level architecture of our Azure cloud environment, detailing the virtual network design, network components, subnet layout, and connectivity from on-premises or home environments.

## Architecture Diagram

```mermaid
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
```

## Core Components

### Azure Virtual Network
- **Address Space**: 10.0.0.0/16 (65,536 IP addresses)
- **Purpose**: Provides isolated network environment for all Azure resources
- **Region**: Primary deployment in East US 2 for optimal performance/cost balance

### Network Components

#### VPN Gateway
- **Type**: Point-to-Site VPN Gateway
- **Authentication**: Certificate-based authentication
- **SKU**: Basic (upgradable to VpnGw1 as needed)
- **Purpose**: Enables secure remote access from client devices to Azure resources

#### NAT Gateway
- **Configuration**: Single public IP address for outbound connectivity
- **Purpose**: Provides outbound internet access for resources in all subnets
- **Management**: Can be enabled/disabled to optimize costs

#### Network Security Groups (NSGs)
- **Implementation**: Subnet-level NSGs with specific rules for each subnet
- **Purpose**: Enforces network-level security policies and access controls
- **Management**: Centrally managed through Azure Policy

### Subnet Layout

#### GatewaySubnet
- **Address Range**: 10.0.0.0/24 (254 usable IPs)
- **Purpose**: Reserved for Azure VPN Gateway
- **Note**: No other resources should be deployed in this subnet

#### Workload Subnet
- **Address Range**: 10.0.1.0/24 (254 usable IPs)
- **Purpose**: Hosts application servers, web servers, and workload VMs
- **Security**: Protected by NSG with application-specific rules

#### Management Subnet
- **Address Range**: 10.0.2.0/24 (254 usable IPs)
- **Purpose**: Hosts jump boxes and administrative tools
- **Security**: Highly restricted access through NSG rules

#### Data Subnet
- **Address Range**: 10.0.3.0/24 (254 usable IPs)
- **Purpose**: Hosts database servers and storage resources
- **Security**: Limited access from workload and management subnets only

## Connectivity

### Remote Access
- Client devices connect via Point-to-Site VPN using certificate authentication
- VPN client configuration distributed to authorized users
- Mobile device support through Azure VPN Client app

### Internet Connectivity
- Outbound internet access provided through NAT Gateway
- Single public IP for all outbound connections
- No direct inbound access from the internet to any resources

## Security Considerations
- All subnets protected by NSGs with principle of least privilege
- No direct internet exposure of any resources
- Certificate-based authentication for VPN access
- Regular security assessments and compliance checks

## Scalability and Future Expansion
- Virtual network design allows for additional subnets as needed
- VPN Gateway can be upgraded to support more connections
- NAT Gateway can scale to support increased outbound traffic
