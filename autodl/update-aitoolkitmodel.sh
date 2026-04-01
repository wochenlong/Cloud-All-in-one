#!/bin/bash

# AI-Toolkit 模型符号链接更新脚本
# 用于在启动时自动创建模型符号链接，从 /.autodl-model/data/ 到 /root/ai-toolkit/
# 如果符号链接已存在则跳过，不存在则创建

export CUDA_VISIBLE_DEVICES=0
export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1
export HF_HUB_OFFLINE=1
export DISABLE_TELEMETRY=YES

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
            # 检查符号链接指向的文件是否存在（使用 readlink -f 解析最终路径）
            current_target=$(readlink -f "$target_path" 2>/dev/null)
            source_real=$(readlink -f "$source_path" 2>/dev/null)
            
            # 如果符号链接指向的文件不存在，删除旧的符号链接
            if [ -z "$current_target" ] || [ ! -e "$current_target" ]; then
                log_warn "符号链接指向不存在的文件，删除旧链接: $target_path -> $current_link"
                rm -f "$target_path" 2>/dev/null || {
                    log_warn "删除旧链接失败（可能是只读文件系统），跳过: $target_path"
                    skipped_count=$((skipped_count + 1))
                    return 0
                }
                # 继续创建新的符号链接
            elif [ -n "$current_target" ] && [ -n "$source_real" ] && [ "$current_target" = "$source_real" ]; then
                # 符号链接已存在且指向正确的源（最终路径相同）
                log_info "符号链接已存在且正确，跳过: $target_path"
                skipped_count=$((skipped_count + 1))
                return 0
            else
                # 符号链接指向不同的目标，删除并重新创建
                log_warn "符号链接指向不同目标，删除旧链接: $target_path -> $current_link (实际: $current_target)"
                rm -f "$target_path" 2>/dev/null || {
                    log_warn "删除旧链接失败（可能是只读文件系统），跳过: $target_path"
                    skipped_count=$((skipped_count + 1))
                    return 0
                }
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
        # 检查是否是只读文件系统错误
        local error_msg=$(command ln -s "$source_path" "$target_path" 2>&1)
        if echo "$error_msg" | grep -q "Read-only file system"; then
            log_warn "创建符号链接失败（只读文件系统）: $source_path -> $target_path"
            skipped_count=$((skipped_count + 1))
            return 0
        else
            log_error "创建符号链接失败: $source_path -> $target_path ($error_msg)"
            error_count=$((error_count + 1))
            return 1
        fi
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
    # 格式：源路径在 /.autodl-model/data/ 下，目标路径在 /root/ai-toolkit/ 下
    local models=(
        # Tongyi-MAI 模型
        "Tongyi-MAI/Z-Image-Turbo"
        "Tongyi-MAI/Z-Image"
        # Mistral 模型
        "mistralai/Mistral-Small-3.1-24B-Instruct-2503"
        # Black Forest Labs 模型
        "black-forest-labs/FLUX.1-dev"
        "black-forest-labs/FLUX.1-Kontext-dev"
        "black-forest-labs/FLUX.2-dev"
        "black-forest-labs/FLUX.2-klein-base-4B"
        "black-forest-labs/FLUX.2-klein-base-9B"
        # Qwen 模型
        "Qwen/Qwen-Image"
        "Qwen/Qwen-Image-Edit-2509"
        "Qwen/Qwen-Image-Edit-2511"
        "Qwen/Qwen-Image-2512"
        "Qwen/Qwen3-4B"
        "Qwen/Qwen3-8B"
        # Ostris 模型
        "ostris/Z-Image-De-Turbo"
        # AI Toolkit 模型
        "ai-toolkit/Wan2.2-T2V-A14B-Diffusers-bf16"
        "ai-toolkit/Wan2.2-I2V-A14B-Diffusers-bf16"
        # Lightricks 模型
        "Lightricks/LTX-2"
        "Lightricks/LTX-2.3"
        # Lodestones 模型
        "lodestones/Zeta-Chroma"
    )
    
    for model in "${models[@]}"; do
        local source_path="/.autodl-model/data/${model}"
        local target_path="/root/ai-toolkit/${model}"
        
        # 使用重定义的 ln 函数创建符号链接
        ln -s "$source_path" "$target_path"
    done
    
    log_info "AI-Toolkit 模型符号链接更新完成"
}

# 为 FLUX.2-klein 模型创建 VAE 符号链接
update_flux2_klein_vae_links() {
    log_info "更新 FLUX.2-klein VAE 符号链接..."
    
    # VAE 源文件路径
    local vae_source="/.autodl/black-forest-labs/FLUX.2-dev/ae.safetensors"
    
    # 检查 VAE 源文件是否存在
    if [ ! -f "$vae_source" ]; then
        log_warn "VAE 源文件不存在，跳过 VAE 符号链接创建: $vae_source"
        return 0
    fi
    
    # FLUX.2-klein 模型列表（需要创建 ae.safetensors 符号链接）
    local flux2_klein_models=(
        "black-forest-labs/FLUX.2-klein-base-4B"
        "black-forest-labs/FLUX.2-klein-base-9B"
    )
    
    for model in "${flux2_klein_models[@]}"; do
        # 目标路径和源路径
        local target_model_path="/root/ai-toolkit/${model}"
        local source_model_path="/.autodl-model/data/${model}"
        local vae_link="${target_model_path}/ae.safetensors"
        
        # 确定源目录路径（如果目标路径是符号链接，解析它）
        if [ -L "$target_model_path" ]; then
            source_model_path=$(readlink -f "$target_model_path" 2>/dev/null)
            if [ -z "$source_model_path" ] || [ ! -d "$source_model_path" ]; then
                log_warn "无法解析符号链接指向的路径，跳过: $target_model_path"
                skipped_count=$((skipped_count + 1))
                continue
            fi
        fi
        
        # 检查源目录是否存在
        if [ ! -d "$source_model_path" ]; then
            log_warn "源目录不存在，跳过: $source_model_path"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        
        # 如果目标路径是符号链接，删除它并创建实际目录
        if [ -L "$target_model_path" ]; then
            log_info "删除符号链接并创建实际目录: $target_model_path"
            rm -f "$target_model_path" 2>/dev/null || {
                log_warn "删除符号链接失败，跳过: $target_model_path"
                skipped_count=$((skipped_count + 1))
                continue
            }
        fi
        
        # 创建实际目录（如果不存在）
        if [ ! -d "$target_model_path" ]; then
            log_info "创建目录: $target_model_path"
            mkdir -p "$target_model_path" 2>/dev/null || {
                log_warn "创建目录失败，跳过: $target_model_path"
                skipped_count=$((skipped_count + 1))
                continue
            }
        fi
        
        # 在目录中创建指向源目录文件的符号链接
        log_info "创建文件符号链接: $source_model_path -> $target_model_path"
        local link_count=0
        local skip_file_count=0
        
        # 遍历源目录中的文件和子目录
        while IFS= read -r item; do
            local item_name=$(basename "$item")
            local source_item="${source_model_path}/${item_name}"
            local target_item="${target_model_path}/${item_name}"
            
            # 跳过已存在的项（避免覆盖）
            if [ -e "$target_item" ] || [ -L "$target_item" ]; then
                skip_file_count=$((skip_file_count + 1))
                continue
            fi
            
            # 创建符号链接（从目标目录指向源目录）
            if ln -s "$source_item" "$target_item" 2>/dev/null; then
                link_count=$((link_count + 1))
            else
                log_warn "创建文件符号链接失败: $source_item -> $target_item"
            fi
        done < <(find "$source_model_path" -maxdepth 1 -mindepth 1 2>/dev/null)
        
        if [ $link_count -gt 0 ]; then
            log_info "创建了 $link_count 个文件符号链接"
        fi
        if [ $skip_file_count -gt 0 ]; then
            log_info "跳过了 $skip_file_count 个已存在的项"
        fi
        
        # 检查符号链接是否已存在且正确
        if [ -L "$vae_link" ]; then
            local current_target=$(readlink -f "$vae_link" 2>/dev/null)
            local source_real=$(readlink -f "$vae_source" 2>/dev/null)
            
            if [ -n "$current_target" ] && [ -n "$source_real" ] && [ "$current_target" = "$source_real" ]; then
                log_info "VAE 符号链接已存在且正确，跳过: $vae_link"
                skipped_count=$((skipped_count + 1))
                continue
            else
                log_warn "VAE 符号链接指向不同目标，删除旧链接: $vae_link -> $(readlink "$vae_link")"
                rm -f "$vae_link" 2>/dev/null || {
                    log_warn "删除旧链接失败，跳过: $vae_link"
                    skipped_count=$((skipped_count + 1))
                    continue
                }
            fi
        elif [ -f "$vae_link" ]; then
            log_warn "目标路径已存在但不是符号链接，跳过: $vae_link"
            skipped_count=$((skipped_count + 1))
            continue
        fi
        
        # 创建符号链接
        log_info "创建 VAE 符号链接: $vae_source -> $vae_link"
        if command ln -s "$vae_source" "$vae_link" 2>/dev/null; then
            created_count=$((created_count + 1))
        else
            local error_msg=$(command ln -s "$vae_source" "$vae_link" 2>&1)
            # 检查是否是只读文件系统错误
            if echo "$error_msg" | grep -q "Read-only file system"; then
                log_warn "创建 VAE 符号链接失败（只读文件系统）: $vae_link"
                log_info "提示: 代码已支持从 vae 子目录读取 VAE 文件，训练可以正常进行"
                skipped_count=$((skipped_count + 1))
            else
                log_error "创建 VAE 符号链接失败: $vae_link ($error_msg)"
                error_count=$((error_count + 1))
            fi
        fi
    done
    
    log_info "FLUX.2-klein VAE 符号链接更新完成"
}

# 更新精度恢复适配器符号链接
update_accuracy_recovery_adapters() {
    log_info "更新精度恢复适配器符号链接..."
    
    # 精度恢复适配器列表（源路径 -> 目标路径）
    # 格式：源路径在 /.autodl/ 下（使用哈希路径），目标路径在 /root/ai-toolkit/ostris/accuracy_recovery_adapters/ 下
    local adapters=(
        "af/8e/96/af8e960132155123034c31cd7ddf9e4d|qwen_image_edit_2511_torchao_uint3.safetensors"
        "af/c8/d9/afc8d932cdfa4e31771b3a088230814d|wan22_14b_t2i_torchao_uint4.safetensors"
        "a7/fe/bb/a7febb52c1c1110e78b512e43d51a6dc|wan22_14b_t2i_torchao_uint3.safetensors"
        "0e/2d/20/0e2d2013c0ec4e560e198a90be4a024b|wan22_14b_i2v_torchao_uint4.safetensors"
        "b6/ca/a8/b6caa8144982bb3e98cd97e659e8b3ce|wan22_14b_i2v_torchao_uint3.safetensors"
        "02/9d/55/029d5568e2f892f6f08d417cf8017372|qwen_image_torchao_uint3.safetensors"
        "ed/1a/26/ed1a26f54f3bb70702079846d7640f77|qwen_image_edit_torchao_uint3.safetensors"
        "ff/15/ba/ff15ba1800ca4ccc465e1423094cf88c|qwen_image_edit_2509_torchao_uint3.safetensors"
        "fa/02/48/fa0248348a4f9cfa94d763ed98380f73|qwen_image_2512_torchao_uint3.safetensors"
        "4c/8b/02/4c8b02c61ba7bb9ebe821bfa968eaa1a|qwen_image_2512_torchao_uint4.safetensors"
        "40/9e/83/409e83f90accf035481b5c3ce2c40b63|hidream_i1_full_torchao_uint3.safetensors"
        "7a/cc/8d/7acc8d1e0038c0159bb51cd1ff721595|flux1_dev_kontext_torchao_uint3.safetensors"
    )
    
    # 创建目标目录
    local target_dir="/root/ai-toolkit/ostris/accuracy_recovery_adapters"
    mkdir -p "$target_dir"
    
    for adapter in "${adapters[@]}"; do
        IFS='|' read -r source_hash target_name <<< "$adapter"
        local source_path="/.autodl/${source_hash}"
        local target_path="${target_dir}/${target_name}"
        
        # 使用重定义的 ln 函数创建符号链接
        ln -s "$source_path" "$target_path"
    done
    
    log_info "精度恢复适配器符号链接更新完成"
}

# 更新训练适配器符号链接
update_training_adapters() {
    log_info "更新训练适配器符号链接..."
    
    # 训练适配器列表（源路径 -> 目标路径）
    local adapters=(
        "ostris/zimage_turbo_training_adapter/zimage_turbo_training_adapter_v1.safetensors|zimage_turbo_training_adapter_v1.safetensors"
        "d0/27/eb/d027ebd615353732579a346a3d5d36f1|zimage_turbo_training_adapter_v2.safetensors"
    )
    
    # 创建目标目录
    local target_dir="/root/ai-toolkit/ostris/zimage_turbo_training_adapter"
    mkdir -p "$target_dir"
    
    for adapter in "${adapters[@]}"; do
        IFS='|' read -r source_path_rel target_name <<< "$adapter"
        local source_path="/.autodl/${source_path_rel}"
        local target_path="${target_dir}/${target_name}"
        
        # 使用重定义的 ln 函数创建符号链接
        ln -s "$source_path" "$target_path"
    done
    
    log_info "训练适配器符号链接更新完成"
}

# 更新 AI-Toolkit 模型符号链接
update_aitoolkit_model_links

# 更新精度恢复适配器符号链接
update_accuracy_recovery_adapters

# 更新训练适配器符号链接
update_training_adapters

# 更新 FLUX.2-klein VAE 符号链接
update_flux2_klein_vae_links

# 输出统计信息
log_info "符号链接更新完成"
log_info "创建: $created_count 个"
log_info "跳过: $skipped_count 个"
log_info "错误: $error_count 个"

exit 0
