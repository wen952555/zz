
import requests
import logging
import json
import re
from .system import get_admin_pass

logger = logging.getLogger(__name__)

ALIST_API_URL = "http://127.0.0.1:5244"
_cached_token = None

def get_token():
    """获取或刷新 Alist Token"""
    global _cached_token
    if _cached_token: return _cached_token
    
    raw_output = get_admin_pass()
    if not raw_output or "失败" in raw_output:
        logger.error(f"无法获取 Alist 密码信息: {raw_output}")
        return None

    password = None
    
    # 解析密码逻辑增强
    # 策略1: 正则匹配常见输出格式 (admin: xxx 或 password: xxx)
    # 使用 (.+) 匹配直到行尾，支持密码中包含空格或特殊字符
    match = re.search(r'(?:admin|password):\s*(.+)', raw_output, re.IGNORECASE)
    if match:
        password = match.group(1).strip()
    
    # 策略2: 如果正则失败，尝试倒序查找最后一行有效内容
    if not password:
        lines = [l.strip() for l in raw_output.split('\n') if l.strip()]
        # 过滤掉明显的日志行 (包含 time=, level=, [INFO] 等)
        candidates = [
            l for l in lines 
            if "time=" not in l and "[INFO]" not in l and "level=" not in l
        ]
        if candidates:
            last_line = candidates[-1]
            # 如果包含冒号，可能是 "admin: 123"，尝试分割
            if ":" in last_line:
                parts = last_line.split(":", 1)
                # 确保冒号后面有内容
                if len(parts) > 1:
                    password = parts[1].strip()
                else:
                    password = last_line
            else:
                password = last_line

    if not password:
        logger.error(f"解析 Alist 密码失败，原始输出: {raw_output[:100]}...")
        return None

    try:
        # 尝试登录获取 Token
        url = f"{ALIST_API_URL}/api/auth/login"
        payload = {"username": "admin", "password": password}
        
        r = requests.post(url, json=payload, timeout=5)
        data = r.json()
        
        if data.get("code") == 200:
            _cached_token = data["data"]["token"]
            return _cached_token
        else:
            logger.error(f"Alist 登录失败: {data} (User: admin, Pass: {password})")
            return None
    except Exception as e:
        logger.error(f"Alist API 连接失败: {e}")
        return None

def fetch_file_list(path="/", page=1, per_page=100):
    """获取文件列表"""
    global _cached_token
    
    # 第一次尝试
    token = get_token()
    if not token: 
        return None, "❌ 认证失败: 无法获取 Token。\n请检查:\n1. Alist 是否正在运行 (pm2 status)\n2. 密码是否正确 (尝试 ./set_pass.sh 重置)"

    url = f"{ALIST_API_URL}/api/fs/list"
    headers = {"Authorization": token}
    payload = {
        "path": path,
        "page": page,
        "per_page": per_page,
        "refresh": False
    }

    try:
        r = requests.post(url, headers=headers, json=payload, timeout=10)
        data = r.json()
        
        # 成功
        if data.get("code") == 200:
            return data["data"]["content"], None
            
        # 如果是 401 或 Token 无效，尝试清除缓存重试一次
        if data.get("code") in [401, 403]:
            logger.info("Token 可能失效，尝试重新获取...")
            _cached_token = None
            token = get_token()
            if token:
                headers["Authorization"] = token
                r = requests.post(url, headers=headers, json=payload, timeout=10)
                data = r.json()
                if data.get("code") == 200:
                    return data["data"]["content"], None

        return None, f"API 错误: {data.get('message')}"
    except Exception as e:
        return None, f"网络错误: {str(e)}"

def get_file_info(path):
    """获取单个文件信息"""
    token = get_token()
    if not token: return None
    url = f"{ALIST_API_URL}/api/fs/get"
    headers = {"Authorization": token}
    try:
        r = requests.post(url, headers=headers, json={"path": path}, timeout=5)
        return r.json()
    except:
        return None
