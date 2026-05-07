# lora-scripts-next 训练镜像

基于 [wochenlong/lora-scripts-next](https://github.com/wochenlong/lora-scripts-next)（fork 自 [Akegarasu/lora-scripts](https://github.com/Akegarasu/lora-scripts)）的 AutoDL 训练镜像，针对 RTX 5090 / 50 系（Blackwell）优化，开机即用。

> 本文档是 [`lora-scripts-next.toml`](lora-scripts-next.toml) profile 的对外发布说明。镜像维护流程见
> [`autodl/skills/lora-scripts-next-maintenance/SKILL.md`](../skills/lora-scripts-next-maintenance/SKILL.md)；
> 从零部署见 [`autodl/docs/lora-scripts-next-5090-deploy.md`](../docs/lora-scripts-next-5090-deploy.md)。

## 启动方式

| 端口 | 用途 |
|---|---|
| `6006` | 训练 GUI（秋叶式 UI，加 Anima LoRA / SDXL Rectified Flow 训练入口） |
| `6008` | 轻量训练监控页：当前任务、step/total、ETA、loss、lr、最近日志 |
| `28001` | 上游 WD 1.4 标签编辑器后端（随 GUI 启动） |

开机自启脚本：`/root/autostart_lora_gui.sh` → `/root/start_lora_next.sh`

## 镜像相对上游做了什么

| 能力 | 说明 |
|---|---|
| **Anima LoRA 训练入口** | UI 左侧栏新增；`model_train_type = anima-lora`，后端调用 `scripts/dev/anima_train_network.py` |
| **本地默认值补丁** | 启动时自动恢复 Anima / Flux / SDXL 主模型、TE、VAE 默认路径，并把共享盘哈希文件名映射成展示文件名 |
| **训练监控页 (6008)** | `train_status_server.py`，从 GUI 后端拉日志/状态，每 2 秒自刷 |
| **SSE 训练日志** | `/api/train/log/stream/{task_id}`，可嵌 iframe 或外部 dashboard 订阅 |
| **5090 / cu128 适配** | 推荐 `PyTorch 2.8.0 + CUDA 12.8`，与 `bitsandbytes` 较新版本兼容 |

## 内置模型路径

启动脚本会通过软链接把以下共享盘模型挂到 `sd-models/`：

```text
sd-models/
  anima/  anima-preview3-base.safetensors  qwen_3_06b_base.safetensors  qwen_image_vae.safetensors
  flux/   flux1-dev-fp8.safetensors        ae.safetensors  t5xxl_fp8_e4m3fn.safetensors  clip_l.safetensors
  sdxl/eps/             ChenkinNoob-XL-V0.5.safetensors  illustriousXL_v01.safetensors
  sdxl/v_prediction/    noobaiXLNAIXL_vPred10Version.safetensors
  sdxl/rectified_flow/  ...
```

具体 hash → 文件名映射见 [`lora-scripts-next.toml`](lora-scripts-next.toml) 的 `[shared_models]` 段。

## 推荐硬件

- GPU：RTX 5090 / RTX PRO 6000（Blackwell, sm_120）
- CUDA：12.8
- PyTorch：2.8.0+cu128
- Python：3.10（conda 环境名 `lora-next`）

## 常见任务入口

| 任务 | 入口 |
|---|---|
| 5090 新机从零部署 | [`autodl/docs/lora-scripts-next-5090-deploy.md`](../docs/lora-scripts-next-5090-deploy.md) |
| 镜像运行中 / 升级 / 保存检查 | [`autodl/skills/lora-scripts-next-maintenance/SKILL.md`](../skills/lora-scripts-next-maintenance/SKILL.md) |
| 模型默认值修复 | `/root/lora-scripts-next/apply_lora_next_anima_defaults.py` |
| 一键拉上游 + 重启 | `/root/lora-scripts-next/update_lora_gui.sh` |
