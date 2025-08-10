@echo off
:: Windows VPS代理自动重启脚本
:: 需要设置Docker环境变量

set PROJECT_DIR=E:\zhakil\vpn
set LOG_FILE=%PROJECT_DIR%\logs\restart.log

:: 创建日志目录
if not exist "%PROJECT_DIR%\logs" mkdir "%PROJECT_DIR%\logs"

:: 日志函数
echo %date% %time% - 开始重启代理服务 >> %LOG_FILE%

:: 切换到项目目录
cd /d %PROJECT_DIR%

:: 重启Clash服务
echo 重启Clash核心服务...
docker-compose stop clash-core clash-adapter
timeout /t 5
docker-compose up -d clash-core clash-adapter

:: 检查服务状态
timeout /t 10
docker-compose ps clash-core | findstr "Up" >nul
if %errorlevel%==0 (
    echo %date% %time% - Clash重启成功 >> %LOG_FILE%
) else (
    echo %date% %time% - Clash重启失败 >> %LOG_FILE%
)

:: 清理Docker缓存
docker system prune -f

echo %date% %time% - 重启完成 >> %LOG_FILE%