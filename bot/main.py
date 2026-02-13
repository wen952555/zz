import logging
import asyncio
from telegram.ext import ApplicationBuilder, CommandHandler, MessageHandler, filters
from .config import BOT_TOKEN, validate_config
from .handlers import (
    start, trigger_stream, download_command, handle_message, 
    send_usage_stats, global_error_handler, monitor_services_job
)

# 配置日志到标准输出
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

if __name__ == '__main__':
    validate_config()
    
    # 建立支持 JobQueue 的 Application
    app = ApplicationBuilder().token(BOT_TOKEN).build()
    
    # 1. 注册全局错误处理器 (关键: 捕获所有 Bot 内部异常)
    app.add_error_handler(global_error_handler)
    
    # 2. 注册定时任务 (每 2 分钟检查一次服务状态)
    if app.job_queue:
        app.job_queue.run_repeating(monitor_services_job, interval=120, first=10)
    
    # 3. 注册命令处理器
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("stream", trigger_stream))
    app.add_handler(CommandHandler("dl", download_command))
    app.add_handler(CommandHandler("usage", send_usage_stats))
    
    # 4. 注册消息处理器
    app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_message))
    
    print("🤖 机器人正在后台运行 (已开启全功能监控)...")
    app.run_polling()
