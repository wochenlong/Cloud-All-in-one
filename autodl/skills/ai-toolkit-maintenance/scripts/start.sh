#!/bin/bash
set -e

# AI-Toolkit UI 启动脚本
# 用法: bash /root/start.sh [--inside-tmux]

# 配置
UI_DIR="/root/ai-toolkit/ui"
LOG_FILE="/tmp/ai-toolkit-ui.log"
UPDATE_MODEL_SCRIPT="${UPDATE_MODEL_SCRIPT:-/root/update-aitoolkitmodel.sh}"
NODE_BIN="/root/.nvm/versions/node/v18.20.8/bin"
CONDA_PROFILE="$HOME/miniconda3/etc/profile.d/conda.sh"
NETWORK_TURBO="/etc/network_turbo"
ENABLE_NETWORK_TURBO="${ENABLE_NETWORK_TURBO:-true}"  # 可设为 false 关闭
PORT="${PORT:-6006}"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[start][INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[start][WARN]${NC} $1"; }
log_error() { echo -e "${RED}[start][ERROR]${NC} $1" >&2; }

prepare_env() {
  # 可开关的学术加速
  if [[ "${ENABLE_NETWORK_TURBO,,}" == "true" ]]; then
    if [ -f "$NETWORK_TURBO" ]; then
      # shellcheck disable=SC1090
      source "$NETWORK_TURBO"
      log_info "已开启学术加速 ($NETWORK_TURBO)"
    else
      log_warn "未找到学术加速配置: $NETWORK_TURBO"
    fi
  else
    log_info "已禁用学术加速 (ENABLE_NETWORK_TURBO=$ENABLE_NETWORK_TURBO)"
  fi

  if [ ! -f "$CONDA_PROFILE" ]; then
    log_error "未找到 conda 初始化脚本: $CONDA_PROFILE"
    exit 1
  fi
  # 激活 conda 环境
  source "$CONDA_PROFILE"
  conda activate ai-toolkit

  # 添加 node 路径
  export PATH="$NODE_BIN:$PATH"

  # 优先使用本地 Mistral 模型
  export MISTRAL_PATH="/root/ai-toolkit/Mistral-Small-3.1-24B-Instruct-2503"
}

# 更新模型符号链接（可重复执行，安全）
update_model_links() {
  if [ -f "$UPDATE_MODEL_SCRIPT" ]; then
    log_info "更新模型符号链接 (脚本: $UPDATE_MODEL_SCRIPT)..."
    bash "$UPDATE_MODEL_SCRIPT" || log_warn "模型符号链接更新脚本执行失败"
  else
    log_warn "未找到模型符号链接脚本: $UPDATE_MODEL_SCRIPT，跳过"
  fi
}

# 停止已占用 6006 的相关进程
stop_existing_processes() {
  log_info "检查并清理已有 UI 进程..."
  local pids
  pids=$(ps aux | grep -E "[c]oncurrently.*${PORT}|[n]ode.*dist/cron/worker\.js|[n]ext.*start.*${PORT}|[n]ext-server" | awk '{print $2}' | tr '\n' ' ')
  if [ -z "$pids" ]; then
    log_info "未发现相关进程"
    return
  fi
  log_warn "发现相关进程: $pids"
  local concurrently_pid
  concurrently_pid=$(ps aux | grep -E "[c]oncurrently.*${PORT}" | awk '{print $2}' | head -1)
  if [ -n "$concurrently_pid" ]; then
    log_info "优雅停止 concurrently ($concurrently_pid)..."
    kill -TERM "$concurrently_pid" 2>/dev/null || true
    sleep 2
  fi
  for pid in $pids; do
    if kill -0 "$pid" 2>/dev/null; then
      log_info "发送 SIGTERM -> $pid"
      kill -TERM "$pid" 2>/dev/null || true
    fi
  done
  sleep 3
  local remaining
  remaining=$(ps aux | grep -E "[c]oncurrently.*${PORT}|[n]ode.*dist/cron/worker\.js|[n]ext.*start.*${PORT}|[n]ext-server" | awk '{print $2}' | tr '\n' ' ')
  if [ -n "$remaining" ]; then
    log_warn "仍有进程存活，SIGKILL: $remaining"
    for pid in $remaining; do
      kill -9 "$pid" 2>/dev/null || true
    done
    sleep 1
  fi
  log_info "进程清理完成"
}

# 检查目录与构建产物
check_ui_ready() {
  if [ ! -d "$UI_DIR" ]; then
    log_error "UI 目录不存在: $UI_DIR"
    exit 1
  fi
  if [ ! -f "$UI_DIR/package.json" ]; then
    log_error "缺少 package.json: $UI_DIR/package.json"
    exit 1
  fi
  if [ ! -f "$UI_DIR/dist/cron/worker.js" ]; then
    log_warn "缺少 dist/cron/worker.js，可能需要先 npm run build"
  fi
  if [ ! -d "$UI_DIR/.next" ]; then
    log_warn "缺少 .next 目录，可能需要先 npm run build"
  fi
  log_info "目录与必要文件检查通过"
}

# 启动 UI
start_ui() {
  cd "$UI_DIR"
  log_info "工作目录: $(pwd)"
  log_info "后台启动 npm run start (PORT=$PORT)，日志: $LOG_FILE"
  export PORT
  nohup npm run start > "$LOG_FILE" 2>&1 &
  UI_PID=$!
  sleep 3
  if kill -0 "$UI_PID" 2>/dev/null; then
    log_info "✅ UI 已启动，PID: $UI_PID"
    log_info "访问: http://localhost:${PORT}"
  else
    log_error "启动失败，查看日志: $LOG_FILE"
    exit 1
  fi
  # 保持与旧行为一致，等待子进程结束以便 tmux 观察
  wait "$UI_PID"
}

main() {
  log_info "启动流程开始 (pid=$$)"
  prepare_env
  update_model_links
  stop_existing_processes
  check_ui_ready
  start_ui
}

# 若不在 tmux 会话中，则以 tmux 方式启动，便于后台查看日志
if [[ "${1:-}" != "--inside-tmux" && -z "${TMUX:-}" ]]; then
  SESSION="${TMUX_SESSION:-aiui}"
  if ! command -v tmux >/dev/null 2>&1; then
    log_error "tmux 未安装，无法创建会话"
    exit 1
  fi
  tmux kill-session -t "${SESSION}" 2>/dev/null || true
  log_info "创建 tmux 会话: ${SESSION}"
  tmux new-session -d -s "${SESSION}" "/bin/bash /root/start.sh --inside-tmux"
  tmux set-option -t "${SESSION}" remain-on-exit on >/dev/null 2>&1 || true
  log_info "查看日志: tmux attach -t ${SESSION}"
  log_info "退出会话但保持运行: Ctrl-b d"
  exit 0
fi

main