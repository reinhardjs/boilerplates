```
[Unit]
Description=Meilisearch
After=network.target

[Service]
EnvironmentFile=/mnt/data/shared/envs/meilisearch/.env
ExecStart=/mnt/data/shared/meilisearch --db-path=/mnt/data/shared/db/data.meilisearch
User=root
Restart=always

[Install]
WantedBy=multi-user.target
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

```
sudo nano /etc/systemd/system/autossh-tunnel.service

sudo systemctl daemon-reload

sudo systemctl enable autossh-tunnel.service

sudo systemctl start autossh-tunnel.service

sudo systemctl status autossh-tunnel.service

journalctl -u autossh-tunnel.service
```
