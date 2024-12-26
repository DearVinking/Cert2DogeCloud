# Cert2DogeCloud

用于将宝塔 Let's Encrypt 证书上传到多吉云 CDN 并绑定到指定域名。

## 功能

- 生成多吉云 API 访问令牌（AccessToken）
- 上传证书到多吉云 CDN
- 将上传的证书绑定到指定的域名
- 支持删除旧证书（可选功能）

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

- `ACCESS_KEY` 和 `SECRET_KEY`：多吉云的 `AccessKey` 和 `SecretKey`。
- `FULLCHAIN_PATH` 和 `PRIVKEY_PATH`：宝塔面板 Let's Encrypt 证书的全链证书路径和私钥路径。
- `DOMAINS`：需要绑定证书的域名列表。
- `DELETE_OLD_CERT`：是否删除旧证书（默认为 `false`）。设置为 `true` 时，将在成功绑定新证书后删除旧证书。

## MIT
