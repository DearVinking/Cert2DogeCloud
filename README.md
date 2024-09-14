# LetEncryptToDogeCloud

用于将宝塔 Let's Encrypt 证书上传到多吉云 CDN 并绑定到指定域名。

## 功能

- 生成多吉云 API 访问令牌（AccessToken）
- 上传证书到多吉云 CDN
- 将上传的证书绑定到指定的域名

## 环境要求

- Bash
- OpenSSL
- cURL
- jq (用于处理 JSON 数据)

## 使用方法

### 宝塔计划任务（推荐）

- 任务类型：Shell 脚本
- 任务名称：随意
- 执行周期：每月 1 号 01:30 执行一次
- 执行用户：root
- 脚本内容：`letsencrypt_to_dogecloud.sh` 内容

配合自动续签Let’s Encrypt 证书定时任务 `/www/server/panel/pyenv/bin/python /www/server/panel/class/acme_v2.py –renew=1` 理论上可以实现放养多吉云 CDN 的证书。

## 配置说明

在脚本中，需要配置以下变量：

`ACCESS_KEY` 和 `SECRET_KEY`：多吉云的 `AccessKey ` 和 `SecretKey`。

`FULLCHAIN_PATH` 和 `PRIVKEY_PATH`：宝塔面板 Let's Encrypt 证书的全链证书路径和私钥路径。

`DOMAINS`：需要绑定证书的域名列表。

## 脚本结构

`generateAccessToken` 函数：生成用于 API 调用的 `AccessToken`。

`uploadCert` 函数：上传证书到多吉云。

`bindCert` 函数：将证书绑定到指定域名。

## MIT
