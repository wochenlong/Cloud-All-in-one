#!/bin/bash

# AI-Toolkit 模型符号链接更新脚本
# 用于在启动时自动创建模型符号链接，从 /.autodl-model/data/ 到 /root/autodl-tmp/
# 如果符号链接已存在则跳过，不存在则创建

# 日志函数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# 重定义 ln 命令，自动添加检查和日志
ln() {
    # 只处理 ln -s 命令
    if [ "$1" != "-s" ] || [ -z "$2" ] || [ -z "$3" ]; then
        # 如果不是 ln -s 格式，调用原始命令
        command ln "$@"
        return $?
    fi
    
    local source_path="$2"
    local target_path="$3"
    
    # 检查源文件是否存在
    if [ ! -e "$source_path" ]; then
        log_warn "源文件不存在，跳过: $source_path -> $target_path"
        skipped_count=$((skipped_count + 1))
        return 0
    fi
    
    # 检查目标路径是否已存在
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ -L "$target_path" ]; then
            # 获取符号链接指向的原始路径（不解析，因为可能指向不存在的文件）
            current_link=$(readlink "$target_path" 2>/dev/null)
            # 检查符号链接指向的文件是否存在
            current_target=$(readlink -f "$target_path" 2>/dev/null)
            source_real=$(readlink -f "$source_path" 2>/dev/null)
            
            # 如果符号链接指向的文件不存在，删除旧的符号链接
            if [ -z "$current_target" ] || [ ! -e "$current_target" ]; then
                log_warn "符号链接指向不存在的文件，删除旧链接: $target_path -> $current_link"
                rm -f "$target_path"
                # 继续创建新的符号链接
            elif [ "$current_target" = "$source_real" ] && [ -n "$current_target" ] && [ -n "$source_real" ]; then
                # 符号链接已存在且指向正确的源
                log_info "符号链接已存在且正确，跳过: $target_path"
                skipped_count=$((skipped_count + 1))
                return 0
            else
                # 符号链接指向不同的目标，删除并重新创建
                log_warn "符号链接指向不同目标，删除旧链接: $target_path -> $current_link"
                rm -f "$target_path"
                # 继续创建新的符号链接
            fi
        else
            log_warn "目标路径已存在但不是符号链接，跳过: $target_path"
            skipped_count=$((skipped_count + 1))
            return 0
        fi
    fi
    
    # 创建目标目录（如果不存在）
    target_dir=$(dirname "$target_path")
    if [ ! -d "$target_dir" ]; then
        log_info "创建目录: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # 创建符号链接
    log_info "创建符号链接: $source_path -> $target_path"
    if command ln -s "$source_path" "$target_path" 2>/dev/null; then
        created_count=$((created_count + 1))
        return 0
    else
        log_error "创建符号链接失败: $source_path -> $target_path"
        error_count=$((error_count + 1))
        return 1
    fi
}

log_info "开始更新 AI-Toolkit 模型符号链接..."

# 计数器
created_count=0
skipped_count=0
error_count=0

# 更新 AI-Toolkit 模型符号链接
update_aitoolkit_model_links() {
    log_info "更新 AI-Toolkit 模型符号链接..."
    
    # AI-Toolkit 模型列表（源路径 -> 目标路径）
    # 格式：源路径在 /.autodl-model/data/ 下，目标路径在 /root/autodl-tmp/ 下
    local models=(
        "black-forest-labs/FLUX.1-dev"
        "black-forest-labs/FLUX.1-Kontext-dev"
        "black-forest-labs/FLUX.2-dev"
        "black-forest-labs/FLUX.2-klein-base-4B"
        "black-forest-labs/FLUX.2-klein-base-9B"
        "Qwen/Qwen-Image"
        "Qwen/Qwen-Image-Edit-2509"
        "Qwen/Qwen-Image-Edit-2511"
        "Qwen/Qwen-Image-2512"
        "Tongyi-MAI/Z-Image-Turbo"
        "ostris/Z-Image-De-Turbo"
        "ai-toolkit/Wan2.2-T2V-A14B-Diffusers-bf16"
        "ai-toolkit/Wan2.2-I2V-A14B-Diffusers-bf16"
        "Lightricks/LTX-2"
        "Qwen/Qwen3-4B"
        "Qwen/Qwen3-8B"
        "mistralai/Mistral-Small-3.1-24B-Instruct-2503"
    )
    
    for model in "${models[@]}"; do
        local source_path="/.autodl-model/data/${model}"
        local target_path="/root/ai-toolkit/${model}"
        
        # 使用重定义的 ln 函数创建符号链接
        ln -s "$source_path" "$target_path"
    done
    
    log_info "AI-Toolkit 模型符号链接更新完成"
}

# 更新 AI-Toolkit 模型符号链接
update_aitoolkit_model_links

# 输出统计信息
log_info "符号链接更新完成"
log_info "创建: $created_count 个"
log_info "跳过: $skipped_count 个"
log_info "错误: $error_count 个"

exit 0
