---
name: ai-toolkit-training
description: 使用 AI-Toolkit 启动训练任务。用于数据集已上传到 AutoDL 后，生成训练配置、检查模型链接、用 tmux 启动训练、监控日志并定位输出模型。
---

# AI-Toolkit 训练流程

## 适用边界

本 skill 负责**实例内部训练**，默认用户已经手动完成：

1. 数据集上传到 AutoDL 实例
2. 训练结果下载由用户手动处理，或后续交给 `cloud-training`

本 skill 不负责创建/释放实例，也不负责文件传输。

## 路径约定

| 类型 | 路径 | 说明 |
|---|---|---|
| AI-Toolkit | `/root/ai-toolkit` | 主项目目录 |
| 数据集 | `/root/autodl-tmp/datasets/<job_name>/` | 用户手动上传 |
| 训练配置 | `/root/autodl-tmp/jobs/<job_name>.yaml` | 由 agent 生成或从模板复制 |
| 输出目录 | `/root/autodl-tmp/output/` | 推荐统一输出到数据盘 |
| 日志目录 | `/root/autodl-tmp/logs/` | tmux 外的日志副本 |

不要把数据集、模型权重、训练输出放到 `/root/` 系统盘。

## 数据集格式

图片训练默认格式：

```text
/root/autodl-tmp/datasets/my_job/
├── image001.png
├── image001.txt
├── image002.jpg
├── image002.txt
└── ...
```

约定：

- 图片支持 `jpg`、`jpeg`、`png`
- caption 文件与图片同名，扩展名为 `.txt`
- caption 为空时，配置里应设置 `default_caption`
- 触发词可写入 caption，也可用配置里的 `trigger_word`

视频训练（如 Wan/LTX）可以放视频文件，但必须在配置里明确 `num_frames`、分辨率和采样策略。

## 训练配置来源

优先复制 AI-Toolkit 官方示例，再修改关键字段：

```bash
cp /root/ai-toolkit/config/examples/train_lora_qwen_image_24gb.yaml \
  /root/autodl-tmp/jobs/my_job.yaml
```

常用示例：

| 目标模型 | 示例配置 |
|---|---|
| FLUX.1/FLUX.1 Kontext | `train_lora_flux_24gb.yaml`, `train_lora_flux_kontext_24gb.yaml` |
| Qwen Image | `train_lora_qwen_image_24gb.yaml` |
| Qwen Image Edit | `train_lora_qwen_image_edit_2509_32gb.yaml`, `train_lora_qwen_image_edit_32gb.yaml` |
| Wan2.2 14B | `train_lora_wan22_14b_24gb.yaml` |
| Chroma | `train_lora_chroma_24gb.yaml` |
| Flex.2 | `train_lora_flex2_24gb.yaml` |
| OmniGen2 | `train_lora_omnigen2_24gb.yaml` |
| HiDream | `train_lora_hidream_48.yaml` |

如果没有现成示例，先从最接近的 LoRA 配置复制，再根据模型 `arch` 和 `name_or_path` 修改。

## 必改字段

每个训练配置至少修改：

```yaml
config:
  name: "<job_name>"
  process:
    - training_folder: "/root/autodl-tmp/output"
      datasets:
        - folder_path: "/root/autodl-tmp/datasets/<job_name>"
          caption_ext: "txt"
          resolution: [512, 768, 1024]
      train:
        steps: 2000
        batch_size: 1
        gradient_checkpointing: true
        optimizer: "adamw8bit"
        dtype: bf16
      model:
        name_or_path: "<本地可解析模型路径或 HF id>"
```

推荐：

- `training_folder` 使用绝对路径 `/root/autodl-tmp/output`
- 24GB/32GB 卡优先 `batch_size: 1`
- 大模型优先打开 `quantize: true`、`low_vram: true`
- Qwen/Wan 等大模型优先启用 `cache_text_embeddings: true`
- `push_to_hub: false`，不要默认上传 HuggingFace

## 模型路径约定

先运行模型链接脚本：

```bash
bash /root/update-aitoolkitmodel.sh
```

配置里的 `name_or_path` 可以继续使用 HF id，例如：

```yaml
name_or_path: "Qwen/Qwen-Image"
```

因为脚本会创建：

```text
/root/ai-toolkit/Qwen/Qwen-Image -> /.autodl-model/data/Qwen/Qwen-Image
```

AI-Toolkit 的本地修改会优先解析这些本地路径，避免重新从 HF 下载。

## 启动训练

长期任务必须用 `tmux`。

```bash
source /root/miniconda3/etc/profile.d/conda.sh
conda activate ai-toolkit
bash /root/update-aitoolkitmodel.sh
mkdir -p /root/autodl-tmp/jobs /root/autodl-tmp/output /root/autodl-tmp/logs

tmux new-session -d -s train_<job_name> \
  "cd /root/ai-toolkit && python run.py /root/autodl-tmp/jobs/<job_name>.yaml 2>&1 | tee /root/autodl-tmp/logs/<job_name>.log"
```

查看训练：

```bash
tmux attach -t train_<job_name>
```

退出但保持训练：

```text
Ctrl-b d
```

## 监控与判断

```bash
# 查看最近日志
tail -n 100 /root/autodl-tmp/logs/<job_name>.log

# 查看 GPU
nvidia-smi

# 查看输出
find /root/autodl-tmp/output -maxdepth 4 -type f | sort
```

常见输出通常在：

```text
/root/autodl-tmp/output/<job_name>/
```

中间 LoRA 权重一般是 `.safetensors` 文件。

## 常见问题

| 问题 | 处理 |
|---|---|
| OOM | 降低分辨率、确认 `batch_size: 1`、开启 `gradient_checkpointing`、`quantize`、`low_vram` |
| 重新下载模型 | 确认执行过 `/root/update-aitoolkitmodel.sh`，检查 `/root/ai-toolkit/<org>/<model>` 链接 |
| caption 不生效 | 检查 `.txt` 是否与图片同名，`caption_ext` 是否为 `txt` |
| 训练跑在系统盘 | 检查 `training_folder` 是否为 `/root/autodl-tmp/output` |
| SSH 断开训练停了 | 没用 tmux，重新按 tmux 方式启动 |

## Agent 工作流

当用户说“帮我训练一个模型”时：

1. 询问模型类型、数据集路径、job 名、训练步数、触发词、样例 prompt
2. 检查数据集目录和 caption 数量
3. 选择最接近的官方示例配置
4. 复制到 `/root/autodl-tmp/jobs/<job_name>.yaml`
5. 修改必改字段
6. 执行 `/root/update-aitoolkitmodel.sh`
7. 用 tmux 启动训练
8. 返回 tmux 会话名、日志路径、输出路径
