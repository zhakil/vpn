# VPS代理管理系统 - 快速开始指南

## 🚀 一键部署

### 步骤1: 准备服务器
确保您的VPS满足以下要求：
- **系统**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **配置**: 2核CPU, 4GB内存, 20GB硬盘
- **网络**: 公网IP，开放必要端口

### 步骤2: 下载部署文件
```bash
# 上传部署文件到服务器
scp -r vps-deployment/ root@your-server-ip:/tmp/
```

### 步骤3: 运行交互式部署
```bash
# 登录服务器
ssh root@your-server-ip

# 进入部署目录
cd /tmp/vps-deployment

# 运行部署脚本
sudo bash scripts/deploy.sh
```

## 🔧 部署配置选项

### SSL证书选择
- **Option 1**: 域名 + Let's Encrypt SSL ✅ 推荐
  - 需要：域名、邮箱
  - 优点：自动续期、浏览器信任
  
- **Option 2**: 域名 + 自签名SSL
  - 需要：域名
  - 缺点：浏览器警告
  
- **Option 3**: IP + 自签名SSL 
  - 需要：仅IP地址
  - 适合：测试环境

### 协议选择指南
- **V2Ray**: 通用推荐，支持VMess/VLESS/Trojan
- **Clash**: 客户端丰富，规则分流强大  
- **Hysteria**: 高速传输，基于QUIC协议
- **全部协议**: 最大灵活性，需要更多资源

## 📝 部署流程示例

```
========================================
  VPS代理管理系统部署程序  
========================================

1. 检测到 Ubuntu 22.04 LTS
2. 服务器IP: 1.2.3.4
3. 选择配置:
   - 域名: proxy.example.com
   - SSL: Let's Encrypt  
   - 协议: V2Ray
   - 管理员: admin@example.com
4. 自动安装Docker和依赖
5. 生成配置文件和证书
6. 启动所有服务
7. 部署完成 ✅
```

## 🌐 访问系统

部署成功后访问：

- **管理界面**: `https://your-domain.com`
- **监控面板**: `https://your-domain.com/grafana` 
- **API文档**: `https://your-domain.com/api/docs`

**默认账户**: 使用部署时设置的管理员邮箱和密码

## ⚡ 快速验证

```bash
# 检查所有服务状态
docker-compose ps

# 查看系统日志
docker-compose logs -f

# 测试网络连通性
curl -k https://your-domain.com/health
```

## 🔧 常用管理命令

```bash
# 重启服务
docker-compose restart

# 更新系统
docker-compose pull && docker-compose up -d

# 备份数据
# (将来添加备份脚本)

# 查看资源使用
docker stats

# 查看端口监听
netstat -tlnp | grep -E "(80|443|10001)"
```

## 🆘 常见问题

### 问题1: 证书申请失败
```bash
# 检查域名解析
nslookup your-domain.com

# 手动申请证书
bash scripts/setup-ssl.sh --domain your-domain.com --letsencrypt --email your@email.com
```

### 问题2: 服务启动失败
```bash
# 检查端口占用
netstat -tlnp | grep -E "(80|443)"

# 查看详细错误
docker-compose logs service-name
```

### 问题3: 无法访问管理界面
```bash
# 检查防火墙
ufw status
firewall-cmd --list-all

# 检查Nginx状态  
docker-compose logs nginx
```

## 🔒 安全建议

1. **修改默认密码**: 登录后立即修改管理员密码
2. **限制访问IP**: 配置防火墙仅允许特定IP访问
3. **定期更新**: 保持系统和组件最新版本
4. **监控日志**: 定期检查访问和错误日志
5. **备份数据**: 定期备份配置和数据

## 📞 获取帮助

如需技术支持，请提供：
1. 系统信息: `uname -a && cat /etc/os-release`
2. 错误日志: `docker-compose logs > logs.txt`  
3. 服务状态: `docker-compose ps`

---

**恭喜！** 🎉 您已成功部署VPS代理管理系统！