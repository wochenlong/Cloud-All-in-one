# AutoDL 多镜像 Agent 系统

## 层级

本目录分四层：

1. **怎么用云端**：由 `cloud-training` 处理 AutoDL API、实例、上传下载。
2. **怎么用 AutoDL**：由 `autodl-common` 处理端口、数据盘、网络加速、tmux、镜像通用规则。
3. **怎么用/更新某个 AutoDL 镜像**：由 `image-profiles/` 加镜像专属 skill 处理。
4. **怎么用镜像训练**：交给独立 trainer，例如 `aitoolkit-trainer`。

通用规则不要写进某个训练框架 skill；某个训练框架的路径、环境、启动命令也不要写进通用规则。

## 通用环境

- **平台**: AutoDL GPU 云服务器
- **系统盘**: `/`（常见 30G，随镜像保存）
- **数据盘**: `/root/autodl-tmp`（不随镜像保存）
- **共享模型**: `/.autodl-model/data/`（只读，是否可用取决于镜像/平台）

## Skills

| Skill | 用途 |
|---|---|
| [autodl-common](skills/autodl-common/SKILL.md) | 所有 AutoDL 镜像通用操作：端口、数据盘、网络、tmux、保存前检查 |
| [daily-ops](skills/daily-ops/SKILL.md) | 日常速查，优先引用通用 AutoDL 规则 |
| [cloud-training](skills/cloud-training/SKILL.md) | 使用 AutoDL API 编排云端训练、上传数据、调用外部训练工具、下载结果 |
| [image-maintenance](skills/image-maintenance/SKILL.md) | AI-Toolkit 镜像维护：更新代码、保留本地改动、保存镜像检查 |
| [scripts-update](skills/scripts-update/SKILL.md) | AI-Toolkit 镜像模型链接脚本维护 |
| 外部 [aitoolkit-trainer](https://github.com/wochenlong/aitoolkit-trainer) | 验证数据集、生成 AI-Toolkit 训练配置、启动 tmux 训练、监控输出 |

## 镜像 Profiles

镜像差异写在：

```bash
image-profiles/
```

当前 profiles：

| Profile | 状态 | 用途 |
|---|---|---|
| [ai-toolkit](image-profiles/ai-toolkit.toml) | active | 当前 AI-Toolkit 训练镜像 |
| [lora-scripts](image-profiles/lora-scripts.toml) | draft | Akegarasu/lora-scripts 待接入镜像 |

Agent 处理任务前必须先确认 profile。如果无法判断镜像类型，只能执行 `autodl-common` 的通用操作。

## 任务路由

收到任务后，先按下面规则选择 skill，避免重复执行或跨边界修改：

| 用户意图 | 首选 skill | 边界 |
|---|---|---|
| 不确定是什么镜像、只问 AutoDL 平台规则 | [autodl-common](skills/autodl-common/SKILL.md) | 只做跨镜像通用判断 |
| 启动 UI、检查端口、开关网络加速、排查常见问题 | [daily-ops](skills/daily-ops/SKILL.md) + profile | 不修改仓库脚本 |
| 本地数据集要上云训练，需要创建实例、上传数据、下载结果 | [cloud-training](skills/cloud-training/SKILL.md) + profile | 负责编排云实例和传输 |
| AI-Toolkit 模型链接失败、共享模型新增 | [scripts-update](skills/scripts-update/SKILL.md) + `ai-toolkit` profile | 只适用于 AI-Toolkit 镜像 |
| 更新 `/root/ai-toolkit`、AI-Toolkit 镜像保存前检查 | [image-maintenance](skills/image-maintenance/SKILL.md) + `ai-toolkit` profile | 只适用于 AI-Toolkit 镜像 |
| AI-Toolkit 数据集已经在训练机器上，需要训练 | 外部 `aitoolkit-trainer` + `ai-toolkit` profile | 负责本机训练，不创建/释放云实例 |
| lora-scripts 镜像训练 | `lora-scripts` profile | 当前仅有 profile 草案；先手动确认路径和命令 |

组合任务按阶段拆分：

1. 云端一键训练：先选 `image-profiles/<profile>.toml`，再用 `cloud-training` 创建实例和传输数据，最后调用 profile 指定的 trainer。
2. 模型加载失败：先用 `autodl-common`/`daily-ops` 快速排查；确认是 AI-Toolkit 共享模型链接问题时再用 `scripts-update`。
3. 镜像更新：先确认 profile；AI-Toolkit 镜像用 `image-maintenance`，其他镜像先只执行 `autodl-common` 通用检查。

## 其他资源

- `config/env.sh` — 环境变量统一配置
- `image-profiles/` — 镜像 profile，定义不同训练镜像的路径、环境、trainer
- `docs/autodl-model-request.md` — 向 AutoDL 申请补充共享模型
- `docs/maintenance-guide.md` — 维护本仓库、新增 skill/profile/trainer 和重构规则
- `skills/scripts-update/` 下的脚本 — AI-Toolkit 模型符号链接管理
- `https://github.com/wochenlong/aitoolkit-trainer` — 独立 AI-Toolkit 训练 agent 工具
