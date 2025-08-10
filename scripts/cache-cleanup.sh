#!/bin/bash
# VPS代理系统 - 自动缓存清理脚本

# 配置参数
PROJECT_DIR="/opt/proxy-manager"
LOG_FILE="/var/log/cache-cleanup.log"
RETENTION_DAYS=7
MAX_LOG_SIZE="100M"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] - $1" | tee -a $LOG_FILE
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] - $1" | tee -a $LOG_FILE
}

# 检查磁盘空间
check_disk_space() {
    local threshold=80
    local usage=$(df / | awk 'NR==2 {print int($5)}')
    
    if [ $usage -ge $threshold ]; then
        log "磁盘使用率达到 ${usage}%，开始清理缓存"
        return 0
    else
        log "磁盘使用率 ${usage}%，无需清理"
        return 1
    fi
}

# 清理系统缓存
cleanup_system_cache() {
    log "开始清理系统缓存..."
    
    # 清理页面缓存
    sync && echo 3 > /proc/sys/vm/drop_caches
    
    # 清理包管理器缓存
    if command -v apt &> /dev/null; then
        apt clean && apt autoremove -y
    elif command -v yum &> /dev/null; then
        yum clean all
    fi
    
    log "系统缓存清理完成"
}

# 清理Docker缓存
cleanup_docker_cache() {
    log "开始清理Docker缓存..."
    
    # 清理未使用的镜像、容器、网络
    docker system prune -a -f --volumes
    
    # 清理构建缓存
    docker builder prune -a -f
    
    # 清理特定项目的停止容器
    docker container prune -f --filter "label=com.docker.compose.project=vpn"
    
    log "Docker缓存清理完成"
}

# 清理应用日志
cleanup_application_logs() {
    log "开始清理应用日志..."
    
    # 清理Docker容器日志
    find /var/lib/docker/containers/ -name "*.log" -size +${MAX_LOG_SIZE} -delete 2>/dev/null
    
    # 清理项目日志
    if [ -d "$PROJECT_DIR/logs" ]; then
        find "$PROJECT_DIR/logs" -name "*.log" -mtime +${RETENTION_DAYS} -delete
        find "$PROJECT_DIR/logs" -name "*.gz" -mtime +${RETENTION_DAYS} -delete
    fi
    
    # 清理系统日志
    journalctl --vacuum-time=${RETENTION_DAYS}d
    journalctl --vacuum-size=50M
    
    log "应用日志清理完成"
}

# 清理临时文件
cleanup_temp_files() {
    log "开始清理临时文件..."
    
    # 清理/tmp目录
    find /tmp -type f -atime +7 -delete 2>/dev/null
    find /tmp -type d -empty -delete 2>/dev/null
    
    # 清理用户缓存
    find /home/*/.*cache -type f -atime +7 -delete 2>/dev/null
    find /root/.cache -type f -atime +7 -delete 2>/dev/null
    
    # 清理Nginx缓存
    if [ -d "/var/cache/nginx" ]; then
        rm -rf /var/cache/nginx/*
    fi
    
    log "临时文件清理完成"
}

# 清理数据库缓存
cleanup_database_cache() {
    log "开始清理数据库缓存..."
    
    cd $PROJECT_DIR
    
    # Redis缓存清理
    if docker-compose ps redis | grep -q "Up"; then
        docker-compose exec -T redis redis-cli FLUSHDB
        log "Redis缓存已清理"
    fi
    
    # PostgreSQL缓存清理
    if docker-compose ps postgres | grep -q "Up"; then
        docker-compose exec -T postgres psql -U \$POSTGRES_USER -d \$POSTGRES_DB -c "VACUUM;"
        log "PostgreSQL缓存已清理"
    fi
    
    log "数据库缓存清理完成"
}

# 优化内存使用
optimize_memory() {
    log "开始内存优化..."
    
    # 清理内存缓存
    sync && echo 1 > /proc/sys/vm/drop_caches
    sync && echo 2 > /proc/sys/vm/drop_caches  
    sync && echo 3 > /proc/sys/vm/drop_caches
    
    # 清理swap
    if [ $(cat /proc/swaps | wc -l) -gt 1 ]; then
        swapoff -a && swapon -a
    fi
    
    log "内存优化完成"
}

# 生成清理报告
generate_report() {
    local start_time=$1
    local end_time=$(date)
    local disk_after=$(df -h / | awk 'NR==2 {print $4}')
    local memory_after=$(free -h | awk 'NR==2 {print $7}')
    
    log "==================== 清理报告 ===================="
    log "开始时间: $start_time"
    log "结束时间: $end_time"  
    log "清理后可用磁盘空间: $disk_after"
    log "清理后可用内存: $memory_after"
    log "================================================"
}

# 主执行函数
main() {
    local start_time=$(date)
    log "==================== 开始自动清理 ===================="
    
    case "$1" in
        "--force")
            log "强制清理模式"
            cleanup_system_cache
            cleanup_docker_cache
            cleanup_application_logs
            cleanup_temp_files
            cleanup_database_cache
            optimize_memory
            ;;
        "--system")
            cleanup_system_cache
            optimize_memory
            ;;
        "--docker")
            cleanup_docker_cache
            ;;
        "--logs")
            cleanup_application_logs
            ;;
        "--temp")
            cleanup_temp_files
            ;;
        "--database")
            cleanup_database_cache
            ;;
        *)
            # 默认模式：检查磁盘空间决定是否清理
            if check_disk_space; then
                cleanup_system_cache
                cleanup_docker_cache
                cleanup_application_logs
                cleanup_temp_files
                optimize_memory
            fi
            ;;
    esac
    
    generate_report "$start_time"
    log "==================== 清理完成 ===================="
}

# 设置定时任务
setup_cron() {
    log "设置自动清理定时任务..."
    
    # 添加到crontab (每天凌晨2点执行)
    (crontab -l 2>/dev/null; echo "0 2 * * * $PWD/cache-cleanup.sh") | crontab -
    
    # 添加到crontab (每小时检查一次)
    (crontab -l 2>/dev/null; echo "0 */4 * * * $PWD/cache-cleanup.sh --system") | crontab -
    
    log "定时任务设置完成"
    crontab -l
}

# 如果是安装模式
if [ "$1" = "--install" ]; then
    setup_cron
    exit 0
fi

# 执行主函数
main "$@"