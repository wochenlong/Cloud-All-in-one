#!/bin/bash
set -euo pipefail

APP_DIR=/root/ai-toolkit
UI_DIR=$APP_DIR/ui
CONDA_SH=/root/miniconda3/etc/profile.d/conda.sh
ENV=ai-toolkit
NODE_BIN=/root/.nvm/versions/node/v18.20.8/bin
NETWORK_TURBO=/etc/network_turbo
# 默认开启学术加速用于 git/pip/npm install；构建阶段可单独关闭
ENABLE_NETWORK_TURBO=${ENABLE_NETWORK_TURBO:-true}
# 构建阶段是否关闭加速（避免 Google Fonts 证书问题）
DISABLE_TURBO_FOR_BUILD=${DISABLE_TURBO_FOR_BUILD:-true}
GIT_HTTP_VERSION=${GIT_HTTP_VERSION:-HTTP/1.1}
# 默认关闭自签跳过，保持 TLS 校验；若需绕过设为 true
ALLOW_SELF_SIGNED_CERT=${ALLOW_SELF_SIGNED_CERT:-false}

LOG=/var/log/ai-toolkit-ui.log
PID=/run/ai-toolkit-ui.pid
REQ=requirements.txt
PORT=6006

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
log_info(){ echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error(){ echo -e "${RED}[ERROR]${NC} $1" >&2; }

cleanup() {
  [ -n "${BACKUP_DIR:-}" ] && [ -d "$BACKUP_DIR" ] && rm -rf "$BACKUP_DIR"
}
trap cleanup EXIT

# optional network turbo
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

disable_network_turbo_for_build() {
  # 尝试清空常见代理环境变量，确保构建阶段不用学术加速
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY ftp_proxy FTP_PROXY no_proxy NO_PROXY
  log_info "构建阶段已关闭学术加速（清除代理环境变量）"
}

# conda + node
if [ ! -f "$CONDA_SH" ]; then
  log_error "未找到 conda 初始化脚本: $CONDA_SH"
  exit 1
fi
source "$CONDA_SH" && conda activate "$ENV"
export PATH="$NODE_BIN:$PATH"
# 优先使用本地 Mistral 模型
export MISTRAL_PATH="/root/ai-toolkit/Mistral-Small-3.1-24B-Instruct-2503"

# --- Git update policy (保留关键本地改动) ---
cd "$APP_DIR"
export GIT_HTTP_VERSION

# 需要保留的本地文件列表（避免被远端覆盖）
PRESERVE_FILES=(
#  "extensions_built_in/diffusion_models/flux2/flux2_model.py"
  "ui/package.json"
)

BACKUP_DIR="$(mktemp -d)"
for f in "${PRESERVE_FILES[@]}"; do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp "$f" "$BACKUP_DIR/$f"
  fi
done

# 拉取更新，自动暂存本地改动再 rebase
git pull --rebase --autostash

# 还原需保留的本地文件（确保本地版本不被覆盖）
for f in "${PRESERVE_FILES[@]}"; do
  if [ -f "$BACKUP_DIR/$f" ]; then
    cp "$BACKUP_DIR/$f" "$f"
  fi
done
# 强制确保 ui/package.json 的 start 端口为目标值
python - <<'PY'
import json, pathlib
p = pathlib.Path("/root/ai-toolkit/ui/package.json")
data = json.loads(p.read_text())
desired = 'concurrently --restart-tries -1 --restart-after 1000 -n WORKER,UI "node dist/cron/worker.js" "next start --port ${PORT:-6006}"'
scripts = data.get("scripts", {})
if scripts.get("start") != desired:
    scripts["start"] = desired
    data["scripts"] = scripts
    p.write_text(json.dumps(data, indent=2) + "\n")
PY
# -------------------------------------------

# deps + build

# 1) Python 依赖（在项目根目录，使用 conda 环境的 pip）
cd "$APP_DIR"
if [ -f "$REQ" ]; then
  log_info "更新 Python 依赖 (conda env: $ENV) ..."
  pip install -r "$REQ"
fi

# 2) Node 依赖 + UI 构建
cd "$UI_DIR"
# node 依赖：尽量复用缓存并跳过 audit，提高速度
npm install --prefer-offline --no-audit
# Prisma client 重新生成 + schema 同步（上游 schema 变更时必需）
npm run update_db
if [[ "${DISABLE_TURBO_FOR_BUILD,,}" == "true" ]]; then
  disable_network_turbo_for_build
fi
if [[ "${ALLOW_SELF_SIGNED_CERT,,}" == "true" ]]; then
  export NODE_TLS_REJECT_UNAUTHORIZED=0
  log_warn "构建时已关闭 TLS 证书校验 (ALLOW_SELF_SIGNED_CERT=true)"
fi
npm run build

# restart ui
if [ -f "$PID" ]; then
  OLD_PID=$(cat "$PID" || true)
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    log_info "停止旧进程: $OLD_PID"
    kill "$OLD_PID" 2>/dev/null || true
    sleep 2
    if kill -0 "$OLD_PID" 2>/dev/null; then
      log_warn "旧进程未退出，强制终止: $OLD_PID"
      kill -9 "$OLD_PID" 2>/dev/null || true
    fi
  fi
fi

# 端口占用检查
if command -v ss >/dev/null 2>&1; then
  if ss -ltn "( sport = :$PORT )" | grep -q "$PORT"; then
    log_warn "端口 $PORT 仍被占用，尝试强制清理"
    fuser -k "$PORT"/tcp 2>/dev/null || true
    sleep 1
  fi
elif command -v netstat >/dev/null 2>&1; then
  if netstat -ltn 2>/dev/null | awk '{print $4}' | grep -q ":$PORT$"; then
    log_warn "端口 $PORT 仍被占用，尝试强制清理"
    fuser -k "$PORT"/tcp 2>/dev/null || true
    sleep 1
  fi
else
  log_warn "未找到 ss/netstat，跳过端口占用检查"
fi

nohup npm run start -- --port "$PORT" >> "$LOG" 2>&1 &
echo $! > "$PID"

echo "OK. pid=$(cat "$PID")  port=$PORT  log=$LOG"
