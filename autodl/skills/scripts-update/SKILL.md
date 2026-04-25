---
name: scripts-update
description: AI-Toolkit 镜像模型符号链接脚本和模型清单维护。当 ai-toolkit 新增模型支持或 AutoDL 共享目录有变化时使用。
---

# AI-Toolkit 脚本更新

本 skill 只适用于 `image-profiles/ai-toolkit.toml`。其他训练镜像不要直接使用 `/root/update-aitoolkitmodel.sh`，应先新增对应 image profile 和专属链接策略。

维护 `update-aitoolkitmodel.sh`，使其与 ai-toolkit 支持的模型保持同步。

## 核心逻辑

脚本将 `/.autodl-model/data/{hf_path}` 符号链接到 `/root/ai-toolkit/{hf_path}`，供 ai-toolkit 读取。

### 三类链接

1. **标准模型** — 直接目录级 `ln -s`
2. **FLUX.2 Klein VAE** — Klein 不自带 `ae.safetensors`，需从 `FLUX.2-dev` 借用。做法：拆开整体链接→逐文件链接→额外链接 VAE
3. **精度恢复适配器** — 存在共享目录哈希路径下（如 `/.autodl/af/8e/96/af8e96...`），映射到 `/root/ai-toolkit/ostris/accuracy_recovery_adapters/`

### 新增模型时

1. 检查 `/.autodl-model/data/` 中是否已有该模型
2. 在脚本 `models` 数组中添加 HF 路径
3. 如需特殊处理（如借用 VAE），参照 Klein 的模式

### 新增适配器时

在 `update_accuracy_recovery_adapters()` 的 `adapters` 数组中添加 `"哈希路径|文件名"` 条目。
哈希路径可通过 `find /.autodl/ -name "*.safetensors" | head` 搜索。

## 部署与验证

仓库内脚本是源文件：

```bash
skills/scripts-update/scripts/update-aitoolkitmodel.sh
```

镜像运行时实际执行：

```bash
/root/update-aitoolkitmodel.sh
```

修改仓库脚本后，需要同步到镜像路径并验证：

```bash
cp skills/scripts-update/scripts/update-aitoolkitmodel.sh /root/update-aitoolkitmodel.sh
chmod +x /root/update-aitoolkitmodel.sh
bash /root/update-aitoolkitmodel.sh
```

验证标准：

```bash
# 标准模型应链接到 /root/ai-toolkit/<hf_path>
ls -la /root/ai-toolkit/Qwen/Qwen-Image

# 精度恢复适配器应在 ai-toolkit 仓库内可见
ls -la /root/ai-toolkit/ostris/accuracy_recovery_adapters
```

如果链接目标指向 `/root/autodl-tmp`，说明脚本或旧文档已经过期，应改为 `/root/ai-toolkit`。

## 模型清单

模型清单以 `scripts/update-aitoolkitmodel.sh` 中的 `models` 数组为准。

### 当前 ai-toolkit 支持的模型（截至 2026-04）

**主模型**: FLUX.1-dev, FLUX.1-Kontext, FLUX.2-dev, FLUX.2-Klein-4B/9B, Flex.1-alpha, Flex.2-preview, Chroma1-Base, Qwen-Image 系列, Z-Image 系列, HiDream, OmniGen2, Lumina2, ERNIE-Image, Nucleus-Image, LTX-2/2.3, Wan2.2, SDXL, SD1.5

**依赖模型**: Mistral-Small-3.1-24B (flux2 TE), Qwen3-4B/8B (klein TE), umt5_xxl_encoder (wan22 TE), flux2_vae, wan2.1-vae, Gemma-3-12B (ltx2 TE), LLaMA-3.1-8B (hidream TE)

### 最近更新

- `baidu/ERNIE-Image` 已由 AutoDL 收录，并已加入链接脚本。
