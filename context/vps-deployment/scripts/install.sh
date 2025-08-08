#!/bin/bash

# 代理管理系统一键安装脚本
# 支持 Ubuntu 20.04+, CentOS 8+, Debian 11+

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
        log_info "检测到 CentOS/RHEL 系统"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        if grep -qi ubuntu /etc/os-release; then
            OS="ubuntu"
            log_info "检测到 Ubuntu 系统"
        else
            log_info "检测到 Debian 系统"
        fi
    else
        log_error "不支持的操作系统"
        exit 1
    fi
}

# 检查系统要求
check_requirements() {
    log_step "检查系统要求"
    
    # 检查内存
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $MEMORY_GB -lt 2 ]]; then
        log_warn "内存不足2GB，建议升级到4GB以上"
    fi
    
    # 检查磁盘空间
    DISK_GB=$(df -BG / | awk 'NR==2{gsub(/G/,"",$4); print $4}')
    if [[ $DISK_GB -lt 20 ]]; then
        log_error "磁盘空间不足20GB，无法继续安装"
        exit 1
    fi
    
    log_info "系统要求检查通过"
}

# 更新系统包
update_system() {
    log_step "更新系统包"
    
    case $OS in
        "ubuntu"|"debian")
            apt update && apt upgrade -y
            apt install -y curl wget git unzip htop
            ;;
        "centos")
            yum update -y
            yum install -y curl wget git unzip htop
            ;;
    esac
    
    log_info "系统包更新完成"
}

# 安装Docker
install_docker() {
    log_step "安装Docker"
    
    if command -v docker &> /dev/null; then
        log_info "Docker已安装，版本: $(docker --version)"
        return 0
    fi
    
    case $OS in
        "ubuntu"|"debian")
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker
            apt update
            apt install -y docker-ce docker-ce-cli containerd.io
            ;;
        "centos")
            # 安装依赖
            yum install -y yum-utils device-mapper-persistent-data lvm2
            
            # 添加Docker仓库
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # 安装Docker
            yum install -y docker-ce docker-ce-cli containerd.io
            ;;
    esac
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 添加当前用户到docker组
    if [[ -n "$SUDO_USER" ]]; then
        usermod -aG docker $SUDO_USER
    fi
    
    log_info "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log_step "安装Docker Compose"
    
    if command -v docker-compose &> /dev/null; then
        log_info "Docker Compose已安装，版本: $(docker-compose --version)"
        return 0
    fi
    
    # 获取最新版本号
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # 下载Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 设置执行权限
    chmod +x /usr/local/bin/docker-compose
    
    log_info "Docker Compose安装完成，版本: $COMPOSE_VERSION"
}

# 配置防火墙
setup_firewall() {
    log_step "配置防火墙"
    
    case $OS in
        "ubuntu"|"debian")
            if command -v ufw &> /dev/null; then
                # 重置防火墙规则
                ufw --force reset
                
                # 允许SSH
                ufw allow ssh
                ufw allow 22/tcp
                
                # 允许HTTP和HTTPS
                ufw allow 80/tcp
                ufw allow 443/tcp
                
                # 允许代理端口范围
                ufw allow 10001:10100/tcp
                ufw allow 10001:10100/udp
                
                # 启用防火墙
                ufw --force enable
                
                log_info "UFW防火墙配置完成"
            fi
            ;;
        "centos")
            if command -v firewall-cmd &> /dev/null; then
                # 添加HTTP和HTTPS服务
                firewall-cmd --permanent --add-service=http
                firewall-cmd --permanent --add-service=https
                
                # 添加SSH服务
                firewall-cmd --permanent --add-service=ssh
                
                # 添加代理端口范围
                firewall-cmd --permanent --add-port=10001-10100/tcp
                firewall-cmd --permanent --add-port=10001-10100/udp
                
                # 重新加载防火墙规则
                firewall-cmd --reload
                
                log_info "FirewallD配置完成"
            fi
            ;;
    esac
}

# 设置系统优化
setup_system_optimization() {
    log_step "设置系统优化"
    
    # 优化系统参数
    cat >> /etc/sysctl.conf << EOF

# 代理管理系统优化参数
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 65536 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
fs.file-max=1048576
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_keepalive_time=1200
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_keepalive_probes=5
EOF
    
    # 应用系统参数
    sysctl -p
    
    # 设置文件句柄限制
    cat >> /etc/security/limits.conf << EOF

# 代理管理系统文件句柄限制
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
    
    log_info "系统优化配置完成"
}

# 创建项目目录
setup_directories() {
    log_step "创建项目目录"
    
    PROJECT_DIR="/opt/proxy-manager"
    
    # 创建主目录
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # 创建子目录
    mkdir -p {configs,ssl,logs,backups,plugins,data}
    mkdir -p configs/{nginx,api-gateway,rule-engine,config-manager,v2ray,clash,hysteria,prometheus,grafana}
    mkdir -p ssl/{letsencrypt,custom}
    mkdir -p logs/{nginx,api,protocols,system}
    
    log_info "项目目录创建完成: $PROJECT_DIR"
}

# 生成环境配置文件
generate_env_config() {
    log_step "生成环境配置文件"
    
    # 生成随机密码
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    REDIS_PASSWORD=$(openssl rand -hex 16)
    INFLUXDB_PASSWORD=$(openssl rand -hex 16)
    INFLUXDB_TOKEN=$(openssl rand -hex 32)
    JWT_SECRET=$(openssl rand -hex 32)
    API_KEY_SECRET=$(openssl rand -hex 32)
    SESSION_SECRET=$(openssl rand -hex 32)
    GRAFANA_PASSWORD=$(openssl rand -hex 12)
    CLASH_API_SECRET=$(openssl rand -hex 16)
    
    # 获取服务器IP
    SERVER_IP=$(curl -s https://ipv4.icanhazip.com || curl -s https://api.ipify.org)
    
    # 创建.env文件
    cat > .env << EOF
# 代理管理系统环境变量配置
NODE_ENV=production
DOMAIN=${SERVER_IP}
API_DOMAIN=api.${SERVER_IP}

# 数据库配置
POSTGRES_DB=proxy_manager
POSTGRES_USER=proxy_admin
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}

# InfluxDB配置
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=${INFLUXDB_PASSWORD}
INFLUXDB_ORG=proxy-manager-org
INFLUXDB_BUCKET=proxy-metrics
INFLUXDB_TOKEN=${INFLUXDB_TOKEN}

# 安全配置
JWT_SECRET=${JWT_SECRET}
API_KEY_SECRET=${API_KEY_SECRET}
SESSION_SECRET=${SESSION_SECRET}

# 监控配置
GRAFANA_USER=admin
GRAFANA_PASSWORD=${GRAFANA_PASSWORD}
PROMETHEUS_RETENTION=200h

# SSL配置
LETSENCRYPT_EMAIL=admin@${SERVER_IP}
SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/key.pem

# Clash配置
CLASH_API_SECRET=${CLASH_API_SECRET}

# 其他配置使用默认值
V2RAY_LOG_LEVEL=warning
CLASH_LOG_LEVEL=info
HYSTERIA_LOG_LEVEL=info
LOG_LEVEL=info
BACKUP_RETENTION_DAYS=30
ENABLE_FAIL2BAN=true
MAX_LOGIN_ATTEMPTS=5
LOGIN_LOCKOUT_TIME=30
EOF
    
    # 保护.env文件权限
    chmod 600 .env
    
    log_info "环境配置文件生成完成"
    log_warn "重要: 请妥善保管生成的密码信息"
}

# 下载项目文件
download_project_files() {
    log_step "下载项目文件"
    
    # 这里应该从你的代码仓库下载
    # git clone https://github.com/your-username/proxy-manager.git .
    
    # 临时创建基础配置文件
    create_basic_configs
    
    log_info "项目文件下载完成"
}

# 创建基础配置文件
create_basic_configs() {
    # 创建基础nginx配置
    mkdir -p configs/nginx/conf.d
    
    cat > configs/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF
    
    cat > configs/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://api-gateway:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
}

# 申请SSL证书
setup_ssl() {
    log_step "设置SSL证书"
    
    # 安装certbot
    case $OS in
        "ubuntu"|"debian")
            apt install -y certbot
            ;;
        "centos")
            yum install -y certbot
            ;;
    esac
    
    # 生成自签名证书作为临时方案
    mkdir -p ssl/custom
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/custom/key.pem \
        -out ssl/custom/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=${SERVER_IP}"
    
    log_info "SSL证书设置完成（使用自签名证书）"
    log_info "如需正式SSL证书，请配置域名后运行: certbot --nginx"
}

# 启动服务
start_services() {
    log_step "启动服务"
    
    # 构建和启动服务
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    docker-compose ps
    
    log_info "服务启动完成"
}

# 显示安装结果
show_install_result() {
    log_step "安装结果"
    
    echo ""
    echo "=========================================="
    echo "  代理管理系统安装完成！"
    echo "=========================================="
    echo ""
    echo "访问信息:"
    echo "  管理界面: http://${SERVER_IP}"
    echo "  API接口: http://${SERVER_IP}:8080"
    echo "  Grafana: http://${SERVER_IP}:3000"
    echo ""
    echo "默认账户信息:"
    echo "  Grafana用户: admin"
    echo "  Grafana密码: $(grep GRAFANA_PASSWORD .env | cut -d= -f2)"
    echo ""
    echo "重要文件位置:"
    echo "  项目目录: /opt/proxy-manager"
    echo "  配置文件: /opt/proxy-manager/.env"
    echo "  日志目录: /opt/proxy-manager/logs"
    echo ""
    echo "常用命令:"
    echo "  查看状态: docker-compose ps"
    echo "  查看日志: docker-compose logs -f"
    echo "  重启服务: docker-compose restart"
    echo "  停止服务: docker-compose down"
    echo ""
    echo "=========================================="
    
    log_warn "请妥善保管.env文件中的密码信息！"
}

# 主函数
main() {
    echo "========================================"
    echo "  代理管理系统一键安装脚本"
    echo "========================================"
    echo ""
    
    check_root
    detect_os
    check_requirements
    update_system
    install_docker
    install_docker_compose
    setup_firewall
    setup_system_optimization
    setup_directories
    generate_env_config
    download_project_files
    setup_ssl
    start_services
    show_install_result
    
    echo ""
    log_info "安装完成！享受你的代理管理系统吧！"
}

# 错误处理
trap 'log_error "安装过程中出现错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"