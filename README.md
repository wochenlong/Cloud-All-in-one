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
│   └── skills/
│       ├── cloud-training/           # API 创建实例、上传训练集、下载结果
│       ├── daily-ops/               # 日常启动、网络加速、模型检查
│       ├── image-maintenance/       # 镜像维护、更新代码、保存前检查
│       └── scripts-update/          # 模型链接脚本维护
└── README.md
```

## AutoDL 镜像维护

`autodl/` 是一套面向 Agent 的 AutoDL 镜像维护资料。克隆本仓库后，Agent 先阅读：

```bash
autodl/AGENTS.md
```

然后按任务选择对应 skill：

| Skill | 用途 |
|---|---|
| `daily-ops` | 启动 UI、网络加速、共享模型检查、常见问题 |
| `image-maintenance` | 更新 ai-toolkit、保留本地修改、保存镜像前检查 |
| `scripts-update` | 更新模型符号链接脚本、同步新共享模型 |
| `cloud-training` | 使用 AutoDL API 创建实例，配合 SSH/SCP/rsync 上传训练集并下载结果 |

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

https://www.codewithgpu.com/i/t4wefan/kohya_ss/kohya-ss-SDXL
