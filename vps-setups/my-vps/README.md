# Setup

## 1. Install docker and docker compose.
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04

<br>

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

<br>

## 3.Install Wireguard
https://github.com/reinhardjs/boilerplates/tree/main/wireguard-vpn

<br>

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

```bash
cat /etc/rancher/k3s/k3s.yaml
```

Copy the content and dont forget to change the https://0.0.0.0:6443 to https://<SERVER_PUBLIC_IP>:6443

Then on the client machine, copy the content to ~/.kube/config

Once the 4 steps are completed, the memory usage typically increases by approximately 528MB, primarily due to the k3s server and Docker.

<br>

## 5. Setup reverse ssh tunnel
https://github.com/reinhardjs/boilerplates/tree/main/ssh/reverse-tunnel

<br>

## 6. Setup k3s traefik ssl secrets
Setup for k3s traefik ingress controler of reinhardjs.my.id. Go to cloudflare and get the ssl certificate and key. 
To get the certificate and key, go to the SSL/TLS settings of the domain -> origin server then create certificate.
Save it on to the .crt and .key file. Then put it in the secret manager. Look at the detail on this github on how to put it as secret k3s.
https://github.com/reinhardjs/boilerplates/tree/main/k3s/traefik

Execute the command below to create the secret.
```bash
kubectl create secret tls traefik-cert --cert=./traefik.crt --key=./traefik.key
```

```bash
kubectl create secret tls reinhardjs-my-id-tls-secret --cert=/etc/ssl/reinhardjs.my.id.crt --key=/etc/ssl/reinhardjs.my.id.key
```

## Edit local-path-provisioner configmap default path to the desired path (Optional)

```bash
kubectl edit configmap local-path-config -n kube-system
```

the file will look like this.
```yaml
     apiVersion: v1
     kind: ConfigMap
     metadata:
       name: local-path-config
       namespace: kube-system
     data:
       config.json: |
         {
           "nodePathMap": [
             {
               "node": "DEFAULT_PATH_FOR_NON_LISTED_NODES",
               "paths": ["/var/lib/rancher/k3s/storage"]
             }
           ]
         }
```

Press i to edit the file, then modify the paths to the desired path. Press esc then type :wq to save the file.

```bash
kubectl rollout restart deployment local-path-provisioner -n kube-system
```

