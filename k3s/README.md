curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token 123456

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - --server https://103.193.176.202:6443 --token 123456

sudo systemctl restart k3s

sudo systemctl status k3s

sudo journalctl -u k3s

sudo systemctl restart k3s-agent


### Get server token

cat /var/lib/rancher/k3s/server/node-token
