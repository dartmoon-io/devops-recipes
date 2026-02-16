# WireGuard

## Installation
1. Install WireGuard following Pi-hole guidance:
   <https://docs.pi-hole.net/guides/vpn/wireguard/server/>
2. Install UFW and allow required traffic:

```bash
sudo apt install -y ufw
sudo ufw allow 47111/udp
sudo ufw allow OpenSSH
sudo ufw enable
```

3. Use the helper script below to manage clients automatically.

## Client management script
> Save as `wg-clients.sh`, make it executable, and run as root.

```bash
#!/usr/bin/env bash
# wg-clients.sh
# Features:
#   - Add a WireGuard client (auto IP assignment)
#   - Remove a WireGuard client
#   - List existing clients with assigned IPs
#   - Backup wg0.conf before any modification
#   - Detect IP conflicts by checking wg0.conf AND wg live state
#   - Provide usage help when run without parameters

set -e
umask 077
...
```

> The script body is intentionally shortened in this README. Keep your full version in version control.
