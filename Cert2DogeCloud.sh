#!/bin/bash

# 多吉云 AccessKey 和 SecretKey
ACCESS_KEY="xxxx"
SECRET_KEY="xxxxxx"

# SSL 证书路径
FULLCHAIN_PATH="/path/to/fullchain.pem"
PRIVKEY_PATH="/path/to/privkey.pem"

# 证书备注名
CURRENT_DATE=$(date +"%y/%m/%d")
NOTE="Certificate $CURRENT_DATE"

# 需要绑定的域名列表
DOMAINS=("primary.com" "cdn.example.com" "www.example.com")

# 是否删除旧证书
DELETE_OLD_CERT=false

ACCESS_TOKEN_CACHE=""

# 生成AccessToken
function generateAccessToken() {
    local apiPath="$1"
    local body="$2"

    if [ -z "$ACCESS_TOKEN_CACHE" ]; then
        local signStr=$(echo -e "${apiPath}\n${body}")
        local sign=$(echo -n "$signStr" | openssl dgst -sha1 -hmac "$SECRET_KEY" | awk '{print $NF}')
        ACCESS_TOKEN_CACHE="$ACCESS_KEY:$sign"
    fi

    echo "$ACCESS_TOKEN_CACHE"
}

function parallelRequest() {
    local url="$1"
    local body="$2"
    local apiPath="$3"
    local accessToken=$(generateAccessToken "$apiPath" "$body")

    curl -s -X POST "$url" \
        -H "Authorization: TOKEN $accessToken" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data "$body"
}

# 获取域名当前绑定的证书ID
function getCurrentCertId() {
    local domain="$1"
    local body="domain=$domain"
    local apiPath="/cdn/domain/info.json"
    local response=$(parallelRequest "https://api.dogecloud.com/cdn/domain/info.json" "$body" "$apiPath")

    local code=$(echo "$response" | jq -r '.code')
    if [ "$code" -eq 200 ]; then
        echo "$(echo "$response" | jq -r '.data.cert_id')"
    else
        echo ""
    fi
}

# 删除证书
function deleteCert() {
    local certId="$1"
    local body="id=$certId"
    local apiPath="/cdn/cert/delete.json"
    local response=$(parallelRequest "https://api.dogecloud.com/cdn/cert/delete.json" "$body" "$apiPath")

    local code=$(echo "$response" | jq -r '.code')
    if [ "$code" -eq 200 ]; then
        echo "证书ID $certId 删除成功。"
    else
        local errMsg=$(echo "$response" | jq -r '.msg')
        echo "证书ID $certId 删除失败，错误代码：$code，错误信息：$errMsg"
    fi
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
    local apiPath="/cdn/cert/upload.json"
    local response=$(parallelRequest "https://api.dogecloud.com/cdn/cert/upload.json" "$body" "$apiPath")

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
    declare -A oldCertIdsMap=()

    # 获取每个域名当前绑定的证书ID
    for domain in "${DOMAINS[@]}"; do
        local currentCertId=$(getCurrentCertId "$domain")
        if [ -n "$currentCertId" ]; then
            oldCertIdsMap["$currentCertId"]=1
        fi
    done

    # 绑定新证书
    for domain in "${DOMAINS[@]}"; do
        (
            local body="id=$certId&domain=$domain"
            local apiPath="/cdn/cert/bind.json"
            local response=$(parallelRequest "https://api.dogecloud.com/cdn/cert/bind.json" "$body" "$apiPath")

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

    if [ "$DELETE_OLD_CERT" = true ]; then
        for oldCertId in "${!oldCertIdsMap[@]}"; do
            if [ "$oldCertId" != "$certId" ]; then
                deleteCert "$oldCertId"
            fi
        done
    fi
}

uploadCert "$NOTE" "$FULLCHAIN_PATH" "$PRIVKEY_PATH"
