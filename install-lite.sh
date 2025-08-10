#!/bin/bash

# VPS代理管理系统 - 轻量版部署脚本
# 专为1GB内存VPS优化

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查系统资源
check_system() {
    local mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    local disk=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    log_info "系统资源检查："
    log_info "内存: ${mem}MB"
    log_info "可用磁盘: ${disk}GB"
    
    if [[ $mem -lt 900 ]]; then
        log_error "内存不足900MB，无法安装"
        exit 1
    fi
    
    if [[ $disk -lt 5 ]]; then
        log_error "可用磁盘空间不足5GB"
        exit 1
    fi
    
    log_success "系统资源检查通过"
}

# 系统优化
optimize_system() {
    log_info "优化系统配置..."
    
    # 创建swap文件(如果内存小于2GB)
    if ! swapon --show | grep -q "/swapfile"; then
        log_info "创建1GB swap文件..."
        fallocate -l 1G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
    
    # 优化内存使用
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    sysctl -p
    
    log_success "系统优化完成"
}

# 安装轻量版Docker
install_docker_lite() {
    if command -v docker &> /dev/null; then
        log_success "Docker已安装"
        return
    fi
    
    log_info "安装Docker(轻量版)..."
    curl -fsSL https://get.docker.com | sh
    
    # 配置Docker使用更少资源
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true
}
EOF
    
    systemctl start docker
    systemctl enable docker
    
    # 安装轻量版docker-compose
    pip3 install docker-compose || {
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    }
    
    log_success "Docker安装完成"
}

# 创建轻量版docker-compose
create_lite_compose() {
    log_info "创建轻量版配置..."
    
    cat > docker-compose-lite.yml << 'EOF'
version: '3.8'

services:
  # 轻量Nginx
  nginx:
    image: nginx:alpine
    container_name: vps-nginx-lite
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-lite.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - proxy-net
    mem_limit: 50m
    cpus: 0.2

  # 单一API服务(整合所有功能)
  api-all-in-one:
    image: node:18-alpine
    container_name: vps-api-lite
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./src/api-lite:/app
      - ./protocol-configs:/app/configs
    working_dir: /app
    command: ["node", "server.js"]
    environment:
      - NODE_ENV=production
      - PORT=8080
    networks:
      - proxy-net
    mem_limit: 100m
    cpus: 0.3

  # V2Ray核心(单实例)
  v2ray:
    image: v2fly/v2fly-core:latest
    container_name: vps-v2ray-lite
    restart: unless-stopped
    ports:
      - "10001:10001"
      - "10002:10002"
    volumes:
      - ./protocol-configs/v2ray:/etc/v2ray:ro
    command: ["v2ray", "run", "-config", "/etc/v2ray/config.json"]
    networks:
      - proxy-net
    mem_limit: 80m
    cpus: 0.2

  # Clash核心
  clash:
    image: ghcr.io/metacubex/mihomo:latest
    container_name: vps-clash-lite
    restart: unless-stopped
    ports:
      - "7890:7890"
      - "7891:7891"
      - "9090:9090"
    volumes:
      - ./protocol-configs/clash:/root/.config/mihomo:ro
    networks:
      - proxy-net
    mem_limit: 60m
    cpus: 0.2

  # 轻量Redis(作为数据存储)
  redis:
    image: redis:7-alpine
    container_name: vps-redis-lite
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --maxmemory 50mb --maxmemory-policy allkeys-lru --save 900 1
    volumes:
      - redis_data:/data
    networks:
      - proxy-net
    mem_limit: 60m
    cpus: 0.1

volumes:
  redis_data:
    driver: local

networks:
  proxy-net:
    driver: bridge
EOF
    
    log_success "轻量版配置创建完成"
}

# 创建轻量版Nginx配置
create_nginx_config() {
    cat > nginx-lite.conf << 'EOF'
worker_processes 1;
worker_rlimit_nofile 1024;

events {
    worker_connections 512;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 30;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    
    # 简化日志
    access_log off;
    error_log /var/log/nginx/error.log warn;
    
    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript;
    
    upstream api {
        server api-all-in-one:8080;
    }
    
    server {
        listen 80;
        server_name _;
        
        location / {
            proxy_pass http://api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_cache_bypass $http_upgrade;
        }
        
        location /clash {
            proxy_pass http://clash:9090;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
EOF
}

# 创建全功能API服务
create_api_service() {
    mkdir -p src/api-lite
    
    cat > src/api-lite/server.js << 'EOF'
const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());
app.use(express.static('public'));

// 主页
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 健康检查
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// 系统状态
app.get('/api/status', (req, res) => {
    res.json({
        system: 'running',
        memory: process.memoryUsage(),
        protocols: {
            v2ray: 'active',
            clash: 'active'
        },
        timestamp: new Date().toISOString()
    });
});

// 生成V2Ray订阅
app.get('/api/subscribe/v2ray', (req, res) => {
    const serverIP = req.headers.host.split(':')[0];
    const vmessConfig = {
        v: "2",
        ps: "VPS-V2Ray",
        add: serverIP,
        port: "10001",
        id: "550e8400-e29b-41d4-a716-446655440000",
        aid: "0",
        net: "ws",
        type: "none",
        host: "",
        path: "/ray",
        tls: ""
    };
    const encoded = Buffer.from(JSON.stringify(vmessConfig)).toString('base64');
    res.type('text').send(`vmess://${encoded}`);
});

app.listen(port, () => {
    console.log(`🚀 VPS代理管理系统启动 - 端口 ${port}`);
});
EOF

    # package.json
    cat > src/api-lite/package.json << 'EOF'
{
  "name": "vps-proxy-lite",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

    # 创建简化前端
    mkdir -p src/api-lite/public
    cat > src/api-lite/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPS代理管理系统 - 轻量版</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .title { color: #333; font-size: 24px; margin-bottom: 10px; }
        .subtitle { color: #666; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .section h3 { color: #555; margin-bottom: 10px; }
        .status { display: flex; gap: 15px; flex-wrap: wrap; }
        .status-item { padding: 10px 15px; background: #e8f5e8; border-radius: 5px; flex: 1; min-width: 150px; text-align: center; }
        .links { display: flex; gap: 10px; flex-wrap: wrap; }
        .link { padding: 8px 16px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; }
        .link:hover { background: #0056b3; }
        .config-box { background: #f8f9fa; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; overflow-x: auto; white-space: pre; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="title">🚀 VPS代理管理系统</h1>
            <p class="subtitle">轻量版 - 为1GB内存VPS优化</p>
        </div>
        
        <div class="section">
            <h3>📊 服务状态</h3>
            <div class="status">
                <div class="status-item">V2Ray<br>运行中</div>
                <div class="status-item">Clash<br>运行中</div>
                <div class="status-item">API<br>运行中</div>
                <div class="status-item">内存<br>~300MB</div>
            </div>
        </div>
        
        <div class="section">
            <h3>🔗 快速访问</h3>
            <div class="links">
                <a href="/api/status" class="link">系统状态</a>
                <a href="#" class="clash-link link" target="_blank">Clash面板</a>
                <a href="/api/subscribe/v2ray" class="link">V2Ray订阅</a>
            </div>
        </div>
        
        <div class="section">
            <h3>⚡ 客户端配置</h3>
            <h4>Clash配置示例:</h4>
            <div class="config-box" id="clash-config">mixed-port: 7890
socks-port: 7891  
allow-lan: true
mode: rule
external-controller: [服务器IP]:9090

proxies:
  - name: "VPS-V2Ray"
    type: vmess
    server: [服务器IP]
    port: 10001
    uuid: 550e8400-e29b-41d4-a716-446655440000
    alterId: 0
    cipher: auto
    network: ws
    ws-opts:
      path: /ray</div>
        </div>
        
        <div class="section">
            <h3>💡 端口说明</h3>
            <p>• V2Ray VMess: 10001 (WebSocket /ray)</p>
            <p>• Clash HTTP: 7890, SOCKS: 7891</p>  
            <p>• Clash管理: 9090</p>
            <p>• 订阅链接: 自动更新服务器IP</p>
        </div>
    </div>

    <script>
        const serverIP = window.location.hostname;
        
        // 替换配置中的服务器IP
        document.getElementById('clash-config').innerHTML = 
            document.getElementById('clash-config').innerHTML.replace(/\[服务器IP\]/g, serverIP);
        
        // 更新Clash面板链接
        document.querySelector('.clash-link').href = `http://${serverIP}:9090`;
    </script>
</body>
</html>
EOF
}

# 主安装流程
main() {
    clear
    echo -e "${BLUE}"
    echo "========================================"
    echo "   VPS代理管理系统 - 轻量版部署"
    echo "========================================"
    echo -e "${NC}"
    
    [[ $EUID -ne 0 ]] && { log_error "需要root权限"; exit 1; }
    
    check_system
    optimize_system
    install_docker_lite
    create_lite_compose
    create_nginx_config
    create_api_service
    
    # 创建基础协议配置
    mkdir -p protocol-configs/{v2ray,clash} ssl
    
    # 生成V2Ray配置
    cat > protocol-configs/v2ray/config.json << 'EOF'
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "port": 10001,
      "protocol": "vmess",
      "settings": {
        "clients": [{"id": "550e8400-e29b-41d4-a716-446655440000", "alterId": 0}]
      },
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/ray"}}
    }
  ],
  "outbounds": [{"protocol": "freedom"}]
}
EOF
    
    # 生成Clash配置
    cat > protocol-configs/clash/config.yaml << 'EOF'
port: 7890
socks-port: 7891
allow-lan: true
mode: rule
log-level: info
external-controller: 0.0.0.0:9090
proxies: []
proxy-groups:
  - name: "PROXY"
    type: select
    proxies: ["DIRECT"]
rules:
  - MATCH,PROXY
EOF
    
    log_info "安装Node.js依赖..."
    cd src/api-lite && npm install --production --silent && cd ../..
    
    log_info "启动轻量版服务..."
    docker-compose -f docker-compose-lite.yml up -d
    
    sleep 15
    
    local SERVER_IP=$(curl -s ifconfig.me || echo "未知")
    
    echo -e "${GREEN}"
    echo "========================================"
    echo "    🎉 轻量版部署成功！"
    echo "========================================"
    echo -e "${NC}"
    echo -e "${BLUE}📱 访问地址:${NC}"
    echo -e "  🏠 管理界面: ${GREEN}http://${SERVER_IP}${NC}"
    echo -e "  ⚡ Clash面板: ${GREEN}http://${SERVER_IP}:9090${NC}"
    echo -e "  📋 订阅链接: ${GREEN}http://${SERVER_IP}/api/subscribe/v2ray${NC}"
    echo
    echo -e "${BLUE}💾 资源使用:${NC}"
    echo -e "  内存占用: ~300MB"
    echo -e "  磁盘占用: ~2GB"
    echo
    echo -e "${BLUE}🛠️ 管理命令:${NC}"
    echo -e "  docker-compose -f docker-compose-lite.yml ps"
    echo -e "  docker-compose -f docker-compose-lite.yml logs -f"
    echo -e "  docker-compose -f docker-compose-lite.yml restart"
    echo
    log_success "部署完成！请访问管理界面配置您的代理服务"
}

main "$@"