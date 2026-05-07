# AI-Toolkit 云端训练镜像

基于 [ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) 的 AutoDL 一键训练镜像，开机即用，覆盖图像生成、图像编辑、视频生成主流模型。

## 🚀 启动方式

**开机后在控制台访问 `6006` 端口即可进入训练 UI。**

![训练 UI](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-153588373-SHp9qdvsAQFaiXICHKJI.png)

进入训练 UI 后，在 **Model Architecture** 中选择想训练的模型，即可切换到对应的训练界面。

![选择模型](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-108990519-aibkhX9x8CZu02PGVOUv.jpg)

在 **Datasets** 界面，可以通过右上角新建数据集，上传已处理好的训练图集。

![数据集](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-743417363-QKeiWXDihB7utiXRHRW7.png)

## lora-scripts-next 5090 部署

RTX 5090 / 50 系显卡建议使用 `PyTorch 2.8.0 + CUDA 12.8` 镜像，并在实例内创建 Python 3.10 环境运行 `lora-scripts-next`。详见 [`autodl/docs/lora-scripts-next-5090-deploy.md`](autodl/docs/lora-scripts-next-5090-deploy.md)。

## 🧩 支持模型

> 以下显存需求为 **LoRA 训练参考值**，实际占用会受分辨率、batch size、优化策略影响。

| 模型类型 | 模型名称 | LoRA 训练显存建议 |
|---------|----------|------------------|
| 🖼️ 图像生成 | **Z-Image** | 16 GB |
| 🖼️ 图像生成 | Z-Image-De-Turbo | 16 GB |
| 🖼️ 图像生成 | FLUX1 | 16–24 GB |
| 🖼️ 图像生成 | Qwen-Image | 24 GB |
| 🖼️ 图像生成 | SDXL | 8 GB |
| 🖼️ 图像生成 | Qwen-Image-2512 | 24 GB |
| 🖼️ 图像生成 | FLUX.2-klein-4B | 16 GB |
| 🖼️ 图像生成 | FLUX.2-klein-9B | 28 GB |
| 🖼️ 图像生成 | ERNIE-Image | 16 GB |
| 🎨 图像编辑 | FLUX.1-Kontext-dev | 16–24 GB |
| 🎨 图像编辑 | FLUX2 | 50 GB |
| 🎨 图像编辑 | Qwen-Image-Edit2509 | 24 GB |
| 🎨 图像编辑 | Qwen-Image-Edit2511 | 24 GB |
| 🎬 视频生成 | LTX-2 | 45 GB |
| 🎬 视频生成 | LTX-2.3 | 45 GB |
| 🎬 视频生成 | wan2.2 | 24–48 GB |

> **显存提示：** SDXL 低至 8 GB 即可训练；大部分模型 16–24 GB 可用；FLUX2 和 LTX 系列建议 48 GB+ 显卡（RTX PRO 6000 / H800）。

## 🎥 视频教程

**主教程：AI-Toolkit 云端训练全流程**

[![主教程](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-153588373-SHp9qdvsAQFaiXICHKJI.png)](https://www.bilibili.com/video/BV1DXCaBEEGF/?spm_id_from=333.337.search-card.all.click)

> https://www.bilibili.com/video/BV1DXCaBEEGF

**Z-Image Turbo LoRA 训练教程（AI-Toolkit 作者）**

[![Z-Image Turbo 教程](http://i0.hdslb.com/bfs/archive/2ce2c8107d84edcfc67861b5ea366ba090b03551.jpg)](https://www.bilibili.com/video/BV1TqSmBTEzn/)

> https://www.bilibili.com/video/BV1TqSmBTEzn

## 🖼️ 界面预览

**FLUX2 LoRA 训练**

![FLUX2](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-664848033-vXxzGtAbI6gDLmkr8KrB.png)

**FLUX LoRA 训练**

![FLUX](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-836461696-rnEV7Xhp0cPmWmg3tGdz.jpg)

**Qwen-Image-Edit LoRA 训练**

![Qwen Edit](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-139090954-EXgisykJuMLMwdTjsBVo.jpg)

**Z-Image Turbo LoRA 训练**

![Z-Image Turbo](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-676957506-ohTUnaCwTo40NT2XUDob.png)

## 📝 更新日志

### 2026.04.28

- ai-toolkit 同步至 **2026-04-28 主分支**
- 新增 **ERNIE-Image**（百度文心图像生成）训练支持
- 新增 **LTX-2.3**（视频生成升级版，含音频支持）训练支持
- 新增 **Nucleus-Image**、**Zeta-Chroma**、**HiDream**、**OmniGen2** 模型架构支持（共享盘模型待补充）
- 升级 **diffusers** 至 0.38.0、**transformers** 至 5.5.3 等核心依赖
- 修复 Worker 训练进程 Python 环境识别问题
- 修复上游 Prisma schema 变更导致的 UI 构建失败

### 2026.01.28

- 第一时间支持 **Z-Image** 训练

  ![Z-Image](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-567731952-VLDdgRBsorpFJAATyrgB.jpg)

### 2026.01.20

- 新增 **FLUX.2-klein-4B** 和 **FLUX.2-klein-9B** 训练支持
- ai-toolkit 脚本同步至 **2026-01-18 主分支**

### 2026.01.15

- 新增 **LTX-2** 训练支持
- ai-toolkit 脚本同步至 **2026-01-15 主分支**
- 修复 **FLUX2 训练报错** 问题

### 2026.01.04

- 新增 **Qwen-Image-2512** 与 **Qwen-Image-Edit-2511** 训练支持
- 新增 **Loss 曲线图表**，支持训练过程可视化

  ![loss](https://pbs.twimg.com/media/G8d5lfOa4AAhqQN?format=jpg&name=small)

### 2025.12.16

- 新增 **Z-Image-De-Turbo** 去蒸馏版基础模型（社区）支持

### 2025.12.04

- 集成 **Z-Image Turbo V2 训练适配器**，效果与稳定性进一步提升

### 2025.11.29

- 新增 **Z-Image Turbo LoRA** 训练支持（基于去蒸馏训练适配器，保留 Turbo 推理能力）
- 镜像内置模型与训练适配器
- FP8 训练 **最低 16 GB 显存**

### 2025.11.26

- 新增 **FLUX.2-dev** 训练支持
- 内置 **Qwen-Image**、**Mistral-Small-3.1-24B**、**WAN2.2 5B** 模型

### 2025.10.12

- 修复 NPM 在特殊环境下无法加载的问题
- 修复自定义服务 404 问题

### 2025.10.10

- 支持 **FLUX.1-Kontext-dev** 训练

### 2025.09.30

- 支持 **FLUX** / **Qwen-Image-Edit-2509** 模型训练

## 🤝 技术交流

云端镜像交流企鹅群：**852404741**

2026 年：每天群内随机掉落 **AutoDL 代金券**

| 群二维码 | 群名片 |
|:---:|:---:|
| ![group](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-602556033-RNVkPQZXnmMwHth0Udu1.png) | ![qr](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-185428711-i2ZjSJsIOsTzWf1M2Rwv.png) |
