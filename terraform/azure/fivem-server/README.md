# FiveM Server on Azure VM with Storage Account (Cost-Optimized)

This Terraform configuration deploys a **minimal-cost** FiveM server on an Ubuntu virtual machine in Azure with Azure File Shares for persistent storage. **Total monthly cost: ~$5-10**.

## Prerequisites

- Azure account with active subscription
- Azure CLI installed and logged in (`az login`)
- Terraform installed
- **SSH key pair**

### Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
cat ~/.ssh/id_rsa.pub
```

## Key Features

- **Ultra-minimal VM** (Standard_B1s: 1 vCPU, 1GB RAM) for lowest cost
- **Azure File Shares** for persistent storage (only 60GB total default)
- **Only run.sh stored locally** - everything else on Azure Storage
- **Auto-starts on boot** and runs in background
- **Auto-shutdown scheduling** to reduce costs further
- **No server.cfg setup** - you provide your own configuration

## Cost Breakdown (~$5-10/month)

- **VM (Standard_B1s)**: ~$7-8/month
- **Storage (60GB)**: ~$1-2/month  
- **Networking**: ~$1/month
- **Total**: ~$9-11/month

## Storage Architecture

Everything except `run.sh` is stored on Azure File Shares:
- **fivem-server** (30GB): FiveM binaries, your server.cfg, logs
- **fivem-resources** (20GB): Custom resources, maps, scripts  
- **fivem-cache** (10GB): Cache files for performance

Benefits:
- **Persistent** - survives VM restarts/recreations
- **Scalable** - increase quotas as needed
- **VM-independent** - can move to different/larger VMs later

## Quick Start

1. **Clone and navigate to the directory:**
   ```bash
   cd terraform/azure/fivem-server
   ```

2. **Copy and edit the variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars
   ```

3. **Required configuration:**
   - Set your SSH public key in `ssh_public_key`
   - Optionally adjust VM size, storage quotas, and other settings

4. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Get connection info:**
   ```bash
   terraform output
   ```

## After Deployment

1. **Wait for setup to complete** (5-10 minutes)
2. **SSH to your VM**:
   ```bash
   ssh azureuser@<vm-ip>
   ```
3. **Server auto-starts** - FiveM runs automatically on boot
4. **Connect via FiveM** to `<vm-ip>:30120`

## File Structure

```
VM (only run.sh):
/home/azureuser/run.sh          # Only local file

Azure Storage (everything else):
/mnt/fivem-server/              # FiveM binaries & your config
├── FXServer                    # Main executable
├── fivem.log                   # Server logs
├── fivem.pid                   # Process ID file
└── [other FiveM files]

/mnt/fivem-resources/           # Your custom content
└── [your resources]

/mnt/fivem-cache/               # Cache files
└── [cache data]
```

## Server Management

Helper scripts in the home directory:

- `./start-fivem.sh` - Start FiveM server
- `./stop-fivem.sh` - Stop FiveM server  
- `./restart-fivem.sh` - Restart FiveM server
- `./fivem-logs.sh` - View live server logs

### Manual commands:
```bash
sudo systemctl start fivem     # Start
sudo systemctl stop fivem      # Stop  
sudo systemctl status fivem    # Status
tail -f /mnt/fivem-server/fivem.log  # Logs
```

### From your local machine:
```bash
./scripts/manage.sh status     # Check server status
./scripts/manage.sh logs       # View logs
./scripts/manage.sh ssh        # SSH to server
```

## Configuration

### VM Sizing for Cost Optimization

| VM Size | vCPUs | RAM | Players | Monthly Cost | Recommendation |
|---------|-------|-----|---------|--------------|----------------|
| **Standard_B1s** | 1 | 1GB | 8-16 | **~$7-8** | **Minimal cost** |
| Standard_B1ms | 1 | 2GB | 16-24 | ~$15 | Budget option |
| Standard_B2s | 2 | 4GB | 24-32 | ~$30 | Better performance |

**Default**: Standard_B1s for absolute minimal cost

### Storage Quotas (Minimal for Cost)

Default quotas are optimized for minimal cost:
- **fivem-server**: 30GB (FiveM binaries, configs, logs)
- **fivem-resources**: 20GB (your custom content)
- **fivem-cache**: 10GB (cache files)

**Total**: 60GB = ~$1-2/month

To increase later: Azure Portal → Storage Account → File shares → Increase quota

## Networking

- **SSH (22)**: Restricted to your IP for management
- **FiveM (30120 UDP/TCP)**: Open to all for game connections
- **Private subnet**: VM is in a private subnet with public IP for access

## Security Considerations

1. **SSH Key Authentication**: Password authentication is disabled
2. **Network Security Groups**: Only necessary ports are open
3. **Private Storage**: Storage account keys are managed securely
4. **Regular Updates**: VM is configured for automatic security updates

## Backup Strategy

### Storage Account Backup
1. Enable Azure Backup for the storage account
2. Configure backup policies for file shares
3. Set retention periods based on your needs

### VM Backup
1. Enable Azure Backup for the VM
2. Schedule regular snapshots
3. Test restore procedures

## Monitoring

View real-time server performance:
```bash
htop                    # System resource usage
./fivem-logs.sh        # Server logs
sudo systemctl status fivem  # Service status
```

## Troubleshooting

### Common Issues

1. **Server won't start**:
   ```bash
   sudo journalctl -u fivem -n 50  # Check recent logs
   ```

2. **Storage not mounted**:
   ```bash
   mount -a                # Remount all filesystems
   df -h                   # Check mounted filesystems
   ```

3. **Permission issues**:
   ```bash
   sudo chown -R azureuser:azureuser /opt/fivem
   sudo chown -R azureuser:azureuser /mnt/fivem-*
   ```

4. **Network connectivity**:
   ```bash
   sudo ufw status         # Check firewall
   netstat -tulpn | grep 30120  # Check if port is listening
   ```

### Performance Tuning

1. **Upgrade to Premium Storage** for better I/O performance
2. **Increase VM size** for more CPU/RAM
3. **Enable accelerated networking** on the VM
4. **Tune FiveM server settings** in server.cfg

## Cost Optimization Features

1. **Minimal VM Size**: Standard_B1s (1 vCPU, 1GB RAM)
2. **Standard Storage**: Standard_LRS instead of Premium
3. **Small Storage Quotas**: Only 60GB total by default
4. **Auto-shutdown**: VM shuts down at 2 AM UTC daily (configurable)
5. **Minimal Local Storage**: Only run.sh stored on VM
6. **Burstable Performance**: B-series VMs provide CPU bursting

### Further Cost Reduction

1. **Stop VM when not gaming**:
   ```bash
   az vm deallocate --resource-group <rg-name> --name <vm-name>
   ```
   Storage persists, but you only pay for storage (~$1-2/month)

2. **Use Azure Automation** for scheduled start/stop
3. **Monitor usage** and resize storage as needed

## Scaling

### Vertical Scaling (Single Server)
1. Stop the VM
2. Resize to a larger VM size
3. Start the VM

### Horizontal Scaling (Multiple Servers)
The storage setup supports multiple VMs accessing the same file shares, enabling:
- Load balancing across multiple servers
- Dedicated servers for different game modes
- Development/staging environments sharing resources

## Support

For FiveM-specific issues:
- [FiveM Documentation](https://docs.fivem.net/)
- [FiveM Community Forums](https://forum.cfx.re/)
- [FiveM Discord](https://discord.gg/fivem)

For Azure infrastructure issues:
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure Support](https://azure.microsoft.com/support/)

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will permanently delete the VM and all data. Make sure to backup any important data first.

## Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `location` | Azure region | "West US 2" | No |
| `environment` | Environment name | "dev" | No |
| `project_name` | Project name prefix | "my" | No |
| `admin_username` | VM admin username | "azureuser" | No |
| `ssh_public_key` | SSH public key | - | **Yes** |
| `vm_size` | VM size | "Standard_B2s" | No |
| `os_disk_type` | OS disk type | "Premium_LRS" | No |
| `os_disk_size_gb` | OS disk size | 30 | No |
| `storage_account_tier` | Storage tier | "Standard" | No |
| `storage_account_replication_type` | Replication type | "LRS" | No |
| `fivem_storage_quota_gb` | Server data quota | 100 | No |
| `fivem_resources_quota_gb` | Resources quota | 200 | No |
| `fivem_cache_quota_gb` | Cache quota | 50 | No |
| `fivem_download_url` | FiveM download URL | Latest build | No |
| `tags` | Resource tags | Default tags | No |
