#!/bin/bash

# SSL证书设置脚本
# 支持Let's Encrypt和自签名证书

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

# 配置变量
PROJECT_DIR="/opt/proxy-manager"
SSL_DIR="$PROJECT_DIR/ssl"
DOMAIN=""
EMAIL=""

# 显示使用说明
show_usage() {
    echo "SSL证书设置脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 --domain example.com --email admin@example.com [选项]"
    echo ""
    echo "选项:"
    echo "  --domain DOMAIN     设置域名 (必需)"
    echo "  --email EMAIL       设置邮箱 (Let's Encrypt必需)"
    echo "  --self-signed       生成自签名证书"
    echo "  --letsencrypt       使用Let's Encrypt证书"
    echo "  --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  # 使用Let's Encrypt"
    echo "  $0 --domain example.com --email admin@example.com --letsencrypt"
    echo ""
    echo "  # 使用自签名证书"
    echo "  $0 --domain example.com --self-signed"
}

# 解析命令行参数
parse_args() {
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
            --self-signed)
                SSL_TYPE="self-signed"
                shift
                ;;
            --letsencrypt)
                SSL_TYPE="letsencrypt"
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

    # 验证必需参数
    if [[ -z "$DOMAIN" ]]; then
        log_error "请指定域名"
        show_usage
        exit 1
    fi

    if [[ "$SSL_TYPE" == "letsencrypt" && -z "$EMAIL" ]]; then
        log_error "使用Let's Encrypt需要指定邮箱"
        show_usage
        exit 1
    fi

    # 默认使用自签名证书
    if [[ -z "$SSL_TYPE" ]]; then
        SSL_TYPE="self-signed"
    fi
}

# 检查依赖
check_dependencies() {
    log_step "检查依赖"
    
    if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
        if ! command -v certbot &> /dev/null; then
            log_info "安装certbot..."
            if [[ -f /etc/debian_version ]]; then
                apt update && apt install -y certbot
            elif [[ -f /etc/redhat-release ]]; then
                yum install -y certbot
            else
                log_error "不支持的操作系统，请手动安装certbot"
                exit 1
            fi
        fi
    fi
    
    # 确保openssl可用
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL未安装"
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 创建SSL目录
setup_directories() {
    log_step "创建SSL目录"
    
    mkdir -p "$SSL_DIR"/{letsencrypt,custom}
    chmod 755 "$SSL_DIR"
    
    log_info "SSL目录创建完成"
}

# 生成自签名证书
generate_self_signed() {
    log_step "生成自签名证书"
    
    CERT_PATH="$SSL_DIR/custom/cert.pem"
    KEY_PATH="$SSL_DIR/custom/key.pem"
    
    # 创建配置文件
    cat > "$SSL_DIR/openssl.conf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C=US
ST=State
L=City
O=Organization
OU=Organizational Unit
CN=$DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF

    # 生成私钥
    openssl genrsa -out "$KEY_PATH" 2048
    
    # 生成证书
    openssl req -new -x509 -key "$KEY_PATH" -out "$CERT_PATH" -days 365 \
        -config "$SSL_DIR/openssl.conf" -extensions v3_req
    
    # 设置权限
    chmod 600 "$KEY_PATH"
    chmod 644 "$CERT_PATH"
    
    # 清理配置文件
    rm "$SSL_DIR/openssl.conf"
    
    log_info "自签名证书生成完成"
    log_info "证书路径: $CERT_PATH"
    log_info "私钥路径: $KEY_PATH"
}

# 申请Let's Encrypt证书
setup_letsencrypt() {
    log_step "申请Let's Encrypt证书"
    
    # 检查域名DNS解析
    if ! nslookup "$DOMAIN" > /dev/null 2>&1; then
        log_warn "域名 $DOMAIN DNS解析失败，请确保域名指向此服务器"
        read -p "是否继续？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
    
    # 停止nginx以释放80端口
    if docker ps --format "table {{.Names}}" | grep -q "proxy-nginx"; then
        log_info "临时停止nginx服务"
        docker stop proxy-nginx
    fi
    
    # 申请证书
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        -d "$DOMAIN" \
        --rsa-key-size 2048
    
    if [[ $? -eq 0 ]]; then
        # 复制证书到项目目录
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/letsencrypt/cert.pem"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/letsencrypt/key.pem"
        
        # 设置权限
        chmod 644 "$SSL_DIR/letsencrypt/cert.pem"
        chmod 600 "$SSL_DIR/letsencrypt/key.pem"
        
        log_info "Let's Encrypt证书申请成功"
        log_info "证书路径: $SSL_DIR/letsencrypt/cert.pem"
        log_info "私钥路径: $SSL_DIR/letsencrypt/key.pem"
        
        # 设置自动续期
        setup_auto_renewal
    else
        log_error "证书申请失败"
        
        # 重启nginx
        if docker ps -a --format "table {{.Names}}" | grep -q "proxy-nginx"; then
            docker start proxy-nginx
        fi
        
        exit 1
    fi
    
    # 重启nginx
    if docker ps -a --format "table {{.Names}}" | grep -q "proxy-nginx"; then
        log_info "重启nginx服务"
        docker start proxy-nginx
    fi
}

# 设置证书自动续期
setup_auto_renewal() {
    log_step "设置证书自动续期"
    
    # 创建续期脚本
    cat > "$SSL_DIR/renew-cert.sh" << EOF
#!/bin/bash

# Let's Encrypt证书续期脚本
LOG_FILE="/var/log/letsencrypt-renew.log"

echo "\$(date): 开始证书续期检查" >> "\$LOG_FILE"

# 停止nginx
docker stop proxy-nginx >> "\$LOG_FILE" 2>&1

# 续期证书
certbot renew --standalone >> "\$LOG_FILE" 2>&1

if [ \$? -eq 0 ]; then
    echo "\$(date): 证书续期成功" >> "\$LOG_FILE"
    
    # 复制新证书
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/letsencrypt/cert.pem"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/letsencrypt/key.pem"
    
    # 设置权限
    chmod 644 "$SSL_DIR/letsencrypt/cert.pem"
    chmod 600 "$SSL_DIR/letsencrypt/key.pem"
else
    echo "\$(date): 证书续期失败" >> "\$LOG_FILE"
fi

# 重启nginx
docker start proxy-nginx >> "\$LOG_FILE" 2>&1

echo "\$(date): 续期检查完成" >> "\$LOG_FILE"
EOF

    chmod +x "$SSL_DIR/renew-cert.sh"
    
    # 添加到crontab
    if ! crontab -l 2>/dev/null | grep -q "renew-cert.sh"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * $SSL_DIR/renew-cert.sh") | crontab -
        log_info "已添加自动续期计划任务"
    fi
    
    log_info "证书自动续期设置完成"
}

# 更新docker-compose配置
update_docker_config() {
    log_step "更新Docker配置"
    
    cd "$PROJECT_DIR"
    
    # 更新.env文件中的证书路径
    if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
        sed -i "s|SSL_CERT_PATH=.*|SSL_CERT_PATH=/etc/nginx/ssl/letsencrypt/cert.pem|g" .env
        sed -i "s|SSL_KEY_PATH=.*|SSL_KEY_PATH=/etc/nginx/ssl/letsencrypt/key.pem|g" .env
        
        # 更新nginx配置中的域名
        find configs/nginx -name "*.conf" -exec sed -i "s|your-domain.com|$DOMAIN|g" {} \;
    else
        sed -i "s|SSL_CERT_PATH=.*|SSL_CERT_PATH=/etc/nginx/ssl/custom/cert.pem|g" .env
        sed -i "s|SSL_KEY_PATH=.*|SSL_KEY_PATH=/etc/nginx/ssl/custom/key.pem|g" .env
    fi
    
    # 更新域名配置
    sed -i "s|DOMAIN=.*|DOMAIN=$DOMAIN|g" .env
    
    log_info "Docker配置更新完成"
}

# 测试SSL证书
test_ssl_certificate() {
    log_step "测试SSL证书"
    
    if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
        CERT_PATH="$SSL_DIR/letsencrypt/cert.pem"
    else
        CERT_PATH="$SSL_DIR/custom/cert.pem"
    fi
    
    # 检查证书有效性
    if openssl x509 -in "$CERT_PATH" -text -noout > /dev/null 2>&1; then
        log_info "SSL证书格式验证通过"
        
        # 显示证书信息
        echo ""
        echo "证书信息:"
        openssl x509 -in "$CERT_PATH" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After :|DNS:)"
        echo ""
    else
        log_error "SSL证书格式验证失败"
        exit 1
    fi
}

# 显示完成信息
show_completion() {
    log_step "安装完成"
    
    echo ""
    echo "=========================================="
    echo "  SSL证书设置完成！"
    echo "=========================================="
    echo ""
    echo "证书类型: $SSL_TYPE"
    echo "域名: $DOMAIN"
    
    if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
        echo "证书路径: $SSL_DIR/letsencrypt/"
        echo "自动续期: 已设置 (每日3:00检查)"
    else
        echo "证书路径: $SSL_DIR/custom/"
        echo "有效期: 365天"
    fi
    
    echo ""
    echo "后续步骤:"
    echo "1. 重启nginx服务: docker-compose restart nginx"
    echo "2. 访问 https://$DOMAIN 验证证书"
    if [[ "$SSL_TYPE" == "self-signed" ]]; then
        echo "3. 浏览器会显示证书警告，点击高级选项继续访问"
    fi
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    echo "========================================"
    echo "  SSL证书设置脚本"
    echo "========================================"
    echo ""
    
    parse_args "$@"
    check_dependencies
    setup_directories
    
    case "$SSL_TYPE" in
        "self-signed")
            generate_self_signed
            ;;
        "letsencrypt")
            setup_letsencrypt
            ;;
    esac
    
    update_docker_config
    test_ssl_certificate
    show_completion
}

# 错误处理
trap 'log_error "脚本执行失败"; exit 1' ERR

# 运行主函数
main "$@"