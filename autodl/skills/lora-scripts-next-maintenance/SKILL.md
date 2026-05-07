---
name: lora-scripts-next-maintenance
description: lora-scripts-next AutoDL 镜像维护。包含启动脚本、Anima/Flux/SDXL 默认值补丁、6008 训练监控页、上游同步策略、保存镜像前检查。
---

# lora-scripts-next 镜像维护

本 skill 只适用于 `image-profiles/lora-scripts-next.toml`。其他 AutoDL 镜像（AI-Toolkit、Akegarasu/lora-scripts 上游）不要套用本流程。

镜像基于 [wochenlong/lora-scripts-next](https://github.com/wochenlong/lora-scripts-next)：在「秋叶式」UI 上加了 Anima LoRA 训练入口、SSE 训练日志、本地默认值补丁，目标硬件是 RTX 5090 / 50 系（Blackwell, CUDA 12.8 + PyTorch 2.8）。从零部署见 [`docs/lora-scripts-next-5090-deploy.md`](../../docs/lora-scripts-next-5090-deploy.md)。

## 适用边界

负责：

- `/root/lora-scripts-next` 代码更新 + 保留本地默认值补丁
- `apply_lora_next_anima_defaults.py` 模型软链接和 schema 默认值
- `start_lora_next.sh` / `restart_lora_gui.sh` / `update_lora_gui.sh` 启动维护
- 6008 训练监控页（`train_status_server.py`）
- 镜像保存前清理与回归检查

不负责：

- 创建/释放 AutoDL 实例（→ `cloud-training`）
- 端口、数据盘、网络加速等通用规则（→ `autodl-common`）
- AI-Toolkit 镜像（`update-aitoolkitmodel.sh` / `ai-toolkit-maintenance` skill）
- Akegarasu/lora-scripts 上游镜像（`lora-scripts.toml` 草案）

## 关键文件清单

镜像内必须存在且可执行：

| 路径 | 角色 |
|---|---|
| `/root/lora-scripts-next/start_lora_next.sh` | 唯一推荐启动入口；激活 `lora-next`、跑默认值补丁、清旧端口、起 GUI + 监控页 |
| `/root/lora-scripts-next/restart_lora_gui.sh` | 杀旧 PID 后再调用 `start_lora_next.sh` |
| `/root/lora-scripts-next/update_lora_gui.sh` | `git pull --recurse-submodules` + 默认值补丁 + 重启 |
| `/root/lora-scripts-next/apply_lora_next_anima_defaults.py` | Anima/Flux/SDXL 模型软链接 + UI schema 默认值修补 |
| `/root/lora-scripts-next/start_lora_monitor.sh` | 起 `train_status_server.py` 监控页 |
| `/root/lora-scripts-next/train_status_server.py` | 6008 端口的轻量训练监控页 |
| `/root/autostart_lora_gui.sh` | AutoDL 开机自启钩子，nohup 调起 `start_lora_next.sh` |

PID 与日志：

- `/root/lora_gui.pid` — GUI 主进程 PID
- `/root/lora_gui_autostart.log` — 开机自启日志
- `/root/lora_gui_restart.log` — 手动重启日志
- `/root/lora_monitor.log` — 6008 监控页日志

## 启动 GUI

统一使用：

```bash
/root/lora-scripts-next/start_lora_next.sh
```

不要直接 `python gui.py`，会跳过默认值补丁和端口清理。

启动脚本顺序：

1. `conda activate lora-next`
2. 若 `/etc/network_turbo` 存在则 `source` 启用学术加速（无则跳过，保持兼容性）
3. `cd /root/lora-scripts-next`
4. `export OMP_NUM_THREADS=1`
5. 运行 `apply_lora_next_anima_defaults.py` 恢复 Anima/Flux/SDXL 默认值与软链接
6. 清理在 `60006/6006/6007/6008/28000/28001/30000` 上的旧监听进程
7. 后台启动 `start_lora_monitor.sh` → 6008 监控页
8. 前台启动 `python gui.py --listen --host 0.0.0.0 --port 6006 --skip-prepare-environment --disable-tensorboard`

> 启动脚本里带了 `--skip-prepare-environment`：上游依赖检查会把 `setuptools<81` 当成 shell 重定向导致启动失败，必须保留这个 flag。
> 同样 `--disable-tensorboard`，避免和 6008 监控页 / 外部 TensorBoard 端口冲突。

## 端口约定

| 端口 | 用途 |
|---|---|
| `6006` | 训练 GUI（`gui.py`）。AutoDL 自定义服务通常默认开放 6006 |
| `6008` | 训练监控页（`train_status_server.py`） |
| `28001` | 上游标签编辑器后端（GUI 启动时随 `gui.py` 起；无卡环境可能被 cgroup OOM kill） |

不要为了无卡环境给启动脚本加 `--disable-tageditor`，正式有显卡镜像里让标签编辑器随 GUI 启动即可。

## Anima 模型默认值

UI 路径必须是这三条（schema 注入）：

| 字段 | 路径 |
|---|---|
| `pretrained_model_name_or_path` | `./sd-models/anima/anima-preview3-base.safetensors` |
| `qwen3` | `./sd-models/anima/qwen_3_06b_base.safetensors` |
| `vae` | `./sd-models/anima/qwen_image_vae.safetensors` |

实际文件来自共享盘：

- `/.autodl/circlestone-labs/Anima/split_files/diffusion_models/anima-preview3-base.safetensors`
- `/.autodl/circlestone-labs/Anima/split_files/text_encoders/qwen_3_06b_base.safetensors`
- `/.autodl/circlestone-labs/Anima/split_files/vae/qwen_image_vae.safetensors`

由 `apply_lora_next_anima_defaults.py` 软链接到 `/root/lora-scripts-next/sd-models/anima/`，并修补 `mikazuki/schema/sd3-lora.ts` 的默认值。

## Flux 模型默认值

UI 路径必须是：

| 字段 | 路径 |
|---|---|
| 主模型 | `./sd-models/flux/flux1-dev-fp8.safetensors` |
| VAE/AE | `./sd-models/flux/ae.safetensors` |
| T5XXL | `./sd-models/flux/t5xxl_fp8_e4m3fn.safetensors` |
| CLIP-L | `./sd-models/flux/clip_l.safetensors` |

共享盘真实路径（注意 AutoDL 面板上的展示文件名和实际哈希文件名不一致，补丁脚本负责映射）：

| 展示名 | 实际路径 |
|---|---|
| `flux1-dev-fp8.safetensors` | `/.autodl/23/73/8c/23738c26b548113ea2d392abd91d3fd0` |
| `t5xxl_fp8_e4m3fn.safetensors` | `/.autodl/a3/e7/20/a3e720ed91f439ecc3dfd15e56b137bc` |
| `ae.safetensors` | `/.autodl/black-forest-labs/FLUX.1-dev/ae.safetensors` |
| `clip_l.safetensors` | `/.autodl/comfyanonymous/flux_text_encoders/clip_l.safetensors` |

Flux 默认值文件：`/root/lora-scripts-next/mikazuki/schema/flux-lora.ts`。共享盘哈希路径若变更，**先**更新 `apply_lora_next_anima_defaults.py` 中的映射表，**再**运行：

```bash
/root/lora-scripts-next/apply_lora_next_anima_defaults.py
```

## SDXL 模型默认值

SDXL 专家模式默认底模：`./sd-models/sdxl/eps/ChenkinNoob-XL-V0.5.safetensors`，源 `/.autodl/5c/18/f8/5c18f83c804c06e10e24c191b422f02d`。容器若尚未挂载该哈希，补丁脚本会跳过、不会报错。

`sd-models/` 目录约束：

```text
sd-models/
  anima/             # Anima DiT + Qwen3 TE + Qwen Image VAE
  flux/              # Flux DiT + AE + T5XXL + CLIP-L
  sdxl/eps/          # SDXL EPS 底模
  sdxl/v_prediction/ # SDXL v-prediction 底模
  sdxl/rectified_flow/ # SDXL rectified flow 底模
```

不要把模型软链接放回 `sd-models/` 根目录。新增默认模型时优先改 `apply_lora_next_anima_defaults.py`，再跑一遍。

SDXL 专家模式默认值文件：`/root/lora-scripts-next/mikazuki/schema/lora-master.ts`。

## 训练监控页（6008）

监控页用 `/root/lora-scripts-next/train_status_server.py` 启动，从 GUI 后端拉数据：

- 状态 JSON：`http://<实例地址>:6008/api/status`
- 页面：`http://<实例地址>:6008`

监控页依赖后端的只读接口：

```
GET /api/train/log/tail/{task_id}
```

如果上游同步覆盖了这个接口，要么把它加回去、要么改监控页改用 SSE 接口 `/api/train/log/stream/{task_id}`。

## 更新 lora-scripts-next（拉上游）

一键：

```bash
/root/lora-scripts-next/update_lora_gui.sh
```

该脚本会：

1. 激活 `lora-next` 环境
2. 启用 `/etc/network_turbo`（若可用）
3. `cd /root/lora-scripts-next && git pull --recurse-submodules`
4. 跑 `apply_lora_next_anima_defaults.py` 补回默认值 + 软链接
5. 调用 `restart_lora_gui.sh` 滚动重启

冲突处理优先级：

1. **不要**丢用户数据集和训练输出。
2. 如果 `git pull` 被 `mikazuki/schema/{sd3-lora,flux-lora,lora-master}.ts` 的本地默认值修改挡住，先 `git restore` 这三份 schema 再拉，**拉完一定要重新跑** `apply_lora_next_anima_defaults.py` 把默认值补回。
3. 如果只是想验证补丁不重启 GUI：

```bash
/root/lora-scripts-next/apply_lora_next_anima_defaults.py
```

## 已知环境细节

- `transformers==4.51.3`、`diffusers==0.33.1` 是当前已验证版本。
- 启动脚本必须保留 `--skip-prepare-environment`：上游 prepare_environment 用 shell 解析 `setuptools<81` 会被识别成重定向。
- 启动脚本必须保留 `--disable-tensorboard`：避免和 6008 监控页 / 外部 TensorBoard 端口冲突。
- 无卡 / 受限容器（CPU 内存上限较低）里，标签编辑器可能被 cgroup OOM；正式带卡镜像不会触发，所以**不要**为了调试加回 `--disable-tageditor`。
- GUI 启动后 `curl -sI http://127.0.0.1:6006` 应返回 `HTTP/1.1 200`。
- Torch / GPU 检测会出现警告，只要 GUI 页面能开就忽略。

## 保存镜像前检查

1. 停 GUI：

   ```bash
   if [ -f /root/lora_gui.pid ]; then
     kill "$(cat /root/lora_gui.pid)" 2>/dev/null || true
   fi
   pkill -f train_status_server.py 2>/dev/null || true
   ```

2. 清缓存：

   ```bash
   pip cache purge || true
   conda clean -a -y || true
   rm -rf ~/.cache/huggingface/hub/
   ```

3. 系统盘占用（30G 系统盘建议 < 24G）：

   ```bash
   df -h /
   du -sh /root/* 2>/dev/null | sort -rh | head
   ```

4. 确认大模型不在系统盘里以实体文件存在：

   ```bash
   find /root/lora-scripts-next/sd-models -name "*.safetensors" -not -type l -size +100M
   ```

   预期输出为空——所有 `.safetensors` 都应是软链接到 `/.autodl/...`。

5. 确认默认值补丁脚本和启动脚本是可执行的：

   ```bash
   ls -l /root/lora-scripts-next/{start_lora_next.sh,restart_lora_gui.sh,update_lora_gui.sh,apply_lora_next_anima_defaults.py,start_lora_monitor.sh}
   ls -l /root/autostart_lora_gui.sh
   ```

6. 验证开机自启钩子：AutoDL 控制台 「开机自启」 应指向 `/root/autostart_lora_gui.sh`，重启实例后从公网访问 `6006` 端口能拉起 GUI。

7. 确认无 token / SSH 私钥 / 个人凭据写入 `/root/`：

   ```bash
   grep -RIl --exclude-dir=.git -E "ghp_|gho_|ghs_|sk-[A-Za-z0-9]{20,}" /root/lora-scripts-next /root/_lora_internal 2>/dev/null
   ```

## 与其他 skill 的关系

- 通用 AutoDL 操作（端口、数据盘、网络加速）→ [`autodl-common`](../autodl-common/SKILL.md)
- 创建/释放 AutoDL 实例 / 数据传输 → [`cloud-training`](../cloud-training/SKILL.md)
- AI-Toolkit 镜像更新 → [`ai-toolkit-maintenance`](../ai-toolkit-maintenance/SKILL.md)（**不要**用在本镜像）
- AI-Toolkit 模型链接脚本 → [`ai-toolkit-scripts-update`](../ai-toolkit-scripts-update/SKILL.md)（**不要**用在本镜像）
- Akegarasu/lora-scripts 上游镜像 → 当前只有 `lora-scripts.toml` 草案，未接入 skill
