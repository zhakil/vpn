#!/bin/bash

# VPS代理管理系统 - 专业管理界面
# zhakil科技箱 VPN代理管理专用工具 v4.0.0
# 专注于代理服务管理和配置

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
    
    # VPN服务状态
    if command -v docker &> /dev/null && [[ -f docker-compose.yml ]]; then
        V2RAY_STATUS=$(docker-compose ps v2ray-core 2>/dev/null | grep -q "Up" && echo "运行中" || echo "已停止")
        CLASH_STATUS=$(docker-compose ps clash-core 2>/dev/null | grep -q "Up" && echo "运行中" || echo "已停止")
        HYSTERIA_STATUS=$(docker-compose ps hysteria-core 2>/dev/null | grep -q "Up" && echo "运行中" || echo "已停止")
        NGINX_STATUS=$(docker-compose ps nginx 2>/dev/null | grep -q "Up" && echo "运行中" || echo "已停止")
    else
        V2RAY_STATUS="未部署"
        CLASH_STATUS="未部署"
        HYSTERIA_STATUS="未部署"
        NGINX_STATUS="未部署"
    fi
}

# 显示主菜单
show_main_menu() {
    clear
    get_system_info
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                ${WHITE}VPS代理管理系统${CYAN}                     ║${NC}"
    echo -e "${CYAN}║              ${YELLOW}zhakil科技箱 v4.0.0${CYAN}                  ║${NC}"
    echo -e "${CYAN}║            ${GREEN}专业VPN代理服务管理平台${CYAN}               ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}服务器信息: ${GREEN}$SERVER_IP${NC}  ${BLUE}系统: ${GREEN}$SYSTEM_VERSION${NC}"
    echo -e "${BLUE}运行时间: ${GREEN}$UPTIME${NC}  ${BLUE}负载: ${GREEN}$LOAD_AVG${NC}"
    echo -e "${BLUE}内存: ${GREEN}$MEMORY_USAGE${NC}  ${BLUE}磁盘: ${GREEN}$DISK_USAGE${NC}"
    echo
    
    # 服务状态显示
    echo -e "${CYAN}┌─────────────── ${WHITE}代理服务状态${CYAN} ───────────────┐${NC}"
    printf "${CYAN}│${NC} V2Ray: %-12s Clash: %-12s ${CYAN}│${NC}\n" \
           "$(echo -e "${V2RAY_STATUS}" | sed "s/运行中/${GREEN}运行中${NC}/;s/已停止/${RED}已停止${NC}/;s/未部署/${YELLOW}未部署${NC}/")" \
           "$(echo -e "${CLASH_STATUS}" | sed "s/运行中/${GREEN}运行中${NC}/;s/已停止/${RED}已停止${NC}/;s/未部署/${YELLOW}未部署${NC}/")"
    printf "${CYAN}│${NC} Hysteria: %-9s Nginx: %-12s ${CYAN}│${NC}\n" \
           "$(echo -e "${HYSTERIA_STATUS}" | sed "s/运行中/${GREEN}运行中${NC}/;s/已停止/${RED}已停止${NC}/;s/未部署/${YELLOW}未部署${NC}/")" \
           "$(echo -e "${NGINX_STATUS}" | sed "s/运行中/${GREEN}运行中${NC}/;s/已停止/${RED}已停止${NC}/;s/未部署/${YELLOW}未部署${NC}/")"
    echo -e "${CYAN}└───────────────────────────────────────────────────┘${NC}"
    echo
    
    # 主菜单
    echo -e "${CYAN}┌─────────────── ${WHITE}代理协议管理${CYAN} ───────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}1.${NC} V2Ray管理        ${YELLOW}2.${NC} Clash管理        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}3.${NC} Hysteria管理      ${YELLOW}4.${NC} Nginx管理        ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "${CYAN}┌─────────────── ${WHITE}节点和用户管理${CYAN} ─────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}5.${NC} 节点管理          ${YELLOW}6.${NC} 用户管理         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}7.${NC} 配置生成          ${YELLOW}8.${NC} 订阅管理         ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "${CYAN}┌─────────────── ${WHITE}监控和维护${CYAN} ─────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}9.${NC} 流量监控          ${YELLOW}10.${NC} 连接状态        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}11.${NC} 日志查看         ${YELLOW}12.${NC} 性能优化        ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "${CYAN}┌─────────────── ${WHITE}系统管理${CYAN} ───────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}13.${NC} 系统信息         ${YELLOW}14.${NC} 安全设置        ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}15.${NC} 备份恢复         ${YELLOW}16.${NC} 证书管理        ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────────┘${NC}"
    echo
    echo -e "${CYAN}┌─────────────── ${WHITE}部署选项${CYAN} ───────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}I.${NC} 系统安装/重装     ${RED}U.${NC} 系统卸载         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${BLUE}00.${NC} 脚本更新         ${RED}0.${NC} 退出程序         ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────────┘${NC}"
    echo
    echo -ne "${WHITE}请选择功能 [1-16/I/U/00/0]: ${NC}"
}

# V2Ray管理
v2ray_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}V2Ray 管理${CYAN}                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    # 检查V2Ray状态
    if command -v docker &> /dev/null && [[ -f docker-compose.yml ]]; then
        V2RAY_STATUS=$(docker-compose ps v2ray-core 2>/dev/null | grep -q "Up" && echo "运行中" || echo "已停止")
        echo -e "${BLUE}当前状态: ${GREEN}$V2RAY_STATUS${NC}"
        
        if [[ "$V2RAY_STATUS" == "运行中" ]]; then
            echo -e "${BLUE}监听端口: ${GREEN}10001-10020${NC}"
            echo -e "${BLUE}配置文件: ${GREEN}/opt/vpn-proxy/protocol-configs/v2ray/config.json${NC}"
        fi
    else
        echo -e "${RED}Docker未安装或配置文件不存在${NC}"
    fi
    echo
    
    echo -e " ${YELLOW}1.${NC} 启动V2Ray服务"
    echo -e " ${YELLOW}2.${NC} 停止V2Ray服务"
    echo -e " ${YELLOW}3.${NC} 重启V2Ray服务"
    echo -e " ${YELLOW}4.${NC} 查看V2Ray日志"
    echo -e " ${YELLOW}5.${NC} 编辑V2Ray配置"
    echo -e " ${YELLOW}6.${NC} 生成V2Ray链接"
    echo -e " ${YELLOW}7.${NC} 添加V2Ray用户"
    echo -e " ${YELLOW}8.${NC} 删除V2Ray用户"
    echo -e " ${YELLOW}9.${NC} V2Ray流量统计"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) docker-compose start v2ray-core; echo -e "${GREEN}V2Ray已启动${NC}" ;;
        2) docker-compose stop v2ray-core; echo -e "${YELLOW}V2Ray已停止${NC}" ;;
        3) docker-compose restart v2ray-core; echo -e "${BLUE}V2Ray已重启${NC}" ;;
        4) docker-compose logs --tail=100 v2ray-core ;;
        5) 
            echo -e "${YELLOW}V2Ray配置编辑功能开发中...${NC}"
            echo -e "${BLUE}配置文件位置: /opt/vpn-proxy/protocol-configs/v2ray/config.json${NC}"
            ;;
        6) generate_v2ray_links ;;
        7) add_v2ray_user ;;
        8) remove_v2ray_user ;;
        9) show_v2ray_traffic ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    v2ray_management
}

# Clash管理
clash_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}Clash 管理${CYAN}                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    # 检查Clash状态
    if command -v docker &> /dev/null && [[ -f docker-compose.yml ]]; then
        CLASH_STATUS=$(docker-compose ps clash-core 2>/dev/null | grep -q "Up" && echo "运行中" || echo "已停止")
        echo -e "${BLUE}当前状态: ${GREEN}$CLASH_STATUS${NC}"
        
        if [[ "$CLASH_STATUS" == "运行中" ]]; then
            echo -e "${BLUE}HTTP端口: ${GREEN}7890${NC}"
            echo -e "${BLUE}SOCKS端口: ${GREEN}7891${NC}"
            echo -e "${BLUE}控制面板: ${GREEN}http://$SERVER_IP:9090${NC}"
        fi
    else
        echo -e "${RED}Docker未安装或配置文件不存在${NC}"
    fi
    echo
    
    echo -e " ${YELLOW}1.${NC} 启动Clash服务"
    echo -e " ${YELLOW}2.${NC} 停止Clash服务"
    echo -e " ${YELLOW}3.${NC} 重启Clash服务"
    echo -e " ${YELLOW}4.${NC} 查看Clash日志"
    echo -e " ${YELLOW}5.${NC} 编辑Clash配置"
    echo -e " ${YELLOW}6.${NC} 更新规则集"
    echo -e " ${YELLOW}7.${NC} 节点测速"
    echo -e " ${YELLOW}8.${NC} 流量统计"
    echo -e " ${YELLOW}9.${NC} 打开Web面板"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) docker-compose start clash-core; echo -e "${GREEN}Clash已启动${NC}" ;;
        2) docker-compose stop clash-core; echo -e "${YELLOW}Clash已停止${NC}" ;;
        3) docker-compose restart clash-core; echo -e "${BLUE}Clash已重启${NC}" ;;
        4) docker-compose logs --tail=100 clash-core ;;
        5) 
            echo -e "${YELLOW}Clash配置编辑功能开发中...${NC}"
            echo -e "${BLUE}配置文件位置: /opt/vpn-proxy/protocol-configs/clash/config.yaml${NC}"
            ;;
        6) echo -e "${YELLOW}规则集更新功能开发中...${NC}" ;;
        7) echo -e "${YELLOW}节点测速功能开发中...${NC}" ;;
        8) show_clash_traffic ;;
        9) 
            echo -e "${GREEN}Clash Web面板地址: http://$SERVER_IP:9090${NC}"
            echo -e "${BLUE}请在浏览器中访问上述地址${NC}"
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    clash_management
}

# Hysteria管理
hysteria_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            ${WHITE}Hysteria 管理${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    # 检查Hysteria状态
    if command -v docker &> /dev/null && [[ -f docker-compose.yml ]]; then
        HYSTERIA_STATUS=$(docker-compose ps hysteria-core 2>/dev/null | grep -q "Up" && echo "运行中" || echo "已停止")
        echo -e "${BLUE}当前状态: ${GREEN}$HYSTERIA_STATUS${NC}"
        
        if [[ "$HYSTERIA_STATUS" == "运行中" ]]; then
            echo -e "${BLUE}UDP端口: ${GREEN}36712${NC}"
            echo -e "${BLUE}协议版本: ${GREEN}Hysteria v1/v2${NC}"
        fi
    else
        echo -e "${RED}Docker未安装或配置文件不存在${NC}"
    fi
    echo
    
    echo -e " ${YELLOW}1.${NC} 启动Hysteria服务"
    echo -e " ${YELLOW}2.${NC} 停止Hysteria服务"
    echo -e " ${YELLOW}3.${NC} 重启Hysteria服务"
    echo -e " ${YELLOW}4.${NC} 查看Hysteria日志"
    echo -e " ${YELLOW}5.${NC} 编辑Hysteria配置"
    echo -e " ${YELLOW}6.${NC} 生成客户端配置"
    echo -e " ${YELLOW}7.${NC} 用户管理"
    echo -e " ${YELLOW}8.${NC} 流量统计"
    echo -e " ${YELLOW}9.${NC} 端口检测"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) docker-compose start hysteria-core; echo -e "${GREEN}Hysteria已启动${NC}" ;;
        2) docker-compose stop hysteria-core; echo -e "${YELLOW}Hysteria已停止${NC}" ;;
        3) docker-compose restart hysteria-core; echo -e "${BLUE}Hysteria已重启${NC}" ;;
        4) docker-compose logs --tail=100 hysteria-core ;;
        5) 
            echo -e "${YELLOW}Hysteria配置编辑功能开发中...${NC}"
            echo -e "${BLUE}配置文件位置: /opt/vpn-proxy/protocol-configs/hysteria/config.yaml${NC}"
            ;;
        6) generate_hysteria_config ;;
        7) hysteria_user_management ;;
        8) show_hysteria_traffic ;;
        9) 
            echo -e "${GREEN}测试Hysteria端口连通性...${NC}"
            nc -u -z -v $SERVER_IP 36712 && echo -e "${GREEN}端口36712连通${NC}" || echo -e "${RED}端口36712不通${NC}"
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    hysteria_management
}

# 节点管理
node_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}节点管理${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 查看所有节点"
    echo -e " ${YELLOW}2.${NC} 添加新节点"
    echo -e " ${YELLOW}3.${NC} 删除节点"
    echo -e " ${YELLOW}4.${NC} 编辑节点信息"
    echo -e " ${YELLOW}5.${NC} 节点测速"
    echo -e " ${YELLOW}6.${NC} 节点负载均衡"
    echo -e " ${YELLOW}7.${NC} 导入节点配置"
    echo -e " ${YELLOW}8.${NC} 导出节点配置"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) list_all_nodes ;;
        2) add_new_node ;;
        3) remove_node ;;
        4) edit_node ;;
        5) test_nodes_speed ;;
        6) echo -e "${YELLOW}负载均衡功能开发中...${NC}" ;;
        7) import_node_config ;;
        8) export_node_config ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    node_management
}

# 用户管理
user_management() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}用户管理${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 查看所有用户"
    echo -e " ${YELLOW}2.${NC} 添加新用户"
    echo -e " ${YELLOW}3.${NC} 删除用户"
    echo -e " ${YELLOW}4.${NC} 修改用户信息"
    echo -e " ${YELLOW}5.${NC} 重置用户密码"
    echo -e " ${YELLOW}6.${NC} 用户流量统计"
    echo -e " ${YELLOW}7.${NC} 用户连接状态"
    echo -e " ${YELLOW}8.${NC} 批量用户管理"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择操作: ${NC}"
    
    read choice
    case $choice in
        1) list_all_users ;;
        2) add_new_user ;;
        3) remove_user ;;
        4) edit_user ;;
        5) reset_user_password ;;
        6) show_user_traffic ;;
        7) show_user_connections ;;
        8) batch_user_management ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    user_management
}

# 流量监控
traffic_monitoring() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}流量监控${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 实时流量监控"
    echo -e " ${YELLOW}2.${NC} 今日流量统计"
    echo -e " ${YELLOW}3.${NC} 本月流量统计"
    echo -e " ${YELLOW}4.${NC} 用户流量排行"
    echo -e " ${YELLOW}5.${NC} 协议流量分析"
    echo -e " ${YELLOW}6.${NC} 流量图表显示"
    echo -e " ${YELLOW}7.${NC} 导出流量报告"
    echo -e " ${YELLOW}8.${NC} 流量预警设置"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择功能: ${NC}"
    
    read choice
    case $choice in
        1) 
            echo -e "${GREEN}启动实时流量监控...${NC}"
            echo -e "${BLUE}使用 Ctrl+C 退出监控${NC}"
            watch -n 1 'cat /proc/net/dev'
            ;;
        2) show_daily_traffic ;;
        3) show_monthly_traffic ;;
        4) show_user_traffic_ranking ;;
        5) show_protocol_traffic ;;
        6) 
            echo -e "${GREEN}流量图表功能...${NC}"
            echo -e "${BLUE}Grafana面板: http://$SERVER_IP:3000${NC}"
            ;;
        7) export_traffic_report ;;
        8) set_traffic_alerts ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    traffic_monitoring
}

# 系统信息
system_information() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}系统信息${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${YELLOW}服务器信息:${NC}"
    echo -e "  公网IP: ${GREEN}$(curl -s ifconfig.me)${NC}"
    echo -e "  系统版本: ${GREEN}$(lsb_release -d | cut -f2)${NC}"
    echo -e "  内核版本: ${GREEN}$(uname -r)${NC}"
    echo -e "  运行时间: ${GREEN}$(uptime -p)${NC}"
    echo -e "  系统架构: ${GREEN}$(uname -m)${NC}"
    echo
    
    echo -e "${YELLOW}硬件资源:${NC}"
    echo -e "  CPU型号: ${GREEN}$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs)${NC}"
    echo -e "  CPU核心: ${GREEN}$(nproc) 核心${NC}"
    echo -e "  内存信息: ${GREEN}$(free -h | awk 'NR==2{printf "%s/%s (%.1f%%)", $3,$2,$3*100/$2}')${NC}"
    echo -e "  磁盘信息: ${GREEN}$(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3,$2,$5}')${NC}"
    echo -e "  系统负载: ${GREEN}$(uptime | awk -F'load average:' '{print $2}')${NC}"
    echo
    
    echo -e "${YELLOW}网络信息:${NC}"
    echo -e "  网络接口: ${GREEN}$(ip route | grep default | awk '{print $5}')${NC}"
    echo -e "  DNS服务器: ${GREEN}$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)${NC}"
    echo
    
    echo -e "${YELLOW}代理服务:${NC}"
    if command -v docker &> /dev/null && [[ -f docker-compose.yml ]]; then
        echo -e "  Docker版本: ${GREEN}$(docker --version | cut -d' ' -f3 | cut -d',' -f1)${NC}"
        echo -e "  服务状态:"
        docker-compose ps --format "table {{.Name}}\t{{.Status}}" | head -10
    else
        echo -e "  ${RED}Docker环境未安装${NC}"
    fi
    
    echo -ne "${WHITE}按回车键返回主菜单...${NC}"
    read
}

# 安装系统
install_system() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            ${WHITE}系统安装/重装${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} 全新安装完整版"
    echo -e " ${YELLOW}2.${NC} 重新安装系统"
    echo -e " ${YELLOW}3.${NC} 安装轻量版本"
    echo -e " ${YELLOW}4.${NC} 从GitHub安装"
    echo -e " ${YELLOW}5.${NC} 更新现有安装"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择安装方式: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${GREEN}正在执行完整版安装...${NC}"
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
                bash ./uninstall.sh --backup 2>/dev/null || true
                sleep 2
                bash ./deploy.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/deploy.sh)
            fi
            ;;
        3)
            echo -e "${BLUE}正在安装轻量版...${NC}"
            bash ./install-lite.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/install-lite.sh)
            ;;
        4)
            echo -e "${GREEN}正在从GitHub安装最新版...${NC}"
            bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/deploy.sh)
            ;;
        5)
            echo -e "${BLUE}正在更新现有安装...${NC}"
            git pull origin main 2>/dev/null || echo -e "${YELLOW}无法自动更新，请检查网络${NC}"
            docker-compose pull
            docker-compose up -d
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    install_system
}

# 卸载系统
uninstall_system() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}系统卸载${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${RED}警告: 这将完全删除VPS代理管理系统！${NC}"
    echo
    echo -e " ${YELLOW}1.${NC} 备份后完全卸载"
    echo -e " ${YELLOW}2.${NC} 直接卸载（不备份）"
    echo -e " ${YELLOW}3.${NC} 仅停止所有服务"
    echo -e " ${YELLOW}4.${NC} 清理Docker环境"
    echo -e " ${YELLOW}5.${NC} 重置为默认配置"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择卸载方式: ${NC}"
    
    read choice
    case $choice in
        1)
            echo -e "${GREEN}正在备份数据并卸载...${NC}"
            bash ./uninstall.sh --backup 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/uninstall.sh) --backup
            ;;
        2)
            echo -e "${RED}正在直接卸载...${NC}"
            read -p "$(echo -e "${RED}确认删除所有数据? [y/N]: ${NC}")" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                bash ./uninstall.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/zhakil/vpn/main/uninstall.sh)
            fi
            ;;
        3)
            echo -e "${YELLOW}正在停止所有服务...${NC}"
            docker-compose down
            echo -e "${GREEN}所有服务已停止${NC}"
            ;;
        4)
            echo -e "${YELLOW}正在清理Docker环境...${NC}"
            docker system prune -af
            docker volume prune -f
            echo -e "${GREEN}Docker环境已清理${NC}"
            ;;
        5)
            echo -e "${BLUE}正在重置配置...${NC}"
            docker-compose down
            rm -rf protocol-configs/*/
            echo -e "${GREEN}配置已重置${NC}"
            ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    uninstall_system
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
        if [[ -f /usr/local/bin/zhakil-manage ]]; then
            cp ./manage.sh /usr/local/bin/zhakil-manage
        fi
        echo -e "${GREEN}管理脚本更新完成${NC}"
    fi
    
    # 更新项目文件
    git pull origin main 2>/dev/null && echo -e "${GREEN}项目文件更新完成${NC}" || echo -e "${YELLOW}无法自动更新项目${NC}"
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
}

# 配置生成中心
config_generator() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}配置生成中心${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${GREEN}当前服务器IP: ${YELLOW}$SERVER_IP${NC}"
    echo -e "${BLUE}支持生成以下客户端配置:${NC}"
    echo
    
    echo -e " ${YELLOW}1.${NC} V2Ray配置生成 (VMESS/VLESS)"
    echo -e " ${YELLOW}2.${NC} Clash配置生成 (YAML)"
    echo -e " ${YELLOW}3.${NC} Hysteria配置生成 (YAML)"
    echo -e " ${YELLOW}4.${NC} 分享链接生成 (URI)"
    echo -e " ${YELLOW}5.${NC} 订阅链接生成 (Base64)"
    echo -e " ${YELLOW}6.${NC} 二维码生成"
    echo -e " ${YELLOW}7.${NC} 批量配置生成"
    echo -e " ${YELLOW}8.${NC} 配置文件导出"
    echo -e " ${RED}0.${NC} 返回主菜单"
    echo
    echo -ne "${WHITE}请选择配置类型: ${NC}"
    
    read choice
    case $choice in
        1) generate_v2ray_config ;;
        2) generate_clash_config ;;
        3) generate_hysteria_config ;;
        4) generate_share_links ;;
        5) generate_subscription ;;
        6) generate_qrcode ;;
        7) batch_config_generation ;;
        8) export_all_configs ;;
        0) return ;;
        *) echo -e "${RED}无效选择${NC}"; sleep 1 ;;
    esac
    
    echo -ne "${WHITE}按回车键继续...${NC}"
    read
    config_generator
}

# V2Ray配置生成
generate_v2ray_config() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            ${WHITE}V2Ray配置生成${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    # 读取配置信息
    if [[ -f /root/vpn-config.env ]]; then
        source /root/vpn-config.env
        UUID=${V2RAY_UUID}
        PORT=${V2RAY_PORT}
        ALTID="64"
        log_info "从配置文件加载V2Ray信息"
    else
        # 尝试从系统配置读取
        UUID=$(grep -o '"id": "[^"]*"' /usr/local/etc/v2ray/config.json 2>/dev/null | head -1 | cut -d'"' -f4)
        PORT=$(grep -o '"port": [0-9]*' /usr/local/etc/v2ray/config.json 2>/dev/null | head -1 | cut -d' ' -f2)
        ALTID="64"
        
        # 如果还是没有，则生成新的
        if [[ -z "$UUID" ]]; then
            UUID=$(cat /proc/sys/kernel/random/uuid)
            log_warning "未找到现有配置，生成新UUID"
        fi
        PORT=${PORT:-10001}
    fi
    
    echo -e "${GREEN}V2Ray VMESS配置信息:${NC}"
    echo -e "服务器地址: ${YELLOW}$SERVER_IP${NC}"
    echo -e "端口: ${YELLOW}$PORT${NC}"
    echo -e "UUID: ${YELLOW}$UUID${NC}"
    echo -e "额外ID: ${YELLOW}$ALTID${NC}"
    echo -e "传输协议: ${YELLOW}ws (WebSocket)${NC}"
    echo -e "路径: ${YELLOW}/ray${NC}"
    echo
    
    # 生成V2Ray客户端配置
    echo -e "${BLUE}V2Ray客户端配置文件:${NC}"
    cat > /tmp/v2ray-client.json << EOF
{
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    },
    {
      "port": 8080,
      "listen": "127.0.0.1", 
      "protocol": "http"
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_IP",
            "port": $PORT,
            "users": [
              {
                "id": "$UUID",
                "alterId": $ALTID,
                "security": "auto"
              }
            ]
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
  ]
}
EOF
    
    echo -e "${GREEN}配置文件已生成: ${YELLOW}/tmp/v2ray-client.json${NC}"
    echo
    
    # 生成VMESS链接
    VMESS_LINK="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"zhakil-VPN\",\"add\":\"$SERVER_IP\",\"port\":\"$PORT\",\"id\":\"$UUID\",\"aid\":\"$ALTID\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ray\",\"tls\":\"\"}" | base64 -w 0)"
    
    echo -e "${BLUE}VMESS分享链接:${NC}"
    echo -e "${GREEN}$VMESS_LINK${NC}"
    echo
    
    echo -e "${YELLOW}使用方法:${NC}"
    echo "1. 复制上面的VMESS链接"
    echo "2. 在V2Ray客户端中导入链接"
    echo "3. 或者使用配置文件 /tmp/v2ray-client.json"
}

# Clash配置生成
generate_clash_config() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            ${WHITE}Clash配置生成${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    # 读取配置信息
    if [[ -f /root/vpn-config.env ]]; then
        source /root/vpn-config.env
        UUID=${V2RAY_UUID}
        V2RAY_PORT=${V2RAY_PORT}
        HYSTERIA_PORT=${HYSTERIA_PORT}
        HYSTERIA_PASSWORD=${HYSTERIA_PASSWORD}
        log_info "从配置文件加载服务器信息"
    else
        # 尝试从系统配置读取
        UUID=$(grep -o '"id": "[^"]*"' /usr/local/etc/v2ray/config.json 2>/dev/null | head -1 | cut -d'"' -f4)
        V2RAY_PORT=$(grep -o '"port": [0-9]*' /usr/local/etc/v2ray/config.json 2>/dev/null | head -1 | cut -d' ' -f2)
        HYSTERIA_PORT=$(grep -o 'listen: :[0-9]*' /etc/hysteria/config.yaml 2>/dev/null | cut -d':' -f3)
        HYSTERIA_PASSWORD=$(grep -o 'password: .*' /etc/hysteria/config.yaml 2>/dev/null | cut -d' ' -f2)
        
        # 默认值
        UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
        V2RAY_PORT=${V2RAY_PORT:-10001}
        HYSTERIA_PORT=${HYSTERIA_PORT:-36712}
        HYSTERIA_PASSWORD=${HYSTERIA_PASSWORD:-zhakil123}
    fi
    
    echo -e "${GREEN}生成Clash配置文件...${NC}"
    
    cat > /tmp/clash-client.yaml << EOF
# Clash配置文件 - zhakil科技箱
port: 7890
socks-port: 7891
allow-lan: true
mode: rule
log-level: info
external-controller: 127.0.0.1:9090

dns:
  enable: true
  listen: 0.0.0.0:53
  default-nameserver:
    - 223.5.5.5
    - 8.8.8.8
  nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query

proxies:
  - name: "zhakil-V2Ray"
    type: vmess
    server: $SERVER_IP
    port: $V2RAY_PORT
    uuid: $UUID
    alterId: 64
    cipher: auto
    network: ws
    ws-opts:
      path: /ray
      headers:
        Host: $SERVER_IP

  - name: "zhakil-Hysteria"
    type: hysteria
    server: $SERVER_IP
    port: $HYSTERIA_PORT
    auth_str: zhakil123
    alpn:
      - h3
    protocol: udp
    up: 20
    down: 100

proxy-groups:
  - name: "🚀 节点选择"
    type: select
    proxies:
      - "♻️ 自动选择"
      - "🔯 故障转移"
      - "🔮 负载均衡"
      - "zhakil-V2Ray"
      - "zhakil-Hysteria"

  - name: "♻️ 自动选择"
    type: url-test
    proxies:
      - "zhakil-V2Ray"
      - "zhakil-Hysteria"
    url: 'http://www.gstatic.com/generate_204'
    interval: 300

  - name: "🔯 故障转移"
    type: fallback
    proxies:
      - "zhakil-V2Ray"
      - "zhakil-Hysteria"
    url: 'http://www.gstatic.com/generate_204'
    interval: 300

  - name: "🔮 负载均衡"
    type: load-balance
    proxies:
      - "zhakil-V2Ray"  
      - "zhakil-Hysteria"
    url: 'http://www.gstatic.com/generate_204'
    interval: 300

rules:
  - DOMAIN-SUFFIX,google.com,🚀 节点选择
  - DOMAIN-SUFFIX,youtube.com,🚀 节点选择
  - DOMAIN-SUFFIX,facebook.com,🚀 节点选择
  - DOMAIN-SUFFIX,twitter.com,🚀 节点选择
  - DOMAIN-SUFFIX,instagram.com,🚀 节点选择
  - DOMAIN-SUFFIX,telegram.org,🚀 节点选择
  - DOMAIN-KEYWORD,google,🚀 节点选择
  - GEOIP,CN,DIRECT
  - MATCH,🚀 节点选择
EOF

    echo -e "${GREEN}配置文件已生成: ${YELLOW}/tmp/clash-client.yaml${NC}"
    echo
    echo -e "${YELLOW}使用方法:${NC}"
    echo "1. 下载配置文件: /tmp/clash-client.yaml"
    echo "2. 导入到Clash客户端"
    echo "3. 或者复制配置内容到Clash配置中"
}

# Hysteria配置生成  
generate_hysteria_config() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          ${WHITE}Hysteria配置生成${CYAN}             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    # 读取配置信息
    if [[ -f /root/vpn-config.env ]]; then
        source /root/vpn-config.env
        HYSTERIA_PORT=${HYSTERIA_PORT}
        HYSTERIA_PASSWORD=${HYSTERIA_PASSWORD}
        HYSTERIA_OBFS_PASSWORD=${HYSTERIA_OBFS_PASSWORD}
        UP_MBPS=${HYSTERIA_UP_MBPS:-20}
        DOWN_MBPS=${HYSTERIA_DOWN_MBPS:-100}
        log_info "从配置文件加载Hysteria信息"
    else
        # 尝试从系统配置读取
        HYSTERIA_PORT=$(grep -o 'listen: :[0-9]*' /etc/hysteria/config.yaml 2>/dev/null | cut -d':' -f3)
        HYSTERIA_PASSWORD=$(grep -A1 'auth:' /etc/hysteria/config.yaml 2>/dev/null | grep 'password:' | cut -d' ' -f4)
        HYSTERIA_OBFS_PASSWORD=$(grep -A2 'salamander:' /etc/hysteria/config.yaml 2>/dev/null | grep 'password:' | cut -d'"' -f2)
        
        # 默认值
        HYSTERIA_PORT=${HYSTERIA_PORT:-36712}
        HYSTERIA_PASSWORD=${HYSTERIA_PASSWORD:-zhakil123}
        UP_MBPS="20"
        DOWN_MBPS="100"
        log_warning "未找到配置文件，使用默认值"
    fi
    
    echo -e "${GREEN}Hysteria客户端配置:${NC}"
    
    cat > /tmp/hysteria-client.yaml << EOF
# Hysteria客户端配置 - zhakil科技箱
# 服务器连接配置
server: $SERVER_IP:$HYSTERIA_PORT
auth_str: $HYSTERIA_PASSWORD

# 带宽配置
up_mbps: $UP_MBPS
down_mbps: $DOWN_MBPS

# 本地代理端口
socks5:
  listen: 127.0.0.1:1080

http:
  listen: 127.0.0.1:8080

# TLS设置
tls:
  sni: $SERVER_IP
  insecure: true  # 使用自签名证书时设为true
  
# QUIC传输优化
quic:
  initial_stream_receive_window: 8388608      # 8MB
  max_stream_receive_window: 8388608          # 8MB
  initial_connection_receive_window: 20971520 # 20MB
  max_connection_receive_window: 20971520     # 20MB
  max_idle_timeout: 60s                       # 空闲超时
  max_incoming_streams: 1024                  # 最大流数
  disable_path_mtu_discovery: false           # 启用MTU发现

# 混淆设置（增强安全性）
$(if [[ -n "$HYSTERIA_OBFS_PASSWORD" ]]; then
echo "obfs: salamander"
echo "obfs_password: $HYSTERIA_OBFS_PASSWORD"
else
echo "# obfs: salamander"
echo "# obfs_password: 混淆密码未设置"
fi)

# 连接重试设置
retry: 5
retry_interval: 3s

# 路由规则（可选）
acl:
  - reject(geoip:cn && port:25)     # 阻止中国IP访问25端口
  - reject(all && port:22)          # 阻止SSH连接
  - allow(all)                      # 允许其他连接
EOF

    echo -e "${GREEN}配置文件已生成: ${YELLOW}/tmp/hysteria-client.yaml${NC}"
    echo
    echo -e "${BLUE}Hysteria分享链接:${NC}"
    HYSTERIA_LINK="hysteria://$SERVER_IP:$HYSTERIA_PORT?auth=$HYSTERIA_PASSWORD&upmbps=20&downmbps=100&obfs=salamander&obfspassword=zhakil_obfs_2024#zhakil-Hysteria"
    echo -e "${GREEN}$HYSTERIA_LINK${NC}"
    echo
    echo -e "${YELLOW}使用方法:${NC}"
    echo "1. 下载配置文件或复制分享链接"
    echo "2. 导入到Hysteria客户端"
    echo "3. 支持Windows/macOS/Linux/Android/iOS"
}

# 生成分享链接
generate_share_links() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}分享链接生成${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
    V2RAY_PORT=${V2RAY_PORT:-10001}
    HYSTERIA_PORT=${HYSTERIA_PORT:-36712}
    
    echo -e "${YELLOW}━━━━━━━━ V2Ray VMESS 链接 ━━━━━━━━${NC}"
    VMESS_LINK="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"zhakil-V2Ray\",\"add\":\"$SERVER_IP\",\"port\":\"$V2RAY_PORT\",\"id\":\"$UUID\",\"aid\":\"64\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ray\",\"tls\":\"\"}" | base64 -w 0)"
    echo -e "${GREEN}$VMESS_LINK${NC}"
    echo
    
    echo -e "${YELLOW}━━━━━━━━ Hysteria 链接 ━━━━━━━━${NC}" 
    HYSTERIA_LINK="hysteria://$SERVER_IP:$HYSTERIA_PORT?auth=zhakil123&upmbps=20&downmbps=100&obfs=salamander&obfspassword=zhakil_obfs_2024#zhakil-Hysteria"
    echo -e "${GREEN}$HYSTERIA_LINK${NC}"
    echo
    
    echo -e "${YELLOW}━━━━━━━━ 通用订阅链接 ━━━━━━━━${NC}"
    SUBSCRIPTION_CONTENT="$VMESS_LINK"$'\n'"$HYSTERIA_LINK"
    SUBSCRIPTION_LINK="http://$SERVER_IP:8080/subscription/$(echo -n "$SUBSCRIPTION_CONTENT" | base64 -w 0 | head -c 8)"
    echo -e "${GREEN}$SUBSCRIPTION_LINK${NC}"
    echo
    
    echo -e "${BLUE}使用说明:${NC}"
    echo "• VMESS链接适用于: V2RayN, V2RayNG, Clash"
    echo "• Hysteria链接适用于: Hysteria客户端"
    echo "• 订阅链接适用于: 支持订阅的所有客户端"
    echo
    
    # 保存到文件
    cat > /tmp/share-links.txt << EOF
zhakil科技箱 VPN分享链接
====================

V2Ray VMESS:
$VMESS_LINK

Hysteria:
$HYSTERIA_LINK

订阅链接:
$SUBSCRIPTION_LINK

服务器信息:
- IP地址: $SERVER_IP
- V2Ray端口: $V2RAY_PORT  
- Hysteria端口: $HYSTERIA_PORT
- 生成时间: $(date)
EOF
    
    echo -e "${GREEN}分享链接已保存到: ${YELLOW}/tmp/share-links.txt${NC}"
}

# 生成订阅链接
generate_subscription() {
    clear  
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}订阅链接生成${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${GREEN}正在生成通用订阅链接...${NC}"
    
    # 生成各种协议的链接
    UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
    VMESS_LINK="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"zhakil-V2Ray\",\"add\":\"$SERVER_IP\",\"port\":\"10001\",\"id\":\"$UUID\",\"aid\":\"64\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ray\",\"tls\":\"\"}" | base64 -w 0)"
    HYSTERIA_LINK="hysteria://$SERVER_IP:36712?auth=zhakil123&upmbps=20&downmbps=100#zhakil-Hysteria"
    
    # 创建订阅内容
    SUBSCRIPTION_CONTENT="$VMESS_LINK"$'\n'"$HYSTERIA_LINK"
    
    # Base64编码
    ENCODED_SUBSCRIPTION=$(echo -n "$SUBSCRIPTION_CONTENT" | base64 -w 0)
    
    # 创建订阅服务目录
    mkdir -p /tmp/subscription
    echo -n "$ENCODED_SUBSCRIPTION" > /tmp/subscription/nodes
    
    # 生成订阅链接
    SUBSCRIPTION_URL="http://$SERVER_IP:8080/subscription/nodes"
    
    echo -e "${YELLOW}━━━━━━━━ 订阅信息 ━━━━━━━━${NC}"
    echo -e "订阅链接: ${GREEN}$SUBSCRIPTION_URL${NC}"
    echo -e "更新间隔: ${YELLOW}24小时${NC}"
    echo -e "节点数量: ${YELLOW}2个${NC}"
    echo -e "支持协议: ${YELLOW}VMESS, Hysteria${NC}"
    echo
    
    echo -e "${BLUE}客户端使用方法:${NC}"
    echo "1. 复制上面的订阅链接"
    echo "2. 在客户端中添加订阅"
    echo "3. 更新订阅获取节点"
    echo
    
    echo -e "${YELLOW}兼容客户端:${NC}"
    echo "• Clash for Windows/Android"
    echo "• V2RayN/V2RayNG"  
    echo "• Shadowrocket"
    echo "• Quantumult X"
    echo "• Surge"
    
    # 保存订阅文件
    cat > /tmp/subscription-info.txt << EOF
zhakil科技箱 VPN订阅信息
=====================

订阅链接: $SUBSCRIPTION_URL
Base64内容: $ENCODED_SUBSCRIPTION

包含节点:
1. zhakil-V2Ray (VMESS WebSocket)
2. zhakil-Hysteria (UDP)

生成时间: $(date)
有效期: 永久
更新频率: 24小时
EOF
    
    echo -e "${GREEN}订阅信息已保存到: ${YELLOW}/tmp/subscription-info.txt${NC}"
}

# 生成二维码
generate_qrcode() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${WHITE}二维码生成${CYAN}                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    # 检查是否安装了qrencode
    if ! command -v qrencode &> /dev/null; then
        echo -e "${YELLOW}正在安装二维码生成工具...${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install -y qrencode
        elif command -v yum &> /dev/null; then
            yum install -y qrencode
        else
            echo -e "${RED}无法自动安装qrencode，请手动安装${NC}"
            return
        fi
    fi
    
    UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
    VMESS_LINK="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"zhakil-V2Ray\",\"add\":\"$SERVER_IP\",\"port\":\"10001\",\"id\":\"$UUID\",\"aid\":\"64\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/ray\",\"tls\":\"\"}" | base64 -w 0)"
    
    echo -e "${GREEN}生成V2Ray配置二维码:${NC}"
    echo
    qrencode -t ansiutf8 "$VMESS_LINK"
    echo
    
    echo -e "${BLUE}扫码说明:${NC}"
    echo "1. 使用手机V2Ray客户端扫描上方二维码"
    echo "2. 自动导入服务器配置"
    echo "3. 连接即可使用"
    
    # 保存二维码到文件
    qrencode -t PNG -o /tmp/v2ray-qrcode.png "$VMESS_LINK"
    echo -e "${GREEN}二维码图片已保存到: ${YELLOW}/tmp/v2ray-qrcode.png${NC}"
}

# 批量配置生成
batch_config_generation() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            ${WHITE}批量配置生成${CYAN}               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${GREEN}正在生成所有配置文件...${NC}"
    
    # 创建配置目录
    CONFIG_DIR="/tmp/vpn-configs-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$CONFIG_DIR"
    
    # 生成所有配置
    echo -e "${BLUE}[1/5]${NC} 生成V2Ray配置..."
    generate_v2ray_config > /dev/null
    cp /tmp/v2ray-client.json "$CONFIG_DIR/"
    
    echo -e "${BLUE}[2/5]${NC} 生成Clash配置..."
    generate_clash_config > /dev/null
    cp /tmp/clash-client.yaml "$CONFIG_DIR/"
    
    echo -e "${BLUE}[3/5]${NC} 生成Hysteria配置..."
    generate_hysteria_config > /dev/null
    cp /tmp/hysteria-client.yaml "$CONFIG_DIR/"
    
    echo -e "${BLUE}[4/5]${NC} 生成分享链接..."
    generate_share_links > /dev/null
    cp /tmp/share-links.txt "$CONFIG_DIR/"
    
    echo -e "${BLUE}[5/5]${NC} 生成订阅信息..."
    generate_subscription > /dev/null
    cp /tmp/subscription-info.txt "$CONFIG_DIR/"
    
    # 生成README
    cat > "$CONFIG_DIR/README.md" << EOF
# zhakil科技箱 VPN配置包

## 配置文件说明

### V2Ray配置
- **文件**: v2ray-client.json
- **适用**: V2RayN, V2RayNG, V2Ray核心
- **协议**: VMESS over WebSocket

### Clash配置  
- **文件**: clash-client.yaml
- **适用**: Clash for Windows, ClashX, Clash for Android
- **功能**: 自动选择、故障转移、负载均衡

### Hysteria配置
- **文件**: hysteria-client.yaml  
- **适用**: Hysteria客户端
- **协议**: UDP over QUIC

### 分享链接
- **文件**: share-links.txt
- **内容**: VMESS链接、Hysteria链接、订阅链接
- **用途**: 直接导入客户端

### 订阅信息
- **文件**: subscription-info.txt
- **用途**: 客户端订阅更新

## 服务器信息
- **IP地址**: $SERVER_IP
- **生成时间**: $(date)
- **技术支持**: zhakil科技箱 v4.0.0

## 使用建议
1. 根据设备选择对应配置文件
2. 优先使用Clash配置（功能最完整）
3. 移动设备推荐使用分享链接导入
4. 定期更新订阅获取最新配置
EOF
    
    echo -e "${GREEN}批量配置生成完成！${NC}"
    echo -e "${YELLOW}配置目录: ${GREEN}$CONFIG_DIR${NC}"
    echo
    echo -e "${BLUE}包含文件:${NC}"
    ls -la "$CONFIG_DIR"
    
    # 创建打包文件
    cd /tmp
    tar -czf "vpn-configs-$(date +%Y%m%d-%H%M%S).tar.gz" "$(basename "$CONFIG_DIR")"
    echo -e "${GREEN}配置包已打包: ${YELLOW}/tmp/vpn-configs-*.tar.gz${NC}"
}

# 导出所有配置
export_all_configs() {
    echo -e "${GREEN}正在导出所有配置...${NC}"
    batch_config_generation
}

# 一些辅助函数的简单实现
add_v2ray_user() { echo -e "${YELLOW}V2Ray用户添加功能开发中...${NC}"; }
remove_v2ray_user() { echo -e "${YELLOW}V2Ray用户删除功能开发中...${NC}"; }
show_v2ray_traffic() { echo -e "${YELLOW}V2Ray流量统计功能开发中...${NC}"; }
show_clash_traffic() { echo -e "${YELLOW}Clash流量统计功能开发中...${NC}"; }
hysteria_user_management() { echo -e "${YELLOW}Hysteria用户管理功能开发中...${NC}"; }
show_hysteria_traffic() { echo -e "${YELLOW}Hysteria流量统计功能开发中...${NC}"; }
list_all_nodes() { echo -e "${YELLOW}节点列表功能开发中...${NC}"; }
add_new_node() { echo -e "${YELLOW}添加节点功能开发中...${NC}"; }
remove_node() { echo -e "${YELLOW}删除节点功能开发中...${NC}"; }
edit_node() { echo -e "${YELLOW}编辑节点功能开发中...${NC}"; }
test_nodes_speed() { echo -e "${YELLOW}节点测速功能开发中...${NC}"; }
import_node_config() { echo -e "${YELLOW}导入配置功能开发中...${NC}"; }
export_node_config() { echo -e "${YELLOW}导出配置功能开发中...${NC}"; }
list_all_users() { echo -e "${YELLOW}用户列表功能开发中...${NC}"; }
add_new_user() { echo -e "${YELLOW}添加用户功能开发中...${NC}"; }
remove_user() { echo -e "${YELLOW}删除用户功能开发中...${NC}"; }
edit_user() { echo -e "${YELLOW}编辑用户功能开发中...${NC}"; }
reset_user_password() { echo -e "${YELLOW}重置密码功能开发中...${NC}"; }
show_user_traffic() { echo -e "${YELLOW}用户流量功能开发中...${NC}"; }
show_user_connections() { echo -e "${YELLOW}用户连接功能开发中...${NC}"; }
batch_user_management() { echo -e "${YELLOW}批量管理功能开发中...${NC}"; }
show_daily_traffic() { echo -e "${YELLOW}日流量统计功能开发中...${NC}"; }
show_monthly_traffic() { echo -e "${YELLOW}月流量统计功能开发中...${NC}"; }
show_user_traffic_ranking() { echo -e "${YELLOW}流量排行功能开发中...${NC}"; }
show_protocol_traffic() { echo -e "${YELLOW}协议流量功能开发中...${NC}"; }
export_traffic_report() { echo -e "${YELLOW}流量报告功能开发中...${NC}"; }
set_traffic_alerts() { echo -e "${YELLOW}流量预警功能开发中...${NC}"; }

# 主循环
main() {
    while true; do
        show_main_menu
        read choice
        
        case $choice in
            1) v2ray_management ;;
            2) clash_management ;;
            3) hysteria_management ;;
            4) echo -e "${YELLOW}Nginx管理功能开发中...${NC}"; sleep 2 ;;
            5) node_management ;;
            6) user_management ;;
            7) config_generator ;;
            8) echo -e "${YELLOW}订阅管理功能开发中...${NC}"; sleep 2 ;;
            9) traffic_monitoring ;;
            10) echo -e "${YELLOW}连接状态功能开发中...${NC}"; sleep 2 ;;
            11) echo -e "${YELLOW}日志查看功能开发中...${NC}"; sleep 2 ;;
            12) echo -e "${YELLOW}性能优化功能开发中...${NC}"; sleep 2 ;;
            13) system_information ;;
            14) echo -e "${YELLOW}安全设置功能开发中...${NC}"; sleep 2 ;;
            15) echo -e "${YELLOW}备份恢复功能开发中...${NC}"; sleep 2 ;;
            16) echo -e "${YELLOW}证书管理功能开发中...${NC}"; sleep 2 ;;
            i|I) install_system ;;
            u|U) uninstall_system ;;
            00) update_script ;;
            0) 
                echo -e "${GREEN}感谢使用 zhakil科技箱 VPS代理管理系统！${NC}"
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
echo -e "${GREEN}正在启动 zhakil科技箱 VPS代理管理系统...${NC}"
check_environment
main