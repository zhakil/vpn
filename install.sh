#!/bin/bash

# VPS代理管理系统 - 简化一键部署脚本
# 适配现有Docker Compose配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
}

# 获取服务器IP
get_server_ip() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "未知")
    log_info "检测到服务器IP: $SERVER_IP"
}

# 安装Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_success "Docker已安装"
        return
    fi
    
    log_info "安装Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    
    # 安装Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker安装完成"
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙..."
    
    # 开放必要端口
    if command -v ufw &> /dev/null; then
        ufw --force enable
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 8080/tcp
        ufw allow 3000/tcp
        ufw allow 7890/tcp
        ufw allow 7891/tcp
        ufw allow 9090/tcp
        ufw allow 10001:10020/tcp
        ufw allow 36712/udp
    elif command -v firewall-cmd &> /dev/null; then
        systemctl start firewalld
        systemctl enable firewalld
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --permanent --add-port=3000/tcp
        firewall-cmd --permanent --add-port=7890/tcp
        firewall-cmd --permanent --add-port=7891/tcp
        firewall-cmd --permanent --add-port=9090/tcp
        firewall-cmd --permanent --add-port=10001-10020/tcp
        firewall-cmd --permanent --add-port=36712/udp
        firewall-cmd --reload
    fi
    
    log_success "防火墙配置完成"
}

# 生成环境配置
generate_env() {
    log_info "生成环境配置..."
    
    cat > .env << EOF
# 数据库配置
POSTGRES_DB=vps_proxy
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Redis配置
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# JWT配置
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# Clash配置
CLASH_API_SECRET=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# InfluxDB配置
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
INFLUXDB_TOKEN=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)
INFLUXDB_ORG=vps-proxy
INFLUXDB_BUCKET=metrics

# Grafana配置
GRAFANA_USER=admin
GRAFANA_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-12)

# Prometheus配置
PROMETHEUS_RETENTION=200h
EOF

    log_success "环境配置已生成"
}

# 创建必要目录和文件
setup_directories() {
    log_info "创建项目目录结构..."
    
    # 创建源码目录
    mkdir -p src/{api-gateway,rule-engine,config-manager,adapters/{v2ray,clash,hysteria},stats-collector}
    
    # 创建配置目录
    mkdir -p configs/{grafana/{provisioning/{dashboards,datasources,notifiers},dashboards}}
    
    # 创建SSL目录
    mkdir -p ssl
    
    # 创建协议配置目录
    mkdir -p protocol-configs/{v2ray,clash,hysteria}
    
    log_success "目录结构创建完成"
}

# 创建基础API服务
create_api_service() {
    log_info "创建API Gateway..."
    
    cat > src/api-gateway/server.js << 'EOF'
const express = require('express');
const path = require('path');
const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());
app.use(express.static('public'));

// 健康检查
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        service: 'VPS Proxy Management API'
    });
});

// 根路径
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API路由
app.get('/api', (req, res) => {
    res.json({
        name: 'VPS代理管理系统',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            api: '/api',
            status: '/api/status'
        }
    });
});

app.get('/api/status', (req, res) => {
    res.json({
        system: 'running',
        protocols: {
            v2ray: 'active',
            clash: 'active', 
            hysteria: 'active'
        },
        timestamp: new Date().toISOString()
    });
});

app.listen(port, () => {
    console.log(`🚀 API Gateway started on port ${port}`);
});
EOF

    # 创建package.json
    cat > src/api-gateway/package.json << 'EOF'
{
  "name": "vps-proxy-api",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2"
  },
  "scripts": {
    "start": "node server.js"
  }
}
EOF

    # 创建公共目录和首页
    mkdir -p src/api-gateway/public
    cat > src/api-gateway/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VPS代理管理系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Arial', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; }
        .container { background: white; padding: 2rem; border-radius: 10px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); text-align: center; max-width: 600px; }
        .logo { font-size: 2.5rem; color: #667eea; margin-bottom: 1rem; }
        .title { font-size: 1.8rem; color: #333; margin-bottom: 1rem; }
        .subtitle { color: #666; margin-bottom: 2rem; }
        .status { display: flex; justify-content: space-around; margin: 2rem 0; }
        .status-item { padding: 1rem; background: #f8f9fa; border-radius: 8px; flex: 1; margin: 0 0.5rem; }
        .status-label { font-weight: bold; color: #333; }
        .status-value { color: #28a745; font-size: 1.2rem; }
        .links { margin-top: 2rem; }
        .link { display: inline-block; margin: 0.5rem; padding: 0.8rem 1.5rem; background: #667eea; color: white; text-decoration: none; border-radius: 5px; transition: background 0.3s; }
        .link:hover { background: #5a67d8; }
        .footer { margin-top: 2rem; color: #888; font-size: 0.9rem; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🚀</div>
        <h1 class="title">VPS代理管理系统</h1>
        <p class="subtitle">多协议代理服务统一管理平台</p>
        
        <div class="status">
            <div class="status-item">
                <div class="status-label">V2Ray</div>
                <div class="status-value" id="v2ray-status">运行中</div>
            </div>
            <div class="status-item">
                <div class="status-label">Clash</div>
                <div class="status-value" id="clash-status">运行中</div>
            </div>
            <div class="status-item">
                <div class="status-label">Hysteria</div>
                <div class="status-value" id="hysteria-status">运行中</div>
            </div>
        </div>
        
        <div class="links">
            <a href="/api" class="link">API接口</a>
            <a href=":3000" class="link">监控面板</a>
            <a href=":9090" class="link">Clash面板</a>
        </div>
        
        <div class="footer">
            <p>© 2024 VPS代理管理系统 | 版本 1.0.0</p>
        </div>
    </div>

    <script>
        // 简单的状态检查
        fetch('/api/status')
            .then(response => response.json())
            .then(data => {
                console.log('系统状态:', data);
            })
            .catch(error => console.error('状态检查失败:', error));
    </script>
</body>
</html>
EOF
}

# 创建基础配置文件
create_configs() {
    log_info "创建基础配置文件..."
    
    # V2Ray配置
    cat > protocol-configs/v2ray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10001,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/ray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

    # Clash配置
    cat > protocol-configs/clash/config.yaml << 'EOF'
port: 7890
socks-port: 7891
allow-lan: true
mode: rule
log-level: info
external-controller: 0.0.0.0:9090
secret: "clash-secret"

proxies: []

proxy-groups:
  - name: "PROXY"
    type: select
    proxies:
      - DIRECT

rules:
  - MATCH,PROXY
EOF

    log_success "配置文件创建完成"
}

# 拉取Docker镜像
pull_images() {
    log_info "拉取Docker镜像..."
    
    docker pull nginx:alpine &
    docker pull node:18-alpine &
    docker pull postgres:15-alpine &
    docker pull redis:7-alpine &
    docker pull v2fly/v2fly-core:latest &
    docker pull ghcr.io/metacubex/mihomo:latest &
    docker pull prom/prometheus:latest &
    docker pull grafana/grafana:latest &
    
    wait
    log_success "镜像拉取完成"
}

# 安装Node.js依赖
install_node_deps() {
    log_info "安装Node.js依赖..."
    
    cd src/api-gateway
    npm install --production --silent
    cd ../..
    
    log_success "依赖安装完成"
}

# 启动服务
start_services() {
    log_info "启动所有服务..."
    
    docker-compose up -d
    sleep 15
    
    log_success "服务启动完成"
}

# 显示结果
show_results() {
    clear
    echo -e "${GREEN}"
    echo "=========================================="
    echo "    🎉 VPS代理管理系统部署成功！"
    echo "=========================================="
    echo -e "${NC}"
    echo
    echo -e "${BLUE}📱 访问地址:${NC}"
    echo -e "  🏠 管理界面: ${GREEN}http://${SERVER_IP}${NC}"
    echo -e "  📊 监控面板: ${GREEN}http://${SERVER_IP}:3000${NC}"
    echo -e "  ⚡ Clash面板: ${GREEN}http://${SERVER_IP}:9090${NC}"
    echo -e "  🔍 Prometheus: ${GREEN}http://${SERVER_IP}:9090${NC}"
    echo
    echo -e "${BLUE}🔑 默认账户:${NC}"
    echo -e "  Grafana用户: ${GREEN}admin${NC}"
    echo -e "  Grafana密码: ${GREEN}$(grep GRAFANA_PASSWORD .env | cut -d'=' -f2)${NC}"
    echo
    echo -e "${BLUE}🛠️ 管理命令:${NC}"
    echo -e "  查看状态: ${YELLOW}docker-compose ps${NC}"
    echo -e "  查看日志: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "  重启服务: ${YELLOW}docker-compose restart${NC}"
    echo -e "  停止服务: ${YELLOW}docker-compose down${NC}"
    echo
    echo -e "${YELLOW}⚠️  请妥善保存 .env 文件中的密码信息！${NC}"
    echo
}

# 主安装流程
main() {
    clear
    echo -e "${BLUE}"
    echo "========================================"
    echo "     VPS代理管理系统 - 一键部署"
    echo "========================================"
    echo -e "${NC}"
    
    check_root
    get_server_ip
    
    log_info "开始安装，请稍候..."
    
    install_docker
    setup_firewall
    generate_env
    setup_directories
    create_api_service
    create_configs
    pull_images
    install_node_deps
    start_services
    
    show_results
}

# 运行主程序
main "$@"