# AutoDL 多镜像 Agent 系统

## 层级

本目录分四层：

1. **怎么用云端**：由 `cloud-training` 处理 AutoDL API、实例、上传下载。
2. **怎么用 AutoDL**：由 `autodl-common` 处理端口、数据盘、网络加速、tmux、镜像通用规则。
3. **怎么用/更新某个 AutoDL 镜像**：由 `image-profiles/` 加镜像专属 skill 处理。
4. **怎么用镜像训练**：profile 的 `[trainer].type` 决定。`external` 交给独立 trainer 仓库（例如 `aitoolkit-trainer`）；`manual` 由用户在镜像自带 GUI 内训练，云端编排只负责开机和数据传输。

通用规则不要写进某个训练框架 skill；某个训练框架的路径、环境、启动命令也不要写进通用规则。

## 通用环境

- **平台**: AutoDL GPU 云服务器
- **系统盘**: `/`（常见 30G，随镜像保存）
- **数据盘**: `/root/autodl-tmp`（不随镜像保存）
- **共享模型**: `/.autodl-model/data/`（只读，是否可用取决于镜像/平台）

## Skills

| Skill | 镜像范围 | 用途 |
|---|---|---|
| [autodl-common](skills/autodl-common/SKILL.md) | 通用 | 所有 AutoDL 镜像通用操作：端口、数据盘、网络、tmux、保存前检查 |
| [daily-ops](skills/daily-ops/SKILL.md) | 通用 | 日常速查，优先引用通用 AutoDL 规则 |
| [cloud-training](skills/cloud-training/SKILL.md) | 通用 | 使用 AutoDL API 编排云端训练、上传数据、调用外部训练工具、下载结果 |
| [ai-toolkit-maintenance](skills/ai-toolkit-maintenance/SKILL.md) | `ai-toolkit` | 代码更新（保留本地改动）、启动/重启脚本、保存镜像检查 |
| [ai-toolkit-scripts-update](skills/ai-toolkit-scripts-update/SKILL.md) | `ai-toolkit` | 模型符号链接脚本 `/root/update-aitoolkitmodel.sh` 维护 |
| [lora-scripts-next-maintenance](skills/lora-scripts-next-maintenance/SKILL.md) | `lora-scripts-next` | 启动脚本、Anima/Flux/SDXL 默认值补丁、6008 监控页、上游同步 |
| 外部 [aitoolkit-trainer](https://github.com/wochenlong/aitoolkit-trainer) | `ai-toolkit` | 验证数据集、生成 AI-Toolkit 训练配置、启动 tmux 训练、监控输出 |

> 通用 skill 不绑定具体镜像；带镜像范围的 skill 在 SKILL.md 第一段会写明只服务哪个 profile，agent 不要跨镜像套用。

## 镜像 Profiles

镜像差异写在：

```bash
image-profiles/
```

当前 profiles：

| Profile | 状态 | 用途 |
|---|---|---|
| [ai-toolkit](image-profiles/ai-toolkit.toml) | active | 当前 AI-Toolkit 训练镜像 |
| [lora-scripts-next](image-profiles/lora-scripts-next.toml) | active | wochenlong/lora-scripts-next 训练镜像（5090 / Blackwell，含 Anima/Flux/SDXL 默认值补丁与 6008 监控页） |
| [musubi-tuner](image-profiles/musubi-tuner.toml) | draft | kohya-ss/musubi-tuner 纯命令行训练脚本集（5090 / Python 3.12 / cu128，图像架构 LoRA 优先；trainer 仓库 musubi-trainer 待建立） |
| [lora-scripts](image-profiles/lora-scripts.toml) | draft | Akegarasu/lora-scripts 上游待接入镜像 |

Agent 处理任务前必须先确认 profile。如果无法判断镜像类型，只能执行 `autodl-common` 的通用操作。

## 任务路由

收到任务后，先按下面规则选择 skill，避免重复执行或跨边界修改：

| 用户意图 | 首选 skill | 边界 |
|---|---|---|
| 不确定是什么镜像、只问 AutoDL 平台规则 | [autodl-common](skills/autodl-common/SKILL.md) | 只做跨镜像通用判断 |
| 启动 UI、检查端口、开关网络加速、排查常见问题 | [daily-ops](skills/daily-ops/SKILL.md) + profile | 不修改仓库脚本 |
| 本地数据集要上云训练，需要创建实例、上传数据、下载结果 | [cloud-training](skills/cloud-training/SKILL.md) + profile | 负责编排云实例和传输 |
| AI-Toolkit 模型链接失败、共享模型新增 | [ai-toolkit-scripts-update](skills/ai-toolkit-scripts-update/SKILL.md) + `ai-toolkit` profile | 只适用于 AI-Toolkit 镜像 |
| 更新 `/root/ai-toolkit`、AI-Toolkit 镜像保存前检查 | [ai-toolkit-maintenance](skills/ai-toolkit-maintenance/SKILL.md) + `ai-toolkit` profile | 只适用于 AI-Toolkit 镜像 |
| AI-Toolkit 数据集已经在训练机器上，需要训练 | 外部 `aitoolkit-trainer` + `ai-toolkit` profile | 负责本机训练，不创建/释放云实例 |
| 更新 `/root/lora-scripts-next`、Anima/Flux/SDXL 默认值修复、6008 监控页、镜像保存前检查 | [lora-scripts-next-maintenance](skills/lora-scripts-next-maintenance/SKILL.md) + `lora-scripts-next` profile | 只适用于 lora-scripts-next 镜像 |
| 5090 / 50 系新机从零部署 lora-scripts-next | [`docs/lora-scripts-next-5090-deploy.md`](docs/lora-scripts-next-5090-deploy.md) + `lora-scripts-next` profile | 从空白 PyTorch 2.8 + CUDA 12.8 镜像建环境到首次启动 GUI |
| 部署 / 升级 musubi-tuner 镜像（命令行训练） | [`docs/musubi-tuner-deploy.md`](docs/musubi-tuner-deploy.md) + `musubi-tuner` profile | profile 当前 draft；trainer 仓库 musubi-trainer 尚未建立，首次部署后回填实测、升级 active |
| Akegarasu/lora-scripts 上游镜像训练 | `lora-scripts` profile | 当前仅有 profile 草案；先手动确认路径和命令 |

组合任务按阶段拆分：

1. 云端一键训练：先选 `image-profiles/<profile>.toml`，再用 `cloud-training` 创建实例和传输数据，最后调用 profile 指定的 trainer（`type=manual` 时由用户在镜像 GUI 内训练，不需要独立 trainer）。
2. 模型加载失败：先用 `autodl-common`/`daily-ops` 快速排查；确认是 AI-Toolkit 共享模型链接问题时用 `ai-toolkit-scripts-update`；如果是 lora-scripts-next 的 Anima/Flux/SDXL 默认值或 schema 被覆盖，用 `lora-scripts-next-maintenance` 重新跑 `apply_lora_next_anima_defaults.py`。
3. 镜像更新：先确认 profile；AI-Toolkit 镜像用 `ai-toolkit-maintenance`，lora-scripts-next 镜像用 `lora-scripts-next-maintenance`，其他镜像先只执行 `autodl-common` 通用检查。

## 其他资源

- `config/ai-toolkit.env.sh` — AI-Toolkit 镜像专属环境变量
- `image-profiles/` — 镜像 profile，定义不同训练镜像的路径、环境、trainer
- `docs/ai-toolkit-model-request.md` — 向 AutoDL 申请补充 AI-Toolkit 训练所需共享模型
- `docs/lora-scripts-next-5090-deploy.md` — lora-scripts-next 在 5090 / 50 系新机的从零部署
- `docs/musubi-tuner-deploy.md` — musubi-tuner 在 AutoDL 的从零部署（5090 + Python 3.12 + cu128）
- `docs/maintenance-guide.md` — 维护本仓库、新增 skill/profile/trainer 和重构规则
- `skills/ai-toolkit-maintenance/scripts/` — AI-Toolkit 启动与一键重启脚本
- `skills/ai-toolkit-scripts-update/scripts/` — AI-Toolkit 模型符号链接脚本
- `https://github.com/wochenlong/aitoolkit-trainer` — 独立 AI-Toolkit 训练 agent 工具
