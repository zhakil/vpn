#!/bin/bash
# VPS代理服务自动重启脚本

# 配置参数
PROJECT_DIR="/path/to/your/vpn"
LOG_FILE="/var/log/vpn-restart.log"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# 重启Clash核心
restart_clash() {
    log "开始重启Clash服务"
    cd $PROJECT_DIR
    
    # 停止Clash容器
    docker-compose stop clash-core clash-adapter
    
    # 清理缓存
    docker system prune -f
    
    # 重启Clash服务
    docker-compose up -d clash-core clash-adapter
    
    # 检查服务状态
    sleep 10
    if docker-compose ps clash-core | grep -q "Up"; then
        log "Clash重启成功"
    else
        log "Clash重启失败"
    fi
}

# 重启所有代理服务
restart_all() {
    log "开始重启所有代理服务"
    cd $PROJECT_DIR
    
    docker-compose restart v2ray-core clash-core hysteria-core
    docker-compose restart v2ray-adapter clash-adapter hysteria-adapter
    
    log "所有代理服务重启完成"
}

# 内存清理
cleanup_memory() {
    log "清理系统内存"
    sync
    echo 3 > /proc/sys/vm/drop_caches
}

# 完整缓存清理
full_cleanup() {
    log "执行完整缓存清理"
    
    # 调用专用清理脚本
    if [ -f "$PROJECT_DIR/scripts/cache-cleanup.sh" ]; then
        bash "$PROJECT_DIR/scripts/cache-cleanup.sh" --force
    else
        # 基础清理
        cleanup_memory
        docker system prune -a -f
        
        # 清理日志
        find /var/log -name "*.log" -size +100M -exec truncate -s 50M {} \;
        journalctl --vacuum-size=50M
    fi
}

# 主函数
main() {
    case "$1" in
        "clash")
            restart_clash
            ;;
        "all")
            restart_all
            ;;
        "cleanup")
            cleanup_memory
            ;;
        "full-cleanup")
            full_cleanup
            ;;
        *)
            restart_clash  # 默认重启Clash
            ;;
    esac
}

main $1