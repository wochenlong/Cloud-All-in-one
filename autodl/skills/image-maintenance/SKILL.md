---
name: image-maintenance
description: AI-Toolkit AutoDL 镜像维护。更新 ai-toolkit 代码（保留本地修改）、保存镜像前检查、环境修复。
---

# AI-Toolkit 镜像维护

本 skill 只适用于 `image-profiles/ai-toolkit.toml`。其他 AutoDL 镜像先使用 `autodl-common`，不要套用这里的 `/root/ai-toolkit` 更新流程。

## 本地修改清单（更新代码时必须保留）

| 文件 | 改了什么 |
|---|---|
| `ui/package.json` | start 端口 → `${PORT:-6006}` |
| `flux2/flux2_model.py` | 引入 `local_config` 做本地模型路径解析 |
| `flux2/flux2_klein_model.py` | 环境变量支持本地 VAE/Qwen3 路径 |
| `.gitignore` | 添加 `local_config.py` |

### 安全更新流程

```bash
source /etc/network_turbo
cd /root/ai-toolkit

# 1. 代码更新（保留本地修改）
git stash push -m "local-mods"
git pull origin main
git stash pop
# 有冲突则手动解决，优先保留本地逻辑

# 2. Python 依赖更新（必须在 conda 环境中执行）
conda activate ai-toolkit
pip install -r requirements.txt

# 3. UI 依赖 + 数据库 + 构建 + 启动
cd ui
npm install --prefer-offline --no-audit
npm run update_db          # Prisma schema 同步，上游变更时必需
npm run build
npm run start
```

> **一键方式**: 也可以直接运行 `/root/update_restart.sh`，它会按上述顺序自动完成全部步骤。

## 保存镜像前检查

1. **停服务**: `tmux kill-session -t aiui`
2. **清缓存**: `pip cache purge && conda clean -a -y && rm -rf ~/.cache/huggingface/hub/`
3. **查空间**: `df -h /`（系统盘 30G，建议 < 24G）
4. **确认无大模型文件误存系统盘**: `find /root/ai-toolkit -name "*.safetensors" -not -type l -size +100M`
5. **验证本地修改完整**: `cd /root/ai-toolkit && git diff --stat`（应有 4 个文件）

## 关键环境信息

| 项目 | 值 |
|---|---|
| conda 环境 | `ai-toolkit`（Python 3.10） |
| venv 符号链接 | `/root/ai-toolkit/venv` → conda 环境，Worker 通过此链接找到正确的 Python |
| Node.js | `/root/.nvm/versions/node/v18.20.8/bin` |
| Python 包 | `/root/ai-toolkit/requirements.txt`（git pull 后必须 `pip install -r`） |
| 端口 | 6006（`~/.bashrc` 中 `export PORT=6006`） |
| 更新脚本 | `/root/update_restart.sh`（自动完成 git pull + pip + npm + build + restart） |
| 模型链接脚本 | `/root/update-aitoolkitmodel.sh`（镜像内实际部署脚本） |
