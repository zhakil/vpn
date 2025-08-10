#!/bin/bash

# VPS代理管理系统 - 强制卸载脚本
# 用于Docker不可用时的紧急卸载

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo bash force-uninstall.sh"
        exit 1
    fi
}

# 确认卸载
confirm_uninstall() {
    echo -e "${RED}"
    echo "========================================"
    echo "     VPS代理管理系统 - 强制卸载"
    echo "           zhakil科技箱 v4.0.0"
    echo "========================================"
    echo -e "${NC}"
    
    log_warning "此强制卸载脚本将："
    echo "  • 终止所有代理相关进程"
    echo "  • 删除所有项目文件"
    echo "  • 清理端口占用"
    echo "  • 删除系统服务"
    echo "  • 清理防火墙规则"
    echo
    
    read -p "$(echo -e "${RED}确定要继续吗? [y/N]: ${NC}")" -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "卸载已取消"
        exit 0
    fi
}

# 强制停止所有服务
force_stop_services() {
    log_info "强制停止所有相关服务..."
    
    # 终止代理进程
    log_info "终止代理进程..."
    pkill -f "v2ray\|clash\|hysteria\|nginx" 2>/dev/null || true
    
    # 检查并终止端口占用
    PORTS=(80 443 8080 3000 9090 7890 7891 10001 10002 10003 36712)
    for port in "${PORTS[@]}"; do
        PID=$(lsof -ti:$port 2>/dev/null || true)
        if [[ -n "$PID" ]]; then
            log_info "终止占用端口$port的进程: $PID"
            kill -9 $PID 2>/dev/null || true
        fi
    done
    
    # 停止系统服务
    SERVICES=(v2ray clash hysteria nginx vpn-proxy vps-proxy)
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet $service 2>/dev/null; then
            log_info "停止系统服务: $service"
            systemctl stop $service 2>/dev/null || true
            systemctl disable $service 2>/dev/null || true
        fi
    done
    
    log_success "服务停止完成"
}

# 清理项目文件
cleanup_all_files() {
    log_info "清理所有项目文件..."
    
    # 标准安装目录
    INSTALL_DIRS=("/opt/vpn-proxy" "/opt/vps-proxy" "/root/vpn" "/home/*/vpn")
    for dir in "${INSTALL_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "删除目录: $dir"
            rm -rf "$dir"
        fi
    done
    
    # 当前目录下的文件
    CURRENT_DIR_FILES=(
        "docker-compose.yml" "deploy.sh" "install.sh" "install-lite.sh" 
        "manage.sh" "uninstall.sh" ".env" "README.md" ".gitignore"
    )
    
    CURRENT_DIR_FOLDERS=(
        "src" "configs" "protocol-configs" "ssl" "scripts" 
        "data" "logs" "backups"
    )
    
    for file in "${CURRENT_DIR_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "删除文件: $file"
            rm -f "$file"
        fi
    done
    
    for folder in "${CURRENT_DIR_FOLDERS[@]}"; do
        if [[ -d "$folder" ]]; then
            log_info "删除目录: $folder"
            rm -rf "$folder"
        fi
    done
    
    log_success "项目文件清理完成"
}

# 清理系统配置
cleanup_system_config() {
    log_info "清理系统配置..."
    
    # 删除systemd服务文件
    SERVICE_FILES=(
        "/etc/systemd/system/vps-proxy.service"
        "/etc/systemd/system/vpn-proxy.service"
        "/etc/systemd/system/v2ray.service"
        "/etc/systemd/system/clash.service"
        "/etc/systemd/system/hysteria.service"
    )
    
    for service_file in "${SERVICE_FILES[@]}"; do
        if [[ -f "$service_file" ]]; then
            log_info "删除服务文件: $service_file"
            rm -f "$service_file"
        fi
    done
    
    # 重载systemd
    systemctl daemon-reload 2>/dev/null || true
    
    # 清理定时任务
    log_info "清理定时任务..."
    crontab -l 2>/dev/null | grep -v "vps-proxy\|vpn\|cache-cleanup\|v2ray\|clash\|hysteria" | crontab - 2>/dev/null || true
    
    # 删除全局命令
    GLOBAL_COMMANDS=("/usr/local/bin/zhakil" "/usr/bin/zhakil" "/usr/local/bin/zhakil-manage")
    for cmd in "${GLOBAL_COMMANDS[@]}"; do
        if [[ -f "$cmd" ]]; then
            log_info "删除全局命令: $cmd"
            rm -f "$cmd"
        fi
    done
    
    log_success "系统配置清理完成"
}

# 清理防火墙规则
cleanup_firewall_rules() {
    log_info "清理防火墙规则..."
    
    PORTS=(80 443 8080 3000 9090 7890 7891 36712)
    
    if command -v ufw &> /dev/null; then
        for port in "${PORTS[@]}"; do
            ufw --force delete allow $port 2>/dev/null || true
        done
        # 清理端口范围
        ufw --force delete allow 10001:10020/tcp 2>/dev/null || true
        ufw --force delete allow 10001:10020/udp 2>/dev/null || true
    elif command -v firewall-cmd &> /dev/null; then
        for port in "${PORTS[@]}"; do
            firewall-cmd --permanent --remove-port=${port}/tcp 2>/dev/null || true
            firewall-cmd --permanent --remove-port=${port}/udp 2>/dev/null || true
        done
        firewall-cmd --permanent --remove-port=10001-10020/tcp 2>/dev/null || true
        firewall-cmd --permanent --remove-port=10001-10020/udp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    log_success "防火墙规则清理完成"
}

# 显示结果
show_result() {
    echo
    log_success "=================================="
    log_success "   强制卸载完成！"
    log_success "=================================="
    echo
    log_info "已清理的内容："
    echo "  ✓ 所有代理相关进程"
    echo "  ✓ 端口占用"
    echo "  ✓ 系统服务"
    echo "  ✓ 项目文件和配置"
    echo "  ✓ 防火墙规则"
    echo "  ✓ 定时任务"
    echo "  ✓ 全局命令"
    echo
    log_info "如需重新安装，请运行:"
    echo -e "  ${GREEN}bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/install.sh)${NC}"
}

# 主函数
main() {
    clear
    check_root
    confirm_uninstall
    force_stop_services
    cleanup_all_files
    cleanup_system_config
    cleanup_firewall_rules
    show_result
}

# 执行主函数
main "$@"