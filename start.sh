#!/data/data/com.termux/files/usr/bin/bash

ENV_FILE="$HOME/.env"
export PATH="$HOME/bin:$PATH"

# 1. 申请唤醒锁
echo "🔒 申请 Termux 唤醒锁 (Wake Lock)..."
termux-wake-lock

if [ -f "$ENV_FILE" ]; then
    echo ">>> 加载环境变量..."
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "❌ 未找到 ~/.env 文件，请先运行 ./setup.sh"
    exit 1
fi

# --- 环境变量检查 ---
if [ -z "$BOT_TOKEN" ]; then
    echo "--------------------------------------------------------"
    echo "⚠️  检测到 BOT_TOKEN 为空！"
    echo "Bot 无法启动。请先编辑配置文件填入 Telegram Bot Token。"
    echo "👉 命令: nano ~/.env"
    echo "--------------------------------------------------------"
    exit 1
fi
# --------------------

# 2. 检查核心组件是否存在
echo "🔍 检查组件完整性..."
MISSING_FILES=0

if [ ! -f "$HOME/bin/alist" ]; then
    echo "❌ 缺失文件: ~/bin/alist"
    MISSING_FILES=1
else
    # 尝试运行 alist version 检查文件是否损坏
    echo "🧪 验证 Alist 二进制..."
    if ! "$HOME/bin/alist" version > /dev/null 2>&1; then
         echo "❌ Alist 文件似乎已损坏，无法运行。"
         echo "💡 建议运行: ./setup.sh 进行修复"
         exit 1
    fi
fi

if [ ! -f "$HOME/bin/cloudflared" ]; then
    echo "❌ 缺失文件: ~/bin/cloudflared"
    MISSING_FILES=1
fi

if [ $MISSING_FILES -eq 1 ]; then
    echo "-----------------------------------"
    echo "⚠️ 检测到核心组件缺失，无法启动！"
    echo "请重新运行安装脚本进行修复："
    echo "👉 ./setup.sh"
    echo "-----------------------------------"
    exit 1
fi

# 确保 Alist 数据目录存在
mkdir -p "$HOME/alist-data"

# 3. 生成 PM2 配置文件
echo "⚙️ 生成 PM2 任务配置..."
if [ -f "generate-config.js" ]; then
    node generate-config.js
else
    echo "❌ 错误: 找不到 generate-config.js 文件"
    exit 1
fi

# 4. 清理旧的 JS/CJS 配置文件
echo "🧹 清理旧配置文件..."
rm -f ecosystem.config.js ecosystem.config.cjs pm2.config.cjs

# 5. 重置 PM2 状态
echo "🔄 重置 PM2 进程状态..."
pm2 kill > /dev/null 2>&1 || true
sleep 2

echo "✅ 正在启动 PM2 服务组..."

# 6. 启动服务
pm2 start ecosystem.config.json
pm2 save

echo "⏳ 等待服务启动 (3秒)..."
sleep 3

# 7. 检查 Alist 状态 (关键修复)
if pm2 list | grep "alist" | grep -q "online"; then
    echo "✅ Alist 启动成功"
else
    echo "❌ Alist 启动失败！"
    echo "📋 正在读取 Alist 错误日志:"
    echo "--------------------------------"
    pm2 logs alist --lines 10 --nostream
    echo "--------------------------------"
    echo "💡 提示: 可能是端口占用或配置文件损坏。"
    echo "👉 尝试运行: rm -rf ~/alist-data/config.json 并重启"
fi

echo "-----------------------------------"
echo "🚀 服务已在后台运行"
echo "-----------------------------------"
echo "❓ 如果 Cloudflare 报错 1033，说明 Alist 未启动，请检查上方日志。"
echo "-----------------------------------"
