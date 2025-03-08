flowchart TD
  subgraph "Cost Management"
      NATGwManagement["NAT Gateway Management"]
      VPNGwSizing["VPN Gateway Sizing"]
      VMOptimization["VM Optimization"]
  end
  
  subgraph "NAT Gateway States"
      NATEnabled["NAT Gateway Enabled<br>~$32/month + data"]
      NATDisabled["NAT Gateway Disabled<br>$0/month"]
  end
  
  subgraph "VPN Gateway Options"
      BasicSKU["Basic SKU<br>~$27/month<br>Max 250 Mbps"]
      VpnGw1SKU["VpnGw1 SKU<br>~$138/month<br>Max 650 Mbps"]
  end
  
  subgraph "VM Strategies"
      AutoShutdown["Auto-Shutdown<br>During Off Hours"]
      RightSizing["Right-sizing VMs<br>Based on Workload"]
      BurstableVMs["B-Series VMs<br>For Dev/Test"]
  end
  
  NATGwManagement --> NATEnabled
  NATGwManagement --> NATDisabled
  NATEnabled -- "When Internet Access<br>is Required" --> NATDisabled
  NATDisabled -- "When Internet Access<br>is Needed" --> NATEnabled
  
  VPNGwSizing --> BasicSKU
  VPNGwSizing --> VpnGw1SKU
  
  VMOptimization --> AutoShutdown
  VMOptimization --> RightSizing
  VMOptimization --> BurstableVMs
  
  %% Add styling
  classDef costSaving fill:#bfb,stroke:#333,stroke-width:2px
  classDef costIncurring fill:#fbb,stroke:#333,stroke-width:2px
  classDef strategy fill:#bbf,stroke:#333,stroke-width:2px
  
  class NATGwManagement,VPNGwSizing,VMOptimization strategy
  class NATDisabled,BasicSKU,AutoShutdown,RightSizing,BurstableVMs costSaving
  class NATEnabled,VpnGw1SKU costIncurring