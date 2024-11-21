# Landing Page 部署指南

这是一个简单的个人落地页部署项目，包含了网站文件和自动化部署脚本。

## 项目结构

```
landingPage/
├── index.html      # 网站主页
├── styles.css      # 样式文件
├── nginx.conf      # Nginx 配置文件
├── deploy.sh       # 部署脚本
└── README.md       # 本文档
```

## 部署要求

- Ubuntu 22.04 或更高版本
- Root 访问权限
- 域名已经配置好 DNS 解析

## 快速开始

1. 将项目文件上传到服务器：
```bash
scp -r * user@your-server:/path/to/upload/
```

2. SSH 连接到服务器：
```bash
ssh user@your-server
```

3. 进入项目目录：
```bash
cd /path/to/upload/
```

4. 添加执行权限：
```bash
chmod +x deploy.sh
```

5. 运行部署脚本：
```bash
# 方式 1：直接运行（交互式输入域名）
sudo ./deploy.sh

# 方式 2：通过参数指定域名
sudo ./deploy.sh -d example.com
```

## 部署脚本说明

`deploy.sh` 脚本提供以下功能：

- 创建专用的网站用户（webmaster）
- 安装和配置 Nginx
- 设置合适的文件权限
- 配置防火墙规则

### 命令行选项

```bash
使用方法: ./deploy.sh [-h|--help] [-d|--domain domain_name]

选项:
  -h, --help            显示帮助信息
  -d, --domain          指定域名 (例如: example.com)
```

## SSL 配置

本项目建议使用 Cloudflare 提供的 SSL 服务：

1. 在 Cloudflare 添加域名
2. 添加 A 记录指向您的服务器 IP
3. 启用 Cloudflare 代理（橙色云朵）

## 维护说明

- 网站文件位置：`/var/www/landingPage/`
- Nginx 配置：`/etc/nginx/nginx.conf`
- 日志文件：`/var/log/nginx/access.log`

## 故障排除

1. 检查 Nginx 状态：
```bash
systemctl status nginx
```

2. 查看错误日志：
```bash
tail -f /var/log/nginx/error.log
```

3. 检查网站用户权限：
```bash
ls -l /var/www/landingPage/
```

## 安全说明

- 使用专用的受限用户（webmaster）运行网站
- 所有文件权限都经过适当配置
- 通过 UFW 防火墙限制端口访问

## 许可证

MIT
