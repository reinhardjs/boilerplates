# Reverse SSH Tunnel with Auto Reconnect

This guide explains how to set up a reverse SSH tunnel that automatically reconnects if the connection drops.

## Setup on server

```
  sudo nano /etc/ssh/sshd_config    
```

Ensure the following lines are present and uncommented:

```
AllowTcpForwarding yes   # Allows TCP forwarding, which is necessary for SSH tunneling.
GatewayPorts yes         # Allows remote hosts to connect to ports forwarded for the client.
TCPKeepAlive yes         # Enables TCP keepalive messages to ensure the connection stays active.
```

## Setup on client

```bash
sudo nano /etc/systemd/system/autossh-tunnel.service
```

```
[Unit]
Description=Reverse SSH Tunnel with Auto Reconnect
After=network.target

[Service]
User=reinhard
ExecStart=/usr/bin/autossh -M 0 -N \
    -R 2223:localhost:23 \
    -R 0.0.0.0:5000:localhost:5000 \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=120 \
    -o ExitOnForwardFailure=no \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o TCPKeepAlive=yes \
    -o ConnectTimeout=15 \
    -o BatchMode=yes \
    reinhardjs@10.0.0.1
Restart=always
RestartSec=3s
StartLimitIntervalSec=0
StartLimitBurst=0

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload

sudo systemctl enable autossh-tunnel.service

sudo systemctl start autossh-tunnel.service

sudo systemctl status autossh-tunnel.service

journalctl -u autossh-tunnel.service
```
