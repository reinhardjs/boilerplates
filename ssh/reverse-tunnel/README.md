```
[Unit]
Description=Reverse SSH Tunnel with Auto Reconnect
After=network.target

[Service]
User=reinhardjs
ExecStart=/usr/bin/autossh -M 0 -N -R 2223:localhost:22 reinhardjs@103.193.176.202
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
