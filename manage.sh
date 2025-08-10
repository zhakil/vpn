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

# 一些辅助函数的简单实现
generate_v2ray_links() { echo -e "${YELLOW}V2Ray链接生成功能开发中...${NC}"; }
add_v2ray_user() { echo -e "${YELLOW}V2Ray用户添加功能开发中...${NC}"; }
remove_v2ray_user() { echo -e "${YELLOW}V2Ray用户删除功能开发中...${NC}"; }
show_v2ray_traffic() { echo -e "${YELLOW}V2Ray流量统计功能开发中...${NC}"; }
show_clash_traffic() { echo -e "${YELLOW}Clash流量统计功能开发中...${NC}"; }
generate_hysteria_config() { echo -e "${YELLOW}Hysteria配置生成功能开发中...${NC}"; }
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
            7) echo -e "${YELLOW}配置生成功能开发中...${NC}"; sleep 2 ;;
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