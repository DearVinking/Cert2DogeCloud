#!/bin/bash

# 多吉云 AccessKey 和 SecretKey
ACCESS_KEY="xxxx"
SECRET_KEY="xxxxxx"

# 宝塔面板Let's Encrypt证书路径
FULLCHAIN_PATH="/www/server/panel/vhost/ssl/xxxxxxx/fullchain.pem"
PRIVKEY_PATH="/www/server/panel/vhost/ssl/xxxxxxx/privkey.pem"

# 证书备注名
CURRENT_DATE=$(date +"%y/%m/%d")
NOTE="Certificate $CURRENT_DATE"

# 需要绑定的域名列表
DOMAINS=("xxxxx.com" "cdn.xxxxx.com" "www.xxxxx.com")

# 生成AccessToken
function generateAccessToken() {
    local apiPath="$1"
    local body="$2"
    local signStr=$(echo -e "${apiPath}\n${body}")
    local sign=$(echo -n "$signStr" | openssl dgst -sha1 -hmac "$SECRET_KEY" | awk '{print $NF}')
    local accessToken="$ACCESS_KEY:$sign"

    echo "$accessToken"
}

# 上传证书到多吉云
function uploadCert() {
    local note="$1"
    local certFile="$2"
    local privateKeyFile="$3"
    local certContent=$(<"$certFile")
    local privateKeyContent=$(<"$privateKeyFile")
    local encodedCert=$(echo "$certContent" | jq -sRr @uri)
    local encodedPrivateKey=$(echo "$privateKeyContent" | jq -sRr @uri)
    local body="note=$note&cert=$encodedCert&private=$encodedPrivateKey"
    local accessToken=$(generateAccessToken "/cdn/cert/upload.json" "$body")
    local response=$(curl -s -X POST "https://api.dogecloud.com/cdn/cert/upload.json"  \
         -H "Authorization: TOKEN $accessToken" \
         -H "Content-Type: application/x-www-form-urlencoded" \
         --data "$body")

    local code=$(echo "$response" | jq -r '.code')

    if [ "$code" -eq 200 ]; then
        echo "证书上传成功！"
        local certId=$(echo "$response" | jq -r '.data.id')
        echo "证书ID：$certId"
        bindCert "$certId"
    else
        local errMsg=$(echo "$response" | jq -r '.msg')
        echo "证书上传失败，错误代码：$code，错误信息：$errMsg"
    fi
}

# 绑定证书到域名
function bindCert() {
    local certId="$1"
    local responses=()

    for domain in "${DOMAINS[@]}"; do
        (
            local body="id=$certId&domain=$domain"
            local accessToken=$(generateAccessToken "/cdn/cert/bind.json" "$body")
            local response=$(curl -s -X POST "https://api.dogecloud.com/cdn/cert/bind.json"  \
                 -H "Authorization: TOKEN $accessToken" \
                 -H "Content-Type: application/x-www-form-urlencoded" \
                 --data "$body")
            local code=$(echo "$response" | jq -r '.code')

            if [ "$code" -eq 200 ]; then
                echo "证书已成功绑定到 $domain"
            else
                local errMsg=$(echo "$response" | jq -r '.msg')
                echo "绑定证书到 $domain 失败，错误代码：$code，错误信息：$errMsg"
            fi
        ) &
    done

    wait
}

uploadCert "$NOTE" "$FULLCHAIN_PATH" "$PRIVKEY_PATH"
