
# Termux Alist Bot

专为 **Android Termux** 打造的轻量级网盘与下载机器人。

## ✨ 功能特点

*   📱 **手机即服务器**: 利用旧手机搭建 Alist 网盘。
*   🚀 **内网穿透**: 内置 Cloudflare Tunnel，无公网 IP 也能访问。
*   🤖 **Telegram 控制**: 在 TG 上管理文件、添加下载任务。
*   ⬇️ **离线下载**: 集成 Aria2，支持 http/ftp/magnet 下载。
*   📺 **云端推流**: 利用 GitHub Actions 将网盘视频推送到 Telegram 直播间。

## ⚠️ 关键设置 (Android 12+)

Android 12 及更高版本有名为 "Phantom Process Killer" 的机制，会在后台杀掉 Termux 的子进程。

**解决方法 (推荐):**
连接电脑使用 ADB 执行：
```bash
adb shell "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"
```

## 🛠️ 安装教程

1.  **下载 Termux**: 建议从 F-Droid 下载最新版。
2.  **配置权限**: `termux-setup-storage`
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
5.  **配置变量**:
    ```bash
    nano ~/.env
    ```
    *参考项目中的 `.env.example` 文件填写。*

6.  **启动**: `./start.sh`

## ⚙️ 配置详解

### 1. 基础配置
| 变量名 | 说明 |
| :--- | :--- |
| `BOT_TOKEN` | 必填，Telegram 机器人 Token |
| `ADMIN_ID` | 必填，你的 Telegram 用户 ID |

### 2. GitHub 推流配置 (可选)
如果你想使用 `/stream` 命令将网盘视频推流到 TG 直播间，需要配置 `GITHUB_ACCOUNTS_LIST`。

1.  **Fork 仓库**: 将本项目 Fork 到你自己的 GitHub 账号。
2.  **获取 Token**:
    *   进入 GitHub Settings -> Developer settings -> Personal access tokens (Tokens classic)。
    *   Generate new token。
    *   **⚠️ 必须勾选以下权限**:
        *   `repo` (Full control)
        *   `workflow`
        *   `user` (用于读取额度)
3.  **填写配置**:
    ```bash
    # 格式: 用户名/仓库名|Token
    GITHUB_ACCOUNTS_LIST=yourname/bot-repo|ghp_xxxx123456
    ```

## 📂 目录结构

*   `~/bin/`: 存放二进制文件 (alist, cloudflared)
*   `~/alist-data/`: Alist 数据库与配置
*   `~/.aria2/`: Aria2 配置与会话
*   `~/downloads/`: 默认下载目录
*   `~/.env`: **配置文件 (位于 Termux 根目录)**
