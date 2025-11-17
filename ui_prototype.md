# UI Prototype for HomeLab Tauri App

## 1. Overall Layout

The application will use a sidebar navigation layout.

- **Sidebar (Left):** A fixed-width vertical bar containing navigation links.
- **Main Content (Right):** A larger area that displays the content for the selected navigation link.

## 2. Sidebar Navigation

The sidebar will contain the following navigation links:

- **Dashboard:** A home screen with a summary of the application's status.
- **Deployment:** A section for managing deployments.
- **VPN Management:** A section with sub-menus for managing VPNs.
  - **Certificates:** Manage VPN certificates.
  - **Gateway:** Manage the VPN gateway.
  - **Client:** Manage the VPN client.
- **NAT Gateway:** A section for managing the NAT gateway.
- **Documentation:** A section for viewing documentation.
- **Settings:** A section for configuring the application.

## 3. Main Content Views

### 3.1. Dashboard

- **Title:** Dashboard
- **Content:**
  - Display the current status of the Azure connection.
  - Show the last deployment date and time.
  - Provide a summary of the available resources.

### 3.2. Deployment

- **Title:** Deployment
- **Content:**
  - A button to start a new deployment.
  - A table displaying the status of the current deployment.
  - A log viewer to display the output of the deployment script.

### 3.3. VPN Management

- This section will have a sub-navigation for Certificates, Gateway, and Client.

#### 3.3.1. Certificates

- **Title:** VPN Certificates
- **Content:**
  - A button to generate a new VPN certificate.
  - A table displaying the existing VPN certificates.

#### 3.3.2. Gateway

- **Title:** VPN Gateway
- **Content:**
  - A button to create a new VPN gateway.
  - A table displaying the status of the current VPN gateway.

#### 3.3.3. Client

- **Title:** VPN Client
- **Content:**
  - A button to configure the VPN client.
  - A form for entering the VPN client configuration details.

### 3.4. NAT Gateway

- **Title:** NAT Gateway
- **Content:**
  - A button to create a new NAT gateway.
  - A table displaying the status of the current NAT gateway.

### 3.5. Documentation

- **Title:** Documentation
- **Content:**
  - A simple markdown renderer to display the application's documentation.

### 3.6. Settings

- **Title:** Settings
- **Content:**
  - A form for configuring the application's settings.
  - A button to save the settings.
