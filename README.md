# Cloud-All-in-one

**通用云端 GPU 镜像部署工具集** —— 用一套 *profile + skill + 文档* 描述各种云端训练镜像，让 agent 可以一键开机、维护、升级、上传/下载、保存任意已接入的镜像。

> 当前以 [AutoDL](https://www.autodl.com) 为首要落地平台；架构按云平台分目录（`autodl/` 即 AutoDL 平台），后续可平行扩展其他云。

## 当前接入的镜像

| 镜像 | 状态 | 说明 | 入口 |
|---|---|---|---|
| **AI-Toolkit** | active | [ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) 一键训练镜像，覆盖 Z-Image / FLUX / Qwen / LTX / Wan2.2 等主流图像、图像编辑、视频生成模型 LoRA 训练 | [`autodl/image-profiles/ai-toolkit.md`](autodl/image-profiles/ai-toolkit.md) |
| **lora-scripts-next** | active | [wochenlong/lora-scripts-next](https://github.com/wochenlong/lora-scripts-next) 训练镜像，RTX 5090 / Blackwell 适配，含 Anima/Flux/SDXL 默认值补丁与 6008 训练监控页 | [`autodl/image-profiles/lora-scripts-next.md`](autodl/image-profiles/lora-scripts-next.md) |
| **musubi-tuner** | draft | [kohya-ss/musubi-tuner](https://github.com/kohya-ss/musubi-tuner) 纯命令行训练脚本集，5090 / Python 3.12 / cu128，覆盖 FLUX.1-Kontext / FLUX.2 / Qwen-Image / Z-Image 等图像架构 LoRA | [`autodl/image-profiles/musubi-tuner.md`](autodl/image-profiles/musubi-tuner.md) |
| lora-scripts | draft | [Akegarasu/lora-scripts](https://github.com/Akegarasu/lora-scripts) 上游待接入 | [`autodl/image-profiles/lora-scripts.toml`](autodl/image-profiles/lora-scripts.toml) |

## 设计层级

四层职责清晰，跨层不混写：

1. **怎么用云端** —— [`autodl/skills/cloud-training`](autodl/skills/cloud-training/SKILL.md) 处理 AutoDL API、实例生命周期、上传/下载。
2. **怎么用 AutoDL** —— [`autodl/skills/autodl-common`](autodl/skills/autodl-common/SKILL.md) 处理端口、数据盘、网络加速、tmux、保存前通用检查。
3. **怎么用/更新某个镜像** —— `autodl/image-profiles/<name>.toml` + `autodl/skills/<image>-maintenance/`。
4. **怎么用镜像训练** —— profile 的 `[trainer].type` 决定：`external` 调用独立 trainer 仓库（如 [`aitoolkit-trainer`](https://github.com/wochenlong/aitoolkit-trainer)），`manual` 由用户在镜像 GUI 内训练。

完整路由规则与任务对照表见 [`autodl/AGENTS.md`](autodl/AGENTS.md)。

## 仓库结构

```text
Cloud-All-in-one/
├── README.md                           ← 你正在看
└── autodl/                             ← AutoDL 平台目录（未来其他云会在这一层平行）
    ├── AGENTS.md                       ← agent 路由总入口（必读）
    ├── image-profiles/                 ← 镜像声明：路径、端口、conda、共享模型映射
    │   ├── ai-toolkit.toml + .md
    │   ├── lora-scripts-next.toml + .md
    │   ├── musubi-tuner.toml + .md     (draft)
    │   └── lora-scripts.toml           (draft)
    ├── skills/                         ← 可复用的操作流程
    │   ├── autodl-common/              ← 通用 AutoDL 操作
    │   ├── cloud-training/             ← 云端实例编排
    │   ├── daily-ops/                  ← 日常速查
    │   ├── ai-toolkit-maintenance/     ← AI-Toolkit 镜像维护（含启动/重启脚本）
    │   ├── ai-toolkit-scripts-update/  ← AI-Toolkit 模型符号链接脚本
    │   └── lora-scripts-next-maintenance/  ← lora-scripts-next 镜像维护
    ├── config/
    │   └── ai-toolkit.env.sh           ← AI-Toolkit 镜像专属环境变量
    └── docs/
        ├── maintenance-guide.md                ← 维护本仓库（新增 skill / profile / trainer）
        ├── ai-toolkit-model-request.md         ← 向 AutoDL 申请补充 AI-Toolkit 共享模型
        ├── lora-scripts-next-5090-deploy.md    ← lora-scripts-next 在 5090 / 50 系新机的从零部署
        └── musubi-tuner-deploy.md              ← musubi-tuner 在 AutoDL 的从零部署（5090 + Python 3.12 + cu128）
```

> 镜像专属 skill 命名一律带镜像 ID 前缀（`ai-toolkit-*`、`lora-scripts-next-*`），通用 skill 不带前缀，避免跨镜像误用。

## 快速上手

### 我是 AI-Toolkit 镜像用户

只想训练 → 看 [`autodl/image-profiles/ai-toolkit.md`](autodl/image-profiles/ai-toolkit.md)（开机即用，6006 进 UI）。

需要更新代码或保存镜像 → [`autodl/skills/ai-toolkit-maintenance/SKILL.md`](autodl/skills/ai-toolkit-maintenance/SKILL.md)。

### 我是 lora-scripts-next 镜像用户

只想训练 → 看 [`autodl/image-profiles/lora-scripts-next.md`](autodl/image-profiles/lora-scripts-next.md)（6006 GUI / 6008 监控页）。

5090 新机从零部署 → [`autodl/docs/lora-scripts-next-5090-deploy.md`](autodl/docs/lora-scripts-next-5090-deploy.md)。

镜像维护 → [`autodl/skills/lora-scripts-next-maintenance/SKILL.md`](autodl/skills/lora-scripts-next-maintenance/SKILL.md)。

### 我是 musubi-tuner 镜像用户

只想训练 → 看 [`autodl/image-profiles/musubi-tuner.md`](autodl/image-profiles/musubi-tuner.md)（纯命令行，无 GUI；图像架构 LoRA 优先）。

从零部署 → [`autodl/docs/musubi-tuner-deploy.md`](autodl/docs/musubi-tuner-deploy.md)（5090 + Python 3.12 + PyTorch 2.8 / cu128，含最小 Qwen-Image LoRA 验证示例）。

> 当前为 draft 状态，首次实际部署后会回填实测结果并升级为 active；远程编排 trainer (`musubi-trainer`) 在路线图中。

### 我是 agent / 自动化脚本作者

入口在 [`autodl/AGENTS.md`](autodl/AGENTS.md)。任务对照表会引导你选 skill：先选 profile（`autodl/image-profiles/<name>.toml`），再按用户意图选 skill。

### 我想接入新镜像

按 [`autodl/docs/maintenance-guide.md`](autodl/docs/maintenance-guide.md) 走：先建 `image-profiles/<id>.toml`（draft → active）；如有镜像专属流程，再加 `skills/<id>-maintenance/`；如训练逻辑可独立，做成 `<framework>-trainer` 仓库。

## 维护原则

1. **通用规则** 写在 `skills/autodl-common/`、`skills/cloud-training/`、`skills/daily-ops/`，不带任何镜像名。
2. **镜像差异** 写在 `image-profiles/<id>.toml`（声明）+ `image-profiles/<id>.md`（对外描述）+ `skills/<id>-maintenance/`（操作）。
3. **训练逻辑** 优先独立成 trainer 仓库，不塞进本仓库通用层。
4. **每个镜像专属 skill** 在 `SKILL.md` 第一段必须写明只服务哪个 profile，不可跨镜像复用。

完整重构 / 新增规则见 [`autodl/docs/maintenance-guide.md`](autodl/docs/maintenance-guide.md)。

## 技术交流

云端镜像交流企鹅群：**852404741**（每日群内随机掉落 AutoDL 代金券）

| 群二维码 | 群名片 |
|:---:|:---:|
| ![group](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-602556033-RNVkPQZXnmMwHth0Udu1.png) | ![qr](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-185428711-i2ZjSJsIOsTzWf1M2Rwv.png) |
