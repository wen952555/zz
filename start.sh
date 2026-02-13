#!/data/data/com.termux/files/usr/bin/bash

ENV_FILE="$HOME/.env"
export PATH="$HOME/bin:$PATH"

if [ -f "$ENV_FILE" ]; then
    echo ">>> 加载配置文件: $ENV_FILE"
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "❌ 未找到 ~/.env 文件，请先运行 ./setup.sh"
    exit 1
fi

echo "✅ 正在启动 PM2 服务组..."
# 启动所有进程
pm2 start ecosystem.config.js
# 保存当前进程列表，开机自启需配合 Termux-Boot (可选)
pm2 save

echo "-----------------------------------"
echo "🚀 服务已在后台运行"
echo "-----------------------------------"
echo "📊 监控面板: pm2 monit"
echo "📝 查看日志: pm2 logs"
echo "🔄 重启所有: pm2 restart all"
echo "-----------------------------------"
