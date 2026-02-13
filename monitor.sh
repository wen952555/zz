#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# 更新监控守护进程
# ==========================================

cd "$HOME"
export PATH="$HOME/bin:$PATH"

LOG_FILE="$HOME/.pm2/logs/monitor.log"
UPDATE_SCRIPT="$HOME/update.sh"

while true; do
    # 简单的网络检查
    if curl -s --head https://github.com > /dev/null; then
        git fetch origin main &> /dev/null
        
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        
        if [ "$LOCAL" != "$REMOTE" ]; then
            echo "[$(date)] ⚡ 发现新版本，执行更新..." >> "$LOG_FILE"
            if [ -f "$UPDATE_SCRIPT" ]; then
                bash "$UPDATE_SCRIPT" >> "$LOG_FILE" 2>&1
            fi
        fi
    fi
    # 每 5 分钟检查一次
    sleep 300
done
