# VPS部署文档目录

本目录包含基于混合架构的代理管理系统VPS部署方案。

## 目录结构说明

```
vps-deployment/
├── README.md                    # 本文件，部署概述
├── architecture/               # 架构设计文档
│   ├── system-overview.md      # 系统整体架构
│   ├── component-design.md     # 组件详细设计
│   └── protocol-adapters.md    # 协议适配器设计
├── deployment/                 # 部署配置文件
│   ├── docker-compose.yml      # Docker编排配置
│   ├── nginx/                  # Nginx配置
│   ├── ssl/                    # SSL证书配置
│   └── environment/            # 环境变量配置
├── scripts/                    # 自动化脚本
│   ├── install.sh             # 一键安装脚本
│   ├── backup.sh              # 备份脚本
│   ├── update.sh              # 更新脚本
│   └── monitor.sh             # 监控脚本
├── configs/                    # 应用配置模板
│   ├── api-gateway/           # API网关配置
│   ├── rule-engine/           # 规则引擎配置
│   └── protocol-adapters/     # 协议适配器配置
└── prompts/                   # AI提示词文档
    ├── deployment-setup.md    # 部署配置提示词
    ├── troubleshooting.md     # 故障排查提示词
    └── maintenance.md         # 运维管理提示词
```

## 快速开始

1. 查看 `prompts/deployment-setup.md` 获取详细的部署提示词
2. 运行 `scripts/install.sh` 进行一键部署
3. 访问管理界面进行配置

## 支持的协议

- V2Ray/Xray (VMess, VLESS, Trojan)
- Clash (所有主流协议)
- Hysteria/Hysteria2
- TUIC
- WireGuard
- 可扩展插件协议

## 架构特点

- 混合分层架构，兼顾易用性和专业性
- 统一规则管理 + 协议专用优化
- 微服务设计，支持独立扩展
- 完整监控和日志系统