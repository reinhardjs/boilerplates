# Quick Reference Guide

## 🚀 Quick Start
```bash
# One-command setup
./scripts/setup.sh
```

## 📋 Prerequisites Checklist
- [ ] Azure CLI installed (`az --version`)
- [ ] Terraform installed (`terraform --version`)
- [ ] Git installed (`git --version`)
- [ ] Azure subscription access
- [ ] Appropriate Azure permissions (Contributor role)

## 🛠️ Available Scripts

### Main Scripts
| Script | Purpose | Usage |
|--------|---------|--------|
| `setup.sh` | Complete automated setup | `./scripts/setup.sh` |
| `deploy.sh` | Update/redeploy infrastructure | `./scripts/deploy.sh` |
| `validate.sh` | Validate deployed resources | `./scripts/validate.sh` |
| `cleanup.sh` | Destroy all resources | `./scripts/cleanup.sh` |
| `utils.sh` | Utility commands | `./scripts/utils.sh [command]` |

### Utility Commands
```bash
# View all secrets
./scripts/utils.sh secrets

# Get database connection info
./scripts/utils.sh database

# Get container registry credentials
./scripts/utils.sh registry

# Show all service URLs
./scripts/utils.sh urls

# View container app logs
./scripts/utils.sh logs

# Check resource status
./scripts/utils.sh status
```

## 📦 Infrastructure Overview

### Core Resources
- **Resource Group**: `my-dev-rg`
- **Container Registry**: `mydevacr`
- **Key Vault**: `my-dev-vault`
- **PostgreSQL Server**: `my-dev-postgres`
- **Container App Environment**: `my-dev-env`
- **Container App**: `my-dev-server`
- **Log Analytics**: `my-dev-logs`

### Default Configuration
- **Location**: East US
- **Environment**: dev
- **PostgreSQL**: Version 14, B_Standard_B1ms, 32GB storage
- **Container App**: 0.25 CPU, 0.5Gi memory, 1-3 replicas

## ⚙️ Configuration Files

### terraform.tfvars
Copy from `terraform.tfvars.example` and customize:
```hcl
location = "East US"
environment = "dev"
project_name = "my"
postgres_admin_username = "adminuser"
postgres_admin_password = "YourSecurePassword123!"
```

## 🔧 Manual Commands

### Basic Terraform Commands
```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Show outputs
terraform output

# Destroy everything
terraform destroy
```

### Azure CLI Commands
```bash
# Login
az login

# Set subscription
az account set --subscription "subscription-id"

# List resources
az resource list --resource-group my-dev-rg --output table

# Container registry login
az acr login --name mydevacr

# View container app
az containerapp show --name my-dev-server --resource-group my-dev-rg
```

## 🔐 Security & Secrets

All sensitive information is stored in Azure Key Vault:
- `postgres-admin-password`: Database password
- `acr-username`: Container registry username
- `acr-password`: Container registry password
- `database-url`: Complete database connection string

Access secrets:
```bash
az keyvault secret show --vault-name my-dev-vault --name "secret-name" --query "value" -o tsv
```

## 🌐 Service URLs

After deployment, access your services:
- **Container App**: Check `terraform output container_app_url`
- **Key Vault**: Check `terraform output key_vault_uri`
- **Container Registry**: Check `terraform output container_registry_login_server`
- **Azure Portal**: Resource group overview page

## 🐛 Troubleshooting

### Common Issues

1. **Authentication Error**
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Permission Denied**
   - Ensure your account has Contributor role on the subscription
   - Check with: `az role assignment list --assignee $(az account show --query user.name -o tsv)`

3. **Resource Name Conflicts**
   - Change `project_name` in `terraform.tfvars`
   - Resource names must be globally unique (especially ACR and Key Vault)

4. **Terraform State Issues**
   ```bash
   terraform refresh
   terraform plan
   ```

5. **PostgreSQL Connection Issues**
   - Check firewall rules
   - Verify credentials in Key Vault
   - Ensure Container Apps can reach the database

### Validation Steps
```bash
# Run full validation
./scripts/validate.sh

# Check specific resource
az resource show --ids $(terraform output -raw resource_group_id)
```

## 📝 Next Steps

1. **Configure your application**:
   - Build and push your container image to ACR
   - Update Container App configuration

2. **Database setup**:
   - Connect to PostgreSQL and create schema
   - Configure connection pooling if needed

3. **CI/CD Pipeline**:
   - Set up GitHub Actions or Azure DevOps
   - Automate container builds and deployments

4. **Monitoring**:
   - Configure Application Insights
   - Set up alerts and dashboards

5. **Scaling**:
   - Adjust container app scaling rules
   - Monitor performance and costs

## 📊 Cost Management

Monitor costs with:
```bash
az consumption usage list --start-date $(date -d '1 month ago' +%Y-%m-%d) --end-date $(date +%Y-%m-%d) --output table
```

Expected monthly costs (approximate):
- Resource Group: Free
- Container Registry (Basic): ~$5/month
- Key Vault: ~$1-3/month
- PostgreSQL (B_Standard_B1ms): ~$12-25/month
- Container Apps: Pay-per-use, ~$0-20/month depending on usage
- Log Analytics: Pay-per-GB, ~$2-10/month

## 🆘 Support

1. Check this quick reference guide
2. Review the detailed README.md
3. Run validation script: `./scripts/validate.sh`
4. Check Azure portal for resource status
5. Review Terraform and Azure CLI documentation
