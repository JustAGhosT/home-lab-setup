sequenceDiagram
  participant Client as Client Computer
  participant VPNClient as VPN Client Software
  participant VPNGw as Azure VPN Gateway
  participant VNet as Azure Virtual Network
  participant Resources as Azure Resources
  
  Client->>VPNClient: Initiate VPN Connection
  VPNClient->>VPNGw: Connection Request with Client Certificate
  VPNGw->>VPNGw: Validate Certificate
  VPNGw->>VPNClient: Establish Encrypted Tunnel
  VPNClient->>Client: Connection Established
  
  Note over Client,VPNGw: Secure Tunnel Established
  
  Client->>VPNGw: Request Access to Resources
  VPNGw->>VNet: Route Traffic to Appropriate Subnet
  VNet->>Resources: Forward Request to Resource
  Resources->>VNet: Response
  VNet->>VPNGw: Route Response
  VPNGw->>Client: Deliver Response through Tunnel