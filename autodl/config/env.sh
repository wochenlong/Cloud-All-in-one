#!/bin/bash
# AutoDL 镜像统一环境配置
# 用法: source config/env.sh

# GPU 设置
export CUDA_VISIBLE_DEVICES=0
export NCCL_P2P_DISABLE=1
export NCCL_IB_DISABLE=1

# HuggingFace 离线模式（使用本地/共享模型）
export HF_HUB_OFFLINE=1
export DISABLE_TELEMETRY=YES

# 端口（AutoDL 仅开放 6006）
export PORT="${PORT:-6006}"

# 路径
export AI_TOOLKIT_DIR="/root/ai-toolkit"
export AI_TOOLKIT_UI_DIR="/root/ai-toolkit/ui"
export AUTODL_SHARED_DIR="/.autodl-model/data"
export AUTODL_DATA_DIR="/root/autodl-tmp"
export NODE_BIN="/root/.nvm/versions/node/v18.20.8/bin"
export CONDA_PROFILE="$HOME/miniconda3/etc/profile.d/conda.sh"
export CONDA_ENV="ai-toolkit"

# Mistral 本地模型路径
export MISTRAL_PATH="/root/ai-toolkit/Mistral-Small-3.1-24B-Instruct-2503"

# 网络加速
enable_turbo() {
  if [ -f /etc/network_turbo ]; then
    source /etc/network_turbo
    echo "[env] 已开启学术加速"
  fi
}

disable_turbo() {
  unset http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY
  echo "[env] 已关闭学术加速"
}

# 激活 conda + node 环境
activate_env() {
  if [ -f "$CONDA_PROFILE" ]; then
    source "$CONDA_PROFILE"
    conda activate "$CONDA_ENV"
  fi
  export PATH="$NODE_BIN:$PATH"
}
