curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --docker --token 123456" sh -s -

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://103.193.176.202:6443 --docker --token 123456" sh -s -

sudo systemctl restart k3s

sudo systemctl status k3s

## Monitor k3s server and agent
sudo journalctl -u k3s -f

sudo journalctl -u k3s-agent -f

sudo systemctl restart k3s-agent


### Get server token

cat /var/lib/rancher/k3s/server/node-token
