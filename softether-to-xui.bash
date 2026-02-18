#!/usr/bin/env bash

set -e

PROJECT_NAME="softether-to-xui"

echo "[+] Creating project structure..."

mkdir -p $PROJECT_NAME/systemd
cd $PROJECT_NAME

echo "[+] Creating net_watchdog.sh..."

cat > net_watchdog.sh << 'EOF'
#!/bin/bash

log() {
    echo "[softether-to-xui] $1"
}

setup_network() {
    log "Applying network configuration..."

    if ! ip addr show tap_softether | grep -q "198.19.0.1"; then
        ip addr add 198.19.0.1/24 dev tap_softether || true
        ip link set dev tap_softether mtu 1400 || true
        ethtool -K tap_softether tx off rx off tso off gso off gro off sg off || true
        ip link set dev tap_softether up || true
    fi

    if ! ip link show rtx >/dev/null 2>&1; then
        ip tuntap add mode tun dev rtx || true
    fi

    if ! ip addr show rtx | grep -q "198.18.0.1"; then
        ip addr add 198.18.0.1/15 dev rtx || true
        ip link set dev rtx mtu 1400 || true
        ethtool -K rtx tx off rx off tso off gso off gro off sg off || true
        ip link set dev rtx up || true
    fi

    if ! ip route show table rtx_table | grep -q default; then
        ip route add 198.19.0.0/24 dev rtx table rtx_table || true
        ip route add default dev rtx table rtx_table || true
    fi

    if ! ip rule show | grep -q rtx_table; then
        ip rule add from 198.19.0.0/24 table rtx_table priority 10 || true
    fi

    ip rule show | grep -q "8.8.8.8" || ip rule add to 8.8.8.8 table main priority 11
    ip rule show | grep -q "8.8.4.4" || ip rule add to 8.8.4.4 table main priority 12

    iptables -C FORWARD -i tap_softether -o rtx -j ACCEPT 2>/dev/null || \
        iptables -A FORWARD -i tap_softether -o rtx -j ACCEPT

    iptables -C FORWARD -i rtx -o tap_softether -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
        iptables -A FORWARD -i rtx -o tap_softether -m state --state ESTABLISHED,RELATED -j ACCEPT

    iptables -t mangle -C FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || \
        iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

    echo 1 > /proc/sys/net/ipv4/ip_forward
}

while true; do
    if ip link show tap_softether >/dev/null 2>&1; then
        if ! ip addr show tap_softether | grep -q "198.19.0.1"; then
            log "Network config lost, reapplying..."
            setup_network
        fi

        if ethtool -k tap_softether | grep -q "tx-checksumming: on"; then
            log "Ethtool settings reset, fixing..."
            ethtool -K tap_softether tx off rx off tso off gso off gro off sg off || true
        fi
    else
        log "Waiting for tap_softether interface..."
    fi

    if ! ip route show table rtx_table | grep -q default; then
        setup_network
    fi

    sleep 10
done
EOF

chmod +x net_watchdog.sh

echo "[+] Creating systemd services..."

cat > systemd/vpn-network.service << 'EOF'
[Unit]
Description=SoftEther to X-UI Network Watchdog
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /opt/net_watchdog.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat > systemd/tun2socks.service << 'EOF'
[Unit]
Description=Tun2Socks Service for X-UI
After=network.target vpn-network.service
Requires=vpn-network.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/tun2socks -device rtx -proxy socks5://127.0.0.1:10808
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Creating README.md..."

cat > README.md << 'EOF'
# softether-to-xui

A lightweight bridge that forwards traffic from **SoftEther VPN** to **X-UI (Xray Sanaei)** with full routing control.

## Features
- SoftEther → TUN → tun2socks → X-UI
- Policy-based routing (PBR)
- MTU & MSS fixing
- Offloading disable for stability
- systemd services
- Network watchdog

## Requirements
- SoftEther VPN
- X-UI (xray sanaei)
- tun2socks
- iproute2, iptables, ethtool

## Required routing table
```bash
echo "100 rtx_table" | sudo tee -a /etc/iproute2/rt_tables
