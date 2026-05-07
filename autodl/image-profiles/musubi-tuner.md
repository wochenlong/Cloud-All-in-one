# musubi-tuner 训练镜像

基于 [kohya-ss/musubi-tuner](https://github.com/kohya-ss/musubi-tuner) 的 AutoDL 训练镜像。musubi-tuner 是 sd-scripts 作者维护的纯命令行训练脚本集，覆盖近年主流图像与视频架构 LoRA 训练。

> 本文档是 [`musubi-tuner.toml`](musubi-tuner.toml) profile 的对外发布说明。从零部署见
> [`autodl/docs/musubi-tuner-deploy.md`](../docs/musubi-tuner-deploy.md)。
>
> 当前状态：**draft**（profile 已声明，尚未在真实 AutoDL 镜像中验证；首次部署完成后会升级为 active）。

## 镜像形态

和本仓库其他镜像不同，musubi-tuner **没有自带 GUI / 后台服务**：

| 特性 | 形态 |
|---|---|
| 启动方式 | 不存在「开机即用」；用户进 SSH / Jupyter 后激活 venv 并直接运行训练命令 |
| 端口暴露 | 无；可选 tensorboard 走 `6006` |
| 工作流 | `accelerate config` → 数据集 caching（`*_cache_latents.py`、`*_cache_text_encoder_outputs.py`） → 训练（`*_train_network.py`） → 推理（`*_generate_image.py`） |
| 自动化 | 计划做成独立 trainer 仓库 [`wochenlong/musubi-trainer`](https://github.com/wochenlong/musubi-trainer)（**仓库尚未建立**），由 [`cloud-training`](../skills/cloud-training/SKILL.md) 远程编排 |

## 推荐硬件

| 项目 | 值 |
|---|---|
| GPU | RTX 5090 / 50 系（Blackwell, sm_120） |
| 系统 | Ubuntu 22.04 |
| Python | 3.12（AutoDL 基础 PyTorch 镜像自带；上游官方 verified Python 3.10） |
| PyTorch | 2.8.0+cu128 |
| CUDA | 12.8 |

> 上游 README 标注 verified with Python 3.10；3.12 需要按用户实测验证。如出现兼容问题，请按部署文档建一个 Python 3.10 conda 环境作为 fallback。

## 第一阶段支持架构（图像）

profile 已映射以下共享盘模型，开箱可用：

| 架构 | 主模型共享盘路径 | 备注 |
|---|---|---|
| **FLUX.1 Kontext** | `/.autodl-model/data/black-forest-labs/FLUX.1-Kontext-dev` | 可直接 `flux_kontext_train_network.py` |
| **FLUX.2 dev** | `/.autodl-model/data/black-forest-labs/FLUX.2-dev` | 文本编码器使用共享盘 `mistralai/Mistral-Small-3.1-24B-Instruct-2503` |
| **FLUX.2 klein 4B / 9B** | `/.autodl-model/data/black-forest-labs/FLUX.2-klein-base-{4,9}B` | 文本编码器使用共享盘 `Qwen/Qwen3-4B` 或 `Qwen3-8B`；**VAE 缺失**：`ai-toolkit/flux2_vae` 已通过 [`ai-toolkit-model-request.md`](../docs/ai-toolkit-model-request.md) 申请补充 |
| **Qwen-Image / Qwen-Image-Edit** | `/.autodl-model/data/Qwen/Qwen-Image*` | 含 2509 / 2511 / 2512 三个版本 |
| **Z-Image / Z-Image-Turbo** | `/.autodl-model/data/Tongyi-MAI/Z-Image{,-Turbo}` | musubi-tuner 已验证 LoRA + 全参数微调 |

upstream README 还支持视频架构（HunyuanVideo / Wan2.1-2.2 / FramePack / Kandinsky-5），脚本已经在镜像内可调用，但本 profile **第一阶段暂未列入** `[shared_models]`，等图像通路打通后再补。

## 显存基线

| 任务 | 显存 |
|---|---|
| 图像 LoRA | 12 GB+（960×544，开启 `--blocks_to_swap`、`--fp8_llm`） |
| 视频 LoRA | 24 GB+ |

实际占用受分辨率、batch size、attention 后端（torch SDPA / SageAttention / FlashAttention）影响。

## 关键入口

| 任务 | 入口 |
|---|---|
| 5090 新机从零部署 | [`autodl/docs/musubi-tuner-deploy.md`](../docs/musubi-tuner-deploy.md) |
| 镜像 profile 字段 | [`musubi-tuner.toml`](musubi-tuner.toml) |
| AutoDL 通用操作（端口 / 数据盘 / tmux） | [`autodl/skills/autodl-common/SKILL.md`](../skills/autodl-common/SKILL.md) |
| 上游官方文档（按架构分） | [kohya-ss/musubi-tuner/docs](https://github.com/kohya-ss/musubi-tuner/tree/main/docs) |

## 路线图

- [ ] 在真实 AutoDL 实例上首次部署 + Qwen-Image LoRA 最小训练验证 → profile 升级为 `active`
- [ ] 将 trainer 拆出为独立仓库 `musubi-trainer`（图像 LoRA 配置生成 + tmux 训练编排），更新 profile `[trainer].status` 为 `active`
- [ ] 视频架构（HunyuanVideo / Wan2.1-2.2 / Kandinsky-5）共享盘模型补充与最小训练验证
- [ ] FLUX.2 klein 所需 `flux2_vae` 共享盘补全
