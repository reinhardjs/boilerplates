# FiveM Server Quick Start Guide (Cost-Optimized)

Get your FiveM server running for **~$5-10/month** in just 10 minutes!

## Prerequisites

- Azure account with active subscription
- Azure CLI installed and logged in (`az login`)
- Terraform installed
- SSH key pair generated

## Step 1: Generate SSH Key (if you don't have one)

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
cat ~/.ssh/id_rsa.pub  # Copy this output
```

## Step 2: Deploy Infrastructure

```bash
# Navigate to the FiveM server directory
cd terraform/azure/fivem-server

# Run the deployment script
./scripts/deploy.sh
```

The script will:
1. Check prerequisites
2. Copy configuration template
3. Ask you to edit the SSH public key
4. Plan and deploy the infrastructure

## Step 3: Setup Your FiveM Server

After deployment completes (5-10 minutes):

1. **SSH to your server:**
   ```bash
   ./scripts/manage.sh ssh
   ```

2. **Check if it's running:**
   ```bash
   ./fivem-logs.sh
   ```

## Step 4: Connect to Your Server

1. Open FiveM client
2. Press F8 to open console
3. Type: `connect YOUR_VM_IP:30120`
4. Have fun!

## Management Commands

From your local machine:

```bash
# Check server status
./scripts/manage.sh status

# Start/stop/restart server
./scripts/manage.sh start
./scripts/manage.sh stop
./scripts/manage.sh restart

# View live logs
./scripts/manage.sh logs

# SSH to server
./scripts/manage.sh ssh

# Create backup
./scripts/manage.sh backup

# Update FiveM
./scripts/manage.sh update
```

## File Locations on Server

- **FiveM binaries**: `/mnt/fivem-server/` (auto-downloaded)
- **Resources**: `/mnt/fivem-resources/` (for your custom content)
- **Logs**: `/mnt/fivem-server/fivem.log`
- **Run script**: `~/run.sh` (only local file)

## Adding Resources

1. Upload resources to `/mnt/fivem-resources/`
2. Add to server.cfg: `start resource-name`
3. Restart server: `./restart-fivem.sh`

## Cost Estimate

**Minimal configuration (Standard_B1s VM):**
- VM: **~$7-8/month**
- Storage (60GB): **~$1-2/month**
- Networking: **~$1/month**
- **Total: ~$9-11/month**

**Cost reduction tips:**
- Stop VM when not gaming: `az vm deallocate` (pay only ~$2/month for storage)
- Auto-shutdown enabled by default at 2 AM UTC
- Can upgrade VM size later if needed

## Cleanup

When you're done:
```bash
./scripts/cleanup.sh
```

⚠️ **This deletes everything permanently!**

## Need Help?

- Check the full [README.md](README.md) for detailed information
- Use `./scripts/manage.sh help` for management options
- Visit [FiveM Forums](https://forum.cfx.re/) for game-specific help
