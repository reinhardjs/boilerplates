# How to Use WireGuard Between VPS and Home PC

To set up a WireGuard VPN between your VPS (public server) and your home PC, the idea is to create a secure tunnel where your home PC can securely connect to the VPS. This will make your home PC appear as if it's part of the same network as your VPS, allowing private communication between the two. Here's how you can do this step-by-step:

## Prerequisites:

- A VPS with public IP.
- A home PC (running Linux, Windows, or macOS).
- WireGuard installed on both the VPS and your home PC.

## Step 1: Install WireGuard

### On VPS (Linux):

1. Update your package list and install WireGuard:
    ```
    sudo apt update
    sudo apt install wireguard
    ```

2. Verify WireGuard is installed:
    ```
    wg --version
    ```

## On Home PC (Linux):

1. Install WireGuard using your package manager:
    ```
    sudo apt update
    sudo apt install wireguard
    ```

2. Verify installation:
    ```
    wg --version
    ```

    For Windows/macOS, you can download and install the WireGuard client.

## Step 2: Generate WireGuard Keys

### On both VPS and Home PC:

You will need to generate a public/private key pair for both devices.

1. Generate keys:
    ```
    wg genkey | tee privatekey | wg pubkey > publickey
    ```
    This will generate two files: `privatekey` and `publickey`. The private key is used on the device itself, and the public key is shared with the other device.

2. Note down the keys for both the VPS and Home PC. For example:

    - VPS private key: vps_privatekey
    - VPS public key: vps_publickey
    - Home PC private key: home_pc_privatekey
    - Home PC public key: home_pc_publickey


## Step 3: Configure WireGuard on the VPS

1. Edit the WireGuard configuration on the VPS, usually located in /etc/wireguard/wg0.conf.

    Create the configuration file (wg0.conf) for the VPN interface with the following content:

    ```
    [Interface]
    PrivateKey = <VPS_PRIVATE_KEY>
    Address = 10.0.0.1/24   # IP address for the VPS on the WireGuard network
    ListenPort = 51820       # Default WireGuard port (you can change if needed)

    [Peer]
    PublicKey = <HOME_PC_PUBLIC_KEY>
    AllowedIPs = 10.0.0.2/32  # Home PC IP address on the WireGuard network
    ```
    Replace `<VPS_PRIVATE_KEY>` with the private key from your VPS and `<HOME_PC_PUBLIC_KEY>` with the public key from your home PC.

2. Enable IP forwarding to allow routing:
    ```
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sysctl -w net.ipv6.conf.all.forwarding=1
    ```

    To make the change permanent, add the following to /etc/sysctl.conf:
    ```
    net.ipv4.ip_forward=1
    net.ipv6.conf.all.forwarding=1
    ```

3. Start the WireGuard interface:
    ```
    sudo wg-quick up wg0    
    ```

    To ensure it starts on boot:
    ```
    sudo systemctl enable wg-quick@wg0
    ```

4. Set up firewall rules (if necessary): If you're using ufw, add rules to allow WireGuard traffic:
    ```
    sudo ufw allow 51820/udp
    ```

    If you're using `iptables`, you can use something like this:
    ```
    sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
    sudo iptables -A FORWARD -i wg0 -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  # Adjust `eth0` if needed, sometime it's ens3
    ```

    To make the IP tables changes permanent, you can use `iptables-persistent`:
    ```
    sudo apt install iptables-persistent
    sudo netfilter-persistent save
    ```

    To check what network interface you're using, run:
    ```
    ip route
    ```
    The output will show the default route, which indicates the network interface being used. Use the network interface with flag default and dev to find the correct interface.
    ```
    default via 10.26.10.1 dev ens3 proto dhcp src 10.26.10.107 metric 100 
    1.1.1.1 via 10.26.10.1 dev ens3 proto dhcp src 10.26.10.107 metric 100 
    10.0.0.0/24 dev wg0 proto kernel scope link src 10.0.0.1 
    ```

## Step 4: Configure WireGuard on the Home PC

1. Create the WireGuard configuration file for the home PC. This could be in /etc/wireguard/wg0.conf on Linux or imported via the WireGuard GUI on Windows/macOS.

    Here's the configuration:
    ```
    [Interface]
    PrivateKey = <HOME_PC_PRIVATE_KEY>
    Address = 10.0.0.2/24    # IP address for the Home PC on the WireGuard network

    [Peer]
    PublicKey = <VPS_PUBLIC_KEY>
    Endpoint = <VPS_PUBLIC_IP>:51820  # VPS public IP and WireGuard port
    AllowedIPs = 0.0.0.0/0         # All traffic will go through the VPN
    PersistentKeepalive = 25       # Keeps the connection alive
    ```
    Replace `<HOME_PC_PRIVATE_KEY>` with the private key for your home PC, and `<VPS_PUBLIC_KEY>` with the public key from the VPS. Replace `<VPS_PUBLIC_IP>` with your VPS's public IP.

2. Start the WireGuard interface on the home PC:
    ```
    sudo wg-quick up wg0
    ```
    On Windows/macOS, you can start the WireGuard interface via the GUI to activate the VPN.

## Step 5: Verify the Connection

1. Check the status on the VPS:

    ```
    sudo wg show
    ```
    This will show the connection status, including peer details (your home PC).

2. Check connectivity from your Home PC:

    - Test connectivity to the VPS:
        ```
        ping 10.0.0.1
        ```
    - Test accessing the internet through the VPS:
        ```
        curl http://example.com
        ```

3. Check routing (optional):

    - On the VPS, verify that traffic is being routed correctly:
        ```
        sudo ip route show
        ```
    - You should see the route to the home PC and any internet-bound traffic routed through the VPN.


## Step 6: Automate and Troubleshoot

1. Automate WireGuard startup:

    - Make sure both the VPS and the home PC start WireGuard automatically on boot using `systemd`:
    ```
    sudo systemctl enable wg-quick@wg0
    ```

2. Troubleshooting:
    - If the VPN isn't working, check the status with `wg show` on both the VPS and the home PC.
    - Check your firewall and routing settings on both machines to ensure that the packets are correctly forwarded.


## Additional Notes:
- If you want to route all traffic from your home PC through the VPS, you’ll need to configure NAT on the VPS to forward packets correctly.
- For Windows/macOS, the setup is similar: install WireGuard, generate the keys, configure the .conf file, and start the connection via the GUI.
