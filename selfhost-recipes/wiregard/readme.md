# WireGuard

## Installation
1. Install WireGuard following Pi-hole guidance:
   <https://docs.pi-hole.net/guides/vpn/wireguard/server/>

2. Install UFW:

```bash
sudo apt install -y ufw
```

3. Allow WireGuard and SSH through the firewall:

```bash
sudo ufw allow 47111/udp
sudo ufw allow OpenSSH
```

4. Enable the firewall:

```bash
sudo ufw enable
```

5. Use `wg-clients.sh` (included in this folder) to create and manage clients automatically.

## Client management script
Copy the script to your server and make it executable:

```bash
sudo cp wg-clients.sh /usr/local/sbin/wg-clients.sh
sudo chmod +x /usr/local/sbin/wg-clients.sh
```

Usage:

```bash
sudo /usr/local/sbin/wg-clients.sh add <client_name>
sudo /usr/local/sbin/wg-clients.sh remove <client_name>
sudo /usr/local/sbin/wg-clients.sh list
```
