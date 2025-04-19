#!/bin/sh

CONFIG_DIR="/etc/openvpn-config"
CURRENT_CONFIG_FILE="$CONFIG_DIR/current_config"
RETRY_COUNT_FILE="$CONFIG_DIR/retry_count"
MAX_RETRIES=3

# 初始化重试计数
init_retry_count() {
    echo "0" > "$RETRY_COUNT_FILE"
}

# 获取当前配置索引
get_current_config_index() {
    if [ -f "$CURRENT_CONFIG_FILE" ]; then
        cat "$CURRENT_CONFIG_FILE"
    else
        echo "0"
    fi
}

# 获取可用配置文件列表
get_available_configs() {
    find "$CONFIG_DIR" -name "*.ovpn" -type f | sort
}

# 切换到下一个配置
switch_to_next_config() {
    current_index=$(get_current_config_index)
    configs=$(get_available_configs)
    total_configs=$(echo "$configs" | wc -l)

    # 计算下一个配置索引
    next_index=$((current_index + 1))
    if [ "$next_index" -ge "$total_configs" ]; then
        next_index=0
    fi

    # 保存新的配置索引
    echo "$next_index" > "$CURRENT_CONFIG_FILE"

    # 获取新的配置文件路径
    new_config=$(echo "$configs" | sed -n "$((next_index + 1))p")
    
    # 创建符号链接到新的配置
    ln -sf "$new_config" "$CONFIG_DIR/openvpn.ovpn"

    echo "Switched to config: $new_config"
    
    # 重置重试计数
    init_retry_count
}

# 增加重试计数
increment_retry_count() {
    current_retries=$(cat "$RETRY_COUNT_FILE")
    new_retries=$((current_retries + 1))
    echo "$new_retries" > "$RETRY_COUNT_FILE"
    
    if [ "$new_retries" -ge "$MAX_RETRIES" ]; then
        echo "Max retries reached, switching to next config..."
        switch_to_next_config
    else
        echo "Retry attempt $new_retries of $MAX_RETRIES"
    fi
}

# 初始化配置（如果是首次运行）
if [ ! -f "$CURRENT_CONFIG_FILE" ]; then
    echo "Initializing configuration..."
    echo "0" > "$CURRENT_CONFIG_FILE"
    init_retry_count
    switch_to_next_config
fi 