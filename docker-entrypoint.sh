#!/bin/sh

# 设置信号处理
trap 'kill $(jobs -p)' SIGTERM SIGINT

# 初始化配置管理
. /etc/openvpn-config/config_manager.sh

# 启动OpenVPN
start_openvpn() {
    echo "Starting OpenVPN..."
    nohup openvpn --config /etc/openvpn-config/openvpn.ovpn --askpass /etc/openvpn-config/pass.txt >>/var/log/custom/ovpn.log &
    sleep 8
}

# 启动Shadowsocks
start_shadowsocks() {
    echo "Starting Shadowsocks..."
    nohup ssserver -c /etc/shadowsocks.json &
    sleep 2
}

# 主循环
while true; do
    # 启动服务
    start_openvpn
    start_shadowsocks

    # 等待服务启动
    sleep 10

    # 监控循环
    while true; do
        if ! /etc/openvpn-config/healthcheck.sh; then
            echo "Health check failed"
            increment_retry_count
            
            # 如果重试次数未达到最大值，重启当前配置
            if [ "$(cat $RETRY_COUNT_FILE)" -lt "$MAX_RETRIES" ]; then
                echo "Restarting services..."
                kill $(jobs -p) 2>/dev/null
                break
            fi
            
            # 如果达到最大重试次数，会自动切换到下一个配置
            # config_manager.sh 中的 increment_retry_count 会处理切换
            kill $(jobs -p) 2>/dev/null
            break
        fi
        sleep 30
    done
done
