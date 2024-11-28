## How to install k3s server

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --docker --token=123456 --node-name=master-node" sh -s -
```


If you want to connect to other node using existing wireguard network interface (wg0), you can use the following command:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --docker --token=123456 --node-name=master-node --node-ip=10.0.0.1 --flannel-iface wg0" sh -s -
```

## How to install k3s agent

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --docker --server=https://<K3S_SERVER_IP>:6443 --token=123456 --node-name=worker-node" sh -s -
```

Alternatively, if you need to connect to an endpoint via VPN (look at [wireguard-vpn-install](https://github.com/reinhardjs/boilerplates/tree/main/wireguard-vpn) to setup wireguard VPN between your public server (VPS) and home PC)

such as using your home PC as a worker node, you can use the following command:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --docker --server https://10.0.0.1:6443 --token 123456 --node-name=worker-node --node-ip=10.0.0.2 --node-external-ip=10.0.0.2 --flannel-iface wg0" sh -s -
```

or you can use the following command same as above

```
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.1:6443 K3S_TOKEN=123456 sh -s - --docker --node-name=worker-node --node-ip=10.0.0.2 --node-external-ip=10.0.0.2 --flannel-iface wg0
```


## How to restart k3s server and agent

```
sudo systemctl restart k3s # or k3s-agent
```


## Monitor k3s server and agent
```
sudo journalctl -u k3s -f
```

```
sudo journalctl -u k3s-agent -f
```

```
sudo systemctl status k3s # or k3s-agent
```


### Get server token

```
cat /var/lib/rancher/k3s/server/node-token
```

### Uninstall k3s server and agent

```
/usr/local/bin/k3s-uninstall.sh
```

```
/usr/local/bin/k3s-agent-uninstall.sh
```
