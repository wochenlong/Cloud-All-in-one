# Cloud-All-in-one

面向 Agent 的云端推理与训练资料库。

这个仓库目前重点维护 **AutoDL 多镜像训练工作流**：让 Agent 知道怎么使用 AutoDL、怎么区分不同训练镜像、怎么维护镜像，以及什么时候调用独立训练工具。

## 当前支持什么

### AutoDL 训练镜像

| 镜像 | 状态 | 说明 | 地址 |
|---|---|---|---|
| AI-Toolkit | 已接入 | 支持 Qwen Image/Edit、FLUX、Wan、LTX 等 AI-Toolkit 训练流程；训练自动化由外部 `aitoolkit-trainer` 负责 | https://www.autodl.art/app/market/13 |
| 秋叶训练包（Akegarasu/lora-scripts） | profile 草案 | 已建立 AutoDL 镜像 profile；实际训练命令和自动化流程待挂载镜像后校准 | https://www.autodl.art/app/market/11? |

### 独立训练工具

AI-Toolkit 的训练逻辑已经拆到独立仓库：

https://github.com/wochenlong/aitoolkit-trainer

`Cloud-All-in-one/autodl` 负责 AutoDL 平台和镜像编排，`aitoolkit-trainer` 负责 AI-Toolkit 数据集验证、训练配置生成和 tmux 启动训练。

## 目标愿景

理想状态下，用户只需要在本地准备好训练集和少量训练意图，例如“训练一个 Qwen Image LoRA”：

1. Agent 根据训练类型选择合适的 AutoDL 镜像 profile。
2. Agent 通过云平台 API 创建 GPU 实例。
3. Agent 自动上传本地训练集和必要配置。
4. 云端镜像自动验证数据集、生成训练配置并启动训练。
5. 训练完成后，Agent 自动下载 LoRA/模型产物到本地。
6. Agent 按用户选择关机或释放云实例，避免继续计费。

也就是：

```text
本地训练集 -> 云端 GPU -> 等待训练 -> 本地得到模型
```

## 希望云平台补齐的能力

当前 AutoDL 已经提供实例生命周期 API，适合做创建实例、查询状态、开机、关机、释放等编排。但要实现真正丝滑的一键云端训练，还需要平台侧或工具侧补齐下面这些能力。

这些需求的目标是：让 Agent 不必依赖交互式 SSH，就能稳定完成“上传数据 -> 启动训练 -> 查看状态 -> 下载模型”。

### 文件上传 API

用于把本地训练集、训练配置或小型辅助文件上传到云端实例的数据盘。

建议能力：

- 支持上传单文件和目录。
- 支持大文件分片、断点续传和进度查询。
- 支持指定远端目标路径，例如 `/root/autodl-tmp/datasets/<job_name>/`。
- 支持校验文件大小、hash 或 manifest，避免训练集上传不完整。
- 支持覆盖策略，例如跳过同名文件、覆盖同名文件、清空目录后上传。

当前备用方案：`scp` / `rsync` / `sftp`。

### 文件下载 API

用于把训练完成后的 LoRA、checkpoint、日志、样图等产物下载回本地。

建议能力：

- 支持下载单文件和目录。
- 支持按通配符或 manifest 下载，例如只下载 `.safetensors`、`.pt`、`.json`、`.log`。
- 支持打包下载目录，减少大量小文件传输失败。
- 支持断点续传和下载校验。
- 支持列出远端目录文件，方便 Agent 判断哪些产物应该下载。

当前备用方案：`scp` / `rsync` / `sftp`。

### 训练状态 API

用于让 Agent 判断训练任务是正在运行、成功结束、失败、OOM、中断，还是等待用户处理。

建议能力：

- 支持创建一个平台可识别的训练任务记录。
- 返回状态：`queued`、`running`、`succeeded`、`failed`、`stopped`、`unknown`。
- 返回关键运行信息：开始时间、运行时长、GPU 使用情况、最近一次心跳。
- 返回失败原因分类，例如 OOM、磁盘不足、数据集缺失、依赖错误、用户停止。
- 支持主动停止训练任务。

当前备用方案：读取 `tmux`、进程列表和日志文件。

### 日志 API

用于不进入 SSH 的情况下查看训练日志，方便 Agent 监控进度和定位错误。

建议能力：

- 支持读取完整日志。
- 支持 tail 最近 N 行。
- 支持按 offset 或 cursor 增量读取日志。
- 支持区分 stdout、stderr 和平台事件。
- 支持保留任务结束后的日志，便于失败后诊断。

当前备用方案：`tmux attach`、`tail -f` 或下载日志文件。

### 标准产物路径

不同训练镜像的输出目录差异很大。Agent 需要知道训练完成后应该去哪里找模型文件、样图和日志。

建议标准：

- 每个镜像声明默认输出目录，例如 `/root/autodl-tmp/output/<job_name>/`。
- 每个任务写一个产物 manifest，例如 `artifacts.json`。
- manifest 中列出模型文件、配置文件、日志、样图、最终推荐下载文件。
- 标记产物类型，例如 `lora`、`checkpoint`、`sample_image`、`log`、`config`。
- 明确哪些目录会随镜像保存，哪些目录只在数据盘保存。

当前备用方案：本仓库通过 `autodl/image-profiles/*.toml` 约定 `output_dir`。

### 镜像 Profile 标准

不同训练镜像有不同的项目路径、conda 环境、启动命令、Web UI 端口和训练入口。平台如果能提供统一 profile，Agent 就能更可靠地自动化。

建议 profile 至少包含：

```toml
id = "ai-toolkit"
display_name = "AI-Toolkit AutoDL 镜像"

[paths]
project_dir = "/root/ai-toolkit"
dataset_root = "/root/autodl-tmp/datasets"
output_dir = "/root/autodl-tmp/output"
log_dir = "/root/autodl-tmp/logs"

[runtime]
conda_env = "ai-toolkit"
setup_command = "source /root/miniconda3/etc/profile.d/conda.sh && conda activate ai-toolkit"
ui_command = "bash /root/start.sh"
ui_port = 6006

[trainer]
type = "external"
name = "aitoolkit-trainer"
supported_tasks = ["image", "image_edit"]
```

当前备用方案：本仓库维护 `autodl/image-profiles/`。

### 最小可用 API 组合

如果平台要优先实现最小闭环，建议先支持：

1. 上传目录到实例数据盘。
2. 下载目录或指定后缀文件。
3. 查询实例状态和 GPU 信息。
4. 读取某个日志文件最近 N 行。
5. 镜像提供机器可读的 profile。

有了这些能力，Agent 就可以比较稳定地完成：

```text
本地训练集 -> 上传到云端 -> 调用镜像 trainer -> 监控日志/状态 -> 下载模型
```

所以本仓库当前采用分层方案：平台 API 负责实例生命周期；文件传输先用 SSH/SCP/rsync；具体训练逻辑交给每个镜像对应的 trainer。

## 给 Agent 怎么用

克隆本仓库后，Agent 先读：

```bash
autodl/AGENTS.md
```

然后按任务分流：

| 用户要做什么 | 看哪里 |
|---|---|
| 不确定当前是什么镜像，只想了解 AutoDL 通用规则 | `autodl/skills/autodl-common/SKILL.md` |
| 启动 UI、开关网络加速、检查数据盘、排查常见问题 | `autodl/skills/daily-ops/SKILL.md` |
| 用 AutoDL API 创建实例、上传数据、下载结果 | `autodl/skills/cloud-training/SKILL.md` |
| 判断某个镜像的路径、环境、启动命令和 trainer | `autodl/image-profiles/*.toml` |
| 维护 AI-Toolkit 镜像里的模型链接脚本 | `autodl/skills/scripts-update/SKILL.md` |
| 更新 AI-Toolkit 镜像、保存镜像前检查 | `autodl/skills/image-maintenance/SKILL.md` |
| 维护这个 GitHub 项目、新增 skill 或新镜像 | `autodl/docs/maintenance-guide.md` |
| 在 AI-Toolkit 里真正开始训练 | https://github.com/wochenlong/aitoolkit-trainer |

## 设计思路

这个仓库把 AutoDL 工作流拆成四层：

1. **怎么用云端**  
   `cloud-training` 负责 AutoDL API、实例创建、SSH/SCP/rsync、上传下载、关机释放。

2. **怎么用 AutoDL**  
   `autodl-common` 负责所有 AutoDL 镜像都通用的规则，例如 6006 端口、`/root/autodl-tmp` 数据盘、`/etc/network_turbo`、tmux 长任务。

3. **怎么用/更新某个镜像**  
   `image-profiles/` 描述不同镜像的路径和环境；AI-Toolkit 专属维护由 `image-maintenance` 和 `scripts-update` 处理。

4. **怎么用镜像训练**  
   训练逻辑不强行塞进 AutoDL 通用层。AI-Toolkit 使用独立的 `aitoolkit-trainer`；其他镜像以后可以有自己的 trainer。

## 仓库结构

```text
Cloud-All-in-one/
├── autodl/
│   ├── AGENTS.md                    # Agent 入口：层级说明和任务路由
│   ├── config/
│   │   └── env.sh                   # AutoDL 环境变量
│   ├── docs/
│   │   ├── autodl-model-request.md  # 请求 AutoDL 补充共享模型的清单
│   │   └── maintenance-guide.md     # 新增 skill/profile/trainer 和重构规则
│   ├── image-profiles/              # 不同 AutoDL 镜像的路径、环境和 trainer 配置
│   │   ├── ai-toolkit.toml
│   │   └── lora-scripts.toml
│   └── skills/
│       ├── autodl-common/           # 所有 AutoDL 镜像通用规则
│       ├── cloud-training/          # API 创建实例、上传训练集、调用 trainer、下载结果
│       ├── daily-ops/               # 日常启动、网络加速、磁盘和常见问题
│       ├── image-maintenance/       # AI-Toolkit 镜像维护
│       └── scripts-update/          # AI-Toolkit 模型链接脚本维护
└── README.md
```

## 镜像 Profiles

AutoDL 通用能力和具体训练镜像解耦。镜像差异写在：

```bash
autodl/image-profiles/
```

| Profile | 状态 | 用途 |
|---|---|---|
| `ai-toolkit.toml` | active | 当前 AI-Toolkit AutoDL 镜像，调用外部 `aitoolkit-trainer` |
| `lora-scripts.toml` | draft | 秋叶训练包镜像草案，待实际镜像确认 conda 环境、启动命令和训练流程 |

## AI-Toolkit 镜像专属内容

AI-Toolkit 镜像使用 AutoDL 共享模型目录，模型链接脚本位于：

```bash
autodl/skills/scripts-update/scripts/update-aitoolkitmodel.sh
```

作用是将 AutoDL 共享目录 `/.autodl-model/data/` 中的模型链接到 `/root/ai-toolkit/`，避免重复下载。

在 AutoDL AI-Toolkit 实例中执行：

```bash
bash autodl/skills/scripts-update/scripts/update-aitoolkitmodel.sh
```

当前脚本覆盖的主要共享模型包括 FLUX.1/2、Qwen Image/Edit、ERNIE-Image、Z-Image、Zeta-Chroma、LTX、Wan2.2、Mistral 和相关精度恢复适配器。

## 相关项目

- [aitoolkit-trainer](https://github.com/wochenlong/aitoolkit-trainer) — 面向 Agent 的 AI-Toolkit 训练助手
- [ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) — AI-Toolkit 上游项目
- [Akegarasu/lora-scripts](https://github.com/Akegarasu/lora-scripts) — 秋叶训练包上游项目
- [AutoDL](https://www.autodl.com/home) — GPU 云平台
