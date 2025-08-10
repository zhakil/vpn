#!/bin/bash

# VPS代理管理系统 - 快速安装脚本
# 一键下载并安装完整系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo bash install.sh"
        exit 1
    fi
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════╗"
    echo "║        VPS代理管理系统 - 快速安装         ║"
    echo "║            zhakil科技箱                    ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# 下载项目文件
download_project() {
    log_info "正在下载项目文件..."
    
    # 安装git和curl
    if command -v apt &> /dev/null; then
        apt update && apt install -y git curl
    elif command -v yum &> /dev/null; then
        yum install -y git curl
    fi
    
    # 下载项目
    if [[ -d "/opt/vpn-proxy" ]]; then
        rm -rf /opt/vpn-proxy
    fi
    
    mkdir -p /opt/vpn-proxy
    cd /opt/vpn-proxy
    
    # 下载核心文件
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/docker-compose.yml -o docker-compose.yml
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/deploy.sh -o deploy.sh
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/manage.sh -o manage.sh
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/uninstall.sh -o uninstall.sh
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/install-lite.sh -o install-lite.sh
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/.gitignore -o .gitignore
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/README.md -o README.md
    
    chmod +x *.sh
    
    log_success "项目文件下载完成"
}

# 创建快捷命令
create_shortcut() {
    log_info "创建快捷命令..."
    
    # 创建全局管理脚本
    cp manage.sh /usr/local/bin/zhakil-manage
    chmod +x /usr/local/bin/zhakil-manage
    
    # 创建快捷命令脚本
    cat > /usr/local/bin/zhakil << 'EOF'
#!/bin/bash
# VPS代理管理系统快捷命令

INSTALL_DIR="/opt/vpn-proxy"

if [[ -d "$INSTALL_DIR" && -f "$INSTALL_DIR/manage.sh" ]]; then
    cd "$INSTALL_DIR"
    ./manage.sh
else
    echo -e "\033[0;31m错误: 未找到VPS代理管理系统\033[0m"
    echo -e "\033[1;33m请运行安装命令: bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/install.sh)\033[0m"
    exit 1
fi
EOF

    chmod +x /usr/local/bin/zhakil
    ln -sf /usr/local/bin/zhakil /usr/bin/zhakil
    
    log_success "快捷命令创建完成"
}

# 显示完成信息
show_completion() {
    echo
    log_success "════════════════════════════════════════"
    log_success "    VPS代理管理系统安装完成！"
    log_success "════════════════════════════════════════"
    echo
    echo -e "${BLUE}使用方法:${NC}"
    echo -e "  快速进入: ${GREEN}zhakil${NC}"
    echo -e "  完整部署: ${YELLOW}cd /opt/vpn-proxy && sudo bash deploy.sh${NC}"
    echo -e "  管理界面: ${YELLOW}cd /opt/vpn-proxy && ./manage.sh${NC}"
    echo
    echo -e "${BLUE}项目位置: ${GREEN}/opt/vpn-proxy${NC}"
    echo
    
    read -p "$(echo -e "${GREEN}是否现在就进入管理界面? [Y/n]: ${NC}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$|^$ ]]; then
        sleep 1
        cd /opt/vpn-proxy
        ./manage.sh
    fi
}

# 主安装流程
main() {
    show_welcome
    check_root
    download_project
    create_shortcut
    show_completion
}

# 执行安装
main "$@"