flowchart TD
  subgraph "Certificate Authority Management"
      GenRootCert["Generate Root Certificate"]
      ExportRootCert["Export Root Certificate<br>Public Key"]
      UploadToAzure["Upload Public Key<br>to Azure VPN Gateway"]
  end
  
  subgraph "Client Certificate Management"
      GenClientCert["Generate Client Certificate<br>from Root Certificate"]
      ExportClientCert["Export Client Certificate<br>with Private Key (.pfx)"]
      InstallClientCert["Install Client Certificate<br>on End-User Device"]
  end
  
  subgraph "VPN Configuration"
      ConfigVPN["Configure VPN Client<br>with Azure VPN Profile"]
      ConnectVPN["Connect to VPN using<br>Installed Certificate"]
  end
  
  GenRootCert --> ExportRootCert
  ExportRootCert --> UploadToAzure
  GenRootCert --> GenClientCert
  GenClientCert --> ExportClientCert
  ExportClientCert --> InstallClientCert
  UploadToAzure --> ConfigVPN
  InstallClientCert --> ConfigVPN
  ConfigVPN --> ConnectVPN