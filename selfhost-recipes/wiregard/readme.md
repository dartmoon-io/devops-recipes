# Wiregard

1. Installa wiregard as per [PiHole's instructions](https://docs.pi-hole.net/guides/vpn/wireguard/server/).
2. Once Wiregard is installed and cofigured, install ufw to manage firewall rules:
   ```bash
   sudo apt install ufw
   ```
3. Allow Wiregard traffic through the firewall:
    ```bash
    sudo ufw allow 47111/udp
    sudo ufw allow ssh
    ```
4. Enable the firewall:
    ```bash
    sudo ufw enable
    ```
5. Use this script to automatically create and manage Wiregard clients:
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

# --------------------------
# Configuration
# --------------------------
WG_INTERFACE="wg0"
WG_CONF_DIR="/etc/wireguard"
SERVER_CONF="${WG_CONF_DIR}/${WG_INTERFACE}.conf"

CLIENT_DIR="/home/raspberry"

SERVER_PUBLIC_IP="EXTERNAL_IP_OR_DOMAIN"
SERVER_PORT="47111"

DNS_SERVER="8.8.8.8"
ALLOWED_IPS="192.168.1.1/24"

# Pi-hole recommended addressing
PREFIX4="10.100.0."
PREFIX6="fd08:4711::"

SERVER_ADDR4="${PREFIX4}1"
SERVER_ADDR6="${PREFIX6}1"

BACKUP_DIR="${WG_CONF_DIR}/backups"
mkdir -p "$BACKUP_DIR"

# --------------------------
# Helper: print usage
# --------------------------
print_help() {
    echo ""
    echo "Usage:"
    echo "  $0 add <client_name>      - Add a new WireGuard client"
    echo "  $0 remove <client_name>   - Remove an existing client"
    echo "  $0 list                   - List all configured clients"
    echo ""
    exit 1
}

# --------------------------
# Check if client exists
# --------------------------
client_exists() {
    grep -q "### CLIENT $1" "$SERVER_CONF"
}

# --------------------------
# Extract IPv4 used in config
# --------------------------
used_ips_from_conf() {
    grep AllowedIPs "$SERVER_CONF" | awk -F'[./]' '{print $4}'
}

# --------------------------
# Extract IPv4 from live WG state
# --------------------------
used_ips_from_runtime() {
    wg show "$WG_INTERFACE" allowed-ips 2>/dev/null \
        | awk '{print $2}' | cut -d'/' -f1 | awk -F'.' '{print $4}' || true
}

# --------------------------
# Select first free IPv4
# --------------------------
find_next_ip() {
    CONF_IPS=$(used_ips_from_conf)
    LIVE_IPS=$(used_ips_from_runtime)
    ALL_USED=$(echo -e "${CONF_IPS}\n${LIVE_IPS}" | sort -n | uniq)

    for i in $(seq 2 254); do
        if ! echo "$ALL_USED" | grep -qx "$i"; then
            echo "$i"
            return
        fi
    done

    echo "ERROR"
}

# --------------------------
# Backup wg0.conf
# --------------------------
backup_conf() {
    ts=$(date +"%Y%m%d-%H%M%S")
    cp "$SERVER_CONF" "${BACKUP_DIR}/${WG_INTERFACE}.conf.$ts"
    echo "[+] Backup saved: ${BACKUP_DIR}/${WG_INTERFACE}.conf.$ts"
}

# --------------------------
# Add client
# --------------------------
add_client() {
    CLIENT_NAME="$1"
    echo "[+] Adding client: $CLIENT_NAME"

    if client_exists "$CLIENT_NAME"; then
        echo "❌ Client already exists"
        exit 1
    fi

    NEXT_IP=$(find_next_ip)
    if [[ "$NEXT_IP" == "ERROR" ]]; then
        echo "❌ No available IPs"
        exit 1
    fi

    CLIENT_ADDR4="${PREFIX4}${NEXT_IP}"
    CLIENT_ADDR6="${PREFIX6}${NEXT_IP}"

    echo "[+] Assigned IPv4 $CLIENT_ADDR4 and IPv6 $CLIENT_ADDR6"

    backup_conf
    cd "$WG_CONF_DIR"

    # Generate keys
    wg genkey | tee "${CLIENT_NAME}.key" | wg pubkey > "${CLIENT_NAME}.pub"
    wg genpsk > "${CLIENT_NAME}.psk"

    CLIENT_PRIVKEY=$(cat "${CLIENT_NAME}.key")
    CLIENT_PUBKEY=$(cat "${CLIENT_NAME}.pub")
    CLIENT_PSK=$(cat "${CLIENT_NAME}.psk")
    SERVER_PUBKEY=$(cat server.pub)

    # Append peer
    {
        echo ""
        echo "### CLIENT ${CLIENT_NAME}"
        echo "[Peer]"
        echo "PublicKey = ${CLIENT_PUBKEY}"
        echo "PresharedKey = ${CLIENT_PSK}"
        echo "AllowedIPs = ${CLIENT_ADDR4}/32, ${CLIENT_ADDR6}/128"
    } >> "$SERVER_CONF"

    # Create client config
    CLIENT_CONF="${CLIENT_NAME}.conf"
    {
        echo "[Interface]"
        echo "PrivateKey = ${CLIENT_PRIVKEY}"
        echo "Address = ${CLIENT_ADDR4}/32, ${CLIENT_ADDR6}/128"
        echo "DNS = ${DNS_SERVER}"
        echo ""
        echo "[Peer]"
        echo "PublicKey = ${SERVER_PUBKEY}"
        echo "PresharedKey = ${CLIENT_PSK}"
        echo "Endpoint = ${SERVER_PUBLIC_IP}:${SERVER_PORT}"
        echo "AllowedIPs = ${ALLOWED_IPS}"
        echo "PersistentKeepalive = 25"
    } > "$CLIENT_CONF"

    cp "$CLIENT_CONF" "${CLIENT_DIR}/"
    chown raspberry:raspberry "${CLIENT_DIR}/${CLIENT_CONF}"
    chmod 600 "${CLIENT_DIR}/${CLIENT_CONF}"

    echo "[+] Restarting WireGuard..."
    systemctl restart wg-quick@${WG_INTERFACE}

    echo "✅ Client $CLIENT_NAME added successfully!"
}

# --------------------------
# Remove client
# --------------------------
remove_client() {
    CLIENT_NAME="$1"

    echo "[+] Removing client: $CLIENT_NAME"

    if ! client_exists "$CLIENT_NAME"; then
        echo "❌ Client does not exist"
        exit 1
    fi

    backup_conf

    sed -i "/### CLIENT ${CLIENT_NAME}/,/AllowedIPs/d" "$SERVER_CONF"

    cd "$WG_CONF_DIR"
    rm -f "${CLIENT_NAME}.key" "${CLIENT_NAME}.pub" "${CLIENT_NAME}.psk" "${CLIENT_NAME}.conf"
    rm -f "${CLIENT_DIR}/${CLIENT_NAME}.conf"

    echo "[+] Restarting WireGuard..."
    systemctl restart wg-quick@${WG_INTERFACE}

    echo "🗑️ Client $CLIENT_NAME removed."
}

# --------------------------
# List clients
# --------------------------
list_clients() {
    echo "📜 Existing clients"
    echo "------------------------------------"

    while read -r CLIENT; do
        IPv4=$(grep -A10 -E "### CLIENT[[:space:]]+$CLIENT" "$SERVER_CONF" \
            | grep -i "AllowedIPs" \
            | tr -d '\r' \
            | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" \
            | head -n1 \
            | awk -F'.' '{print $4}')

        echo "• $CLIENT → ${PREFIX4}${IPv4}"
    done < <(grep -E "### CLIENT" "$SERVER_CONF" | awk '{print $3}' | tr -d '\r')

    echo "------------------------------------"
}

# --------------------------
# Main
# --------------------------
if [[ "$#" -lt 1 ]]; then
    print_help
fi

ACTION="$1"

case "$ACTION" in
    add)
        [[ -z "$2" ]] && print_help
        add_client "$2"
        ;;
    remove)
        [[ -z "$2" ]] && print_help
        remove_client "$2"
        ;;
    list)
        list_clients
        ;;
    *)
        print_help
        ;;
esac
   ```