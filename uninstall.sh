#!/bin/bash

# VPS代理管理系统 - 完全卸载脚本
# 用于完全移除所有相关组件和数据

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

# 确认卸载
confirm_uninstall() {
    echo -e "${RED}"
    echo "========================================"
    echo "     VPS代理管理系统 - 完全卸载"
    echo "           zhakil科技箱 v4.0.0"
    echo "========================================"
    echo -e "${NC}"
    
    log_warning "此操作将完全删除以下内容："
    echo "  • 所有Docker容器和镜像"
    echo "  • 所有数据库数据"
    echo "  • 所有配置文件"
    echo "  • 所有日志文件"
    echo "  • 防火墙规则"
    echo
    
    read -p "$(echo -e "${RED}确定要继续吗? [y/N]: ${NC}")" -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "卸载已取消"
        exit 0
    fi
}

# 数据备份选项
backup_data() {
    if [[ "$1" == "--backup" ]] || [[ "$1" == "-b" ]]; then
        log_info "正在备份重要数据..."
        
        BACKUP_DIR="./backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        # 备份数据库
        if docker ps --format "table {{.Names}}" | grep -q "vps-postgres"; then
            log_info "备份PostgreSQL数据..."
            docker exec vps-postgres pg_dump -U postgres vps_proxy > "$BACKUP_DIR/database.sql"
        fi
        
        # 备份配置文件
        if [[ -f .env ]]; then
            cp .env "$BACKUP_DIR/"
        fi
        
        if [[ -d protocol-configs ]]; then
            cp -r protocol-configs "$BACKUP_DIR/"
        fi
        
        if [[ -d configs ]]; then
            cp -r configs "$BACKUP_DIR/"
        fi
        
        log_success "数据已备份到: $BACKUP_DIR"
    fi
}

# 停止所有服务
stop_services() {
    log_info "停止所有Docker服务..."
    
    if [[ -f docker-compose.yml ]]; then
        docker-compose down --remove-orphans
    fi
    
    # 强制停止所有相关容器
    CONTAINERS=$(docker ps -q --filter "name=vps-*")
    if [[ -n "$CONTAINERS" ]]; then
        docker stop $CONTAINERS
        docker rm $CONTAINERS
    fi
    
    log_success "服务已停止"
}

# 清理Docker资源
cleanup_docker() {
    log_info "清理Docker资源..."
    
    # 删除相关镜像
    IMAGES=(
        "nginx:alpine"
        "node:18-alpine"
        "postgres:15-alpine"
        "redis:7-alpine"
        "v2fly/v2fly-core:latest"
        "ghcr.io/metacubex/mihomo:latest"
        "tobyxdd/hysteria:latest"
        "prom/prometheus:latest"
        "grafana/grafana:latest"
        "influxdb:2.7-alpine"
        "alpine:latest"
    )
    
    for image in "${IMAGES[@]}"; do
        if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$image"; then
            docker rmi "$image" 2>/dev/null || true
        fi
    done
    
    # 清理数据卷
    VOLUMES=$(docker volume ls --format "{{.Name}}" | grep "vpn_\|vps-")
    if [[ -n "$VOLUMES" ]]; then
        docker volume rm $VOLUMES
    fi
    
    # 清理网络
    NETWORKS=$(docker network ls --format "{{.Name}}" | grep "vpn_\|vps-")
    if [[ -n "$NETWORKS" ]]; then
        docker network rm $NETWORKS
    fi
    
    # 清理未使用的资源
    docker system prune -f
    
    log_success "Docker资源清理完成"
}

# 清理防火墙规则
cleanup_firewall() {
    log_info "清理防火墙规则..."
    
    PORTS=(80 443 8080 3000 9090 7890 7891 36712)
    
    if command -v ufw &> /dev/null; then
        for port in "${PORTS[@]}"; do
            ufw --force delete allow $port 2>/dev/null || true
        done
        # 也清理端口范围
        ufw --force delete allow 10001:10020/tcp 2>/dev/null || true
        ufw --force delete allow 10001:10020/udp 2>/dev/null || true
    elif command -v firewall-cmd &> /dev/null; then
        for port in "${PORTS[@]}"; do
            firewall-cmd --permanent --remove-port=${port}/tcp 2>/dev/null || true
            firewall-cmd --permanent --remove-port=${port}/udp 2>/dev/null || true
        done
        # 清理端口范围
        firewall-cmd --permanent --remove-port=10001-10020/tcp 2>/dev/null || true
        firewall-cmd --permanent --remove-port=10001-10020/udp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    log_success "防火墙规则清理完成"
}

# 清理项目文件
cleanup_files() {
    log_info "清理项目文件..."
    
    # 删除源码目录
    if [[ -d src ]]; then
        rm -rf src
    fi
    
    # 删除配置目录
    if [[ -d configs ]]; then
        rm -rf configs
    fi
    
    # 删除协议配置
    if [[ -d protocol-configs ]]; then
        rm -rf protocol-configs
    fi
    
    # 删除SSL证书
    if [[ -d ssl ]]; then
        rm -rf ssl
    fi
    
    # 删除脚本文件
    if [[ -d scripts ]]; then
        rm -rf scripts
    fi
    
    # 删除Docker compose文件
    if [[ -f docker-compose.yml ]]; then
        rm -f docker-compose.yml
    fi
    
    # 删除环境配置文件
    if [[ -f .env ]]; then
        read -p "$(echo -e "${YELLOW}是否删除.env配置文件? [y/N]: ${NC}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f .env
        fi
    fi
    
    # 删除安装脚本
    if [[ -f deploy.sh ]]; then
        rm -f deploy.sh
    fi
    
    if [[ -f install.sh ]]; then
        rm -f install.sh
    fi
    
    if [[ -f install-lite.sh ]]; then
        rm -f install-lite.sh
    fi
    
    log_success "项目文件清理完成"
}

# 清理系统服务和定时任务
cleanup_system() {
    log_info "清理系统配置..."
    
    # 清理可能的systemd服务
    if [[ -f /etc/systemd/system/vps-proxy.service ]]; then
        systemctl stop vps-proxy 2>/dev/null || true
        systemctl disable vps-proxy 2>/dev/null || true
        rm -f /etc/systemd/system/vps-proxy.service
        systemctl daemon-reload
    fi
    
    # 清理定时任务
    crontab -l 2>/dev/null | grep -v "vps-proxy\|vpn\|cache-cleanup" | crontab - 2>/dev/null || true
    
    log_success "系统配置清理完成"
}

# 可选：卸载Docker
uninstall_docker() {
    read -p "$(echo -e "${YELLOW}是否同时卸载Docker? [y/N]: ${NC}")" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "卸载Docker..."
        
        # 检测系统类型
        if [[ -f /etc/debian_version ]]; then
            apt remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            apt autoremove -y
        elif [[ -f /etc/redhat-release ]]; then
            yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        fi
        
        # 删除Docker数据目录
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
        
        # 删除Docker组
        groupdel docker 2>/dev/null || true
        
        log_success "Docker卸载完成"
    fi
}

# 显示卸载结果
show_result() {
    echo
    log_success "=================================="
    log_success "   VPS代理管理系统卸载完成！"
    log_success "=================================="
    echo
    log_info "已清理的内容："
    echo "  ✓ 所有Docker容器和镜像"
    echo "  ✓ 所有数据卷和网络"
    echo "  ✓ 项目源码和配置文件"
    echo "  ✓ 防火墙规则"
    echo "  ✓ 系统服务和定时任务"
    echo
    
    if [[ -d ./backup-* ]]; then
        log_info "数据备份保存在当前目录的 backup-* 文件夹中"
    fi
    
    log_warning "如需重新安装，请运行: ./deploy.sh"
}

# 主卸载流程
main() {
    clear
    check_root
    confirm_uninstall
    backup_data "$1"
    stop_services
    cleanup_docker
    cleanup_firewall
    cleanup_files
    cleanup_system
    uninstall_docker
    show_result
}

# 显示帮助信息
show_help() {
    echo "VPS代理管理系统 - 卸载脚本"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -b, --backup    卸载前备份重要数据"
    echo "  -h, --help      显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0              # 直接卸载"
    echo "  $0 --backup     # 备份后卸载"
}

# 参数处理
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -b|--backup)
        main --backup
        ;;
    *)
        main "$1"
        ;;
esac