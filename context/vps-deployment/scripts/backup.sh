#!/bin/bash

# 代理管理系统数据备份脚本
# 支持数据库、配置文件、SSL证书等全量备份

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
BACKUP_DIR="/opt/proxy-manager/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${DATE}"
RETENTION_DAYS=${RETENTION_DAYS:-30}

# Docker环境变量
if [[ -f "$PROJECT_DIR/.env" ]]; then
    source "$PROJECT_DIR/.env"
fi

# 显示使用说明
show_usage() {
    echo "代理管理系统备份脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --full              完整备份（默认）"
    echo "  --database          仅备份数据库"
    echo "  --config            仅备份配置文件"
    echo "  --ssl               仅备份SSL证书"
    echo "  --logs              仅备份日志文件"
    echo "  --retention DAYS    设置备份保留天数（默认30天）"
    echo "  --remote            上传到远程存储"
    echo "  --verify            验证备份完整性"
    echo "  --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --full --remote                # 完整备份并上传"
    echo "  $0 --database --verify            # 仅备份数据库并验证"
    echo "  $0 --retention 7                 # 保留7天的备份"
}

# 解析命令行参数
BACKUP_TYPE="full"
REMOTE_UPLOAD=false
VERIFY_BACKUP=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                BACKUP_TYPE="full"
                shift
                ;;
            --database)
                BACKUP_TYPE="database"
                shift
                ;;
            --config)
                BACKUP_TYPE="config"
                shift
                ;;
            --ssl)
                BACKUP_TYPE="ssl"
                shift
                ;;
            --logs)
                BACKUP_TYPE="logs"
                shift
                ;;
            --retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            --remote)
                REMOTE_UPLOAD=true
                shift
                ;;
            --verify)
                VERIFY_BACKUP=true
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
}

# 检查环境
check_environment() {
    log_step "检查环境"
    
    # 检查项目目录
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_error "项目目录不存在: $PROJECT_DIR"
        exit 1
    fi
    
    # 检查Docker环境
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    log_info "环境检查通过"
}

# 备份数据库
backup_databases() {
    log_step "备份数据库"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path/databases"
    
    # PostgreSQL备份
    if docker ps --format "table {{.Names}}" | grep -q "proxy-postgres"; then
        log_info "备份PostgreSQL数据库"
        docker exec proxy-postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$backup_path/databases/postgres.sql"
        
        # 压缩SQL文件
        gzip "$backup_path/databases/postgres.sql"
        
        log_info "PostgreSQL备份完成"
    else
        log_warn "PostgreSQL容器未运行"
    fi
    
    # Redis备份
    if docker ps --format "table {{.Names}}" | grep -q "proxy-redis"; then
        log_info "备份Redis数据库"
        docker exec proxy-redis redis-cli --rdb - > "$backup_path/databases/redis.rdb"
        
        # 压缩RDB文件
        gzip "$backup_path/databases/redis.rdb"
        
        log_info "Redis备份完成"
    else
        log_warn "Redis容器未运行"
    fi
    
    # InfluxDB备份
    if docker ps --format "table {{.Names}}" | grep -q "proxy-influxdb"; then
        log_info "备份InfluxDB数据库"
        mkdir -p "$backup_path/databases/influxdb"
        docker exec proxy-influxdb influx backup -portable /tmp/backup
        docker cp proxy-influxdb:/tmp/backup "$backup_path/databases/influxdb/"
        
        # 清理容器内临时文件
        docker exec proxy-influxdb rm -rf /tmp/backup
        
        # 压缩备份文件
        tar -czf "$backup_path/databases/influxdb.tar.gz" -C "$backup_path/databases/" influxdb
        rm -rf "$backup_path/databases/influxdb"
        
        log_info "InfluxDB备份完成"
    else
        log_warn "InfluxDB容器未运行"
    fi
    
    log_info "数据库备份完成"
}

# 备份配置文件
backup_configs() {
    log_step "备份配置文件"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"
    
    # 备份所有配置文件
    if [[ -d "$PROJECT_DIR/configs" ]]; then
        tar -czf "$backup_path/configs.tar.gz" -C "$PROJECT_DIR" configs
        log_info "配置文件备份完成"
    else
        log_warn "配置目录不存在"
    fi
    
    # 备份环境变量文件
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        cp "$PROJECT_DIR/.env" "$backup_path/.env"
        log_info "环境变量文件备份完成"
    else
        log_warn ".env文件不存在"
    fi
    
    # 备份docker-compose文件
    if [[ -f "$PROJECT_DIR/docker-compose.yml" ]]; then
        cp "$PROJECT_DIR/docker-compose.yml" "$backup_path/docker-compose.yml"
        log_info "Docker Compose文件备份完成"
    fi
}

# 备份SSL证书
backup_ssl() {
    log_step "备份SSL证书"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"
    
    if [[ -d "$PROJECT_DIR/ssl" ]]; then
        tar -czf "$backup_path/ssl.tar.gz" -C "$PROJECT_DIR" ssl
        log_info "SSL证书备份完成"
    else
        log_warn "SSL目录不存在"
    fi
}

# 备份日志文件
backup_logs() {
    log_step "备份日志文件"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"
    
    if [[ -d "$PROJECT_DIR/logs" ]]; then
        # 只备份最近7天的日志
        find "$PROJECT_DIR/logs" -name "*.log" -mtime -7 | tar -czf "$backup_path/logs.tar.gz" -T -
        log_info "日志文件备份完成"
    else
        log_warn "日志目录不存在"
    fi
}

# 备份Docker数据卷
backup_volumes() {
    log_step "备份Docker数据卷"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path/volumes"
    
    # 获取所有数据卷
    local volumes=$(docker volume ls --format "{{.Name}}" | grep proxy)
    
    for volume in $volumes; do
        log_info "备份数据卷: $volume"
        docker run --rm -v "$volume:/data" -v "$backup_path/volumes:/backup" alpine tar czf "/backup/${volume}.tar.gz" /data
    done
    
    log_info "Docker数据卷备份完成"
}

# 创建备份清单
create_manifest() {
    log_step "创建备份清单"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    local manifest_file="$backup_path/MANIFEST.txt"
    
    cat > "$manifest_file" << EOF
# 备份清单
备份时间: $(date)
备份类型: $BACKUP_TYPE
系统信息: $(uname -a)
Docker版本: $(docker --version)

# 备份内容
EOF
    
    # 列出所有备份文件
    find "$backup_path" -type f -exec ls -lh {} \; | sed 's|^|文件: |' >> "$manifest_file"
    
    # 计算总大小
    local total_size=$(du -sh "$backup_path" | cut -f1)
    echo "总大小: $total_size" >> "$manifest_file"
    
    log_info "备份清单创建完成"
}

# 验证备份
verify_backup() {
    if [[ "$VERIFY_BACKUP" == false ]]; then
        return 0
    fi
    
    log_step "验证备份完整性"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    local verify_log="$backup_path/verify.log"
    
    echo "备份验证报告 - $(date)" > "$verify_log"
    
    # 验证压缩文件完整性
    find "$backup_path" -name "*.tar.gz" -o -name "*.gz" | while read file; do
        if gzip -t "$file" 2>/dev/null; then
            echo "✓ $file - 完整" >> "$verify_log"
            log_info "验证通过: $(basename "$file")"
        else
            echo "✗ $file - 损坏" >> "$verify_log"
            log_error "验证失败: $(basename "$file")"
        fi
    done
    
    # 验证SQL文件
    find "$backup_path" -name "*.sql.gz" | while read file; do
        if zcat "$file" | head -1 | grep -q "PostgreSQL database dump"; then
            echo "✓ $file - SQL格式正确" >> "$verify_log"
            log_info "SQL验证通过: $(basename "$file")"
        else
            echo "✗ $file - SQL格式错误" >> "$verify_log"
            log_warn "SQL验证失败: $(basename "$file")"
        fi
    done
    
    log_info "备份验证完成，查看详细报告: $verify_log"
}

# 上传到远程存储
upload_remote() {
    if [[ "$REMOTE_UPLOAD" == false ]]; then
        return 0
    fi
    
    log_step "上传到远程存储"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    
    # 压缩整个备份目录
    tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"
    
    # 根据配置的远程存储类型上传
    if [[ -n "$AWS_S3_BUCKET" ]]; then
        # AWS S3上传
        if command -v aws &> /dev/null; then
            aws s3 cp "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" "s3://$AWS_S3_BUCKET/backups/"
            log_info "备份已上传到AWS S3"
        else
            log_warn "AWS CLI未安装，跳过S3上传"
        fi
    fi
    
    if [[ -n "$REMOTE_SSH_HOST" ]]; then
        # SSH上传
        if command -v scp &> /dev/null; then
            scp "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" "$REMOTE_SSH_HOST:/backups/"
            log_info "备份已上传到远程服务器"
        else
            log_warn "SCP未可用，跳过SSH上传"
        fi
    fi
    
    # 清理本地压缩文件
    rm -f "$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
}

# 清理旧备份
cleanup_old_backups() {
    log_step "清理旧备份"
    
    # 查找超过保留期的备份
    local old_backups=$(find "$BACKUP_DIR" -name "backup_*" -type d -mtime +$RETENTION_DAYS)
    
    if [[ -n "$old_backups" ]]; then
        echo "$old_backups" | while read backup; do
            log_info "删除旧备份: $(basename "$backup")"
            rm -rf "$backup"
        done
    else
        log_info "没有需要清理的旧备份"
    fi
    
    log_info "旧备份清理完成"
}

# 执行备份
execute_backup() {
    cd "$PROJECT_DIR"
    
    case "$BACKUP_TYPE" in
        "full")
            backup_databases
            backup_configs
            backup_ssl
            backup_volumes
            ;;
        "database")
            backup_databases
            ;;
        "config")
            backup_configs
            ;;
        "ssl")
            backup_ssl
            ;;
        "logs")
            backup_logs
            ;;
    esac
    
    create_manifest
    verify_backup
    upload_remote
    cleanup_old_backups
}

# 显示完成信息
show_completion() {
    log_step "备份完成"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    local backup_size=$(du -sh "$backup_path" | cut -f1)
    
    echo ""
    echo "=========================================="
    echo "  备份完成！"
    echo "=========================================="
    echo ""
    echo "备份信息:"
    echo "  备份类型: $BACKUP_TYPE"
    echo "  备份时间: $(date)"
    echo "  备份大小: $backup_size"
    echo "  备份位置: $backup_path"
    echo ""
    echo "备份内容:"
    find "$backup_path" -type f -exec basename {} \; | sed 's/^/  - /'
    echo ""
    if [[ "$VERIFY_BACKUP" == true ]]; then
        echo "✓ 备份完整性验证通过"
    fi
    if [[ "$REMOTE_UPLOAD" == true ]]; then
        echo "✓ 备份已上传到远程存储"
    fi
    echo ""
    echo "恢复命令:"
    echo "  ./restore.sh --backup $BACKUP_NAME"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    echo "========================================"
    echo "  代理管理系统备份脚本"
    echo "========================================"
    echo ""
    
    parse_args "$@"
    check_environment
    execute_backup
    show_completion
    
    log_info "备份脚本执行完成"
}

# 错误处理
trap 'log_error "备份过程中出现错误"; exit 1' ERR

# 运行主函数
main "$@"