# Cert2DogeCloud

![Shell Script](https://img.shields.io/badge/Shell_Script-%2523121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

自动化同步 SSL 证书到多吉云 CDN 的解决方案，适配宝塔面板和 1Panel 的证书管理。

**本 README 由 AI 辅助生成。**

## 功能

- 🔑 动态生成多吉云 API 访问令牌
- 📤 一键式证书上传与管理
- 🌐 多域名智能证书绑定
- 🗑️ 旧证书清理功能（可选）
- ⏰ 无缝衔接 Let's Encrypt 自动续期
- ✅ 双平台支持（宝塔/1Panel）

## 快速开始

1. 获取多吉云 API 密钥：
   - 登录多吉云控制台
   - 进入「用户中心」→「密钥管理」
   - 创建新密钥对
2. 确认证书路径：
   - 宝塔面板：`/www/server/panel/vhost/ssl/域名目录/`
   - 1Panel 可跳过

## 配置指南

编辑脚本中的以下参数：

```bash
# 多吉云 AccessKey 和 SecretK
ACCESS_KEY="your_access_key_here"   # 替换为你的AccessKey
SECRET_KEY="your_secret_key_here"  # 替换为你的SecretKey

# 证书路径配置
FULLCHAIN_PATH="/path/to/fullchain.pem"  # 全链证书路径
PRIVKEY_PATH="/path/to/privkey.pem"      # 私钥路径

# 域名配置
DOMAINS=("primary.com" "cdn.example.com" "www.example.com")  # 需要绑定的域名列表

# 旧证书处理策略
DELETE_OLD_CERT=false  # true=自动删除旧证书 | false=保留历史证书
```

## 部署指南

### 1Panel

1. 进入证书管理界面
2. 创建/编辑证书：
   - 启用「自动续签」
   - 启用「推送证书到本地目录」
   - 选择目录
   - 启用「申请后执行脚本」
   - 粘贴本脚本内容
   - 修改证书路径为：

      ```sh
      # 证书路径
      FULLCHAIN_PATH="./fullchain.pem"
      PRIVKEY_PATH="./privkey.pem"
      ```

### 宝塔

1. 创建定时任务：
   - 任务类型：Shell 脚本
   - 任务名称：随意
   - 执行周期：每月 1 号 01:30 执行一次
   - 执行用户：root
   - 脚本内容：粘贴本脚本内容

2. 配合自动续签或者定时任务 `/www/server/panel/pyenv/bin/python /www/server/panel/class/acme_v2.py –renew=1` 理论上可以实现放养多吉云 CDN 的证书。

## MIT License
