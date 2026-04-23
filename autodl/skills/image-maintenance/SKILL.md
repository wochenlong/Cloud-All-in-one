---
name: image-maintenance
description: AutoDL 镜像维护。更新 ai-toolkit 代码（保留本地修改）、保存镜像前检查、环境修复。
---

# 镜像维护

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
git stash push -m "local-mods"
git pull origin main
git stash pop
# 有冲突则手动解决，优先保留本地逻辑
```

## 保存镜像前检查

1. **停服务**: `tmux kill-session -t aiui`
2. **清缓存**: `pip cache purge && conda clean -a -y && rm -rf ~/.cache/huggingface/hub/`
3. **查空间**: `df -h /`（系统盘 30G，建议 < 24G）
4. **确认无大模型文件误存系统盘**: `find /root/ai-toolkit -name "*.safetensors" -not -type l -size +100M`
5. **验证本地修改完整**: `cd /root/ai-toolkit && git diff --stat`（应有 4 个文件）

## 关键环境信息

| 项目 | 值 |
|---|---|
| conda 环境 | `ai-toolkit` |
| Node.js | `/root/.nvm/versions/node/v18.20.8/bin` |
| Python 包 | `/root/ai-toolkit/requirements.txt` |
| 端口 | 6006（`~/.bashrc` 中 `export PORT=6006`） |
| 启动脚本 | `/root/start.sh` |
| 模型链接脚本 | `/root/update-aitoolkitmodel.sh`（符号链接） |
