#!/bin/bash

# VPS代理管理系统 - 交互式管理界面
# Ubuntu系统专用管理工具 v4.0.0
# 命令行菜单式操作界面

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 获取系统信息
get_system_info() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "获取失败")
    SYSTEM_VERSION=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Ubuntu")
    UPTIME=$(uptime -p 2>/dev/null || echo "未知")
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    MEMORY_USAGE=$(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    DISK_USAGE=$(df -h / | awk 'NR==2{print $5}')
}

# 显示主菜单
show_main_menu() {
    clear
    get_system_info
    
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           ${WHITE}VPS代理管理系统${CYAN}                ║${NC}"
    echo -e "${CYAN}║         ${YELLOW}zhakil科技箱 v4.0.0${CYAN}            ║${NC}"
    echo -e "${CYAN}║     ${GREEN}命令行菜单操作界面${CYAN}                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}服务器IP: ${GREEN}$SERVER_IP${NC}    ${BLUE}系统: ${GREEN}$SYSTEM_VERSION${NC}"
    echo -e "${BLUE}运行时间: ${GREEN}$UPTIME${NC}"
    echo -e "${BLUE}负载: ${GREEN}$LOAD_AVG${NC}    ${BLUE}内存: ${GREEN}$MEMORY_USAGE${NC}    ${BLUE}磁盘: ${GREEN}$DISK_USAGE${NC}"
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e " ${YELLOW}1.${NC}  系统信息查询"
    echo -e " ${YELLOW}2.${NC}  服务管理"
    echo -e " ${YELLOW}3.${NC}  服务清理"
    echo -e " ${YELLOW}4.${NC}  基础工具"
    echo -e " ${YELLOW}5.${NC}  BBR管理"
    echo -e " ${YELLOW}6.${NC}  Docker管理"
    echo -e " ${YELLOW}7.${NC}  WARP管理"
    echo -e " ${YELLOW}8.${NC}  测试脚本合集"
    echo -e " ${YELLOW}9.${NC}  甲骨文云脚本合集"
    echo -e " ${YELLOW}10.${NC} 监控和日志"
    echo -e " ${YELLOW}11.${NC} 应用市场"
    echo -e " ${YELLOW}12.${NC} 后台工作区"
    echo -e " ${YELLOW}13.${NC} 系统工具"
    echo -e " ${YELLOW}14.${NC} 网络测试"
    echo -e " ${YELLOW}15.${NC} 安全管理"
    
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}I.${NC}   系统安装/重装"
    echo -e " ${RED}U.${NC}   系统卸载"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${GREEN}00.${NC} 脚本更新"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${RED}0.${NC}  退出脚本"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -ne "${WHITE}请输入你的选择: ${NC}"
}

# 系统信息查询
system_info() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}系统信息查询${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}基本信息:${NC}"
    echo -e "  服务器IP: ${GREEN}$(curl -s ifconfig.me)${NC}"
    echo -e "  系统版本: ${GREEN}$(lsb_release -d | cut -f2)${NC}"
    echo -e "  内核版本: ${GREEN}$(uname -r)${NC}"
    echo -e "  运行时间: ${GREEN}$(uptime -p)${NC}"
    echo
    
    echo -e "${YELLOW}资源使用:${NC}"
    echo -e "  CPU使用率: ${GREEN}$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%${NC}"
    echo -e "  内存使用: ${GREEN}$(free -h | awk 'NR==2{printf "%s/%s (%.1f%%)", $3,$2,$3*100/$2}')${NC}"
    echo -e "  磁盘使用: ${GREEN}$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3,$2,$5}')${NC}"
    echo -e "  系统负载: ${GREEN}$(uptime | awk -F'load average:' '{print $2}')${NC}"
    echo
    
    echo -e "${YELLOW}网络信息:${NC}"
    echo -e "  网卡信息: ${GREEN}$(ip route | grep default | awk '{print $5}')${NC}"
    echo -e "  DNS服务器: ${GREEN}$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)${NC}"
    echo
    
    if command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker状态:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
        echo
    fi
    
    echo -ne "${WHITE}按回车键返回主菜单...${NC}"
    read
}

# 服务管理
service_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}服务管理中心${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 查看服务状态"
    echo -e " ${YELLOW}2.${NC} 启动所有服务"
    echo -e " ${YELLOW}3.${NC} 停止所有服务"
    echo -e " ${YELLOW}4.${NC} 重启所有服务"
    echo -e " ${YELLOW}5.${NC} 查看服务日志"
    echo -e " ${YELLOW}6.${NC} 单独管理服务"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) docker-compose ps; echo; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        2) echo -e "${GREEN}正在启动所有服务...${NC}"; docker-compose up -d; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        3) echo -e "${YELLOW}正在停止所有服务...${NC}"; docker-compose down; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        4) echo -e "${BLUE}正在重启所有服务...${NC}"; docker-compose restart; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        5) docker-compose logs --tail=50; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        6) single_service_management ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    service_management
}

# 单独服务管理
single_service_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║             ${WHITE}单独服务管理${CYAN}                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}可用服务:${NC}"
    services=(
        "nginx" "api-gateway" "rule-engine" "config-manager"
        "v2ray-core" "clash-core" "hysteria-core"
        "postgres" "redis" "influxdb"
        "prometheus" "grafana"
    )
    
    for i in "${!services[@]}"; do
        echo -e " ${YELLOW}$((i+1)).${NC} ${services[i]}"
    done
    echo -e " ${RED}0.${NC} 返回上级菜单"
    echo
    echo -ne "${WHITE}请选择要管理的服务: ${NC}"
    
    read choice
    if [[ $choice -ge 1 && $choice -le ${#services[@]} ]]; then
        service_name=${services[$((choice-1))]}
        manage_single_service $service_name
    elif [[ $choice -eq 0 ]]; then
        return
    else
        echo -e "${RED}无效选择${NC}"; sleep 1
        single_service_management
    fi
}

# 管理单个服务
manage_single_service() {
    local service=$1
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            ${WHITE}管理服务: $service${CYAN}            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 启动服务"
    echo -e " ${YELLOW}2.${NC} 停止服务"
    echo -e " ${YELLOW}3.${NC} 重启服务"
    echo -e " ${YELLOW}4.${NC} 查看日志"
    echo -e " ${YELLOW}5.${NC} 查看状态"
    echo -e " ${RED}0.${NC} 返回服务列表"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) docker-compose start $service; echo -e "${GREEN}服务已启动${NC}" ;;
        2) docker-compose stop $service; echo -e "${YELLOW}服务已停止${NC}" ;;
        3) docker-compose restart $service; echo -e "${BLUE}服务已重启${NC}" ;;
        4) docker-compose logs --tail=100 $service ;;
        5) docker-compose ps $service ;;
        0) single_service_management; return ;;
        *) echo -e "${RED}无效选择${NC}" ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    manage_single_service $service
}

# 监控和日志
monitoring_logs() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}监控和日志${CYAN}                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 实时监控面板"
    echo -e " ${YELLOW}2.${NC} 系统资源监控"
    echo -e " ${YELLOW}3.${NC} Docker状态监控"
    echo -e " ${YELLOW}4.${NC} 网络连接监控"
    echo -e " ${YELLOW}5.${NC} 服务日志查看"
    echo -e " ${YELLOW}6.${NC} 错误日志分析"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择功能: ${NC}"
    
    read choice
    case $choice in
        1) 
            echo -e "${GREEN}启动实时监控...${NC}"
            echo -e "${BLUE}Grafana面板: ${GREEN}http://$(curl -s ifconfig.me):3000${NC}"
            echo -e "${BLUE}Prometheus: ${GREEN}http://$(curl -s ifconfig.me):9090${NC}"
            ;;
        2) htop 2>/dev/null || top ;;
        3) watch docker stats ;;
        4) watch ss -tuln ;;
        5) docker-compose logs -f --tail=100 ;;
        6) 
            echo -e "${YELLOW}分析错误日志...${NC}"
            docker-compose logs | grep -i error | tail -20
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    monitoring_logs
}

# Docker管理
docker_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}Docker管理${CYAN}                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} Docker状态查看"
    echo -e " ${YELLOW}2.${NC} 镜像管理"
    echo -e " ${YELLOW}3.${NC} 容器管理"
    echo -e " ${YELLOW}4.${NC} 网络管理"
    echo -e " ${YELLOW}5.${NC} 数据卷管理"
    echo -e " ${YELLOW}6.${NC} 系统清理"
    echo -e " ${YELLOW}7.${NC} Docker更新"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) 
            docker version
            echo
            docker info | head -20
            ;;
        2) docker images ;;
        3) docker ps -a ;;
        4) docker network ls ;;
        5) docker volume ls ;;
        6) 
            echo -e "${YELLOW}清理Docker系统...${NC}"
            docker system prune -f
            ;;
        7) 
            echo -e "${BLUE}更新Docker...${NC}"
            apt update && apt upgrade docker-ce -y
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    docker_management
}

# 系统工具
system_tools() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}系统工具箱${CYAN}                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 系统更新升级"
    echo -e " ${YELLOW}2.${NC} 防火墙管理"
    echo -e " ${YELLOW}3.${NC} SSH配置"
    echo -e " ${YELLOW}4.${NC} 时区设置"
    echo -e " ${YELLOW}5.${NC} 定时任务"
    echo -e " ${YELLOW}6.${NC} 系统优化"
    echo -e " ${YELLOW}7.${NC} 备份恢复"
    echo -e " ${YELLOW}8.${NC} 安全检查"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择工具: ${NC}"
    
    read choice
    case $choice in
        1) 
            echo -e "${GREEN}正在更新系统...${NC}"
            apt update && apt upgrade -y
            ;;
        2) ufw status; echo; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        3) echo -e "${BLUE}SSH配置文件位置: ${GREEN}/etc/ssh/sshd_config${NC}" ;;
        4) timedatectl; echo; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        5) crontab -l; echo; echo -ne "${WHITE}按回车键继续...${NC}"; read ;;
        6) 
            echo -e "${GREEN}执行系统优化...${NC}"
            sysctl -p
            ;;
        7) echo -e "${YELLOW}备份功能开发中...${NC}" ;;
        8) 
            echo -e "${GREEN}执行安全检查...${NC}"
            ss -tuln | grep LISTEN
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    system_tools
}

# 系统安装/重装
install_system() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            ${WHITE}系统安装/重装${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 全新安装系统"
    echo -e " ${YELLOW}2.${NC} 重新安装系统"
    echo -e " ${YELLOW}3.${NC} 安装轻量版"
    echo -e " ${YELLOW}4.${NC} 从GitHub安装最新版"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择安装方式: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${GREEN}正在执行全新安装...${NC}"
            if [[ -f "./deploy.sh" ]]; then
                bash ./deploy.sh
            else
                bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/deploy.sh)
            fi
            ;;
        2)
            echo -e "${YELLOW}正在重新安装系统...${NC}"
            echo -e "${RED}警告: 这将删除所有现有数据！${NC}"
            read -p "确认继续? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if [[ -f "./uninstall.sh" ]]; then
                    bash ./uninstall.sh --backup
                fi
                sleep 2
                if [[ -f "./deploy.sh" ]]; then
                    bash ./deploy.sh
                else
                    bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/deploy.sh)
                fi
            fi
            ;;
        3)
            echo -e "${BLUE}正在安装轻量版...${NC}"
            if [[ -f "./install-lite.sh" ]]; then
                bash ./install-lite.sh
            else
                bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/install-lite.sh)
            fi
            ;;
        4)
            echo -e "${GREEN}正在从GitHub安装最新版...${NC}"
            bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/deploy.sh)
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    install_system
}

# 系统卸载
uninstall_system() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}系统卸载${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${RED}警告: 这将完全删除VPS代理管理系统！${NC}"
    echo
    echo -e " ${YELLOW}1.${NC} 备份后卸载"
    echo -e " ${YELLOW}2.${NC} 直接卸载（不备份）"
    echo -e " ${YELLOW}3.${NC} 仅停止服务"
    echo -e " ${YELLOW}4.${NC} 清理Docker环境"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择卸载方式: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${GREEN}正在备份数据并卸载...${NC}"
            if [[ -f "./uninstall.sh" ]]; then
                bash ./uninstall.sh --backup
            else
                bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/uninstall.sh) --backup
            fi
            ;;
        2)
            echo -e "${RED}正在直接卸载...${NC}"
            read -p "$(echo -e "${RED}确认删除所有数据? [y/N]: ${NC}")" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if [[ -f "./uninstall.sh" ]]; then
                    bash ./uninstall.sh
                else
                    bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/uninstall.sh)
                fi
            fi
            ;;
        3)
            echo -e "${YELLOW}正在停止所有服务...${NC}"
            docker-compose down
            echo -e "${GREEN}服务已停止${NC}"
            ;;
        4)
            echo -e "${YELLOW}正在清理Docker环境...${NC}"
            docker system prune -af
            docker volume prune -f
            echo -e "${GREEN}Docker环境已清理${NC}"
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    uninstall_system
}

# 网络测试
network_test() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}网络测试${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 网络延迟测试"
    echo -e " ${YELLOW}2.${NC} 带宽速度测试"
    echo -e " ${YELLOW}3.${NC} 路由追踪测试"
    echo -e " ${YELLOW}4.${NC} DNS解析测试"
    echo -e " ${YELLOW}5.${NC} 端口连通性测试"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择测试项目: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${GREEN}正在测试网络延迟...${NC}"
            ping -c 4 8.8.8.8
            ping -c 4 1.1.1.1
            ;;
        2)
            echo -e "${GREEN}正在测试带宽速度...${NC}"
            curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3
            ;;
        3)
            echo -e "${GREEN}正在进行路由追踪...${NC}"
            traceroute 8.8.8.8
            ;;
        4)
            echo -e "${GREEN}正在测试DNS解析...${NC}"
            nslookup google.com
            nslookup github.com
            ;;
        5)
            echo -e "${GREEN}正在测试端口连通性...${NC}"
            ss -tuln
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    network_test
}

# 安全管理
security_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}安全管理${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 防火墙状态"
    echo -e " ${YELLOW}2.${NC} SSH配置检查"
    echo -e " ${YELLOW}3.${NC} 登录日志分析"
    echo -e " ${YELLOW}4.${NC} 端口扫描检测"
    echo -e " ${YELLOW}5.${NC} 系统安全加固"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择功能: ${NC}"
    
    read choice
    case $choice in
        1) ufw status verbose ;;
        2) 
            echo -e "${YELLOW}SSH配置信息:${NC}"
            grep -E "Port|PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config
            ;;
        3)
            echo -e "${YELLOW}最近登录记录:${NC}"
            last -n 20
            ;;
        4)
            echo -e "${YELLOW}监听端口:${NC}"
            ss -tuln
            ;;
        5)
            echo -e "${GREEN}系统安全加固功能开发中...${NC}"
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    security_management
}

# 脚本更新
update_script() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}脚本更新${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${GREEN}正在检查更新...${NC}"
    
    # 更新管理脚本
    curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/manage.sh -o /tmp/manage_new.sh
    if [[ -f /tmp/manage_new.sh ]]; then
        cp /tmp/manage_new.sh ./manage.sh
        chmod +x ./manage.sh
        # 如果是全局安装，也更新全局文件
        if [[ -f /usr/local/bin/zhakil-manage ]]; then
            cp ./manage.sh /usr/local/bin/zhakil-manage
        fi
        echo -e "${GREEN}管理脚本更新完成${NC}"
    fi
    
    # 更新项目文件
    git pull origin main 2>/dev/null || echo -e "${YELLOW}无法自动更新项目，请手动更新${NC}"
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
}

# 主循环
main() {
    while true; do
        show_main_menu
        read choice
        
        case $choice in
            1) system_info ;;
            2) service_management ;;
            3) echo -e "${YELLOW}服务清理功能开发中...${NC}"; sleep 2 ;;
            4) system_tools ;;
            5) echo -e "${YELLOW}BBR管理功能开发中...${NC}"; sleep 2 ;;
            6) docker_management ;;
            7) echo -e "${YELLOW}WARP管理功能开发中...${NC}"; sleep 2 ;;
            8) echo -e "${YELLOW}测试脚本合集开发中...${NC}"; sleep 2 ;;
            9) echo -e "${YELLOW}甲骨文云脚本开发中...${NC}"; sleep 2 ;;
            10) monitoring_logs ;;
            11) echo -e "${YELLOW}应用市场开发中...${NC}"; sleep 2 ;;
            12) echo -e "${YELLOW}后台工作区开发中...${NC}"; sleep 2 ;;
            13) system_tools ;;
            14) network_test ;;
            15) security_management ;;
            i|I) install_system ;;
            u|U) uninstall_system ;;
            00) update_script ;;
            0) 
                echo -e "${GREEN}感谢使用 VPS代理管理系统！${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 1
                ;;
        esac
    done
}

# 检查运行环境
check_environment() {
    # 检查标准安装目录
    INSTALL_DIR="/opt/vpn-proxy"
    if [[ -d "$INSTALL_DIR" && -f "$INSTALL_DIR/docker-compose.yml" ]]; then
        cd "$INSTALL_DIR"
        return
    fi
    
    # 检查当前目录
    if [[ -f docker-compose.yml ]]; then
        return
    fi
    
    # 尝试查找项目目录
    for dir in /opt/vpn-proxy /opt/vps-proxy /root/vpn /home/*/vpn .; do
        if [[ -d "$dir" && -f "$dir/docker-compose.yml" ]]; then
            cd "$dir"
            return
        fi
    done
    
    echo -e "${RED}错误: 未找到 VPS代理管理系统${NC}"
    echo -e "${YELLOW}请确保系统已正确安装或在项目目录下运行${NC}"
    echo -e "${BLUE}安装命令: ${GREEN}bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/install.sh)${NC}"
    exit 1
}

# 启动脚本
echo -e "${GREEN}正在启动 VPS代理管理系统...${NC}"
check_environment
main