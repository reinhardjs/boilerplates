# Setup

## 1. Install docker and docker compose.
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04

## 2. Install UFW (Uncomplicated Firewall).
https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu
https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands

```bash
sudo ufw enable
```

```bash
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
```

```bash
sudo ufw default deny incoming
```

```bash
sudo ufw default allow outgoing
```

### Allowing specific ranges
For example, to allow X11 connections, which use ports 6000-6007, use these commands:
```bash
    sudo ufw allow 6000:6007/tcp
    sudo ufw allow 6000:6007/udp
```

## 3.Install Wireguard
https://github.com/reinhardjs/boilerplates/tree/main/wireguard-vpn

## 4. Install k3s server
https://github.com/reinhardjs/boilerplates/tree/main/k3s

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
--docker \
--token=<token-here> \
--node-name=master-node \
--bind-address=0.0.0.0 \
--node-ip=10.0.0.1 \
--node-external-ip=<SERVER_PUBLIC_IP> \
--tls-san=<SERVER_PUBLIC_IP> \
--write-kubeconfig-mode=644 \
--flannel-iface=wg0" sh -s -
```

```bash
# Allow K3s API Serve
sudo ufw allow 6443/tcp

# Allow K3s Alternative: CA certs: Get CA certificates from the K3s server.
sudo ufw allow 6444

# Allow Flannel VXLAN
sudo ufw allow 8472/udp

# Allow NodePort Range
sudo ufw allow 30000:32767/tcp

# Allow Kubelet API: enables communication between the K3s server and its agents, among other functions.
sudo ufw allow 10250/tcp
```

Once the 4 steps are completed, the memory usage typically increases by approximately 528MB, primarily due to the k3s server and Docker.
