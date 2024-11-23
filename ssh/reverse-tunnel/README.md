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
