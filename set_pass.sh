
#!/data/data/com.termux/files/usr/bin/bash

# ==========================================
# Alist 密码修改工具
# ==========================================

export PATH="$HOME/bin:$PATH"
DATA_DIR="$HOME/alist-data"

if [ -z "$1" ]; then
    echo "----------------------------------------"
    echo "❌ 用法错误"
    echo "请在命令后加上新密码，例如："
    echo "👉 ./set_pass.sh 123456"
    echo "----------------------------------------"
    exit 1
fi

NEW_PASS="$1"

echo "⚙️ 正在修改 Alist 密码..."
echo "📂 数据目录: $DATA_DIR"

# 必须指定 --data 才能修改正确的数据库
if alist admin set "$NEW_PASS" --data "$DATA_DIR"; then
    echo "✅ 数据库更新成功"
    
    # ⚡️ 关键修改: 保存密码到文件，供 Bot 直接读取
    # 这样 Bot 就不需要去解析 alist admin 复杂的日志输出了
    echo "$NEW_PASS" > "$HOME/.alist_pass"
    chmod 600 "$HOME/.alist_pass"
    
    echo "🔄 正在重启 Alist 以应用更改..."
    if command -v pm2 &> /dev/null; then
        pm2 restart alist > /dev/null 2>&1
    fi
    
    echo "----------------------------------------"
    echo "✅ 密码修改完成！"
    echo "👤 用户名: admin"
    echo "🔑 新密码: $NEW_PASS"
    echo "----------------------------------------"
    echo "💡 现在可以在 Bot 中重试文件浏览了。"
else
    echo "❌ 修改失败，请检查 alist 是否正确安装。"
fi
