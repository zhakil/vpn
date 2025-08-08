#!/bin/bash

# VPS代理管理系统 - SSL证书配置脚本
# 支持Let's Encrypt自动证书和自签名证书

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/opt/vps-proxy-manager"
SSL_DIR="$PROJECT_DIR/ssl"

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

# 显示使用说明
show_usage() {
    echo "VPS SSL证书配置脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 --domain <域名> [选项]"
    echo ""
    echo "选项:"
    echo "  --domain DOMAIN     域名 (必须)"
    echo "  --email EMAIL       邮箱 (Let's Encrypt需要)"
    echo "  --letsencrypt       使用Let's Encrypt证书"
    echo "  --self-signed       使用自签名证书"
    echo "  --help              显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 --domain proxy.example.com --email admin@example.com --letsencrypt"
    echo "  $0 --domain proxy.example.com --self-signed"
}

# 解析命令行参数
parse_args() {
    DOMAIN=""
    EMAIL=""
    SSL_TYPE="self-signed"  # 默认自签名
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --email)
                EMAIL="$2" 
                shift 2
                ;;
            --letsencrypt)
                SSL_TYPE="letsencrypt"
                shift
                ;;
            --self-signed)
                SSL_TYPE="self-signed"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$DOMAIN" ]]; then
        log_error "必须提供域名"
        show_usage
        exit 1
    fi
    
    if [[ "$SSL_TYPE" == "letsencrypt" && -z "$EMAIL" ]]; then
        log_error "Let's Encrypt模式需要邮箱地址"
        show_usage
        exit 1
    fi
}

# 安装certbot
install_certbot() {
    if ! command -v certbot &> /dev/null; then
        log_step "安装certbot"
        
        if [[ -f /etc/debian_version ]]; then
            apt update > /dev/null 2>&1
            apt install -y certbot > /dev/null 2>&1
        elif [[ -f /etc/redhat-release ]]; then
            yum install -y certbot > /dev/null 2>&1
        else
            log_error "不支持的操作系统"
            exit 1
        fi
    fi
}

# 生成自签名证书
generate_self_signed() {
    log_step "生成自签名证书"
    
    mkdir -p "$SSL_DIR"
    
    # 生成私钥
    openssl genrsa -out "$SSL_DIR/key.pem" 2048
    
    # 生成证书
    openssl req -new -x509 -key "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.pem" \
        -days 365 -subj "/C=US/ST=State/L=City/O=VPS-Proxy/CN=$DOMAIN"
    
    chmod 600 "$SSL_DIR/key.pem"
    chmod 644 "$SSL_DIR/cert.pem"
    
    log_info "自签名证书生成完成"
    log_info "证书路径: $SSL_DIR/cert.pem"
    log_info "密钥路径: $SSL_DIR/key.pem"
}

# 申请Let's Encrypt证书
setup_letsencrypt() {
    log_step "申请Let's Encrypt证书"
    
    install_certbot
    
    # 停止nginx释放80端口
    if docker ps --format "table {{.Names}}" | grep -q "vps-nginx"; then
        log_info "停止nginx服务"
        docker stop vps-nginx > /dev/null 2>&1
    fi
    
    # 申请证书
    if certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        -d "$DOMAIN" \
        --rsa-key-size 2048; then
        
        # 复制证书
        mkdir -p "$SSL_DIR"
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/cert.pem"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/key.pem"
        
        chmod 644 "$SSL_DIR/cert.pem"
        chmod 600 "$SSL_DIR/key.pem"
        
        log_info "Let's Encrypt证书申请成功"
        
        # 设置自动续期
        setup_auto_renewal
    else
        log_error "证书申请失败"
        exit 1
    fi
    
    # 重启nginx
    if docker ps -a --format "table {{.Names}}" | grep -q "vps-nginx"; then
        log_info "重启nginx服务"
        docker start vps-nginx > /dev/null 2>&1
    fi
}

# 设置证书自动续期
setup_auto_renewal() {
    log_step "设置证书自动续期"
    
    # 创建续期脚本
    cat > "/usr/local/bin/renew-ssl.sh" << EOF
#!/bin/bash
# 自动续期脚本

docker stop vps-nginx > /dev/null 2>&1
certbot renew --standalone > /dev/null 2>&1

if [ \$? -eq 0 ]; then
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/cert.pem"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/key.pem"
    chmod 644 "$SSL_DIR/cert.pem" 
    chmod 600 "$SSL_DIR/key.pem"
    echo "\$(date): SSL证书续期成功" >> /var/log/ssl-renewal.log
else
    echo "\$(date): SSL证书续期失败" >> /var/log/ssl-renewal.log
fi

docker start vps-nginx > /dev/null 2>&1
EOF
    
    chmod +x "/usr/local/bin/renew-ssl.sh"
    
    # 添加cron任务
    if ! crontab -l 2>/dev/null | grep -q "renew-ssl.sh"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/renew-ssl.sh") | crontab -
        log_info "已设置证书自动续期"
    fi
}

# 测试证书
test_certificate() {
    log_step "测试SSL证书"
    
    if openssl x509 -in "$SSL_DIR/cert.pem" -text -noout > /dev/null 2>&1; then
        log_info "SSL证书验证通过"
        
        # 显示证书信息
        echo ""
        echo "证书信息:"
        openssl x509 -in "$SSL_DIR/cert.pem" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After :)"
        echo ""
    else
        log_error "SSL证书验证失败"
        exit 1
    fi
}

# 主函数
main() {
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${GREEN}   VPS SSL证书配置工具${NC}"
    echo -e "${BLUE}=======================================${NC}"
    echo ""
    
    parse_args "$@"
    
    log_info "域名: $DOMAIN"
    log_info "SSL类型: $SSL_TYPE"
    
    case "$SSL_TYPE" in
        "letsencrypt")
            setup_letsencrypt
            ;;
        "self-signed")
            generate_self_signed
            ;;
    esac
    
    test_certificate
    
    echo ""
    echo -e "${GREEN}✅ SSL证书配置完成！${NC}"
    echo ""
    echo "访问地址: https://$DOMAIN"
    if [[ "$SSL_TYPE" == "self-signed" ]]; then
        echo -e "${YELLOW}注意: 自签名证书会显示浏览器安全警告${NC}"
    fi
}

# 错误处理
trap 'log_error "SSL配置失败"; exit 1' ERR

# 运行主函数
main "$@"