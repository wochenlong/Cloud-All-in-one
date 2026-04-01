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
├── autodl/                          # AutoDL 云平台相关脚本
│   ├── update-aitoolkitmodel.sh     # 模型符号链接更新脚本（主版本）
│   └── update-aitoolkitmodel-new.sh # 参考版本
└── README.md
```

## AutoDL 模型符号链接脚本

`autodl/update-aitoolkitmodel.sh` 用于在 AutoDL 实例启动时自动创建模型符号链接，避免重复下载。

### 支持的模型

| 厂商 | 模型 |
|---|---|
| Black Forest Labs | FLUX.1-dev, FLUX.1-Kontext-dev, FLUX.2-dev, FLUX.2-klein-base-4B/9B |
| Qwen | Qwen-Image, Qwen-Image-Edit-2509/2511, Qwen-Image-2512, Qwen3-4B/8B |
| Tongyi-MAI | Z-Image, Z-Image-Turbo |
| Ostris | Z-Image-De-Turbo |
| Lodestones | Zeta-Chroma |
| Lightricks | LTX-2, LTX-2.3 |
| AI Toolkit | Wan2.2-T2V-A14B, Wan2.2-I2V-A14B |
| Mistral | Mistral-Small-3.1-24B-Instruct-2503 |

### 附加功能

- FLUX.2-klein VAE 符号链接（从 FLUX.2-dev 共享 ae.safetensors）
- 精度恢复适配器（Qwen/Wan/HiDream/FLUX Kontext 的 uint3/uint4 量化恢复）
- Z-Image Turbo 训练适配器（v1/v2）
- 只读文件系统容错处理

### 使用方法

```bash
# 在 AutoDL 实例中执行
bash autodl/update-aitoolkitmodel.sh
```

## 支持平台

### 1. [AutoDL](https://www.autodl.com/home)

https://www.codewithgpu.com/i/t4wefan/kohya_ss/kohya-ss-SDXL
