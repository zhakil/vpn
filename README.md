# 🚀 VPN - VPS代理管理系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Nginx](https://img.shields.io/badge/Nginx-1.20+-green.svg)](https://nginx.org/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Latest-orange.svg)](https://prometheus.io/)

> 🔒 基于混合分层架构的VPS代理管理系统，支持V2Ray、Clash、Hysteria等多种协议的统一管理和监控。

## ✨ 项目特色

🎯 **交互式部署**: 智能引导，一键部署  
🔧 **多协议支持**: V2Ray/Clash/Hysteria/TUIC/WireGuard  
🌐 **Web管理界面**: 直观友好的管理控制台  
📊 **实时监控**: Prometheus + Grafana 监控体系  
🔒 **安全防护**: SSL/TLS加密，防火墙配置  
💾 **自动备份**: 数据备份和恢复机制  

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────────┐
│                        用户访问层                                 │
├─────────────────────────────────────────────────────────────────┤
│  Web管理界面  │  移动端APP  │  API客户端  │  命令行工具           │
├─────────────────────────────────────────────────────────────────┤
│           Nginx反向代理 + SSL终结 + 限流防护                      │
├─────────────────────────────────────────────────────────────────┤
│  身份认证  │  权限控制  │  请求路由  │  限流熔断  │  日志审计      │
├─────────────────────────────────────────────────────────────────┤
│ 用户管理服务 │ 规则引擎服务 │ 配置管理服务 │ 监控统计服务         │
├─────────────────────────────────────────────────────────────────┤
│ V2Ray适配器 │ Clash适配器 │ Hysteria适配器 │ 插件适配器          │
├─────────────────────────────────────────────────────────────────┤
│   V2Ray实例   │   Clash实例   │ Hysteria实例  │   插件实例        │
├─────────────────────────────────────────────────────────────────┤
│ PostgreSQL │    Redis    │  InfluxDB   │  文件存储  │  日志存储   │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 快速开始

### 📋 系统要求

| 项目 | 最低要求 | 推荐配置 |
|------|---------|---------|
| **操作系统** | Ubuntu 20.04+ / CentOS 8+ / Debian 11+ | Ubuntu 22.04 LTS |
| **CPU** | 2核心 | 4核心 |
| **内存** | 4GB | 8GB |
| **磁盘** | 20GB | 50GB SSD |
| **网络** | 公网IP | 带宽≥10Mbps |

### 🔧 一键部署

```bash
# 1. 克隆仓库
git clone https://github.com/zhakil/vpn.git
cd vpn

# 2. 运行交互式部署脚本
sudo bash scripts/deploy.sh
```

或者直接下载运行：

```bash
# 下载并运行
curl -sSL https://raw.githubusercontent.com/zhakil/vpn/main/scripts/deploy.sh | sudo bash
```

### 3. 部署流程

部署脚本将引导您完成以下配置：

1. **系统检查**: 自动检测操作系统和资源
2. **IP地址获取**: 自动获取或手动输入服务器IP
3. **域名和SSL配置**: 选择域名+Let's Encrypt或IP+自签名证书
4. **协议选择**: 选择V2Ray/Clash/Hysteria或全部协议
5. **管理员账户**: 设置管理员邮箱和密码
6. **自动部署**: 自动安装Docker和启动服务

## 配置选项说明

### SSL证书选项

1. **Let's Encrypt SSL** (推荐)
   - 需要域名和邮箱
   - 自动续期
   - 浏览器信任

2. **自签名SSL**
   - 不需要域名
   - 浏览器警告
   - 适合测试环境

3. **仅IP地址**
   - 使用IP访问
   - 自签名SSL
   - 最简单配置

### 协议选择指南

1. **V2Ray** (通用推荐)
   - 支持VMess/VLESS/Trojan/Shadowsocks
   - 客户端广泛支持
   - 功能全面稳定

2. **Clash** (客户端丰富)
   - 支持所有主流协议
   - 规则分流功能强大
   - 图形化客户端多

3. **Hysteria** (高速传输)
   - 基于QUIC协议
   - 高速传输优化
   - 适合高带宽环境

4. **全部协议** (资源消耗较大)
   - 同时部署所有协议
   - 需要更多系统资源
   - 最大灵活性

## 服务访问

部署完成后，您可以访问：

- **管理界面**: `https://your-domain.com` 或 `https://your-ip`
- **API接口**: `https://your-domain.com/api`
- **监控面板**: `https://your-domain.com/grafana`
- **Prometheus**: `https://your-domain.com/prometheus` (仅内网)

## 端口说明

| 端口范围 | 协议 | 用途 |
|---------|------|------|
| 80/443 | TCP | HTTP/HTTPS管理界面 |
| 8080-8087 | TCP | 内部服务API |
| 10001-10020 | TCP | V2Ray代理端口 |
| 7890-7891 | TCP | Clash代理端口 |
| 9090 | TCP | Clash API端口 |
| 36712 | UDP | Hysteria代理端口 |

## 常用命令

```bash
# 查看所有服务状态
docker-compose ps

# 查看指定服务日志
docker-compose logs -f [service-name]

# 重启所有服务
docker-compose restart

# 重启指定服务
docker-compose restart [service-name]

# 停止所有服务
docker-compose down

# 更新服务
docker-compose pull && docker-compose up -d
```

## 故障排查

### 常见问题

1. **服务无法启动**
   - 检查端口是否被占用
   - 查看配置文件语法
   - 检查系统资源

2. **网络连接问题**
   - 检查防火墙设置
   - 验证DNS解析
   - 查看端口监听状态

3. **SSL证书问题**
   - 检查证书有效期
   - 验证域名配置
   - 重新申请证书

### 日志查看

```bash
# 查看系统日志
journalctl -u docker -f

# 查看Nginx日志
docker-compose logs -f nginx

# 查看所有服务日志
docker-compose logs -f
```

## 安全建议

1. **定期更新系统补丁**
2. **修改默认管理员密码**
3. **限制管理界面访问IP**
4. **定期备份重要数据**
5. **监控系统资源使用**

## 技术支持

如遇到问题，请提供以下信息：

1. 系统信息: `uname -a`
2. Docker版本: `docker --version`
3. 错误日志: `docker-compose logs`
4. 服务状态: `docker-compose ps`

## 版本信息

- **当前版本**: v1.0.0
- **更新日期**: $(date +%Y-%m-%d)
- **兼容性**: Docker 20.10+, Docker Compose 2.0+

---

感谢使用VPS代理管理系统！