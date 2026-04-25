# AutoDL 镜像维护 Agent 系统

## 环境

- **平台**: AutoDL GPU 云服务器（RTX 5090）
- **系统盘**: `/`（30G，随镜像保存）
- **数据盘**: `/root/autodl-tmp`（不随镜像保存）
- **共享模型**: `/.autodl-model/data/`（只读，HF 模型缓存）
- **主项目**: `/root/ai-toolkit`（[ostris/ai-toolkit](https://github.com/ostris/ai-toolkit)）

## Skills

| Skill | 用途 |
|---|---|
| [scripts-update](skills/scripts-update/SKILL.md) | 更新模型链接脚本、同步模型清单 |
| [image-maintenance](skills/image-maintenance/SKILL.md) | 更新代码（保留本地改动）、保存镜像检查、环境信息 |
| [daily-ops](skills/daily-ops/SKILL.md) | 启动 UI、网络加速、模型检查、常见问题速查 |
| [cloud-training](skills/cloud-training/SKILL.md) | 使用 AutoDL API 编排云端训练、上传数据、下载结果 |
| [ai-toolkit-training](skills/ai-toolkit-training/SKILL.md) | 生成 AI-Toolkit 训练配置、启动 tmux 训练、监控输出 |

## 其他资源

- `config/env.sh` — 环境变量统一配置
- `docs/autodl-model-request.md` — 向 AutoDL 申请补充共享模型
- `skills/scripts-update/` 下的脚本 — 模型符号链接管理
