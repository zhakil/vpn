#!/bin/bash

# zhakil科技箱 VPN代理一键部署脚本
# 支持V2Ray、Clash、Hysteria多协议部署
# 包含BBR加速、防火墙配置、SSL证书等

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

# 全局变量
SERVER_IP=""
DOMAIN=""
UUID=""
V2RAY_PORT="10001"
CLASH_PORT="7890"
HYSTERIA_PORT="36712"
WEB_PORT="8080"

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

# 显示欢迎界面
show_welcome() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                zhakil科技箱 v4.0.0                  ║"
    echo "║            VPN代理服务一键部署脚本                  ║"
    echo "║        支持V2Ray + Clash + Hysteria + BBR           ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

# 检查系统环境
check_system() {
    # 检查root权限
    if [[ $EUID -ne 0 ]]; then
        log_error "需要root权限运行此脚本"
        log_info "请使用: sudo bash deploy.sh"
        exit 1
    fi
    
    # 检测操作系统
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
        PM="yum"
    elif [[ -f /etc/debian_version ]]; then
        OS="ubuntu"
        PM="apt"
    else
        log_error "不支持的操作系统，仅支持Ubuntu/Debian/CentOS"
        exit 1
    fi
    
    log_success "检测到系统: $OS"
    
    # 获取服务器IP
    SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || curl -s4 ip.sb 2>/dev/null || echo "")
    if [[ -z "$SERVER_IP" ]]; then
        log_error "无法获取服务器IP地址"
        exit 1
    fi
    
    log_success "服务器IP: $SERVER_IP"
}

# 更新系统并安装基础工具
install_base_tools() {
    log_info "更新系统并安装基础工具..."
    
    if [[ $OS == "ubuntu" ]]; then
        apt update
        apt install -y curl wget unzip tar socat git qrencode python3 python3-pip lsof net-tools
    else
        yum update -y
        yum install -y curl wget unzip tar socat git qrencode python3 python3-pip lsof net-tools
    fi
    
    log_success "基础工具安装完成"
}

# 安装和启用BBR加速
install_bbr() {
    log_info "安装BBR TCP加速..."
    
    # 检查内核版本
    KERNEL_VERSION=$(uname -r | cut -d. -f1,2)
    if awk 'BEGIN{exit !('"$KERNEL_VERSION"' >= 4.9)}'; then
        # 启用BBR
        if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        fi
        
        if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        fi
        
        # 添加其他网络优化参数
        cat >> /etc/sysctl.conf << EOF

# 网络优化配置
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
fs.file-max = 51200
EOF
        
        sysctl -p
        
        # 验证BBR是否启用
        if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
            log_success "BBR加速已启用"
        else
            log_warning "BBR启用可能失败，请重启系统后检查"
        fi
    else
        log_warning "内核版本过低，无法启用BBR (需要4.9+)"
    fi
}

# 配置防火墙
setup_firewall() {
    log_info "配置防火墙规则..."
    
    # 开放必要端口
    PORTS=(22 80 443 $V2RAY_PORT $CLASH_PORT $HYSTERIA_PORT $WEB_PORT)
    
    if command -v ufw &> /dev/null; then
        ufw --force enable
        for port in "${PORTS[@]}"; do
            ufw allow $port
        done
        log_success "UFW防火墙配置完成"
    elif command -v firewall-cmd &> /dev/null; then
        systemctl enable firewalld
        systemctl start firewalld
        for port in "${PORTS[@]}"; do
            firewall-cmd --permanent --add-port=${port}/tcp
        done
        firewall-cmd --permanent --add-port=${HYSTERIA_PORT}/udp
        firewall-cmd --reload
        log_success "Firewalld防火墙配置完成"
    else
        log_warning "未检测到防火墙，请手动配置端口"
    fi
}

# 安装V2Ray
install_v2ray() {
    log_info "开始安装V2Ray核心服务..."
    
    # 生成UUID
    UUID=$(cat /proc/sys/kernel/random/uuid)
    log_info "生成V2Ray UUID: $UUID"
    
    # 检查并清理旧安装
    if systemctl is-active --quiet v2ray 2>/dev/null; then
        log_info "检测到V2Ray服务，正在停止..."
        systemctl stop v2ray
    fi
    
    # 下载V2Ray安装脚本
    log_info "下载V2Ray官方安装脚本..."
    if ! bash <(curl -L -s https://install.direct/go.sh); then
        log_error "V2Ray安装脚本下载失败，尝试备用方案..."
        # 备用安装方法
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) V2RAY_ARCH="64" ;;
            aarch64) V2RAY_ARCH="arm64-v8a" ;;
            armv7l) V2RAY_ARCH="arm32-v7a" ;;
            *) log_error "不支持的系统架构: $ARCH"; return 1 ;;
        esac
        
        V2RAY_VERSION=$(curl -s "https://api.github.com/repos/v2fly/v2ray-core/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-${V2RAY_ARCH}.zip"
        
        cd /tmp
        wget -O v2ray.zip "$V2RAY_URL"
        unzip -o v2ray.zip -d v2ray-tmp/
        
        # 手动安装V2Ray
        mkdir -p /usr/local/bin/v2ray /usr/local/etc/v2ray /var/log/v2ray /usr/local/share/v2ray
        cp v2ray-tmp/v2ray /usr/local/bin/v2ray/
        cp v2ray-tmp/v2ctl /usr/local/bin/v2ray/
        cp v2ray-tmp/geoip.dat v2ray-tmp/geosite.dat /usr/local/share/v2ray/
        chmod +x /usr/local/bin/v2ray/v2ray /usr/local/bin/v2ray/v2ctl
        
        # 创建systemd服务
        cat > /etc/systemd/system/v2ray.service << 'EOFSVC'
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray/v2ray -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOFSVC
        systemctl daemon-reload
        rm -rf v2ray-tmp/ v2ray.zip
    fi
    
    # 确保目录存在
    mkdir -p /usr/local/etc/v2ray /var/log/v2ray
    chown nobody:nogroup /var/log/v2ray 2>/dev/null || true
    
    log_success "V2Ray核心安装完成"
    
    # 生成详细的V2Ray服务器配置
    log_info "生成V2Ray服务器配置文件..."
    cat > /usr/local/etc/v2ray/config.json << EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "api": {
    "tag": "api",
    "services": [
      "StatsService"
    ]
  },
  "stats": {},
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5,
        "statsUserUplink": true,
        "statsUserDownlink": true
      }
    },
    "system": {
      "statsInboundUplink": true,
      "statsInboundDownlink": true
    }
  },
  "inbounds": [
    {
      "port": $V2RAY_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "level": 0,
            "alterId": 64,
            "security": "auto"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": false,
          "path": "/ray",
          "headers": {
            "Host": "$SERVER_IP"
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "listen": "127.0.0.1",
      "port": 10085,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": ["api"],
        "outboundTag": "api"
      },
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF
    
    log_success "V2Ray配置文件生成完成"
    log_info "配置文件位置: /usr/local/etc/v2ray/config.json"
    log_info "监听端口: $V2RAY_PORT"
    log_info "WebSocket路径: /ray"
    
    # 启动V2Ray服务
    log_info "启动V2Ray服务..."
    systemctl enable v2ray
    systemctl start v2ray
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet v2ray; then
        log_success "V2Ray服务启动成功"
        log_info "服务状态: $(systemctl is-active v2ray)"
        
        # 检查端口监听
        if netstat -tlnp | grep -q ":$V2RAY_PORT "; then
            log_success "V2Ray端口 $V2RAY_PORT 监听正常"
        else
            log_warning "V2Ray端口监听检测失败，请检查防火墙设置"
        fi
        
        # 保存配置信息到全局变量
        echo "export V2RAY_UUID=\"$UUID\"" >> /root/.bashrc
        echo "export V2RAY_PORT=\"$V2RAY_PORT\"" >> /root/.bashrc
        
    else
        log_error "V2Ray服务启动失败"
        log_info "查看错误日志: journalctl -u v2ray -f"
        return 1
    fi
}

# 安装Clash
install_clash() {
    log_info "开始安装Clash代理核心..."
    
    # 检查并清理旧安装
    if systemctl is-active --quiet clash 2>/dev/null; then
        log_info "检测到Clash服务，正在停止..."
        systemctl stop clash 2>/dev/null || true
    fi
    
    # 检测系统架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            CLASH_ARCH="amd64"
            ;;
        aarch64)
            CLASH_ARCH="arm64"
            ;;
        armv7l)
            CLASH_ARCH="armv7"
            ;;
        *)
            log_error "不支持的系统架构: $ARCH"
            return 1
            ;;
    esac
    
    log_info "检测到系统架构: $ARCH -> clash-$CLASH_ARCH"
    
    # 下载Clash核心
    log_info "下载Clash核心程序..."
    CLASH_VERSION="v1.18.0"
    CLASH_URL="https://github.com/Dreamacro/clash/releases/download/${CLASH_VERSION}/clash-linux-${CLASH_ARCH}-${CLASH_VERSION}.gz"
    
    cd /tmp
    if ! wget -O clash.gz "$CLASH_URL"; then
        log_error "Clash下载失败，尝试备用地址..."
        # 备用下载地址
        CLASH_URL="https://github.com/MetaCubeX/mihomo/releases/latest/download/mihomo-linux-${CLASH_ARCH}.gz"
        if ! wget -O clash.gz "$CLASH_URL"; then
            log_error "所有下载地址都失败"
            return 1
        fi
    fi
    
    gunzip clash.gz
    chmod +x clash
    mv clash /usr/local/bin/clash
    
    log_success "Clash核心程序安装完成"
    log_info "程序位置: /usr/local/bin/clash"
    
    # 创建配置目录和必要文件
    log_info "创建Clash配置目录和文件..."
    mkdir -p /etc/clash /var/log/clash
    
    # 生成Clash密钥
    CLASH_SECRET="zhakil$(date +%s | tail -c 6)"
    log_info "生成Clash管理密钥: $CLASH_SECRET"
    
    # 下载GeoIP和GeoSite数据库
    log_info "下载GeoIP和GeoSite规则数据库..."
    wget -O /etc/clash/Country.mmdb "https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb" 2>/dev/null || \
    curl -L -o /etc/clash/Country.mmdb "https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb" || \
    log_warning "GeoIP数据库下载失败，将使用默认配置"
    
    # 生成详细的Clash服务器配置
    log_info "生成Clash服务器配置文件..."
    
    # 生成详细的Clash服务器配置文件
    cat > /etc/clash/config.yaml << EOF
# Clash配置文件 - zhakil科技箱 VPN服务器端
port: $CLASH_PORT
socks-port: $((CLASH_PORT + 1))
mixed-port: $((CLASH_PORT + 2))
allow-lan: true
bind-address: '*'
mode: rule
log-level: info
external-controller: 0.0.0.0:9090
external-ui: dashboard
secret: "$CLASH_SECRET"

# 实验性功能
experimental:
  ignore-resolve-fail: true
  sniff-tls-sni: true

# 主机映射
hosts:
  'mtalk.google.com': 108.177.125.188

# DNS配置
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:1053
  default-nameserver:
    - 223.5.5.5
    - 8.8.4.4
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - '*.lan'
    - localhost.ptlogin2.qq.com
    - '+.srv.nintendo.net'
    - '+.stun.playstation.net'
    - '+.msftconnecttest.com'
    - '+.msftncsi.com'
    - '+.xboxlive.com'
    - 'msftconnecttest.com'
    - 'xbox.*.microsoft.com'
    - '*.battlenet.com.cn'
    - '*.battlenet.com'
    - '*.blzstatic.cn'
    - '*.battle.net'
  nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query
    - https://1.1.1.1/dns-query
    - https://dns.google/dns-query
  fallback:
    - https://1.1.1.1/dns-query
    - https://dns.google/dns-query
    - https://dns.cloudflare.com/dns-query
    - https://public.dns.iij.jp/dns-query
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

# 代理服务器（目前只有直连）
proxies:
  - name: "🎯 直连"
    type: direct
    
# 代理组
proxy-groups:
  - name: "🚀 节点选择"
    type: select
    proxies:
      - "🎯 直连"
      - "♻️ 自动选择"
      - "🔯 故障转移"
      
  - name: "♻️ 自动选择"
    type: url-test
    proxies:
      - "🎯 直连"
    url: 'http://www.gstatic.com/generate_204'
    interval: 300
    tolerance: 50
    
  - name: "🔯 故障转移"
    type: fallback
    proxies:
      - "🎯 直连"
    url: 'http://www.gstatic.com/generate_204'
    interval: 300
    
  - name: "🌍 国外媒体"
    type: select
    proxies:
      - "🚀 节点选择"
      - "♻️ 自动选择"
      - "🎯 直连"
      
  - name: "📺 国内媒体"
    type: select
    proxies:
      - "🎯 直连"
      - "🚀 节点选择"
      
  - name: "Ⓜ️ 微软服务"
    type: select
    proxies:
      - "🎯 直连"
      - "🚀 节点选择"
      
  - name: "🍎 苹果服务"
    type: select
    proxies:
      - "🎯 直连"
      - "🚀 节点选择"
      
  - name: "🎯 全球直连"
    type: select
    proxies:
      - "🎯 直连"
      - "🚀 节点选择"
      
  - name: "🛑 全球拦截"
    type: select
    proxies:
      - REJECT
      - "🎯 直连"
      
  - name: "🐟 漏网之鱼"
    type: select
    proxies:
      - "🚀 节点选择"
      - "🎯 直连"

# 分流规则
rules:
  # 本地网络
  - DOMAIN-SUFFIX,local,🎯 直连
  - IP-CIDR,127.0.0.0/8,🎯 直连
  - IP-CIDR,172.16.0.0/12,🎯 直连
  - IP-CIDR,192.168.0.0/16,🎯 直连
  - IP-CIDR,10.0.0.0/8,🎯 直连
  - IP-CIDR,17.0.0.0/8,🎯 直连
  - IP-CIDR,100.64.0.0/10,🎯 直连
  - IP-CIDR,224.0.0.0/4,🎯 直连
  - IP-CIDR6,fe80::/10,🎯 直连
  
  # 广告拦截
  - DOMAIN-SUFFIX,googlesyndication.com,🛑 全球拦截
  - DOMAIN-SUFFIX,googleadservices.com,🛑 全球拦截
  - DOMAIN-SUFFIX,doubleclick.net,🛑 全球拦截
  
  # 国外媒体
  - DOMAIN-SUFFIX,youtube.com,🌍 国外媒体
  - DOMAIN-SUFFIX,googlevideo.com,🌍 国外媒体
  - DOMAIN-SUFFIX,netflix.com,🌍 国外媒体
  - DOMAIN-SUFFIX,nflxvideo.net,🌍 国外媒体
  - DOMAIN-SUFFIX,facebook.com,🌍 国外媒体
  - DOMAIN-SUFFIX,twitter.com,🌍 国外媒体
  - DOMAIN-SUFFIX,instagram.com,🌍 国外媒体
  - DOMAIN-SUFFIX,telegram.org,🌍 国外媒体
  
  # 微软服务
  - DOMAIN-SUFFIX,microsoft.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,microsoftonline.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,office.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,office365.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,outlook.com,Ⓜ️ 微软服务
  - DOMAIN-SUFFIX,skype.com,Ⓜ️ 微软服务
  
  # 苹果服务
  - DOMAIN-SUFFIX,apple.com,🍎 苹果服务
  - DOMAIN-SUFFIX,icloud.com,🍎 苹果服务
  - DOMAIN-SUFFIX,itunes.com,🍎 苹果服务
  - DOMAIN-SUFFIX,appstore.com,🍎 苹果服务
  
  # 国内直连
  - DOMAIN-SUFFIX,baidu.com,🎯 全球直连
  - DOMAIN-SUFFIX,qq.com,🎯 全球直连
  - DOMAIN-SUFFIX,taobao.com,🎯 全球直连
  - DOMAIN-SUFFIX,alipay.com,🎯 全球直连
  - DOMAIN-SUFFIX,weibo.com,🎯 全球直连
  - DOMAIN-SUFFIX,bilibili.com,🎯 全球直连
  
  # GeoIP规则
  - GEOIP,CN,🎯 全球直连
  - MATCH,🐟 漏网之鱼
EOF

    log_success "Clash配置文件生成完成"
    log_info "配置文件位置: /etc/clash/config.yaml"
    log_info "HTTP代理端口: $CLASH_PORT"
    log_info "SOCKS代理端口: $((CLASH_PORT + 1))"
    log_info "混合代理端口: $((CLASH_PORT + 2))"
    log_info "管理面板端口: 9090"
    log_info "管理密钥: $CLASH_SECRET"

    # 创建增强的systemd服务
    log_info "创建Clash系统服务..."
    cat > /etc/systemd/system/clash.service << EOF
[Unit]
Description=Clash daemon, A rule-based proxy in Go
Documentation=https://github.com/Dreamacro/clash/wiki
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=5
ExecStartPre=/bin/mkdir -p /var/log/clash
ExecStart=/usr/local/bin/clash -d /etc/clash -f /etc/clash/config.yaml
ExecReload=/bin/kill -HUP \$MAINPID
StandardOutput=journal
StandardError=journal
SyslogIdentifier=clash
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
EOF

    # 设置权限
    chown -R root:root /etc/clash
    chmod 755 /etc/clash
    chmod 644 /etc/clash/config.yaml
    
    # 启动Clash服务
    log_info "启动Clash服务..."
    systemctl daemon-reload
    systemctl enable clash
    systemctl start clash
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet clash; then
        log_success "Clash服务启动成功"
        log_info "服务状态: $(systemctl is-active clash)"
        
        # 检查端口监听
        if netstat -tlnp | grep -q ":$CLASH_PORT "; then
            log_success "Clash HTTP代理端口 $CLASH_PORT 监听正常"
        fi
        if netstat -tlnp | grep -q ":9090 "; then
            log_success "Clash管理面板端口 9090 监听正常"
        fi
        
        # 保存配置信息
        echo "export CLASH_SECRET=\"$CLASH_SECRET\"" >> /root/.bashrc
        echo "export CLASH_HTTP_PORT=\"$CLASH_PORT\"" >> /root/.bashrc
        echo "export CLASH_SOCKS_PORT=\"$((CLASH_PORT + 1))\"" >> /root/.bashrc
        
    else
        log_error "Clash服务启动失败"
        log_info "查看错误日志: journalctl -u clash -f"
        return 1
    fi
}

# 安装Hysteria
install_hysteria() {
    log_info "开始安装Hysteria高速代理核心..."
    
    # 检查并清理旧安装
    if systemctl is-active --quiet hysteria-server 2>/dev/null; then
        log_info "检测到Hysteria服务，正在停止..."
        systemctl stop hysteria-server 2>/dev/null || true
    fi
    
    # 下载Hysteria官方安装脚本
    log_info "下载Hysteria官方安装脚本..."
    if ! bash <(curl -fsSL https://get.hy2.sh/); then
        log_error "Hysteria官方安装失败，尝试手动安装..."
        
        # 检测系统架构
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) HYSTERIA_ARCH="amd64" ;;
            aarch64) HYSTERIA_ARCH="arm64" ;;
            armv7l) HYSTERIA_ARCH="armv7" ;;
            *) log_error "不支持的系统架构: $ARCH"; return 1 ;;
        esac
        
        # 手动下载安装
        log_info "手动下载Hysteria二进制文件..."
        HYSTERIA_VERSION=$(curl -s "https://api.github.com/repos/apernet/hysteria/releases/latest" | grep '"tag_name":' | sed -E 's/.*"app\/([^"]+)".*/\1/' | head -1)
        HYSTERIA_URL="https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-${HYSTERIA_ARCH}"
        
        cd /tmp
        if ! wget -O hysteria "$HYSTERIA_URL"; then
            log_error "Hysteria下载失败"
            return 1
        fi
        
        chmod +x hysteria
        mv hysteria /usr/local/bin/hysteria
        
        # 创建系统服务
        cat > /etc/systemd/system/hysteria-server.service << 'EOF'
[Unit]
Description=Hysteria Server Service (config.yaml)
After=network.target

[Service]
Type=exec
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
WorkingDirectory=/etc/hysteria
User=hysteria
Group=hysteria
Environment=HYSTERIA_LOG_LEVEL=info
Restart=always
RestartSec=5
RestartPreventExitStatus=1

[Install]
WantedBy=multi-user.target
EOF
        
        # 创建用户
        useradd -r -d /etc/hysteria -s /sbin/nologin hysteria 2>/dev/null || true
        systemctl daemon-reload
    fi
    
    log_success "Hysteria核心程序安装完成"
    
    # 生成强密码
    HYSTERIA_PASSWORD="zhakil$(date +%s | tail -c 6)$(openssl rand -hex 4)"
    log_info "生成Hysteria认证密码: $HYSTERIA_PASSWORD"
    
    # 创建配置目录和必要的目录结构
    log_info "创建Hysteria配置目录..."
    mkdir -p /etc/hysteria /var/log/hysteria
    useradd -r -d /etc/hysteria -s /sbin/nologin hysteria 2>/dev/null || true
    
    # 生成高强度自签名证书
    log_info "生成Hysteria TLS证书..."
    openssl req -x509 -nodes -newkey rsa:4096 \
        -keyout /etc/hysteria/server.key \
        -out /etc/hysteria/server.crt \
        -subj "/C=US/ST=CA/L=San Francisco/O=zhakil/CN=$SERVER_IP" \
        -days 36500 \
        -extensions v3_req \
        -config <(cat <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
L = San Francisco
O = zhakil
CN = $SERVER_IP

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
IP.1 = $SERVER_IP
EOF
)
    
    log_success "TLS证书生成完成"
    
    # 生成详细的Hysteria服务器配置
    log_info "生成Hysteria服务器配置文件..."
    cat > /etc/hysteria/config.yaml << EOF
# Hysteria服务器配置 - zhakil科技箱
# 监听地址和端口
listen: :$HYSTERIA_PORT

# TLS配置
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

# 认证配置
auth:
  type: password
  password: $HYSTERIA_PASSWORD

# 伪装配置
masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true

# QUIC传输层优化配置
quic:
  initStreamReceiveWindow: 8388608      # 8MB 初始流接收窗口
  maxStreamReceiveWindow: 8388608       # 8MB 最大流接收窗口
  initConnReceiveWindow: 20971520       # 20MB 初始连接接收窗口
  maxConnReceiveWindow: 20971520        # 20MB 最大连接接收窗口
  maxIdleTimeout: 60s                   # 60秒最大空闲超时
  maxIncomingStreams: 1024              # 1024 最大传入流
  disablePathMTUDiscovery: false        # 启用路径MTU发现

# 带宽控制（可选）
bandwidth:
  up: 1000 mbps      # 上行带宽限制 1Gbps
  down: 1000 mbps    # 下行带宽限制 1Gbps

# 速率限制配置
speedLimit:
  client:
    maxUpload: 100 mbps      # 单客户端最大上传速度
    maxDownload: 200 mbps    # 单客户端最大下载速度

# 混淆配置（增强安全性）
obfs:
  type: salamander
  salamander:
    password: "zhakil_obfs_$(date +%s | tail -c 8)"

# ACL访问控制（可选）
acl:
  inline:
    - reject(geoip:cn && port:25)      # 阻止中国IP访问25端口
    - reject(geoip:cn && port:587)     # 阻止中国IP访问587端口
    - reject(all && port:22)           # 阻止所有SSH连接
    - allow(all)                       # 允许其他所有连接

# 流量统计
trafficStats:
  listen: :8888
  
# 日志配置
log:
  level: info
  output: /var/log/hysteria/server.log
  maxSize: 100      # 100MB 日志文件最大大小
  maxBackups: 3     # 保留3个备份日志文件
  maxAge: 30        # 保留30天日志
  compress: true    # 压缩旧日志文件
EOF

    log_success "Hysteria配置文件生成完成"
    log_info "配置文件位置: /etc/hysteria/config.yaml"
    log_info "监听端口: $HYSTERIA_PORT (UDP)"
    log_info "认证密码: $HYSTERIA_PASSWORD"
    log_info "TLS证书: /etc/hysteria/server.crt"
    log_info "流量统计: http://$SERVER_IP:8888/stats"
    
    # 设置文件权限
    chown -R hysteria:hysteria /etc/hysteria /var/log/hysteria
    chmod 700 /etc/hysteria
    chmod 600 /etc/hysteria/server.key
    chmod 644 /etc/hysteria/server.crt /etc/hysteria/config.yaml
    
    # 启动Hysteria服务
    log_info "启动Hysteria服务..."
    systemctl daemon-reload
    systemctl enable hysteria-server.service
    systemctl start hysteria-server.service
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet hysteria-server; then
        log_success "Hysteria服务启动成功"
        log_info "服务状态: $(systemctl is-active hysteria-server)"
        
        # 检查UDP端口监听
        if netstat -ulnp | grep -q ":$HYSTERIA_PORT "; then
            log_success "Hysteria UDP端口 $HYSTERIA_PORT 监听正常"
        else
            log_warning "Hysteria端口监听检测失败，请检查防火墙设置"
        fi
        
        # 保存配置信息
        echo "export HYSTERIA_PASSWORD=\"$HYSTERIA_PASSWORD\"" >> /root/.bashrc
        echo "export HYSTERIA_PORT=\"$HYSTERIA_PORT\"" >> /root/.bashrc
        
        # 保存混淆密码
        HYSTERIA_OBFS_PASSWORD=$(grep "password:" /etc/hysteria/config.yaml | grep zhakil_obfs | cut -d'"' -f2)
        echo "export HYSTERIA_OBFS_PASSWORD=\"$HYSTERIA_OBFS_PASSWORD\"" >> /root/.bashrc
        
    else
        log_error "Hysteria服务启动失败"
        log_info "查看错误日志: journalctl -u hysteria-server -f"
        log_info "检查配置文件: cat /etc/hysteria/config.yaml"
        return 1
    fi
}

# 安装Nginx代理
install_nginx() {
    log_info "安装Nginx反向代理..."
    
    if [[ $OS == "ubuntu" ]]; then
        apt install -y nginx
    else
        yum install -y nginx
    fi
    
    # 创建配置文件
    cat > /etc/nginx/sites-available/vpn-proxy << 'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        return 301 https://$host$request_uri;
    }
    
    location /ray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:V2RAY_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    listen 443 ssl http2;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location / {
        root /var/www/html;
        index index.html;
    }
    
    location /ray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:V2RAY_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /clash {
        proxy_pass http://127.0.0.1:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

    # 替换端口变量
    sed -i "s/V2RAY_PORT/$V2RAY_PORT/g" /etc/nginx/sites-available/vpn-proxy
    
    # 启用站点
    if [[ $OS == "ubuntu" ]]; then
        ln -sf /etc/nginx/sites-available/vpn-proxy /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
    else
        cp /etc/nginx/sites-available/vpn-proxy /etc/nginx/conf.d/vpn-proxy.conf
    fi
    
    # 创建SSL证书目录和自签名证书
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt -subj "/CN=$SERVER_IP" -days 36500
    
    # 创建默认网页
    mkdir -p /var/www/html
    cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>zhakil科技箱 VPN服务器</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { color: #28a745; font-weight: bold; }
        .info { margin: 20px 0; padding: 10px; background: #e9ecef; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 zhakil科技箱 VPN服务器</h1>
        <div class="status">✅ 服务器运行正常</div>
        <div class="info">
            <p><strong>服务器IP:</strong> $SERVER_IP</p>
            <p><strong>部署时间:</strong> $(date)</p>
            <p><strong>支持协议:</strong> V2Ray | Clash | Hysteria</p>
        </div>
        <p>请使用管理界面生成客户端配置</p>
        <p><a href="/clash">Clash面板</a> | <a href="http://$SERVER_IP:$WEB_PORT">管理界面</a></p>
    </div>
</body>
</html>
EOF

    # 启动Nginx
    systemctl enable nginx
    systemctl start nginx
    
    if systemctl is-active --quiet nginx; then
        log_success "Nginx代理安装并启动成功"
    else
        log_error "Nginx启动失败"
    fi
}

# 创建Web管理面板
create_web_panel() {
    log_info "创建Web管理面板..."
    
    # 安装Node.js (如果没有)
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        if [[ $OS == "ubuntu" ]]; then
            apt install -y nodejs
        else
            yum install -y nodejs
        fi
    fi
    
    # 创建管理面板目录
    mkdir -p /opt/vpn-panel
    
    # 创建简单的Express服务器
    cat > /opt/vpn-panel/server.js << 'EOF'
const express = require('express');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());
app.use(express.static('public'));

// 获取系统状态
app.get('/api/status', (req, res) => {
    exec('systemctl is-active v2ray clash hysteria-server nginx', (error, stdout) => {
        const services = stdout.trim().split('\n');
        res.json({
            v2ray: services[0] === 'active',
            clash: services[1] === 'active', 
            hysteria: services[2] === 'active',
            nginx: services[3] === 'active'
        });
    });
});

// 生成配置
app.post('/api/config/:type', (req, res) => {
    const { type } = req.params;
    // 调用配置生成脚本
    exec(`/usr/local/bin/zhakil-manage generate-${type}-config`, (error, stdout) => {
        if (error) {
            res.status(500).json({ error: error.message });
        } else {
            res.json({ config: stdout });
        }
    });
});

app.listen(PORT, () => {
    console.log(`VPN管理面板运行在端口 ${PORT}`);
});
EOF

    # 创建package.json
    cat > /opt/vpn-panel/package.json << EOF
{
  "name": "vpn-panel",
  "version": "1.0.0",
  "description": "zhakil科技箱 VPN管理面板",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2"
  },
  "scripts": {
    "start": "node server.js"
  }
}
EOF

    # 安装依赖
    cd /opt/vpn-panel
    npm install
    
    # 创建systemd服务
    cat > /etc/systemd/system/vpn-panel.service << EOF
[Unit]
Description=VPN管理面板
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vpn-panel
Environment=PORT=$WEB_PORT
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 启动面板服务
    systemctl daemon-reload
    systemctl enable vpn-panel
    systemctl start vpn-panel
    
    if systemctl is-active --quiet vpn-panel; then
        log_success "Web管理面板创建成功"
        log_info "管理面板: http://$SERVER_IP:$WEB_PORT"
    else
        log_error "Web管理面板启动失败"
    fi
}

# 保存配置信息
save_config_info() {
    log_info "保存详细配置信息..."
    
    # 获取所有配置变量
    source /root/.bashrc 2>/dev/null || true
    
    # 创建详细的配置信息文件
    cat > /root/vpn-info.txt << EOF
zhakil科技箱 VPN服务器配置信息
======================================

🌐 服务器信息:
- 公网IP地址: $SERVER_IP
- 操作系统: $(lsb_release -d 2>/dev/null | cut -f2 || echo "$OS")
- 系统架构: $(uname -m)
- 安装时间: $(date '+%Y年%m月%d日 %H:%M:%S')
- 部署版本: zhakil科技箱 v4.0.0

🚀 V2Ray VMESS配置:
- 服务器地址: $SERVER_IP
- 端口号: $V2RAY_PORT
- 用户ID (UUID): ${V2RAY_UUID:-$UUID}
- 额外ID (alterID): 64
- 加密方式: auto
- 传输协议: ws (WebSocket)
- 伪装路径: /ray
- 伪装域名: $SERVER_IP
- 网络安全: none (通过Nginx TLS)

🎯 Clash代理配置:
- HTTP代理端口: ${CLASH_HTTP_PORT:-$CLASH_PORT}
- SOCKS代理端口: ${CLASH_SOCKS_PORT:-$((CLASH_PORT + 1))}
- 混合代理端口: $((CLASH_PORT + 2))
- 管理面板地址: http://$SERVER_IP:9090
- 管理密钥: ${CLASH_SECRET:-zhakil123}
- DNS服务端口: 1053
- 配置文件: /etc/clash/config.yaml

⚡ Hysteria UDP配置:
- 服务器地址: $SERVER_IP
- 端口号: ${HYSTERIA_PORT:-36712} (UDP)
- 认证密码: ${HYSTERIA_PASSWORD}
- 混淆类型: salamander
- 混淆密码: ${HYSTERIA_OBFS_PASSWORD}
- 上行带宽: 100 Mbps
- 下行带宽: 200 Mbps
- TLS证书: 自签名证书
- 伪装网站: https://www.bing.com
- 流量统计: http://$SERVER_IP:8888/stats

🌐 Web管理界面:
- 主管理面板: http://$SERVER_IP:${WEB_PORT:-8080}
- Clash控制面板: http://$SERVER_IP:9090
- Hysteria流量统计: http://$SERVER_IP:8888/stats
- 服务器状态页: https://$SERVER_IP

🔧 网络优化:
- BBR拥塞控制: 已启用
- TCP Fast Open: 已启用
- 内核参数优化: 已完成
- 防火墙配置: 已完成

📁 重要文件路径:
- V2Ray配置文件: /usr/local/etc/v2ray/config.json
- V2Ray日志目录: /var/log/v2ray/
- Clash配置文件: /etc/clash/config.yaml
- Clash数据目录: /etc/clash/
- Hysteria配置: /etc/hysteria/config.yaml
- Hysteria证书: /etc/hysteria/server.crt
- Nginx配置: /etc/nginx/sites-available/vpn-proxy

⚡ 快捷命令:
- 进入管理界面: zhakil
- 检查所有服务状态: systemctl status v2ray clash hysteria-server nginx
- 查看V2Ray日志: journalctl -u v2ray -f
- 查看Clash日志: journalctl -u clash -f
- 查看Hysteria日志: journalctl -u hysteria-server -f
- 重启所有服务: systemctl restart v2ray clash hysteria-server nginx
- 生成客户端配置: zhakil (选择第7项)

🔗 客户端配置生成:
建议使用 'zhakil' 命令进入管理界面，选择第7项"配置生成中心"来获取：
1. V2Ray客户端配置文件 (JSON格式)
2. VMESS分享链接 (vmess://)
3. Clash配置文件 (YAML格式，包含完整规则)
4. Hysteria客户端配置 (YAML格式)
5. Hysteria分享链接 (hysteria://)
6. 通用订阅链接 (Base64编码)
7. 二维码 (用于移动设备扫描)

⚠️  重要安全提醒:
1. 请妥善保管此配置文件，其中包含敏感信息
2. UUID和密码是连接的关键，不要泄露给他人
3. 建议定期更换密码和UUID
4. 定期备份 /etc/ 下的配置文件
5. 监控服务器流量使用情况
6. 如发现异常连接，请及时更换配置

📞 技术支持:
- 项目地址: https://github.com/zhakil/vpn
- 管理界面: zhakil命令
- 配置更新: zhakil (选择00进行脚本更新)

生成时间: $(date '+%Y-%m-%d %H:%M:%S %Z')
配置有效性: 永久有效（除非手动修改）
EOF

    # 同时创建机器可读的配置文件供脚本使用
    cat > /root/vpn-config.env << EOF
# zhakil科技箱 VPN服务器环境变量配置
# 此文件供管理脚本自动读取使用

# 服务器信息
SERVER_IP="$SERVER_IP"
INSTALL_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

# V2Ray配置
V2RAY_UUID="${V2RAY_UUID:-$UUID}"
V2RAY_PORT="${V2RAY_PORT:-10001}"
V2RAY_PATH="/ray"
V2RAY_NETWORK="ws"
V2RAY_SECURITY="none"
V2RAY_ALTERID="64"

# Clash配置  
CLASH_HTTP_PORT="${CLASH_HTTP_PORT:-$CLASH_PORT}"
CLASH_SOCKS_PORT="${CLASH_SOCKS_PORT:-$((CLASH_PORT + 1))}"
CLASH_MIXED_PORT="$((CLASH_PORT + 2))"
CLASH_SECRET="${CLASH_SECRET:-zhakil123}"
CLASH_CONTROLLER_PORT="9090"

# Hysteria配置
HYSTERIA_PORT="${HYSTERIA_PORT:-36712}"
HYSTERIA_PASSWORD="${HYSTERIA_PASSWORD}"
HYSTERIA_OBFS_PASSWORD="${HYSTERIA_OBFS_PASSWORD}"
HYSTERIA_UP_MBPS="100"
HYSTERIA_DOWN_MBPS="200"
HYSTERIA_PROTOCOL="udp"

# Web管理
WEB_PORT="${WEB_PORT:-8080}"

# 文件路径
V2RAY_CONFIG="/usr/local/etc/v2ray/config.json"
CLASH_CONFIG="/etc/clash/config.yaml"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
HYSTERIA_CERT="/etc/hysteria/server.crt"

# 服务名称
SERVICES="v2ray clash hysteria-server nginx"
EOF

    # 设置文件权限
    chmod 600 /root/vpn-info.txt /root/vpn-config.env
    
    log_success "配置信息已保存到:"
    log_info "• 详细信息: /root/vpn-info.txt"
    log_info "• 环境变量: /root/vpn-config.env"
    
    # 创建客户端配置生成脚本的软链接
    if [[ ! -f /usr/local/bin/zhakil-config ]]; then
        ln -sf /usr/local/bin/zhakil /usr/local/bin/zhakil-config
    fi
}

# 显示安装结果
show_result() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                🎉 安装完成！🎉                      ║"
    echo "║              zhakil科技箱 VPN服务器                  ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    
    echo -e "${YELLOW}━━━━━━━━ 服务访问地址 ━━━━━━━━${NC}"
    echo -e "${GREEN}🌐 主页面: ${BLUE}https://$SERVER_IP${NC}"
    echo -e "${GREEN}⚡ 管理面板: ${BLUE}http://$SERVER_IP:$WEB_PORT${NC}"
    echo -e "${GREEN}🎛️  Clash面板: ${BLUE}http://$SERVER_IP:9090${NC}"
    echo
    
    echo -e "${YELLOW}━━━━━━━━ 服务状态 ━━━━━━━━${NC}"
    echo -e "${GREEN}✅ V2Ray: ${BLUE}端口 $V2RAY_PORT${NC}"
    echo -e "${GREEN}✅ Clash: ${BLUE}端口 $CLASH_PORT${NC}"
    echo -e "${GREEN}✅ Hysteria: ${BLUE}端口 $HYSTERIA_PORT (UDP)${NC}"
    echo -e "${GREEN}✅ BBR加速: ${BLUE}已启用${NC}"
    echo
    
    echo -e "${YELLOW}━━━━━━━━ 快捷命令 ━━━━━━━━${NC}"
    echo -e "${CYAN}zhakil${NC}          - 进入管理界面"
    echo -e "${CYAN}systemctl status v2ray${NC} - 查看V2Ray状态"
    echo -e "${CYAN}cat /root/vpn-info.txt${NC} - 查看完整配置"
    echo
    
    echo -e "${YELLOW}━━━━━━━━ 下一步操作 ━━━━━━━━${NC}"
    echo -e "1. ${GREEN}输入 ${CYAN}zhakil${GREEN} 进入管理界面${NC}"
    echo -e "2. ${GREEN}选择 ${CYAN}7${GREEN} 生成客户端配置${NC}"
    echo -e "3. ${GREEN}将配置导入到客户端软件${NC}"
    echo
    
    echo -e "${RED}⚠️  重要提醒:${NC}"
    echo -e "• 配置信息已保存到 ${YELLOW}/root/vpn-info.txt${NC}"
    echo -e "• 请妥善保管UUID和密码等敏感信息"
    echo -e "• 建议定期备份配置文件"
    echo
    
    read -p "$(echo -e "${GREEN}按回车键进入管理界面...${NC}")"
    /usr/local/bin/zhakil 2>/dev/null || ./manage.sh
}

# 主安装流程
main() {
    show_welcome
    check_system
    install_base_tools
    install_bbr
    setup_firewall
    install_v2ray
    install_clash
    install_hysteria
    install_nginx
    create_web_panel
    save_config_info
    show_result
}

# 执行安装
main "$@"