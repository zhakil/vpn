# 🚀 zhakil科技箱 VPN代理管理系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-v4.0.0-blue.svg)](https://github.com/zhakil/vpn)
[![Platform](https://img.shields.io/badge/Platform-Linux-green.svg)](https://github.com/zhakil/vpn)
[![Protocols](https://img.shields.io/badge/Protocols-V2Ray|Clash|Hysteria-orange.svg)](https://github.com/zhakil/vpn)

> 🔒 专业的VPN代理服务器一键部署和管理系统，支持V2Ray、Clash、Hysteria多协议，提供完整的客户端配置生成功能。

## ✨ 主要特色

🎯 **一键部署**: 全自动安装配置，无需手动操作  
🔧 **多协议支持**: V2Ray VMESS + Clash + Hysteria UDP  
🌐 **配置生成**: 完整的客户端配置文件和分享链接  
📊 **专业管理**: 交互式管理界面和状态监控  
🔒 **安全优化**: BBR加速、防火墙配置、SSL证书  
💾 **配置导出**: 支持批量导出和二维码生成  

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    zhakil科技箱 v4.0.0                       │
├─────────────────────────────────────────────────────────────┤
│  管理界面  │  配置生成  │  状态监控  │  日志管理  │  系统优化   │
├─────────────────────────────────────────────────────────────┤
│              Nginx反向代理 + SSL终结                          │
├─────────────────────────────────────────────────────────────┤
│  V2Ray服务  │  Clash服务  │ Hysteria服务 │  Web管理面板      │
├─────────────────────────────────────────────────────────────┤
│    VMESS     │   HTTP/SOCKS  │     UDP      │   统计接口      │
│  WebSocket   │   代理服务    │   QUIC传输   │   配置接口      │
├─────────────────────────────────────────────────────────────┤
│  BBR加速  │  防火墙配置  │  系统优化  │  证书管理  │  日志轮转    │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 快速开始

### 📋 系统要求

| 配置 | CPU | 内存 | 磁盘 | 系统 | 推荐用途 |
|------|-----|-----|-----|------|---------|
| **最低配置** | 1核心 | 512MB | 5GB | Ubuntu 18+ / CentOS 7+ | 个人使用 |
| **推荐配置** | 1核心 | 1GB | 10GB | Ubuntu 20+ / CentOS 8+ | 多用户使用 |
| **最佳配置** | 2核心 | 2GB | 20GB | Ubuntu 22+ / Debian 11+ | 高性能需求 |

### 🔧 一键安装

#### 🚀 完整版安装（推荐）
```bash
# 一键安装完整版（包含所有功能）
bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/install.sh)
```

#### ⚡ 快速部署
```bash
# 直接部署VPN服务
bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/deploy.sh)
```

#### 📥 手动安装
```bash
# 1. 下载项目
git clone https://github.com/zhakil/vpn.git
cd vpn

# 2. 执行安装
sudo bash install.sh

# 3. 或直接部署
sudo bash deploy.sh
```

### 🎮 使用管理界面

安装完成后，使用以下命令进入管理界面：

```bash
# 进入管理界面
zhakil
```

## 📱 客户端配置

### 🔗 配置生成中心

在管理界面中选择 **"7. 配置生成中心"** 可以获取：

#### V2Ray 客户端配置
- ✅ 完整的JSON配置文件
- ✅ VMESS分享链接 (vmess://)
- ✅ 二维码扫码导入

#### Clash 客户端配置  
- ✅ 完整的YAML配置文件
- ✅ 智能分流规则
- ✅ 自动选择和故障转移

#### Hysteria 客户端配置
- ✅ 详细的YAML配置文件
- ✅ QUIC传输优化
- ✅ 混淆设置

#### 批量导出功能
- ✅ 所有协议配置文件
- ✅ 通用订阅链接
- ✅ 分享链接合集
- ✅ 二维码图片

### 📲 推荐客户端

#### Windows
- **V2RayN**: 支持V2Ray协议
- **Clash for Windows**: 支持多协议，功能强大
- **Hysteria**: 官方客户端

#### macOS
- **V2RayU**: V2Ray图形客户端
- **ClashX**: Clash图形客户端  
- **Hysteria**: 命令行客户端

#### iOS
- **Shadowrocket**: 付费，功能全面
- **Quantumult X**: 付费，规则强大
- **Surge**: 付费，专业级

#### Android
- **V2RayNG**: V2Ray官方客户端
- **Clash for Android**: 免费开源
- **Hysteria**: 官方客户端

## 🌐 服务访问

部署完成后，您可以访问：

| 服务 | 地址 | 说明 |
|-----|------|------|
| **主页面** | `https://your-server-ip` | 服务器状态页面 |
| **管理界面** | `zhakil` 命令 | 交互式管理界面 |  
| **Clash面板** | `http://your-server-ip:9090` | Clash Web界面 |
| **Web管理** | `http://your-server-ip:8080` | Web管理面板 |
| **配置信息** | `cat /root/vpn-info.txt` | 完整配置信息 |

## 🛠️ 服务端口说明

| 端口 | 协议 | 用途 | 说明 |
|-----|------|------|------|
| 80/443 | TCP | HTTP/HTTPS | Web服务和SSL |
| 10001 | TCP | V2Ray VMESS | WebSocket传输 |
| 7890 | TCP | Clash HTTP | HTTP代理端口 |
| 7891 | TCP | Clash SOCKS | SOCKS代理端口 |  
| 9090 | TCP | Clash API | 管理面板端口 |
| 36712 | UDP | Hysteria | QUIC高速传输 |
| 8080 | TCP | Web管理 | 管理面板 |

## 🎛️ 常用命令

### 管理服务
```bash
# 进入管理界面
zhakil

# 查看所有服务状态
systemctl status v2ray clash hysteria-server nginx

# 重启所有服务
systemctl restart v2ray clash hysteria-server nginx

# 查看服务日志
journalctl -u v2ray -f       # V2Ray日志
journalctl -u clash -f       # Clash日志  
journalctl -u hysteria-server -f  # Hysteria日志
```

### 配置管理
```bash
# 查看完整配置信息
cat /root/vpn-info.txt

# 查看环境变量配置
cat /root/vpn-config.env

# 生成客户端配置
zhakil  # 选择第7项"配置生成中心"
```

### 系统维护
```bash
# 更新系统脚本
zhakil  # 选择00进行脚本更新

# 完全卸载系统
bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/uninstall.sh)

# 强制卸载（紧急情况）
bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/force-uninstall.sh)
```

## 🔧 故障排查

### 常见问题

#### 1. 服务无法启动
```bash
# 检查服务状态
systemctl status v2ray clash hysteria-server

# 查看错误日志  
journalctl -u v2ray -n 50
journalctl -u clash -n 50
journalctl -u hysteria-server -n 50
```

#### 2. 端口无法访问
```bash
# 检查端口监听
netstat -tlnp | grep 10001  # V2Ray
netstat -tlnp | grep 7890   # Clash
netstat -ulnp | grep 36712  # Hysteria

# 检查防火墙状态
ufw status                   # Ubuntu
firewall-cmd --list-ports    # CentOS
```

#### 3. 配置生成问题
```bash
# 检查配置文件
ls -la /root/vpn-*.txt /root/vpn-*.env

# 重新生成配置
source /root/.bashrc
zhakil  # 进入配置生成中心
```

#### 4. 网络连接问题
```bash
# 检查服务器IP
curl -4 ifconfig.me

# 测试端口连通性
telnet your-server-ip 10001  # V2Ray
nc -zv your-server-ip 36712  # Hysteria UDP
```

### 日志分析
```bash
# 实时查看所有相关日志
multitail /var/log/v2ray/access.log /var/log/v2ray/error.log /var/log/hysteria/server.log

# 查看系统性能
top
free -h
df -h
```

## 🔒 安全建议

### 基础安全
1. **定期更新系统补丁**: `apt update && apt upgrade`
2. **修改SSH端口**: 避免使用默认22端口
3. **禁用root登录**: 使用普通用户+sudo
4. **配置密钥认证**: 禁用密码登录

### 服务安全
1. **定期更换UUID和密码**: 通过管理界面重新生成
2. **监控异常连接**: 查看访问日志
3. **限制连接数**: 配置客户端数量限制
4. **定期备份配置**: 备份 `/etc/` 下的配置文件

### 网络安全
1. **使用CDN**: 隐藏真实服务器IP
2. **配置域名**: 使用域名访问更安全
3. **启用防火墙**: 只开放必要端口
4. **监控流量**: 定期检查异常流量

## 📚 技术文档

### 配置文件位置
```bash
# V2Ray配置
/usr/local/etc/v2ray/config.json

# Clash配置  
/etc/clash/config.yaml

# Hysteria配置
/etc/hysteria/config.yaml

# Nginx配置
/etc/nginx/sites-available/vpn-proxy

# 系统配置信息
/root/vpn-info.txt
/root/vpn-config.env
```

### 协议说明

#### V2Ray VMESS
- **传输协议**: WebSocket over HTTP/HTTPS
- **加密方式**: AES-128-GCM (auto)
- **伪装路径**: `/ray`
- **alterID**: 64 (提高安全性)

#### Clash 代理
- **支持协议**: HTTP/SOCKS5/混合代理
- **分流规则**: 基于域名和IP的智能分流  
- **负载均衡**: 自动选择最优节点
- **故障转移**: 自动切换可用节点

#### Hysteria UDP
- **基础协议**: QUIC over UDP
- **认证方式**: Password认证
- **混淆技术**: Salamander混淆
- **带宽优化**: 自适应拥塞控制

## 📞 技术支持

### 问题反馈
- **GitHub Issues**: [提交问题](https://github.com/zhakil/vpn/issues)
- **项目主页**: https://github.com/zhakil/vpn

### 获取帮助
提交问题时请提供以下信息：

1. **系统信息**:
   ```bash
   cat /etc/os-release
   uname -a
   ```

2. **服务状态**:
   ```bash
   systemctl status v2ray clash hysteria-server
   ```

3. **错误日志**:
   ```bash
   journalctl -u v2ray -n 50
   journalctl -u clash -n 50  
   journalctl -u hysteria-server -n 50
   ```

4. **配置信息**:
   ```bash
   cat /root/vpn-info.txt
   ```

## 📄 版本信息

- **当前版本**: v4.0.0
- **发布日期**: 2024年12月
- **兼容系统**: Ubuntu 18+, Debian 10+, CentOS 7+
- **最后更新**: $(date +%Y年%m月%d日)

## 🎯 更新日志

### v4.0.0 (2024-12-XX)
- ✨ 全新的VPN代理管理系统
- ✨ 支持V2Ray VMESS WebSocket
- ✨ 集成Clash代理和智能分流
- ✨ 添加Hysteria UDP高速传输
- ✨ BBR网络优化和系统调优
- ✨ 专业的配置生成和管理界面
- ✨ 完整的客户端配置导出功能
- ✨ Web管理面板和状态监控

## 📜 开源协议

本项目基于 [MIT License](LICENSE) 开源协议发布。

---

## 🙏 致谢

感谢以下开源项目的支持：
- [V2Ray](https://github.com/v2fly/v2ray-core) - 强大的代理工具
- [Clash](https://github.com/Dreamacro/clash) - 规则代理程序  
- [Hysteria](https://github.com/apernet/hysteria) - 高速网络代理

---

**💡 如果这个项目对您有帮助，请给个 ⭐ Star 支持一下！**

使用过程中遇到问题，欢迎提交 [Issue](https://github.com/zhakil/vpn/issues) 或 [Pull Request](https://github.com/zhakil/vpn/pulls)。