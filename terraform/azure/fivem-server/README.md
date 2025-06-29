# FiveM Server on Azure VM with Storage Account (Optimized for txData)

## 🎮 **Cost-Optimized FiveM Server with Correct txData Structure**

This setup creates a FiveM server that properly handles the `txData/qbox_core/cache` and `txData/qbox_core/resources` structure while keeping costs minimal (~$9-11/month).

## **Architecture Overview**

```
Local VM (fast execution):
/opt/fivem/
├── alpine/                    # FiveM runtime environment
├── run.sh                     # Original FiveM startup script  
└── txData/
    └── qbox_core/
        ├── cache/      -> /mnt/fivem-cache/qbox_core (symlink)
        └── resources/  -> /mnt/fivem-resources/qbox_core (symlink)

Azure Storage (persistent):
/mnt/fivem-server/            # General data and logs
/mnt/fivem-cache/qbox_core/   # Cache files (persisted)
/mnt/fivem-resources/qbox_core/ # Resources and maps (persisted)
```

## **How It Works**

1. **FiveM binaries** stay on local VM storage (supports symlinks, fast execution)
2. **txData structure** is created automatically when FiveM runs
3. **Symlinks redirect** `cache` and `resources` to Azure File Shares
4. **Data persists** even if VM is destroyed and recreated
5. **Costs stay low** with minimal local storage and optimized Azure storage

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
- **Proper txData structure** with symlinks to Azure Storage
- **Uses original run.sh** - no custom FiveM configuration needed
- **Auto-starts on boot** and runs in background
- **Auto-shutdown scheduling** to reduce costs further
- **Symlink support** for FiveM's file structure requirements

## Quick Deploy

```bash
# 1. Navigate to directory
cd terraform/azure/fivem-server

# 2. Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add your SSH public key

# 3. Deploy
terraform init
terraform plan
terraform apply
```

## After Deployment

1. **Wait for setup to complete** (5-10 minutes)
2. **SSH to your VM**:
   ```bash
   ssh azureuser@<vm-ip>
   ```
3. **Start FiveM for the first time**:
   ```bash
   ./start-fivem.sh
   ```
4. **Check if it's working**:
   ```bash
   ./logs-fivem.sh
   ./status-fivem.sh
   ```
5. **Connect via FiveM** to `<vm-ip>:30120`

## File Structure Details

### What gets created automatically:

When FiveM runs for the first time with `./run.sh`, it creates:
- `txData/qbox_core/cache/` (redirected to Azure Storage)
- `txData/qbox_core/resources/` (redirected to Azure Storage)

### Storage mapping:

| FiveM Path | Actual Location | Purpose |
|------------|-----------------|---------|
| `/opt/fivem/alpine/` | Local VM | Runtime (needs symlinks) |
| `/opt/fivem/run.sh` | Local VM | Startup script |
| `/opt/fivem/txData/qbox_core/cache/` | `/mnt/fivem-cache/qbox_core/` | Cache files |
| `/opt/fivem/txData/qbox_core/resources/` | `/mnt/fivem-resources/qbox_core/` | Server resources |

## Server Management

Helper scripts in the home directory:

- `./start-fivem.sh` - Start FiveM server (uses original run.sh)
- `./stop-fivem.sh` - Stop FiveM server  
- `./restart-fivem.sh` - Restart FiveM server
- `./logs-fivem.sh` - View live server logs
- `./status-fivem.sh` - Check detailed status

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

## Adding Resources

1. **Upload to Azure Storage**:
   ```bash
   # From VM
   cp your-resource/ /mnt/fivem-resources/qbox_core/
   
   # Or upload via Azure portal to the fivem-resources file share
   ```

2. **Restart server**:
   ```bash
   ./restart-fivem.sh
   ```

3. **Resources appear** in FiveM as `txData/qbox_core/resources/your-resource/`

## Cost Breakdown

- **VM (Standard_B1s)**: ~$7.30/month
- **Storage (60GB total)**: ~$1.50/month  
- **Network (Public IP + data)**: ~$1.00/month
- **Total**: **~$9-11/month**

### Cost reduction features:
- Auto-shutdown at 2 AM UTC (configurable)
- Deallocate when not gaming → pay only ~$2/month for storage
- Burstable CPU performance for gaming workloads

## Monitoring

View real-time server performance:
```bash
htop                    # System resource usage
./logs-fivem.sh        # Server logs
sudo systemctl status fivem  # Service status
./status-fivem.sh      # Detailed FiveM status
```

## Troubleshooting

### Common Issues

1. **Server won't start**:
    ```bash
    # Check logs
    ./logs-fivem.sh
    tail -f /mnt/fivem-server/fivem.log

    # Check systemd service
    sudo systemctl status fivem
    sudo journalctl -u fivem -f

    # Try manual start
    cd /opt/fivem
    ./run.sh
    ```

2. **txData structure issues**:
    ```bash
    # Check symlinks
    ls -la /opt/fivem/txData/qbox_core/

    # Recreate symlinks if needed
    cd /opt/fivem
    mkdir -p txData/qbox_core
    ln -sf /mnt/fivem-cache/qbox_core txData/qbox_core/cache
    ln -sf /mnt/fivem-resources/qbox_core txData/qbox_core/resources
    ```

3. **Storage not mounted**:
    ```bash
    # Check mounted storage
    df -h
    mount | grep fivem
    mount -a                # Remount all filesystems

    # Restart VM if mounts fail
    terraform apply -replace="azurerm_linux_virtual_machine.fivem"
    ```

4. **Permission issues**:
    ```bash
    sudo chown -R azureuser:azureuser /opt/fivem
    sudo chown -R azureuser:azureuser /mnt/fivem-*
    ```

5. **Network connectivity**:
    ```bash
    sudo ufw status         # Check firewall
    netstat -tulpn | grep 30120  # Check if port is listening
    ```

6. **SSH Connection Issues**:
    ```bash
    # Check your SSH key permissions
    chmod 600 ~/.ssh/id_rsa

    # Get connection command from Terraform
    terraform output ssh_connection_command
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
```bash
# Remove all resources
terraform destroy
```

## Customization

### Change auto-shutdown time:
Edit `terraform.tfvars`:
```
auto_shutdown_time = "01:00"  # 1 AM UTC
```

### Increase storage:
Edit `terraform.tfvars`:
```
fivem_resources_quota_gb = 50  # Increase resources storage
fivem_cache_quota_gb = 20      # Increase cache storage
```

### Disable auto-shutdown:
Edit `terraform.tfvars`:
```
enable_auto_shutdown = false
```

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

## Important Notes

1. **Original run.sh**: Uses FiveM's original startup script
2. **Symlink magic**: txData appears local to FiveM but actually uses Azure Storage
3. **Performance**: Binaries run from local SSD for speed
4. **Persistence**: All data survives VM recreations
5. **Cost optimized**: Minimal local storage, maximal persistence

This setup gives you the best of both worlds: **FiveM runs at full speed locally**, but your **data is safe and persistent in the cloud**! 🚀
