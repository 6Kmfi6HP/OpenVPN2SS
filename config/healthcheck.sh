#!/bin/sh

# 测试 OpenVPN 接口是否启动
if ! ip link show tun0 >/dev/null 2>&1; then
    echo "OpenVPN interface tun0 is not up"
    exit 1
fi

# 测试 DNS 解析
if ! nslookup google.com >/dev/null 2>&1; then
    echo "DNS resolution failed"
    exit 1
fi

# 测试网络连通性（使用多个目标以提高可靠性）
TARGETS="8.8.8.8 1.1.1.1"
for target in $TARGETS; do
    if ping -c 1 -W 3 $target >/dev/null 2>&1; then
        echo "Network is healthy"
        exit 0
    fi
done

echo "Network connectivity check failed"
exit 1 