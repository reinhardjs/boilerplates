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
    -R 2222:localhost:2222 \
    -R 9000:localhost:9000 \
    -R 7700:localhost:7700 \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=no \
    reinhardjs@103.193.176.202
Restart=always
RestartSec=10s

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
