## How to install k3s server

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
--docker \
--token=123456 \
--node-name=master-node \
--bind-address=0.0.0.0
--node-external-ip=<YOUR_SERVER_IP> \
--tls-san=<YOUR_SERVER_IP_OR_HOSTNAME> \
--write-kubeconfig-mode=644" sh -s -
```

**Explanation of the parameters:**

- bind-address=0.0.0.0: This tells K3s to bind to all available network interfaces (so it can accept incoming connections from external machines).
- node-external-ip=<YOUR_SERVER_IP>: Replace <YOUR_SERVER_IP> with the external IP address of the K3s server. This tells K3s to use the specified IP for cluster communication.
- tls-san=<YOUR_SERVER_IP_OR_HOSTNAME>: This specifies the Subject Alternative Name (SAN) for the TLS certificate, which is required when accessing the server via a domain name or public IP. Replace <YOUR_SERVER_IP_OR_HOSTNAME> with your server's external IP or DNS name.
- write-kubeconfig-mode=644: Ensures the kubeconfig.yaml file generated for the server is readable by all users, which makes it easier for you to copy the file to client machines.

<br>

If you want to connect to other node using existing wireguard network interface (wg0), you can use the following command:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
--docker \
--token=123456 \
--node-name=master-node \
--node-ip=10.0.0.1 \
--node-external-ip=<YOUR_SERVER_IP> \
--tls-san=<YOUR_SERVER_IP_OR_HOSTNAME> \
--write-kubeconfig-mode=644 \
--flannel-iface=wg0" sh -s -
```

103.193.176.202 is the public IP address of my VPS

## How to install k3s agent

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent \
--docker \
--server=https://<K3S_SERVER_IP>:6443 \
--token=123456 \
--node-name=worker-node" sh -s -
```

Alternatively, if you need to connect to an endpoint via VPN (look at [wireguard-vpn-install](https://github.com/reinhardjs/boilerplates/tree/main/wireguard-vpn) to setup wireguard VPN between your public server (VPS) and home PC)

such as using your home PC as a worker node, you can use the following command:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent \
--docker \
--server https://10.0.0.1:6443 \
--token 123456 \
--node-name=worker-node \
--node-ip=10.0.0.2 \
--node-external-ip=10.0.0.2 \
--flannel-iface wg0" sh -s -
```

or you can use the following command same as above

```
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.1:6443 \
K3S_TOKEN=123456 sh -s - \
--docker \
--node-name=worker-node \
--node-ip=10.0.0.2 \
--node-external-ip=10.0.0.2 \
--flannel-iface=wg0
```


--------------------------------------------------------------------------

# Access the Kubernetes cluster from the client machine

To be able to access the Kubernetes cluster from the client machine, we need to get the server certificate-authority-data.
To obtain the server certificate-authority-data, access the kubeconfig on the k3s server.
This kubeconfig is necessary for any client that wants to connect to the Kubernetes cluster.

Do this on the k3s server:
```
cat /etc/rancher/k3s/k3s.yaml
```

The output will be like this:

```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: DATA+OMITTED
    server: https://0.0.0.0:6443
```

Copy the content and dont forget to change the `https://0.0.0.0:6443` to `https://<YOUR_SERVER_IP>:6443`

Then on the client machine, copy the content to `~/.kube/config`

Afterwards, you can test the connection to the kubernetes cluster by running:

```
kubectl get nodes
```

--------------------------------------------------------------------------


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
