
<p align="center">
  🌐 Languages |
  <a href="README.md">English</a> |
  <a href="README.fa.md">فارسی</a> |
  <a href="README.ru.md">Русский</a> |
  <strong>中文</strong>
</p>

---

# softether-to-xui

一个轻量、稳定且专业的桥接方案，用于将 **SoftEther VPN** 的流量转发到 **X-UI（Xray Sanaei）**，并实现对路由、隧道和出口策略的完整控制。

---

## 🔹 项目简介

**softether-to-xui** 通过 TUN 接口并借助 `tun2socks`，接收来自 **SoftEther VPN** 的入站流量，并将其转发到 **X-UI / Xray**。

通过本项目，你可以：
- 接收 SoftEther VPN 用户的流量
- 将该流量导入 X-UI
- 对流量应用 Xray 的路由、隧道和出口策略
- 完全控制 VPN 流量的出口路径

该项目专为 Linux 服务器设计，并以 `systemd` 服务方式运行，内置网络 watchdog 以保证稳定性。

---

## 🔹 为什么要使用这个脚本

SoftEther 在 VPN 用户管理方面非常强大，但在出站流量的高级路由控制上功能有限。

而 Xray / X-UI 提供了非常强大的能力，包括：
- 高级路由规则
- 多种隧道
- 多出口（outbound）配置
- 基于 IP、域名和地理位置的策略
- 精细的流量分流与控制

**softether-to-xui** 将两者结合：

- **SoftEther** → VPN 用户接入与管理  
- **X-UI / Xray** → 智能路由、隧道与流量控制  

适用于以下场景：
- 需要将 VPN 流量引导到指定的 Xray 隧道
- 针对不同类型的流量应用不同规则
- 将 VPN 接入与路由逻辑完全解耦

---

## 🔹 流量流程图

```

VPN Client
↓
SoftEther VPN
↓
tap_softether
↓
TUN 接口 (rtx)
↓
tun2socks
↓
X-UI（SOCKS :10808）
↓
Xray 路由规则与出口

````

---

## 🔹 功能特性

- SoftEther 到 X-UI 的流量转发
- 基于策略的路由（PBR）
- 自动 MTU 与 MSS 调整
- 关闭网卡 offloading 提高稳定性
- 网络 watchdog（自动检测并修复配置）
- systemd 服务管理
- 适合生产环境使用

---

## 🔹 环境要求

- Linux 服务器（推荐 Debian / Ubuntu）
- **SoftEther VPN Server**
- **X-UI（Xray Sanaei）**
- `tun2socks`
- 依赖工具：
  - iproute2
  - iptables
  - ethtool

---

## 🔹 安装说明

### 1️⃣ 一键安装

```bash
wget -O se-install https://raw.githubusercontent.com/Pink210/softether-to-xui/main/softether-to-xui.bash \
  && chmod +x se-install \
  && sudo ./se-install
````

---

### 2️⃣ 创建路由表（必须）

```bash
echo "100 rtx_table" | sudo tee -a /etc/iproute2/rt_tables
```

---

### 3️⃣ 配置 SoftEther VPN

1. 打开 **SoftEther VPN Server Manager**
2. 进入 **Virtual Hub**
3. 创建 **TAP / Local Bridge**
4. TAP 接口名称必须为：

```
tap_softether
```

⚠️ 接口名称必须完全一致，否则脚本无法工作。

该 TAP 接口是 SoftEther 的输出，也是本项目的输入。

---

### 4️⃣ 配置 X-UI（Xray Sanaei）

1. 登录 **X-UI** 面板
2. 进入 **Inbound**
3. 新建一个 inbound：

   * 类型：**SOCKS**
   * 监听地址：`127.0.0.1`
   * 端口：`10808`
   * 认证：可选

该端口是 SoftEther 流量进入 Xray 的入口。

之后你可以：

* 配置路由规则
* 使用不同的 outbound
* 应用隧道与特殊策略

---

### 5️⃣ 启动服务

```bash
systemctl daemon-reload
systemctl enable vpn-network.service
systemctl enable tun2socks.service
systemctl start vpn-network.service
systemctl start tun2socks.service
```

查看日志：

```bash
journalctl -u vpn-network.service -f
```

---

## 🔹 重要说明

* MTU 设置为 1400，以避免数据分片
* MSS Clamping 可修复图片、视频加载异常问题
* 关闭 offloading 可防止 DHCP 与连接异常
* Watchdog 每 10 秒检测一次网络状态
* 所有路由逻辑应在 X-UI 中完成

---

## 🔹 使用场景

* 将 VPN 流量导入 Xray 隧道
* 按国家或 IP 进行路由
* 多出口流量分流
* 专业 VPN + Proxy 架构
* 集中式流量控制

---

## 🔹 许可证

MIT License
可自由使用、修改和分发。

```

