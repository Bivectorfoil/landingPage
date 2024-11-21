#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo -e "${GREEN}Landing Page 部署脚本${NC}"
    echo
    echo -e "使用方法: $0 [-h|--help] [-d|--domain domain_name]"
    echo
    echo "选项:"
    echo "  -h, --help            显示此帮助信息"
    echo "  -d, --domain          指定域名 (例如: example.com)"
    echo
    echo "示例:"
    echo "  $0 -d example.com     部署网站到指定域名"
    echo "  $0 --help             显示帮助信息"
    echo
    echo "说明:"
    echo "  此脚本用于部署个人落地页网站，包括以下步骤："
    echo "  1. 创建专用网站用户"
    echo "  2. 配置网站目录和权限"
    echo "  3. 安装和配置 Nginx"
    echo "  4. 设置防火墙规则"
    echo
    echo "注意:"
    echo "  - 需要 root 权限运行"
    echo "  - 建议通过 Cloudflare 配置 SSL"
    echo "  - 默认使用 webmaster 用户运行网站"
}

# 解析命令行参数
domain_name=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--domain)
            domain_name="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}错误: 未知参数 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 确保脚本在错误时退出
set -e

# 如果没有提供域名，提示用户输入
if [ -z "$domain_name" ]; then
    echo -e "${YELLOW}请输入您的域名 (例如: example.com):${NC}"
    read domain_name
fi

if [ -z "$domain_name" ]; then
    echo -e "${RED}错误: 域名不能为空${NC}"
    show_help
    exit 1
fi

# 检查是否以root运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误: 此脚本必须以root身份运行${NC}"
   show_help
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
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
NGINX_CONF_NAME="landing-page"

# 确保目录存在
mkdir -p "$NGINX_AVAILABLE" "$NGINX_ENABLED"

# 创建站点配置
sed -e "s/DOMAIN_PLACEHOLDER/$domain_name/g" \
    -e "s/www-data/$WEB_USER/g" \
    nginx.conf > "$NGINX_AVAILABLE/$NGINX_CONF_NAME"

# 检查并删除已存在的软链接
if [ -L "$NGINX_ENABLED/$NGINX_CONF_NAME" ]; then
    rm "$NGINX_ENABLED/$NGINX_CONF_NAME"
fi

# 创建新的软链接
ln -s "$NGINX_AVAILABLE/$NGINX_CONF_NAME" "$NGINX_ENABLED/$NGINX_CONF_NAME"

# 删除默认配置
if [ -L "$NGINX_ENABLED/default" ]; then
    rm "$NGINX_ENABLED/default"
fi

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
echo -e "Nginx 配置文件: ${NGINX_AVAILABLE}/${NGINX_CONF_NAME}"
echo -e "Nginx 日志文件: /var/log/nginx/access.log"
echo -e "\n${YELLOW}提示: 如需查看访问日志，请运行:${NC}"
echo -e "tail -f /var/log/nginx/access.log"

# 显示用户和权限信息
echo -e "\n${YELLOW}目录权限信息:${NC}"
ls -l "$SITE_ROOT"
echo -e "\n${YELLOW}用户信息:${NC}"
id "$WEB_USER"
