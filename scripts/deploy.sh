#!/bin/bash

# VPS代理管理系统 - 交互式一键部署脚本
# 支持多协议统一管理，智能配置生成

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="/opt/vps-proxy-manager"

# 全局配置变量
DOMAIN=""
SERVER_IP=""
SSL_TYPE=""
SSL_EMAIL=""
PROTOCOLS=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
DB_PASSWORD=""
REDIS_PASSWORD=""
JWT_SECRET=""

# 显示横幅
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "██╗   ██╗██████╗ ███████╗    ██████╗ ██████╗  ██████╗ ██╗  ██╗██╗   ██╗"
    echo "██║   ██║██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝╚██╗ ██╔╝"
    echo "██║   ██║██████╔╝███████╗    ██████╔╝██████╔╝██║   ██║ ╚███╔╝  ╚████╔╝ "
    echo "╚██╗ ██╔╝██╔═══╝ ╚════██║    ██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗   ╚██╔╝  "
    echo " ╚████╔╝ ██║     ███████║    ██║     ██║  ██║╚██████╔╝██╔╝ ██╗   ██║   "
    echo "  ╚═══╝  ╚═╝     ╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   "
    echo -e "${NC}"
    echo -e "${WHITE}==================================================================${NC}"
    echo -e "${GREEN}           VPS代理管理系统 - 交互式一键部署程序${NC}"
    echo -e "${WHITE}==================================================================${NC}"
    echo ""
    echo -e "${YELLOW}支持协议: V2Ray, Clash, Hysteria, TUIC, WireGuard${NC}"
    echo -e "${YELLOW}管理功能: Web界面, API接口, 监控面板, 自动备份${NC}"
    echo ""
}

# 日志函数
log_info() {
    echo -e "${GREEN}[信息]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

# 检查系统环境
check_system() {
    log_step "检查系统环境"
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法识别的操作系统"
        exit 1
    fi
    
    source /etc/os-release
    case $ID in
        ubuntu|debian)
            OS_TYPE="debian"
            log_info "检测到 $PRETTY_NAME"
            ;;
        centos|rhel|fedora)
            OS_TYPE="redhat"
            log_info "检测到 $PRETTY_NAME"
            ;;
        *)
            log_error "不支持的操作系统: $PRETTY_NAME"
            exit 1
            ;;
    esac
    
    # 检查权限
    if [[ $EUID -ne 0 ]]; then
        log_error "请使用 root 权限运行此脚本"
        echo "使用方法: sudo $0"
        exit 1
    fi
    
    # 检查系统资源
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
    DISK_GB=$(df -BG / | awk 'NR==2{gsub(/G/,\"\",$4); print $4}')
    
    log_info "系统内存: ${MEMORY_GB}GB"
    log_info "可用磁盘: ${DISK_GB}GB"
    
    if [[ $MEMORY_GB -lt 2 ]]; then
        log_warn "内存少于2GB，建议升级到4GB以上以获得最佳性能"
        read -p "是否继续？[y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    if [[ $DISK_GB -lt 10 ]]; then
        log_error "磁盘空间不足10GB，无法继续安装"
        exit 1
    fi
    
    log_success "系统环境检查通过"
}

# 获取服务器IP
get_server_ip() {
    log_step "获取服务器IP地址"
    
    # 尝试多种方法获取公网IP
    SERVER_IP=$(curl -s --max-time 5 https://ipv4.icanhazip.com 2>/dev/null || \
               curl -s --max-time 5 https://api.ipify.org 2>/dev/null || \
               curl -s --max-time 5 http://whatismyip.akamai.com 2>/dev/null || \
               ip route get 8.8.8.8 | awk '{print $7}' | head -1)
    
    if [[ -z "$SERVER_IP" ]]; then
        log_warn "无法自动获取服务器IP地址"
        while true; do
            read -p "请手动输入服务器公网IP地址: " SERVER_IP
            if [[ $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                break
            else
                log_error "IP地址格式不正确，请重新输入"
            fi
        done
    else
        log_info "检测到服务器IP: $SERVER_IP"
        read -p "确认使用此IP？[Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            while true; do
                read -p "请输入正确的服务器IP地址: " SERVER_IP
                if [[ $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                    break
                else
                    log_error "IP地址格式不正确，请重新输入"
                fi
            done
        fi
    fi
}

# 配置域名和SSL
configure_domain_ssl() {
    log_step "配置域名和SSL证书"
    
    echo ""
    echo -e "${WHITE}域名和SSL配置选项:${NC}"
    echo -e "${CYAN}1.${NC} 使用域名 + Let's Encrypt SSL证书 ${GREEN}(推荐)${NC}"
    echo -e "${CYAN}2.${NC} 使用域名 + 自签名SSL证书"
    echo -e "${CYAN}3.${NC} 仅使用IP地址 + 自签名SSL证书"
    echo ""
    
    while true; do
        read -p "请选择配置方式 [1-3]: " ssl_choice
        case $ssl_choice in
            1)
                SSL_TYPE="letsencrypt"
                echo ""
                while true; do
                    read -p "请输入域名 (例: proxy.example.com): " DOMAIN
                    if [[ $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                        # 检查域名DNS解析
                        log_info "检查域名DNS解析..."
                        if nslookup $DOMAIN > /dev/null 2>&1; then
                            resolved_ip=$(nslookup $DOMAIN | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
                            if [[ "$resolved_ip" == "$SERVER_IP" ]]; then
                                log_success "域名解析正确"
                                break
                            else
                                log_warn "域名解析到 $resolved_ip，但服务器IP是 $SERVER_IP"
                                read -p "是否继续使用此域名？[y/N]: " -n 1 -r
                                echo
                                if [[ $REPLY =~ ^[Yy]$ ]]; then
                                    break
                                fi
                            fi
                        else
                            log_warn "域名解析失败，请确保域名已正确解析到服务器IP"
                            read -p "是否继续使用此域名？[y/N]: " -n 1 -r
                            echo
                            if [[ $REPLY =~ ^[Yy]$ ]]; then
                                break
                            fi
                        fi
                    else
                        log_error "域名格式不正确，请重新输入"
                    fi
                done
                
                while true; do
                    read -p "请输入用于Let's Encrypt的邮箱地址: " SSL_EMAIL
                    if [[ $SSL_EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                        break
                    else
                        log_error "邮箱格式不正确，请重新输入"
                    fi
                done
                break
                ;;
            2)
                SSL_TYPE="self-signed"
                echo ""
                while true; do
                    read -p "请输入域名 (例: proxy.example.com): " DOMAIN
                    if [[ $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                        break
                    else
                        log_error "域名格式不正确，请重新输入"
                    fi
                done
                break
                ;;
            3)
                SSL_TYPE="self-signed"
                DOMAIN="$SERVER_IP"
                log_info "使用IP地址: $DOMAIN"
                break
                ;;
            *)
                log_error "请输入有效选项 (1-3)"
                ;;
        esac
    done
}

# 选择协议
select_protocols() {
    log_step "选择要部署的代理协议"
    
    echo ""
    echo -e "${WHITE}可选择的代理协议:${NC}"
    echo -e "${CYAN}1.${NC} V2Ray (VMess/VLESS/Trojan/Shadowsocks) ${GREEN}[通用推荐]${NC}"
    echo -e "${CYAN}2.${NC} Clash (支持所有主流协议) ${GREEN}[客户端丰富]${NC}"
    echo -e "${CYAN}3.${NC} Hysteria (基于QUIC的高性能协议) ${GREEN}[高速传输]${NC}"
    echo -e "${CYAN}4.${NC} 全部协议 ${YELLOW}[资源消耗较大]${NC}"
    echo ""
    
    while true; do
        read -p "请选择要部署的协议 [1-4]: " protocol_choice
        case $protocol_choice in
            1)
                PROTOCOLS="v2ray"
                log_info "选择协议: V2Ray"
                break
                ;;
            2)
                PROTOCOLS="clash"
                log_info "选择协议: Clash"
                break
                ;;
            3)
                PROTOCOLS="hysteria"
                log_info "选择协议: Hysteria"
                break
                ;;
            4)
                PROTOCOLS="all"
                log_info "选择协议: 全部协议"
                log_warn "全协议模式需要更多系统资源"
                break
                ;;
            *)
                log_error "请输入有效选项 (1-4)"
                ;;
        esac
    done
}

# 配置管理员账户
configure_admin() {
    log_step "配置管理员账户"
    
    echo ""
    while true; do
        read -p "请输入管理员邮箱: " ADMIN_EMAIL
        if [[ $ADMIN_EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            log_error "邮箱格式不正确，请重新输入"
        fi
    done
    
    while true; do
        read -s -p "请设置管理员密码 (至少8位): " ADMIN_PASSWORD
        echo
        if [[ ${#ADMIN_PASSWORD} -ge 8 ]]; then
            read -s -p "请确认管理员密码: " password_confirm
            echo
            if [[ "$ADMIN_PASSWORD" == "$password_confirm" ]]; then
                break
            else
                log_error "两次密码输入不一致，请重新输入"
            fi
        else
            log_error "密码长度至少8位，请重新输入"
        fi
    done
    
    log_success "管理员账户配置完成"
}

# 生成安全密钥
generate_secrets() {
    log_step "生成安全密钥"
    
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d \"=+/\" | cut -c1-25)
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d \"=+/\" | cut -c1-25)
    JWT_SECRET=$(openssl rand -base64 64 | tr -d \"=+/\" | cut -c1-50)
    CLASH_API_SECRET=$(openssl rand -base64 32 | tr -d \"=+/\" | cut -c1-25)
    INFLUXDB_TOKEN=$(openssl rand -base64 64 | tr -d \"=+/\" | cut -c1-60)
    
    log_success "安全密钥生成完成"
}

# 显示配置摘要
show_configuration_summary() {
    echo ""
    echo -e "${WHITE}==================================================================${NC}"
    echo -e "${GREEN}                        配置摘要${NC}"
    echo -e "${WHITE}==================================================================${NC}"
    echo ""
    echo -e "${CYAN}服务器信息:${NC}"
    echo -e "  IP地址: ${YELLOW}$SERVER_IP${NC}"
    echo -e "  域名: ${YELLOW}$DOMAIN${NC}"
    echo -e "  SSL类型: ${YELLOW}$SSL_TYPE${NC}"
    if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
        echo -e "  SSL邮箱: ${YELLOW}$SSL_EMAIL${NC}"
    fi
    echo ""
    echo -e "${CYAN}协议配置:${NC}"
    case $PROTOCOLS in
        "v2ray")
            echo -e "  部署协议: ${YELLOW}V2Ray (VMess/VLESS/Trojan/Shadowsocks)${NC}"
            ;;
        "clash")
            echo -e "  部署协议: ${YELLOW}Clash (多协议支持)${NC}"
            ;;
        "hysteria")
            echo -e "  部署协议: ${YELLOW}Hysteria (QUIC高性能)${NC}"
            ;;
        "all")
            echo -e "  部署协议: ${YELLOW}全部协议 (V2Ray + Clash + Hysteria)${NC}"
            ;;
    esac
    echo ""
    echo -e "${CYAN}管理配置:${NC}"
    echo -e "  管理员邮箱: ${YELLOW}$ADMIN_EMAIL${NC}"
    echo -e "  管理界面: ${YELLOW}https://$DOMAIN${NC}"
    echo -e "  监控面板: ${YELLOW}https://$DOMAIN/grafana${NC}"
    echo ""
    echo -e "${CYAN}服务端口:${NC}"
    echo -e "  Web界面: ${YELLOW}443 (HTTPS)${NC}"
    echo -e "  API接口: ${YELLOW}8080${NC}"
    if [[ "$PROTOCOLS" == "v2ray" || "$PROTOCOLS" == "all" ]]; then
        echo -e "  V2Ray端口: ${YELLOW}10001-10020${NC}"
    fi
    if [[ "$PROTOCOLS" == "clash" || "$PROTOCOLS" == "all" ]]; then
        echo -e "  Clash端口: ${YELLOW}7890, 7891${NC}"
    fi
    if [[ "$PROTOCOLS" == "hysteria" || "$PROTOCOLS" == "all" ]]; then
        echo -e "  Hysteria端口: ${YELLOW}36712/UDP${NC}"
    fi
    echo ""
    echo -e "${WHITE}==================================================================${NC}"
    echo ""
    
    read -p "确认以上配置并开始部署？[Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
}

# 安装系统依赖
install_dependencies() {
    log_step "安装系统依赖"
    
    case $OS_TYPE in
        "debian")
            apt update > /dev/null 2>&1
            apt install -y curl wget git unzip htop net-tools > /dev/null 2>&1
            ;;
        "redhat")
            yum update -y > /dev/null 2>&1
            yum install -y curl wget git unzip htop net-tools > /dev/null 2>&1
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 安装Docker
install_docker() {
    log_step "安装Docker环境"
    
    if command -v docker &> /dev/null; then
        log_info "Docker已安装: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
        return 0
    fi
    
    case $OS_TYPE in
        "debian")
            curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
            ;;
        "redhat")
            curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
            ;;
    esac
    
    systemctl start docker
    systemctl enable docker
    
    # 安装Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'\"' -f4)
        curl -L \"https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose > /dev/null 2>&1
        chmod +x /usr/local/bin/docker-compose
    fi
    
    log_success "Docker环境安装完成"
}

# 创建项目目录
create_project_structure() {
    log_step "创建项目目录结构"
    
    # 创建主目录
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    
    # 创建子目录结构
    mkdir -p {configs/{nginx/conf.d,prometheus/rules,grafana/{provisioning,dashboards}},ssl,logs,backups,data,src/{api-gateway,rule-engine,config-manager,stats-collector,adapters/{v2ray,clash,hysteria}},protocol-configs/{v2ray,clash,hysteria},scripts}
    
    log_success "项目目录创建完成"
}

# 生成环境配置文件
generate_env_file() {
    log_step "生成环境配置文件"
    
    cat > $INSTALL_DIR/.env << EOF
# VPS代理管理系统环境配置
# 生成时间: $(date)

# ===========================================
# 基础配置
# ===========================================
NODE_ENV=production
DOMAIN=$DOMAIN
SERVER_IP=$SERVER_IP

# ===========================================
# 数据库配置
# ===========================================
POSTGRES_DB=vps_proxy_manager
POSTGRES_USER=proxy_admin
POSTGRES_PASSWORD=$DB_PASSWORD

REDIS_PASSWORD=$REDIS_PASSWORD

INFLUXDB_USER=admin
INFLUXDB_PASSWORD=$DB_PASSWORD
INFLUXDB_ORG=vps-proxy-org
INFLUXDB_BUCKET=proxy-metrics
INFLUXDB_TOKEN=$INFLUXDB_TOKEN

# ===========================================
# 安全配置
# ===========================================
JWT_SECRET=$JWT_SECRET
API_KEY_SECRET=$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-25)
SESSION_SECRET=$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-25)

# ===========================================
# 管理员配置
# ===========================================
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# ===========================================
# 监控配置
# ===========================================
GRAFANA_USER=admin
GRAFANA_PASSWORD=$ADMIN_PASSWORD
PROMETHEUS_RETENTION=200h

# ===========================================
# SSL配置
# ===========================================
SSL_TYPE=$SSL_TYPE
EOF

    if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
        cat >> $INSTALL_DIR/.env << EOF
LETSENCRYPT_EMAIL=$SSL_EMAIL
SSL_CERT_PATH=/etc/nginx/ssl/letsencrypt/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/letsencrypt/key.pem
EOF
    else
        cat >> $INSTALL_DIR/.env << EOF
SSL_CERT_PATH=/etc/nginx/ssl/custom/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/custom/key.pem
EOF
    fi

    cat >> $INSTALL_DIR/.env << EOF

# ===========================================
# 协议配置
# ===========================================
PROTOCOLS=$PROTOCOLS
CLASH_API_SECRET=$CLASH_API_SECRET

# ===========================================
# 端口配置
# ===========================================
API_GATEWAY_PORT=8080
RULE_ENGINE_PORT=8081
CONFIG_MANAGER_PORT=8082
STATS_COLLECTOR_PORT=8087

# V2Ray端口范围
V2RAY_PORT_START=10001
V2RAY_PORT_END=10020

# Clash端口
CLASH_HTTP_PORT=7890
CLASH_SOCKS_PORT=7891
CLASH_API_PORT=9090

# Hysteria端口
HYSTERIA_PORT=36712

# ===========================================
# 性能配置
# ===========================================
DB_MAX_CONNECTIONS=100
REDIS_MAX_CONNECTIONS=50
LOG_LEVEL=info
BACKUP_RETENTION_DAYS=30
EOF

    chmod 600 $INSTALL_DIR/.env
    log_success "环境配置文件生成完成"
}

# 主函数
main() {
    show_banner
    
    echo -e "${GREEN}欢迎使用VPS代理管理系统部署程序！${NC}"
    echo ""
    echo "此程序将引导您完成系统的完整部署，包括："
    echo "• 自动检测系统环境和资源"
    echo "• 配置域名和SSL证书"
    echo "• 选择要部署的代理协议"
    echo "• 生成安全配置和密钥"
    echo "• 部署完整的管理系统"
    echo ""
    
    read -p "按回车键开始配置..." -r
    
    # 执行部署流程
    check_system
    get_server_ip
    configure_domain_ssl
    select_protocols
    configure_admin
    generate_secrets
    show_configuration_summary
    
    log_step "开始系统部署"
    install_dependencies
    install_docker
    create_project_structure
    generate_env_file
    
    log_success "VPS代理管理系统部署配置完成！"
    echo ""
    echo -e "${YELLOW}下一步操作:${NC}"
    echo "1. 复制部署文件到服务器: rsync -av vps-deployment/ root@$SERVER_IP:$INSTALL_DIR/"
    echo "2. 在服务器上运行: cd $INSTALL_DIR && docker-compose up -d"
    echo "3. 访问管理界面: https://$DOMAIN"
    echo ""
    echo -e "${GREEN}部署完成！${NC}"
}

# 错误处理
trap 'log_error "部署过程中出现错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"