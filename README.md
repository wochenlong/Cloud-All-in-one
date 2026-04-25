# Cloud-All-in-one

全网统一文生图的云端推理与训练仓库

## 包含模块

### 训练模块

- [ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) — 支持 FLUX、Qwen Image、Z-Image、Zeta-Chroma、Wan2.2、LTX-2/2.3 等模型的 LoRA/Full Fine-tuning 训练
- [bmaltais/kohya_ss](https://github.com/bmaltais/kohya_ss) — SD/SDXL LoRA 训练

### 推理模块

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) — 节点式推理工作流
- [Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) — WebUI 推理

### 数据处理模块

- [Eugeoter/waifuset](https://github.com/Eugeoter/waifuset)

## 仓库结构

```
Cloud-All-in-one/
├── autodl/                          # AutoDL 镜像维护资料
│   ├── AGENTS.md                    # Agent 入口说明：环境设定 + skill 索引
│   ├── config/
│   │   └── env.sh                   # AutoDL 环境变量
│   ├── docs/
│   │   └── autodl-model-request.md  # 请求 AutoDL 补充共享模型的清单
│   ├── image-profiles/              # 不同 AutoDL 镜像的路径、环境和 trainer 配置
│   │   ├── ai-toolkit.toml
│   │   └── lora-scripts.toml
│   └── skills/
│       ├── autodl-common/            # 所有 AutoDL 镜像通用规则
│       ├── cloud-training/           # API 创建实例、上传训练集、调用外部训练工具、下载结果
│       ├── daily-ops/               # 日常启动、网络加速、模型检查
│       ├── image-maintenance/       # AI-Toolkit 镜像维护、更新代码、保存前检查
│       └── scripts-update/          # AI-Toolkit 模型链接脚本维护
└── README.md
```

## AutoDL 镜像维护

`autodl/` 是一套面向 Agent 的 AutoDL 镜像维护资料。克隆本仓库后，Agent 先阅读：

```bash
autodl/AGENTS.md
```

然后按任务选择对应 skill：

| Skill / 模块 | 用途 |
|---|---|
| `autodl-common` | 所有 AutoDL 镜像通用规则：端口、数据盘、网络加速、tmux、保存前检查 |
| `daily-ops` | 启动 UI、网络加速、共享模型检查、常见问题 |
| `image-profiles` | 描述不同镜像的项目路径、环境、启动命令和 trainer |
| `cloud-training` | 使用 AutoDL API 创建实例，配合 SSH/SCP/rsync 上传训练集并按 profile 调用 trainer |
| `image-maintenance` | AI-Toolkit 镜像专属：更新 ai-toolkit、保留本地修改、保存镜像前检查 |
| `scripts-update` | AI-Toolkit 镜像专属：更新模型符号链接脚本、同步新共享模型 |
| 外部 `aitoolkit-trainer` | 验证数据集、生成 Qwen 图像/图像编辑训练配置、tmux 启动和输出定位 |

### 多镜像 Profile

AutoDL 通用能力和具体训练镜像解耦。镜像差异写在：

```bash
autodl/image-profiles/
```

当前包含：

| Profile | 状态 | 说明 |
|---|---|---|
| `ai-toolkit.toml` | active | 当前 AI-Toolkit 训练镜像，调用外部 `aitoolkit-trainer` |
| `lora-scripts.toml` | draft | Akegarasu/lora-scripts 待接入镜像，路径和命令待实际镜像确认 |

### AI-Toolkit 训练工具

AI-Toolkit 训练逻辑已独立到：

https://github.com/wochenlong/aitoolkit-trainer

`autodl/` 只负责 AutoDL 平台、镜像维护、模型链接和云端编排；具体训练由远端克隆的 `aitoolkit-trainer` 执行。

### 模型链接脚本

脚本位置：

```bash
autodl/skills/scripts-update/scripts/update-aitoolkitmodel.sh
```

作用：将 AutoDL 共享目录 `/.autodl-model/data/` 中的模型链接到 `/root/ai-toolkit/`，避免重复下载。

在 AutoDL 实例中执行：

```bash
bash autodl/skills/scripts-update/scripts/update-aitoolkitmodel.sh
```

### 当前支持的共享模型

| 厂商 | 模型 |
|---|---|
| Black Forest Labs | FLUX.1-dev, FLUX.1-Kontext-dev, FLUX.2-dev, FLUX.2-klein-base-4B/9B |
| Qwen | Qwen-Image, Qwen-Image-Edit-2509/2511, Qwen-Image-2512, Qwen3-4B/8B |
| Baidu | ERNIE-Image |
| Tongyi-MAI | Z-Image, Z-Image-Turbo |
| Ostris | Z-Image-De-Turbo |
| Lodestones | Zeta-Chroma |
| Lightricks | LTX-2, LTX-2.3 |
| AI Toolkit | Wan2.2-T2V-A14B, Wan2.2-I2V-A14B |
| Mistral | Mistral-Small-3.1-24B-Instruct-2503 |

### 链接脚本附加功能

- FLUX.2-klein VAE 符号链接（从 FLUX.2-dev 共享 ae.safetensors）
- 精度恢复适配器（Qwen/Wan/HiDream/FLUX Kontext 的 uint3/uint4 量化恢复）
- Z-Image Turbo 训练适配器（v1/v2）
- 只读文件系统容错处理

## 支持平台

### 1. [AutoDL](https://www.autodl.com/home)

当前支持的 AutoDL 训练镜像：

| 镜像 | 用途 | 地址 |
|---|---|---|
| AI-Toolkit | Qwen Image/Edit、FLUX、Wan、LTX 等 AI-Toolkit 训练流程 | https://www.autodl.art/app/market/13 |
| 秋叶训练包（Akegarasu/lora-scripts） | lora-scripts 训练镜像，当前已建立 profile 草案，待实际镜像校准自动训练流程 | https://www.autodl.art/app/market/11? |
