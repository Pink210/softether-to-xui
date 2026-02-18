<p align="center">
  🌐 Languages |
  <strong>English</strong> |
  <a href="README.fa.md">فارسی</a> |
  <a href="README.ru.md">Русский</a> |
  <a href="README.zh.md">中文</a>
</p>





# Softether-To-X-ui

A lightweight and stable bridge that forwards traffic from **SoftEther VPN** to **X-UI (Xray Sanaei)**, designed for advanced routing, tunneling, and traffic control scenarios.

---

## 🔹 Project Summary

**softether-to-xui** connects **SoftEther VPN** to **X-UI (Xray Sanaei)** using a TUN interface and `tun2socks`.

It allows you to:
- Receive traffic from SoftEther clients
- Forward that traffic into X-UI
- Apply **routing rules, policies, tunnels, and outbound logic** inside Xray/X-UI
- Fully control how VPN traffic exits your server

This project is built for Linux servers and runs using `systemd` services with a built-in network watchdog for stability.

---

## 🔹 Why This Script Exists

SoftEther is very good at handling VPN clients, but it does not provide advanced outbound routing features.

Xray / X-UI is very powerful for:
- Routing rules
- Selective tunneling
- Multiple outbounds
- Geo-based or IP-based routing
- Traffic splitting and policy control

**softether-to-xui** combines the best of both worlds:

- **SoftEther** → client management and VPN access  
- **X-UI / Xray** → smart routing, tunneling, and traffic control  

This setup is ideal when you want:
- VPN users routed through specific Xray outbounds
- Different rules for different traffic types
- Clean separation between VPN access and routing logic

---

## 🔹 Traffic Flow (How It Works)

```

VPN Client
↓
SoftEther VPN
↓
tap_softether
↓
TUN interface (rtx)
↓
tun2socks
↓
X-UI (SOCKS inbound :10808)
↓
Xray routing / outbounds

````

---

## 🔹 Features

- SoftEther → X-UI traffic forwarding
- Policy-Based Routing (PBR)
- Automatic MTU and MSS fixing
- Disable NIC offloading for stability
- Network watchdog (auto re-apply config)
- systemd service support
- Designed for production servers

---

## 🔹 Requirements

- Linux server (recommended: Debian / Ubuntu)
- **SoftEther VPN Server**
- **X-UI (Xray Sanaei)**
- `tun2socks`
- `iproute2`
- `iptables`
- `ethtool`

---

## 🔹 Installation Guide

### 1️⃣ Download the Script

Follow the installation instructions from the repository:

👉  
https://github.com/Pink210/softether-to-xui/blob/main/softether-to-xui

```bash
wget -O se-install https://raw.githubusercontent.com/Pink210/softether-to-xui/main/softether-to-xui.bash \
  && chmod +x se-install \
  && sudo ./se-install

````
🔸 Notes (optional to keep under it)
    This script installs softether-to-xui
    It copies files to /opt and /etc/systemd/system
    Requires root access
    Make sure SoftEther, X-UI, and tun2socks are already installed
---


### 2️⃣ Configure SoftEther VPN

1. Open **SoftEther VPN Server Manager**
2. Go to **Virtual Hub**
3. Create a **Local Bridge / TAP interface**
4. Create a TAP device named exactly:

```
tap_softether
```

⚠️ The name **must match**, otherwise the script will not work.

This TAP interface is the **output of SoftEther** and the **input of this script**.

---

### 3️⃣ Configure X-UI (Xray Sanaei)

1. Open **X-UI panel**
2. Go to **Inbound**
3. Create a new inbound:

   * Type: **SOCKS**
   * Listen IP: `127.0.0.1`
   * Port: `10808`
   * Authentication: optional

This SOCKS inbound is where **SoftEther traffic enters Xray**.

You can now:

* Route traffic using Xray rules
* Send traffic to specific outbounds
* Apply tunnels, blocks, or filters

---

### 4️⃣ Enable systemd Services

```bash
systemctl daemon-reload
systemctl enable vpn-network.service
systemctl enable tun2socks.service
systemctl start vpn-network.service
systemctl start tun2socks.service
```

Check logs:

```bash
journalctl -u vpn-network.service -f
```

---

## 🔹 Notes & Best Practices

* MTU is set to **1400** to avoid fragmentation
* MSS clamping fixes broken image/video loading
* Offloading is disabled to prevent SoftEther DHCP issues
* Watchdog checks network state every 10 seconds
* All routing logic should be handled **inside X-UI**

---

## 🔹 Use Cases

* Route VPN users through Xray tunnels
* Apply country-based routing
* Split traffic between multiple outbounds
* Advanced firewall + proxy setups
* Centralized VPN + routing architecture

---

## 🔹 License

MIT License
Free to use, modify, and distribute.
