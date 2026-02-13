#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# Termux Alist Bot 部署脚本 (Android 专用)
# ==========================================
set -e

echo -e "\033[1;36m>>> [1/5] 更新 Termux 基础环境...\033[0m"
pkg update -y
pkg upgrade -y

echo -e "\033[1;36m>>> [2/5] 安装必要依赖...\033[0m"
# 安装 Python, Node.js, Aria2, FFmpeg, Git, Vim 等
pkg install -y python nodejs aria2 ffmpeg git vim curl wget tar openssl-tool build-essential libffi

echo -e "\033[1;36m>>> [3/5] 安装 Python 库...\033[0m"
pip install --upgrade pip
pip install python-telegram-bot requests psutil python-dotenv

echo -e "\033[1;36m>>> [4/5] 安装 PM2 (进程守护)...\033[0m"
npm install -g pm2

# 准备 bin 目录
mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$PATH"

echo -e "\033[1;36m>>> [5/5] 下载核心组件 (Alist & Cloudflared)...\033[0m"

# --- 1. 安装 Cloudflared ---
if ! command -v cloudflared &> /dev/null; then
    echo "正在下载 Cloudflared (Linux-arm64)..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O "$HOME/bin/cloudflared"
    chmod +x "$HOME/bin/cloudflared"
fi

# --- 2. 安装 Alist ---
if ! command -v alist &> /dev/null; then
    echo "正在下载 Alist (Linux-arm64)..."
    # 获取最新版 tag
    LATEST_TAG=$(curl -s https://api.github.com/repos/alist-org/alist/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    wget -q "https://github.com/alist-org/alist/releases/download/${LATEST_TAG}/alist-linux-arm64.tar.gz" -O alist.tar.gz
    tar -zxvf alist.tar.gz
    chmod +x alist
    mv alist "$HOME/bin/alist"
    rm alist.tar.gz
fi

# --- 3. 生成配置文件 ---
ENV_FILE="$HOME/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "生成默认配置文件: ~/.env"
    cat <<EOT >> "$ENV_FILE"
# ==============================
# Termux Bot 配置文件
# ==============================
BOT_TOKEN=
ADMIN_ID=
# 隧道模式: quick (随机域名) 或 token (固定域名)
TUNNEL_MODE=quick
CLOUDFLARE_TOKEN=
# Alist 域名 (可选，如果不填则自动获取隧道域名)
ALIST_DOMAIN=
# 直播推流地址 (可选)
TG_RTMP_URL=
# Aria2 密钥 (默认无需修改)
ARIA2_RPC_SECRET=
EOT
fi

# --- 4. 配置 Aria2 ---
ARIA2_DIR="$HOME/.aria2"
mkdir -p "$ARIA2_DIR"
touch "$ARIA2_DIR/aria2.session"
if [ ! -f "$ARIA2_DIR/aria2.conf" ]; then
    cat <<EOT > "$ARIA2_DIR/aria2.conf"
dir=$HOME/downloads
input-file=$ARIA2_DIR/aria2.session
save-session=$ARIA2_DIR/aria2.session
save-session-interval=60
force-save=true
enable-rpc=true
rpc-allow-origin-all=true
rpc-listen-all=true
rpc-port=6800
max-concurrent-downloads=3
EOT
fi

echo "--------------------------------------------------------"
echo "✅ Termux 环境部署完成！"
echo "--------------------------------------------------------"
echo "下一步:"
echo "1. 编辑配置: nano ~/.env"
echo "2. 启动服务: ./start.sh"
echo "--------------------------------------------------------"
