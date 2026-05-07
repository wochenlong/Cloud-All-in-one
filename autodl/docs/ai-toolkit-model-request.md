# AutoDL 共享模型补充申请

> 用途：[ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) — 开源扩散模型 LoRA 训练/微调工具
>
> 以下模型为 ai-toolkit 支持但 AutoDL 共享目录（`/.autodl-model/data/`）中**尚未收录**的 HuggingFace 模型。
> 恳请补充，感谢！

---

## 一、主模型（Transformer / DiT 权重）

| HuggingFace 路径 | 模型简称 | 说明 | 预估大小 |
|---|---|---|---|
| `baidu/ERNIE-Image-Turbo` | ERNIE Image Turbo | 百度蒸馏加速版（8 步） | ~16 GB |
| `NucleusAI/Nucleus-Image` | Nucleus Image | 17B MoE 扩散模型（激活 2B），SOTA 级 | ~34 GB |
| `lodestones/Chroma1-Base` | Chroma | 开源文本生图扩散模型 | ~23 GB |
| `ostris/Flex.1-alpha` | Flex.1 | 8B 开源 T2I 模型（含 T5 + VAE） | ~23 GB |
| `ostris/Flex.2-preview` | Flex.2 | Flex.1 续作，内置修复+控制功能 | ~23 GB |
| `HiDream-ai/HiDream-I1-Full` | HiDream | 文本生图模型 | ~20 GB |
| `HiDream-ai/HiDream-E1-1` | HiDream E1 | HiDream 图像编辑版 | ~20 GB |
| `OmniGen2/OmniGen2` | OmniGen2 | 多模态图像生成模型 | ~15 GB |
| `Alpha-VLLM/Lumina-Image-2.0` | Lumina2 | 文本生图模型 | ~10 GB |
| `stable-diffusion-v1-5/stable-diffusion-v1-5` | SD 1.5 | 经典 Stable Diffusion 1.5 | ~4 GB |

## 二、依赖模型（文本编码器 / VAE 等）

这些模型被上述主模型或已有模型在训练时自动加载，缺少会导致训练失败。

| HuggingFace 路径 | 被谁依赖 | 说明 | 预估大小 |
|---|---|---|---|
| `ai-toolkit/flux2_vae` | FLUX.2 Klein 4B/9B | FLUX.2 Klein 专用 VAE | ~300 MB |
| `ai-toolkit/wan2.1-vae` | Wan2.2 14B | Wan2.1/2.2 独立 VAE | ~300 MB |
| `Lightricks/gemma-3-12b-it-qat-q4_0-unquantized` | LTX-2 / LTX-2.3 | Gemma-3 12B 文本编码器（QAT 量化版） | ~24 GB |
| `unsloth/Meta-Llama-3.1-8B-Instruct` | HiDream | LLaMA 3.1 8B 文本编码器 | ~16 GB |

## 三、参考：已有模型（无需补充）

以下模型共享目录中**已收录**，仅供核对：

| HuggingFace 路径 | ✅ 状态 |
|---|---|
| `black-forest-labs/FLUX.1-dev` | 已有 |
| `black-forest-labs/FLUX.1-Kontext-dev` | 已有 |
| `black-forest-labs/FLUX.2-dev` | 已有 |
| `black-forest-labs/FLUX.2-klein-base-4B` | 已有 |
| `black-forest-labs/FLUX.2-klein-base-9B` | 已有 |
| `Qwen/Qwen-Image` | 已有 |
| `Qwen/Qwen-Image-2512` | 已有 |
| `Qwen/Qwen-Image-Edit-2509` | 已有 |
| `Qwen/Qwen-Image-Edit-2511` | 已有 |
| `Qwen/Qwen3-4B` | 已有 |
| `Qwen/Qwen3-8B` | 已有 |
| `baidu/ERNIE-Image` | 已有 |
| `Tongyi-MAI/Z-Image` | 已有 |
| `Tongyi-MAI/Z-Image-Turbo` | 已有 |
| `ostris/Z-Image-De-Turbo` | 已有 |
| `mistralai/Mistral-Small-3.1-24B-Instruct-2503` | 已有 |
| `ai-toolkit/umt5_xxl_encoder` | 已有 |
| `ai-toolkit/Wan2.2-T2V-A14B-Diffusers-bf16` | 已有 |
| `ai-toolkit/Wan2.2-I2V-A14B-Diffusers-bf16` | 已有 |
| `Lightricks/LTX-2` | 已有 |
| `Lightricks/LTX-2.3` | 已有 |
| `stabilityai/stable-diffusion-xl-base-1.0` | 已有 |
