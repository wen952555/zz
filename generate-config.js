
import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const HOME = os.homedir();

// 1. 获取 Python 解释器路径
let pythonExec = "python3";
try {
  // 尝试使用 command -v 查找 (比 which 更通用)
  const check = execSync("command -v python3").toString().trim();
  if (check) {
    pythonExec = check;
  }
} catch (e) {
  // 如果 command -v 失败，尝试硬编码路径或保持 python3
  const termuxPy = "/data/data/com.termux/files/usr/bin/python3";
  if (fs.existsSync(termuxPy)) {
    pythonExec = termuxPy;
  }
}

console.log(`ℹ️ Python 路径: ${pythonExec}`);

// 2. 准备目录
const alistDataDir = path.join(HOME, 'alist-data');
if (!fs.existsSync(alistDataDir)) {
    try {
        fs.mkdirSync(alistDataDir, { recursive: true });
        console.log(`✅ 创建 Alist 数据目录: ${alistDataDir}`);
    } catch (e) {
        console.error("❌ 无法创建数据目录:", e);
    }
}

// 3. 解析配置
// ⚡️ 优化: 
// 1. 使用 127.0.0.1 替代 localhost，防止 Termux 优先解析 IPv6 导致 502 Bad Gateway
// 2. 添加 --protocol http2，修复 Termux 环境下 QUIC 协议连接不稳定的问题 (Error 530)
let tunnelArgs = ['tunnel', '--url', 'http://127.0.0.1:5244', '--no-autoupdate', '--protocol', 'http2', '--metrics', '127.0.0.1:49500'];

const envPath = path.join(HOME, '.env');

try {
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    
    // 辅助函数：提取变量并去除引号
    const getEnv = (key, defaultVal) => {
        const regex = new RegExp(`^${key}=(.*)$`, 'm');
        const match = envContent.match(regex);
        if (!match) return defaultVal;
        let val = match[1].trim();
        // 去除开头和结尾的单引号或双引号
        if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
            val = val.slice(1, -1);
        }
        return val;
    };
    
    const token = getEnv('CLOUDFLARE_TOKEN', '');
    const mode = getEnv('TUNNEL_MODE', 'quick');

    if (mode === 'token' && token) {
      // Token 模式同样应用优化参数
      // 注意: Cloudflared 对 Token 格式非常敏感，必须确保没有多余空格或引号
      tunnelArgs = ['tunnel', 'run', '--token', token, '--protocol', 'http2', '--metrics', '127.0.0.1:49500'];
      console.log(`ℹ️ 启用 Tunnel Token 模式 (Token 长度: ${token.length})`);
    } else {
        console.log(`ℹ️ 启用 Tunnel Quick 模式`);
    }
  }
} catch (error) {
  console.error("⚠️ 读取 .env 失败，将使用默认配置:", error);
}

// 4. 定义 PM2 配置
const config = {
  apps: [
    {
      name: "alist",
      script: path.join(HOME, "bin/alist"),
      args: ["server", "--data", alistDataDir], // 显式指定数据目录
      cwd: alistDataDir, // 设置工作目录
      autorestart: true,
      restart_delay: 5000,
      max_restarts: 10,
    },
    {
      name: "aria2",
      script: "aria2c",
      args: [`--conf-path=${path.join(HOME, ".aria2/aria2.conf")}`],
      autorestart: true,
      restart_delay: 5000,
    },
    {
      name: "bot",
      script: pythonExec,
      args: ["-u", "-m", "bot.main"],
      cwd: __dirname,
      autorestart: true,
      restart_delay: 3000,
      env: {
        ...process.env,
        PYTHONUNBUFFERED: "1"
      }
    },
    {
      name: "tunnel",
      script: path.join(HOME, "bin/cloudflared"),
      args: tunnelArgs,
      autorestart: true,
      restart_delay: 5000,
      max_restarts: 10,
    }
  ]
};

// 5. 写入文件
const outputPath = path.join(__dirname, 'ecosystem.config.json');
try {
  fs.writeFileSync(outputPath, JSON.stringify(config, null, 2));
  console.log(`✅ 已生成 PM2 配置文件: ${outputPath}`);
} catch (err) {
  console.error("❌ 生成配置文件失败:", err);
  process.exit(1);
}
