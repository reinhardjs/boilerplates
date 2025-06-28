# Azure Infrastructure Setup with Terraform

This project provides a complete infrastructure setup for Azure using Terraform, including all necessary resources for a containerized application with PostgreSQL database.

## Prerequisites

- Azure CLI installed
- Terraform installed (version >= 1.0)
- Git installed
- A valid Azure subscription

## Infrastructure Components

This setup creates the following Azure resources:

- **Resource Group**: `my-dev-rg`
- **Container Registry**: `mydevacr`
- **Key Vault**: `my-dev-vault`
- **PostgreSQL Flexible Server**: `my-dev-postgres`
- **Container App Environment**: `my-dev-env`
- **Container App**: `my-dev-server`
- **Log Analytics Workspace**: `my-dev-logs`
- **Storage Account**: `mydevstorage` with:
  - **Blob Containers**: app-data, uploads, backups, logs
  - **File Shares**: app-config, shared-data
  - **Tables**: appsessions, applogs
  - **Queues**: processing-queue, notification-queue

## Quick Start

### 1. Initial Setup

```bash
# Clone or navigate to the project directory
cd /home/reinhard/projects/my-terraform

# Make the setup script executable
chmod +x scripts/setup.sh

# Run the automated setup
./scripts/setup.sh
```

### 2. Manual Setup (Alternative)

If you prefer to run commands manually:

```bash
# Step 1: Login to Azure
az login

# Step 2: Set subscription (if you have multiple)
az account set --subscription "your-subscription-id"

# Step 3: Initialize Terraform
terraform init

# Step 4: Plan the deployment
terraform plan

# Step 5: Apply the configuration
terraform apply
```

## Detailed Setup Instructions

### Step 1: Azure CLI Authentication

First, authenticate with Azure CLI:

```bash
# Login to Azure (this will open a browser for authentication)
az login

# If you have multiple subscriptions, list them
az account list --output table

# Set the desired subscription
az account set --subscription "your-subscription-id"

# Verify the current subscription
az account show --output table
```

### Step 2: Terraform Initialization

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# Validate the configuration
terraform validate

# Format the Terraform files
terraform fmt
```

### Step 3: Plan and Apply

```bash
# Create an execution plan
terraform plan -out=tfplan

# Review the plan and apply
terraform apply tfplan
```

### Step 4: Verify Deployment

```bash
# List all resources in the resource group
az resource list --resource-group my-dev-rg --output table

# Check Container Registry
az acr list --resource-group my-dev-rg --output table

# Check Key Vault
az keyvault list --resource-group my-dev-rg --output table

# Check PostgreSQL Server
az postgres flexible-server list --resource-group my-dev-rg --output table

# Check Container Apps
az containerapp list --resource-group my-dev-rg --output table
```

## Configuration

### Environment Variables

You can customize the deployment by setting environment variables or modifying `terraform.tfvars`:

```bash
# Set environment variables (optional)
export TF_VAR_location="East US"
export TF_VAR_environment="dev"
export TF_VAR_project_name="my"
```

### terraform.tfvars

Create a `terraform.tfvars` file to customize variables:

```hcl
location = "East US"
environment = "dev"
project_name = "my"
postgres_admin_username = "adminuser"
postgres_admin_password = "YourSecurePassword123!"
```

## Outputs

After successful deployment, Terraform will output important information:

- Container Registry login server
- Key Vault URI
- PostgreSQL connection string
- Container App URLs
- Log Analytics Workspace ID

## Management Commands

### Updating Infrastructure

```bash
# Update infrastructure
terraform plan
terraform apply
```

### Destroying Infrastructure

```bash
# Destroy all resources (be careful!)
terraform plan -destroy
terraform destroy
```

### Viewing State

```bash
# Show current state
terraform show

# List all resources
terraform state list

# Show specific resource
terraform state show azurerm_resource_group.main
```

## Security Considerations

1. **Key Vault**: All sensitive data is stored in Azure Key Vault
2. **PostgreSQL**: Database is configured with firewall rules
3. **Container Registry**: Uses managed identity for authentication
4. **Container Apps**: Configured with environment-specific settings

## Troubleshooting

### Common Issues

1. **Authentication Error**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Resource Name Conflicts**:
   - Modify the `project_name` variable in `terraform.tfvars`

3. **Permission Issues**:
   - Ensure your Azure account has Contributor role

4. **Terraform State Issues**:
   ```bash
   terraform refresh
   terraform plan
   ```

## File Structure

```
.
├── README.md                  # Complete documentation
├── QUICKSTART.md             # Quick reference commands
├── main.tf                   # Main Terraform configuration
├── variables.tf              # Variable definitions
├── outputs.tf                # Output definitions
├── providers.tf              # Provider configuration
├── terraform.tfvars          # Variable values (environment-specific)
├── terraform.tfvars.example  # Example configuration template
├── scripts/
│   ├── setup.sh             # Automated setup script
│   ├── deploy.sh            # Deployment script
│   ├── validate.sh          # Infrastructure validation
│   ├── cleanup.sh           # Cleanup script
│   └── utils.sh             # Utility commands
└── .gitignore               # Git ignore file
```

## Git Integration

This project is configured for Git tracking:

```bash
# Initialize Git repository
git init

# Add all files
git add .

# Commit initial setup
git commit -m "Initial Terraform Azure infrastructure setup"

# Add remote repository (optional)
git remote add origin <your-repo-url>
git push -u origin main
```

## Next Steps

1. Configure your Container Registry with your application images
2. Update Container App configuration with your application settings
3. Configure PostgreSQL database schema
4. Set up CI/CD pipelines for automated deployments
5. Configure storage access for your applications

## Storage Account Usage

The deployed storage account includes several pre-configured containers and services:

### Blob Containers
- **app-data**: General application data storage
- **uploads**: User file uploads
- **backups**: Database and application backups
- **logs**: Application log files (private access)

### File Shares
- **app-config**: Application configuration files (100GB quota)
- **shared-data**: Shared data between container instances (100GB quota)

### Tables
- **appsessions**: User session data
- **applogs**: Structured application logs

### Queues
- **processing-queue**: Background job processing
- **notification-queue**: Message notifications

### Access Storage from Applications

The storage account credentials are automatically stored in Key Vault:
- Storage account name: `storage-account-name`
- Storage account key: `storage-account-key`
- Connection string: `storage-connection-string`
- Blob endpoint: `storage-blob-endpoint`

Container Apps have these environment variables available:
- `STORAGE_ACCOUNT_NAME`
- `STORAGE_CONNECTION_STRING`
- `STORAGE_BLOB_ENDPOINT`

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Terraform and Azure CLI documentation
3. Check Azure portal for resource status
