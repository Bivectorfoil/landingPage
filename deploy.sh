#!/bin/bash

# 确保脚本在错误时退出
set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 检查是否以root运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误: 此脚本必须以root身份运行${NC}"
   exit 1
fi

# 提示用户输入域名
echo -e "${YELLOW}请输入您的域名 (例如: example.com):${NC}"
read domain_name

if [ -z "$domain_name" ]; then
    echo -e "${RED}错误: 域名不能为空${NC}"
    exit 1
fi

# 设置网站用户名
WEB_USER="webmaster"
WEB_ROOT="/var/www"
SITE_ROOT="$WEB_ROOT/landingPage"

echo -e "\n${GREEN}=== 开始部署落地页 ===${NC}"
echo -e "${YELLOW}域名: ${domain_name}${NC}"
echo -e "${YELLOW}网站用户: ${WEB_USER}${NC}"

# 更新系统包
echo -e "\n${YELLOW}[1/9] 更新系统包...${NC}"
apt update && apt upgrade -y

# 安装 Nginx
echo -e "\n${YELLOW}[2/9] 安装 Nginx...${NC}"
apt install -y nginx

# 创建网站用户
echo -e "\n${YELLOW}[3/9] 创建网站用户...${NC}"
if id "$WEB_USER" &>/dev/null; then
    echo -e "${YELLOW}用户 ${WEB_USER} 已存在${NC}"
else
    useradd -r -s /bin/false -d "$WEB_ROOT" -U "$WEB_USER"
    echo -e "${GREEN}创建用户 ${WEB_USER} 成功${NC}"
fi

# 创建网站目录
echo -e "\n${YELLOW}[4/9] 创建网站目录...${NC}"
mkdir -p "$SITE_ROOT"

# 设置目录权限
echo -e "\n${YELLOW}[5/9] 设置目录权限...${NC}"
chown -R "$WEB_USER:$WEB_USER" "$SITE_ROOT"
chmod -R 755 "$SITE_ROOT"

# 复制网站文件
echo -e "\n${YELLOW}[6/9] 复制网站文件...${NC}"
cp index.html styles.css "$SITE_ROOT/"
chown "$WEB_USER:$WEB_USER" "$SITE_ROOT"/*
chmod 644 "$SITE_ROOT"/*

# 配置 Nginx
echo -e "\n${YELLOW}[7/9] 配置 Nginx...${NC}"
# 替换配置文件中的域名占位符和用户
sed -e "s/DOMAIN_PLACEHOLDER/$domain_name/g" \
    -e "s/www-data/$WEB_USER/g" \
    nginx.conf > /etc/nginx/nginx.conf

# 测试 Nginx 配置
echo -e "\n${YELLOW}[8/9] 测试 Nginx 配置...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}Nginx 配置测试失败${NC}"
    exit 1
fi

# 重启 Nginx
echo -e "\n${YELLOW}[9/9] 重启 Nginx...${NC}"
systemctl restart nginx

# 配置防火墙
echo -e "\n${YELLOW}配置防火墙...${NC}"
if command -v ufw >/dev/null 2>&1; then
    ufw allow 'Nginx Full'
    ufw allow OpenSSH
    ufw --force enable
fi

echo -e "\n${GREEN}=== 部署完成! ===${NC}"
echo -e "${GREEN}您的网站已经部署在: http://${domain_name}${NC}"
echo -e "${YELLOW}请确保您的域名已经通过 Cloudflare 解析到此服务器${NC}"

# 显示 Nginx 状态
echo -e "\n${YELLOW}Nginx 状态:${NC}"
systemctl status nginx | grep Active

# 显示部署信息
echo -e "\n${GREEN}=== 部署信息 ===${NC}"
echo -e "网站用户: ${WEB_USER}"
echo -e "网站文件位置: ${SITE_ROOT}"
echo -e "Nginx 配置文件: /etc/nginx/nginx.conf"
echo -e "Nginx 日志文件: /var/log/nginx/access.log"
echo -e "\n${YELLOW}提示: 如需查看访问日志，请运行:${NC}"
echo -e "tail -f /var/log/nginx/access.log"

# 显示用户和权限信息
echo -e "\n${YELLOW}目录权限信息:${NC}"
ls -l "$SITE_ROOT"
echo -e "\n${YELLOW}用户信息:${NC}"
id "$WEB_USER"
