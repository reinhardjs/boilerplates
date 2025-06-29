# FiveM Server on Azure - Deployment Guide

## Summary
This Terraform configuration creates a cost-optimized FiveM server on Azure with:
- **Cost**: ~$9-11/month total
- **VM**: Standard_B1s (1 vCPU, 1GB RAM)
- **Storage**: 60GB Azure File Shares (20+30+10GB)
- **Features**: Auto-start, helper scripts

## Quick Start

### 1. Prerequisites
```bash
# Install Terraform
# Install Azure CLI and login
az login

# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -C "your-email@example.com"
# Or for RSA: ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

### 2. Configure
```bash
# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - Add your SSH public key
# - Change admin_username if needed
# - Update tags (especially Owner)
```

### 3. Deploy
```bash
# Initialize and deploy
terraform init
terraform plan    # Review what will be created
terraform apply   # Type 'yes' to confirm
```

### 4. Set Up FiveM
```bash
# SSH to the server (IP will be shown in output)
ssh azureuser@<server-ip>

# Start the server
./start-fivem.sh

# Check logs
./logs-fivem.sh
```

## Cost Breakdown
- **VM**: Standard_B1s ~$7.30/month
- **Storage**: 60GB File Shares ~$1.50/month  
- **Network**: Public IP + Data ~$1.00/month
- **Total**: ~$9-11/month

## Helper Scripts Available
- `./start-fivem.sh` - Start via systemctl (auto-restart)
- `./start-fivem-direct.sh` - Start directly (manual)
- `./stop-fivem.sh` - Stop the server
- `./restart-fivem.sh` - Restart the server
- `./check-fivem.sh` - Check server status
- `./logs-fivem.sh` - View live logs

## File Structure
- **FiveM Binaries**: `/opt/fivem/` (local, fast access)
- **Resources**: `/mnt/fivem-resources/` (persistent)
- **Cache**: `/mnt/fivem-cache/` (persistent)
- **Logs**: `/mnt/fivem-server/fivem.log` (persistent)

## Important Notes
1. **License Required**: Get your FiveM license from https://keymaster.fivem.net/
2. **Firewall**: Port 30120 & 40120 is automatically opened
3. **SSH Keys**: RSA is supported
4. **Auto-Start**: Server starts automatically on boot
5. **Persistence**: All data stored on Azure File Shares

## Troubleshooting

### Server won't start
```bash
# Check if license key is set
cat /mnt/fivem-server/server.cfg | grep sv_licenseKey

# Check logs
./logs-fivem.sh
tail -f /mnt/fivem-server/fivem.log

# Try manual start
./start-fivem-direct.sh
```

### SSH Connection Issues
```bash
# Check your SSH key permissions
chmod 600 ~/.ssh/id_rsa

# Get connection command from Terraform
terraform output ssh_connection_command
```

### Storage Issues
```bash
# Check mounted storage
df -h
mount | grep fivem

# Restart VM if mounts fail
terraform apply -replace="azurerm_linux_virtual_machine.fivem"
```

## Cleanup
```bash
# Remove all resources
terraform destroy
```

## Customization

### Increase Performance
Edit `terraform.tfvars`:
```bash
vm_size = "Standard_B2s"  # 2 vCPUs, 4GB RAM (~$30/month)
```

### Increase Storage
Edit `terraform.tfvars`:
```bash
fivem_resources_quota_gb = 50  # Increase resources storage
fivem_cache_quota_gb = 20      # Increase cache storage
```

### Add Custom Resources
```bash
# Upload to resources folder
scp -r ./my-resource azureuser@<server-ip>:/mnt/fivem-resources/

# Add to server.cfg
echo "start my-resource" >> /mnt/fivem-server/server.cfg

# Restart server
./restart-fivem.sh
```
