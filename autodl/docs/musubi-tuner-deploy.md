# AutoDL 部署 musubi-tuner 指导

本文用于指导在 AutoDL 实例上部署 [kohya-ss/musubi-tuner](https://github.com/kohya-ss/musubi-tuner)。目标硬件 RTX 5090 / 50 系（Blackwell, sm_120），CUDA 12.8 + PyTorch 2.8。

镜像 profile：[`autodl/image-profiles/musubi-tuner.toml`](../image-profiles/musubi-tuner.toml)（status: **draft**，等首次部署完成后升级为 active）。

> **状态说明**：本文档基于 musubi-tuner 上游 README 与 profile 字段编写，**尚未在真实 AutoDL 镜像中端到端验证**。实测后会回填具体踩坑点（accelerate 选项、attention 后端、Python 3.12 兼容性等）。

## 1. AutoDL 镜像选择

创建实例时优先选：

- 框架：`PyTorch`
- 框架版本：`2.8.0`
- CUDA 版本：`12.8`
- Python：`3.12`
- 系统：`Ubuntu 22.04`

5090 / Blackwell **不要**选 CUDA 12.1 / 12.4 / 12.5。如果 AutoDL 暂时只提供 Python 3.10 的 cu128 镜像也可以，按本文一样跑。

## 2. 登录后先确认 GPU

```bash
nvidia-smi
```

确认输出里能看到 RTX 5090，且驱动正常。

## 3. 选择 Python 环境

**默认方案：venv**（musubi-tuner 上游推荐路径）

镜像基础 Python 是 3.12。直接在项目目录建 venv：

```bash
cd /root
git clone https://github.com/kohya-ss/musubi-tuner.git
cd musubi-tuner

python -m venv .venv
source .venv/bin/activate
python --version    # 期望 Python 3.12.x
pip install -U pip setuptools wheel
```

> 上游 README 标注 *verified with 3.10*。如 Python 3.12 在装 `pip install -e .` 或运行训练时报兼容性错（典型如某依赖 wheel 无 cp312），请按下面的 fallback 改用 conda 3.10。

**Fallback 方案：conda Python 3.10**

```bash
source /root/miniconda3/etc/profile.d/conda.sh

conda create -n musubi python=3.10 -y \
  -c https://mirrors.ustc.edu.cn/anaconda/pkgs/main \
  -c https://mirrors.ustc.edu.cn/anaconda/pkgs/r \
  --override-channels --solver=classic

conda activate musubi
python --version    # 期望 Python 3.10.x
pip install -U pip setuptools wheel
```

> 中科大源 + `--override-channels` 是为了绕开 AutoDL 镜像里可能存在的失效 `pkgs/free` 通道；这是 [`lora-scripts-next-5090-deploy.md`](lora-scripts-next-5090-deploy.md) 已验证的做法。

后续命令默认你已经激活 venv 或 conda 环境。

## 4. 安装 PyTorch cu128

如果 AutoDL 选的就是 `PyTorch 2.8.0 + CUDA 12.8`，**系统 Python 已经装好了 torch**，但 venv / conda 环境里需要单独装一遍：

```bash
pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128
```

验证：

```bash
python -c "import torch; print(torch.__version__, torch.version.cuda); print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

期望：

```text
2.8.0+cu128 12.8
True
NVIDIA GeForce RTX 5090
```

## 5. 安装 musubi-tuner 项目依赖

```bash
cd /root/musubi-tuner
pip install -e .
```

可选附加依赖（按需）：

```bash
pip install ascii-magic matplotlib tensorboard prompt-toolkit
```

> `ascii-magic` 用于数据集校验、`matplotlib` 用于 timestep 可视化、`tensorboard` 用于训练日志、`prompt-toolkit` 用于 Wan2.1 / FramePack 推理脚本的交互式编辑。

## 6. 配置 accelerate

```bash
accelerate config
```

按以下选项作答（单卡 5090 场景）：

```text
In which compute environment are you running?: This machine
Which type of machine are you using?: No distributed training
Do you want to run your training on CPU only?: NO
Do you wish to optimize your script with torch dynamo?: NO
Do you want to use DeepSpeed?: NO
What GPU(s) (by id) should be used?: all
Would you like to enable numa efficiency?: NO
Do you wish to use mixed precision?: bf16
```

如果出现 `ValueError: fp16 mixed precision requires a GPU`，把 GPU 选择改成 `0`（仅第一张 GPU）。

## 7. 共享盘模型

AutoDL 共享盘已经收录绝大多数图像类主模型，**不要把模型下载到系统盘**。直接在训练命令里写共享盘路径即可，例如：

```text
--dit_path /.autodl-model/data/Qwen/Qwen-Image
--text_encoder_path /.autodl-model/data/Qwen/Qwen-Image  # 同模型自带 TE
--vae_path /.autodl-model/data/Qwen/Qwen-Image
```

> 完整可用路径见 profile [`musubi-tuner.toml`](../image-profiles/musubi-tuner.toml) 的 `[shared_models]` 段。

如果某个模型缺失（profile 里 `missing_shared_models` 标的，例如 `ai-toolkit/flux2_vae`），先按 [`ai-toolkit-model-request.md`](ai-toolkit-model-request.md) 走 AutoDL 申请通道；急用时把它放到 `/root/autodl-tmp/`（数据盘，不会进镜像）。

## 8. 数据集与训练目录规划

参考其他 profile 的数据盘约定：

```text
/root/                         # 系统盘（30G，进镜像）
  musubi-tuner/                # 代码 + venv（venv 大约 6-8 GB）

/root/autodl-tmp/              # 数据盘（不进镜像）
  datasets/                    # 训练集
  jobs/                        # 训练 yaml / cache 输出
  output/                      # LoRA 输出
  logs/                        # tensorboard / 训练日志
```

不要把 `.venv` 放在数据盘——保存镜像时就丢了。

## 9. 最小训练验证（推荐 Qwen-Image LoRA）

第一次部署完成后建议跑 Qwen-Image 最小 LoRA 训练，依赖文件最少（一个目录就是主模型 + TE + VAE）。详细步骤见上游：[`docs/qwen_image.md`](https://github.com/kohya-ss/musubi-tuner/blob/main/docs/qwen_image.md)。

骨架命令（按上游 doc 调整具体参数）：

```bash
# 1. 数据集 latent 缓存
python qwen_image_cache_latents.py \
  --dataset_config /root/autodl-tmp/jobs/sample-dataset.toml \
  --vae /.autodl-model/data/Qwen/Qwen-Image

# 2. 文本编码器输出缓存
python qwen_image_cache_text_encoder_outputs.py \
  --dataset_config /root/autodl-tmp/jobs/sample-dataset.toml \
  --text_encoder /.autodl-model/data/Qwen/Qwen-Image

# 3. 训练
accelerate launch qwen_image_train_network.py \
  --dataset_config /root/autodl-tmp/jobs/sample-dataset.toml \
  --pretrained_model_name_or_path /.autodl-model/data/Qwen/Qwen-Image \
  --output_dir /root/autodl-tmp/output/qwen-image-lora-test \
  --output_name qwen-image-lora-test \
  --max_train_epochs 1 \
  --network_module networks.lora_qwen_image \
  --network_dim 16 \
  --mixed_precision bf16
```

最小验证通过后，把 profile `status` 从 `draft` 改成 `active`。

## 10. 启动 tensorboard（可选）

musubi-tuner 训练命令支持 `--logging_dir <path> --log_with tensorboard`。要从外部访问，启动：

```bash
tensorboard --logdir /root/autodl-tmp/logs --host 0.0.0.0 --port 6006
```

AutoDL 控制台「自定义服务」开放 `6006` 即可。

## 11. 保存镜像前检查

按 [`autodl-common`](../skills/autodl-common/SKILL.md) 的通用流程，针对本镜像追加：

1. 确认无大模型实体文件落在系统盘：

   ```bash
   find /root/musubi-tuner -name "*.safetensors" -not -type l -size +100M
   ```

   预期空输出。如有，应改成 `/.autodl-model/data/...` 软链接或挪到 `/root/autodl-tmp/`。

2. 清缓存：

   ```bash
   pip cache purge || true
   conda clean -a -y || true
   rm -rf ~/.cache/huggingface/hub/
   ```

3. 系统盘占用（建议 < 24 GB）：

   ```bash
   df -h /
   du -sh /root/* 2>/dev/null | sort -rh | head
   ```

4. 验证激活脚本仍然工作：

   ```bash
   source /root/musubi-tuner/.venv/bin/activate
   python -c "import torch, accelerate; print(torch.__version__, accelerate.__version__)"
   ```

5. 确认无 token / SSH 私钥落在 `/root/`：

   ```bash
   grep -RIl --exclude-dir=.git -E "ghp_|gho_|ghs_|sk-[A-Za-z0-9]{20,}" /root/musubi-tuner 2>/dev/null
   ```

## 12. 给 Agent 的执行顺序

1. 确认 AutoDL 镜像是 `PyTorch 2.8.0 + CUDA 12.8 + Python 3.12 + Ubuntu 22.04`。
2. `nvidia-smi` 确认 RTX 5090。
3. `git clone https://github.com/kohya-ss/musubi-tuner.git /root/musubi-tuner`。
4. 进入项目目录建 venv 并激活。
5. `pip install torch==2.8.0 ... --index-url .../cu128`。
6. `pip install -e .`，可选 `pip install ascii-magic matplotlib tensorboard prompt-toolkit`。
7. `python -c "import torch; assert torch.cuda.is_available()"`。
8. `accelerate config`（按本文档第 6 节作答）。
9. 跑一次最小 Qwen-Image LoRA（第 9 节）作为冒烟测试。
10. 若 Python 3.12 在第 5 / 9 步报兼容错，按第 3 节 fallback 改 conda 3.10 重跑。
11. 通过后把 profile `status = "draft"` 改成 `"active"`，回填实测发现的版本细节到 `[notes]` 与本文档第 11 节。

## 13. 常见问题

### 13.1 `pip install -e .` 报 cp312 wheel 不存在

某些上游依赖（典型如旧版 bitsandbytes、某些 attention kernel）暂未提供 Python 3.12 wheel。两条出路：

- 先升级该依赖：`pip install -U <pkg>` 看 PyPI 上是否已发 cp312 wheel。
- 或回到 fallback 方案，建 conda 3.10 环境重装。

### 13.2 训练中 `torch.cuda.is_available() == False`

参考 [`lora-scripts-next-5090-deploy.md`](lora-scripts-next-5090-deploy.md) 第 9.2 节，重装匹配的 cu128 wheel：

```bash
pip uninstall -y torch torchvision torchaudio
pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128
```

### 13.3 SageAttention / FlashAttention 装不上

Blackwell + cu128 当前对这两个 kernel 的预编译 wheel 支持参差。按上游建议：**优先用 PyTorch 2.x 自带 SDPA**（在训练命令里 `--attn_mode torch`），SageAttention 仅推理时按需自行编译。不要为了 SageAttention 降 CUDA。

### 13.4 共享盘模型路径 404

确认实际路径：

```bash
ls /.autodl-model/data/black-forest-labs/
ls /.autodl-model/data/Qwen/
ls /.autodl-model/data/Tongyi-MAI/
```

如果路径变更，回头更新 profile [`musubi-tuner.toml`](../image-profiles/musubi-tuner.toml) 的 `[shared_models]`。
