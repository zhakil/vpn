#!/bin/bash

# VPS代理管理系统 - 一键部署脚本
# 支持Ubuntu/Debian/CentOS系统自动部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检测系统类型
detect_system() {
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
        PM="yum"
    elif [[ -f /etc/debian_version ]]; then
        OS="ubuntu"
        PM="apt"
    else
        log_error "不支持的操作系统"
        exit 1
    fi
    log_info "检测到系统: $OS"
}

# 更新系统
update_system() {
    log_info "更新系统包..."
    if [[ $OS == "ubuntu" ]]; then
        apt update && apt upgrade -y
        apt install -y curl wget git unzip
    else
        yum update -y
        yum install -y curl wget git unzip
    fi
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
    log_success "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose已安装"
        return
    fi
    
    log_info "安装Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    log_success "Docker Compose安装完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙端口..."
    
    # 开放必要端口
    PORTS=(80 443 8080 3000 9090 7890 7891 10001-10020 36712)
    
    if command -v ufw &> /dev/null; then
        ufw --force enable
        for port in "${PORTS[@]}"; do
            ufw allow $port
        done
    elif command -v firewall-cmd &> /dev/null; then
        systemctl start firewalld
        systemctl enable firewalld
        for port in "${PORTS[@]}"; do
            firewall-cmd --permanent --add-port=${port}/tcp
            firewall-cmd --permanent --add-port=${port}/udp
        done
        firewall-cmd --reload
    fi
    
    log_success "防火墙配置完成"
}

# 生成环境配置文件
generate_env() {
    log_info "生成环境配置文件..."
    
    cat > .env << EOF
# 数据库配置
POSTGRES_DB=vps_proxy
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Redis配置
REDIS_PASSWORD=$(openssl rand -base64 32)

# JWT密钥
JWT_SECRET=$(openssl rand -base64 64)

# Clash API密钥
CLASH_API_SECRET=$(openssl rand -base64 32)

# InfluxDB配置
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=$(openssl rand -base64 32)
INFLUXDB_TOKEN=$(openssl rand -base64 64)
INFLUXDB_ORG=vps-proxy
INFLUXDB_BUCKET=metrics

# Grafana配置
GRAFANA_USER=admin
GRAFANA_PASSWORD=$(openssl rand -base64 16)

# Prometheus配置
PROMETHEUS_RETENTION=200h
EOF

    log_success "环境配置文件已生成"
}

# 创建必要目录
create_directories() {
    log_info "创建项目目录..."
    
    mkdir -p {src/{api-gateway,rule-engine,config-manager,adapters/{v2ray,clash,hysteria},stats-collector},ssl,configs/{grafana/{provisioning,dashboards}}}
    
    log_success "目录结构已创建"
}

# 创建基础配置文件
create_basic_configs() {
    log_info "创建基础配置文件..."
    
    # 创建基础的API Gateway
    mkdir -p src/api-gateway
    cat > src/api-gateway/server.js << 'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/', (req, res) => {
    res.json({ 
        message: 'VPS代理管理系统API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            docs: '/api/docs'
        }
    });
});

app.listen(port, () => {
    console.log(`API Gateway running on port ${port}`);
});
EOF

    # 创建package.json
    cat > src/api-gateway/package.json << 'EOF'
{
  "name": "vps-proxy-api-gateway",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^6.1.5"
  },
  "scripts": {
    "start": "node server.js"
  }
}
EOF

    log_success "基础配置文件已创建"
}

# 拉取Docker镜像
pull_images() {
    log_info "拉取Docker镜像..."
    
    # 预拉取所有需要的镜像
    docker pull nginx:alpine
    docker pull node:18-alpine
    docker pull postgres:15-alpine
    docker pull redis:7-alpine
    docker pull v2fly/v2fly-core:latest
    docker pull ghcr.io/metacubex/mihomo:latest
    docker pull tobyxdd/hysteria:latest
    docker pull prom/prometheus:latest
    docker pull grafana/grafana:latest
    docker pull influxdb:2.7-alpine
    
    log_success "Docker镜像拉取完成"
}

# 安装Node.js依赖
install_dependencies() {
    log_info "安装Node.js依赖..."
    
    cd src/api-gateway
    npm install --production
    cd ../..
    
    log_success "依赖安装完成"
}

# 启动服务
start_services() {
    log_info "启动所有服务..."
    
    docker-compose up -d
    
    # 等待服务启动
    sleep 30
    
    log_success "服务启动完成"
}

# 创建快捷命令
create_shortcut_command() {
    log_info "创建快捷命令..."
    
    # 创建全局管理脚本
    cp manage.sh /usr/local/bin/zhakil-manage
    chmod +x /usr/local/bin/zhakil-manage
    
    # 创建快捷命令脚本
    cat > /usr/local/bin/zhakil << 'EOF'
#!/bin/bash
# VPS代理管理系统快捷命令
# 输入 zhakil 即可进入管理界面

INSTALL_DIR="/opt/vpn-proxy"

# 检查安装目录
if [[ -d "$INSTALL_DIR" ]]; then
    cd "$INSTALL_DIR"
    /usr/local/bin/zhakil-manage
else
    # 在当前目录查找
    if [[ -f "./manage.sh" ]]; then
        ./manage.sh
    else
        echo -e "\033[0;31m错误: 未找到VPS代理管理系统\033[0m"
        echo -e "\033[1;33m请确保系统已正确安装\033[0m"
        exit 1
    fi
fi
EOF

    chmod +x /usr/local/bin/zhakil
    
    # 创建软链接到常用路径
    ln -sf /usr/local/bin/zhakil /usr/bin/zhakil
    
    log_success "快捷命令创建完成"
}

# 移动项目到标准位置
move_to_standard_location() {
    local INSTALL_DIR="/opt/vpn-proxy"
    
    log_info "移动项目到标准位置..."
    
    if [[ "$PWD" != "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        cp -r * "$INSTALL_DIR/"
        cd "$INSTALL_DIR"
    fi
    
    log_success "项目已移动到 $INSTALL_DIR"
}

# 显示部署结果
show_result() {
    local SERVER_IP=$(curl -s ifconfig.me)
    
    echo
    log_success "=================================="
    log_success "   VPS代理管理系统部署完成！"
    log_success "=================================="
    echo
    echo -e "${BLUE}访问地址:${NC}"
    echo -e "  管理界面: ${GREEN}http://${SERVER_IP}${NC}"
    echo -e "  监控面板: ${GREEN}http://${SERVER_IP}:3000${NC}"
    echo -e "  Prometheus: ${GREEN}http://${SERVER_IP}:9090${NC}"
    echo
    echo -e "${BLUE}默认账户:${NC}"
    echo -e "  Grafana用户: ${GREEN}admin${NC}"
    echo -e "  Grafana密码: ${GREEN}$(grep GRAFANA_PASSWORD .env | cut -d'=' -f2)${NC}"
    echo
    echo -e "${BLUE}快捷命令:${NC}"
    echo -e "  管理界面: ${GREEN}zhakil${NC}"
    echo -e "  查看状态: ${YELLOW}docker-compose ps${NC}"
    echo -e "  查看日志: ${YELLOW}docker-compose logs -f${NC}"
    echo -e "  重启服务: ${YELLOW}docker-compose restart${NC}"
    echo -e "  停止服务: ${YELLOW}docker-compose down${NC}"
    echo
    log_warning "请保存好.env文件中的密码信息！"
    echo
    echo -e "${GREEN}现在你可以在任何地方输入 'zhakil' 进入管理界面！${NC}"
    
    # 询问是否立即进入管理界面
    echo
    read -p "$(echo -e "${BLUE}是否现在就进入管理界面? [Y/n]: ${NC}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$|^$ ]]; then
        sleep 2
        zhakil
    fi
}

# 主安装流程
main() {
    clear
    echo -e "${BLUE}"
    echo "========================================"
    echo "     VPS代理管理系统 - 一键部署"
    echo "           zhakil科技箱 v4.0.0"
    echo "========================================"
    echo -e "${NC}"
    
    check_root
    detect_system
    update_system
    install_docker
    install_docker_compose
    configure_firewall
    generate_env
    create_directories
    create_basic_configs
    pull_images
    install_dependencies
    start_services
    move_to_standard_location
    create_shortcut_command
    show_result
}

# 执行主流程
main "$@"