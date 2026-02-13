<<<<<<< HEAD
# Termux Alist Bot

专为 **Android Termux** 打造的轻量级网盘与下载机器人。

## ✨ 功能特点

*   📱 **手机即服务器**: 利用旧手机搭建 Alist 网盘。
*   🚀 **内网穿透**: 内置 Cloudflare Tunnel，无公网 IP 也能访问。
*   🤖 **Telegram 控制**: 在 TG 上管理文件、添加下载任务。
*   ⬇️ **离线下载**: 集成 Aria2，支持 http/ftp/magnet 下载。
*   🔄 **自动更新**: 代码推送到 GitHub，手机端自动同步升级。

## 🛠️ 安装教程

1.  **下载 Termux**: 建议从 F-Droid 下载最新版。
2.  **配置权限**: 
    ```bash
    termux-setup-storage
    ```
3.  **拉取代码**:
    ```bash
    git clone https://github.com/YOUR_NAME/YOUR_REPO.git bot
    cd bot
    ```
4.  **一键安装**:
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```
5.  **配置**:
    ```bash
    nano ~/.env
    # 填入 BOT_TOKEN 和 ADMIN_ID 即可
    ```
6.  **启动**:
    ```bash
    ./start.sh
    ```

## 📝 常用命令

*   启动所有服务: `./start.sh`
*   查看运行状态: `pm2 monit`
*   停止服务: `pm2 stop all`
*   查看 Alist 密码: 在 TG 发送 `🔑 查看密码`

## 📂 目录结构

*   `~/bin/`: 存放 alist 和 cloudflared 二进制文件
*   `~/.aria2/`: Aria2 配置文件
*   `~/downloads/`: 默认下载目录
*   `~/.pm2/logs/`: 日志文件

=======
<div align="center">

<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />

  <h1>Built with AI Studio</h2>

  <p>The fastest path from prompt to production with Gemini.</p>

  <a href="https://aistudio.google.com/apps">Start building</a>

</div>
>>>>>>> 51e42e96d6042965111f47b201f919842d6ba31c
