const fs = require('fs');
const os = require('os');
const path = require('path');

const HOME = os.homedir();

// Termux 中脚本通常在 HOME/bin 下
const alistPath = path.join(HOME, 'bin', 'alist');
const cloudflaredPath = path.join(HOME, 'bin', 'cloudflared');

// 读取环境配置
const mode = process.env.TUNNEL_MODE || 'quick';
const token = process.env.CLOUDFLARE_TOKEN;

let tunnelArgs = [];
if (mode === 'token' && token) {
  tunnelArgs = ["tunnel", "run"]; 
} else {
  // 默认使用 Quick Tunnel 转发 Alist 的 5244 端口
  tunnelArgs = ["tunnel", "--url", "http://localhost:5244"];
}

module.exports = {
  apps : [
    {
      name: "alist",
      script: alistPath,
      args: "server",
      autorestart: true,
      max_memory_restart: '300M', // 限制内存防止 Termux 崩溃
      out_file: "/dev/null", // 减少日志写入，保护手机闪存
      error_file: path.join(HOME, ".pm2", "logs", "alist-error.log")
    },
    {
      name: "aria2",
      script: "aria2c",
      args: `--conf-path=${HOME}/.aria2/aria2.conf`,
      autorestart: true
    },
    {
      name: "bot",
      script: "./bot/main.py",
      interpreter: "python", // Termux 直接用 python
      autorestart: true,
      env: {
        PYTHONUNBUFFERED: "1"
      }
    },
    {
      name: "tunnel",
      script: cloudflaredPath,
      args: tunnelArgs,
      autorestart: true,
      restart_delay: 5000 // 失败后等待 5 秒重试
    },
    {
      name: "monitor",
      script: "./monitor.sh",
      interpreter: "bash",
      autorestart: true
    }
  ]
};