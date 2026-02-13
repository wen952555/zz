#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# Termux Alist Bot 部署脚本 (修复版)
# ==========================================
set -e

# 检测架构
ARCH=$(uname -m)
case $ARCH in
    aarch64)
        ALIST_ARCH="linux-arm64"
        CF_ARCH="linux-arm64"
        ;;
    arm*)
        ALIST_ARCH="linux-arm-7"
        CF_ARCH="linux-arm"
        ;;
    x86_64)
        ALIST_ARCH="linux-amd64"
        CF_ARCH="linux-amd64"
        ;;
    *)
        echo "❌ 不支持的架构: $ARCH"
        exit 1
        ;;
esac

echo -e "\033[1;36m>>> [1/5] 更新 Termux 基础环境...\033[0m"
# 使用 || true 防止源更新失败导致脚本退出
pkg update -y || true
pkg upgrade -y || true

echo -e "\033[1;36m>>> [2/5] 安装必要依赖...\033[0m"
pkg install -y python nodejs aria2 ffmpeg git vim curl wget tar openssl-tool build-essential libffi termux-tools

echo -e "\033[1;36m>>> [3/5] 安装 Python 库...\033[0m"
# Termux 禁止使用 pip 升级自身，这里只安装依赖包
if [ -f "bot/requirements.txt" ]; then
    pip install -r bot/requirements.txt
else
    pip install python-telegram-bot requests psutil python-dotenv
fi

echo -e "\033[1;36m>>> [4/5] 安装 PM2 (进程守护)...\033[0m"
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
else
    echo "PM2 已安装"
fi

# 准备 bin 目录
mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$PATH"

echo -e "\033[1;36m>>> [5/5] 下载核心组件 ($ARCH)...\033[0m"

# --- 1. 安装 Cloudflared ---
CLOUDFLARED_BIN="$HOME/bin/cloudflared"
if [ ! -f "$CLOUDFLARED_BIN" ]; then
    echo "⬇️ 正在下载 Cloudflared..."
    wget -O "$CLOUDFLARED_BIN" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${CF_ARCH}"
    chmod +x "$CLOUDFLARED_BIN"
    echo "✅ Cloudflared 安装完成"
else
    echo "✅ Cloudflared 已存在 ($CLOUDFLARED_BIN)"
fi

# --- 2. 安装/修复 Alist ---
ALIST_BIN="$HOME/bin/alist"

# 强制停止现有进程以避免文件占用
pm2 stop alist >/dev/null 2>&1 || true

echo "⬇️ 正在安装/修复 Alist (稳定版)..."

# 强制指定一个极其稳定的版本，避免 Latest 获取到 beta 或 buggy 版本
# v3.41.0 是公认的稳定版本
STABLE_VERSION="v3.41.0"
DOWNLOAD_URL="https://github.com/alist-org/alist/releases/download/${STABLE_VERSION}/alist-${ALIST_ARCH}.tar.gz"

echo "目标版本: $STABLE_VERSION"
echo "下载地址: $DOWNLOAD_URL"

# 删除旧文件，确保纯净安装
rm -f "$ALIST_BIN" alist.tar.gz alist

if wget -O alist.tar.gz "$DOWNLOAD_URL"; then
    echo "📦 解压中..."
    tar -zxvf alist.tar.gz
    chmod +x alist
    mv alist "$ALIST_BIN"
    rm -f alist.tar.gz
    
    # 立即验证文件是否完好
    if "$ALIST_BIN" version > /dev/null 2>&1; then
        echo "✅ Alist 已成功更新至 $STABLE_VERSION"
    else
        echo "❌ Alist 文件似乎损坏，请尝试切换网络后重新运行 setup.sh"
        rm -f "$ALIST_BIN"
        exit 1
    fi
else
    echo "❌ 下载失败，请检查网络连接 (可能需要魔法)"
    exit 1
fi

# --- 3. 生成配置文件 ---
ENV_FILE="$HOME/.env"
echo "📝 配置文件路径: $ENV_FILE"

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
# GitHub 多账号配置
GITHUB_ACCOUNTS_LIST=
EOT
else
    echo "✅ 配置文件已存在，跳过覆盖。"
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
user-agent=Mozilla/5.0
EOT
fi

# --- 5. 赋予脚本执行权限 ---
echo "🔧 设置脚本权限..."
chmod +x start.sh update.sh monitor.sh

echo "--------------------------------------------------------"
echo "✅ Termux 环境部署完成！"
echo "--------------------------------------------------------"
echo "⚠️  注意: 已强制修复 Alist。"
echo "--------------------------------------------------------"
echo "👉 1. 请先运行: ./setup.sh (确保下载成功)"
echo "👉 2. 然后运行: ./start.sh"
echo "--------------------------------------------------------"
