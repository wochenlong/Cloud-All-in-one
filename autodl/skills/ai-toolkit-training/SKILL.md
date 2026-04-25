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

## 第一版支持范围

AI-Toolkit 支持的模型可粗略分为四类：

1. 图像生成
2. 图像编辑
3. 视频（文生视频 / 图生视频）
4. 音频

第一版只正式支持**图像生成**和**图像编辑**，以 Qwen 系列作为标准样板：

| 类型 | 首选模型 | 示例配置 | 状态 |
|---|---|---|---|
| 图像生成 | `Qwen/Qwen-Image` | `train_lora_qwen_image_24gb.yaml` | 第一版支持 |
| 图像编辑 | `Qwen/Qwen-Image-Edit-2509` | `train_lora_qwen_image_edit_2509_32gb.yaml` | 第一版支持 |
| 图像编辑（旧版） | `Qwen/Qwen-Image-Edit` | `train_lora_qwen_image_edit_32gb.yaml` | 可作为兼容参考 |
| 视频 | Wan / LTX | 暂不作为第一版目标 | 后续支持 |
| 音频 | ACE-Step | 暂不作为第一版目标 | 后续支持 |

如果用户指定 FLUX.2 Klein、Wan、LTX、音频等模型，先说明该 skill 的第一版重点是 Qwen 图像/图像编辑；确需继续时，再按最接近的官方示例谨慎修改。

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

## 已确认的数据规则

### Caption 规则

- 图片和 caption **不是硬性必须一一同名**，但第一版自动化要求尽量同名，最稳定。
- 代码会优先读取同名 caption：`image001.png` -> `image001.txt`。
- 没有同名 caption 时，会尝试读取数据集目录下的 `default.txt`。
- 如果配置里设置了 `default_caption`，空 caption 或缺失 caption 会使用它兜底。
- `caption_ext: "txt"` 会被规范成 `.txt`，所以配置里写 `txt` 即可。
- JSON caption 也可用，字段名为 `caption`，但第一版不主动支持 JSON，避免复杂化。

### Trigger Word 规则

- `trigger_word` 支持统一触发词。
- 如果 caption 中没有 trigger，AI-Toolkit 会自动把 trigger 加入 caption。
- 如果 caption 中写了 `[trigger]`，会替换成真实 trigger word。
- 如果没有 caption 且设置了 trigger，caption 会变成 trigger word。
- Qwen Image Edit 使用 `cache_text_embeddings: true` 时，不建议依赖 trigger word 动态注入；第一版优先要求 caption 中直接写好编辑指令。

### 图片扩展名规则

- 第一版统一要求小写扩展名：`.jpg`、`.jpeg`、`.png`、`.webp`。
- 不接受 `.JPG`、`.PNG` 这类大写扩展名，尤其是 Qwen Image Edit 的 control 图匹配容易因此失败。

### 图像生成数据集

Qwen Image 普通 LoRA 训练默认格式：

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

### 图像编辑数据集

Qwen Image Edit 需要**目标图像目录**和**控制图像目录**，文件名必须匹配。

已确认约定：

- target 是训练目标，也就是“编辑后 / 期望输出”的图片。
- control 是输入图，也就是“编辑前 / 参考输入”的图片。
- caption 写在 target 图片旁边，语义应是**编辑指令**，不是普通图像描述。
- control 图不需要 caption。
- target 与 control 通过 basename 匹配：`target/0001.png` 匹配 `control_1/0001.png`。
- 多 control 时，`control_1`、`control_2`、`control_3` 按列表顺序传入模型。
- 文件数量和 basename 应完全对齐；否则容易报 `Missing control images for QwenImageEditPlusModel`。

单控制图（旧版 `Qwen/Qwen-Image-Edit`）：

```text
/root/autodl-tmp/datasets/my_edit/
├── target/
│   ├── 0001.png
│   ├── 0001.txt
│   └── 0002.png
└── control/
    ├── 0001.png
    └── 0002.png
```

配置字段：

```yaml
datasets:
  - folder_path: "/root/autodl-tmp/datasets/my_edit/target"
    control_path: "/root/autodl-tmp/datasets/my_edit/control"
    caption_ext: "txt"
```

多控制图（推荐 `Qwen/Qwen-Image-Edit-2509` / `qwen_image_edit_plus`）：

```text
/root/autodl-tmp/datasets/my_edit_plus/
├── target/
├── control_1/
├── control_2/
└── control_3/
```

配置字段：

```yaml
datasets:
  - folder_path: "/root/autodl-tmp/datasets/my_edit_plus/target"
    control_path:
      - "/root/autodl-tmp/datasets/my_edit_plus/control_1"
      - "/root/autodl-tmp/datasets/my_edit_plus/control_2"
      - "/root/autodl-tmp/datasets/my_edit_plus/control_3"
    caption_ext: "txt"
```

视频和音频训练暂不纳入第一版标准流程。

## 训练配置来源

优先复制 AI-Toolkit 官方示例，再修改关键字段：

```bash
cp /root/ai-toolkit/config/examples/train_lora_qwen_image_24gb.yaml \
  /root/autodl-tmp/jobs/my_job.yaml
```

第一版常用示例：

| 目标模型 | 示例配置 |
|---|---|
| Qwen Image | `train_lora_qwen_image_24gb.yaml` |
| Qwen Image Edit 2509 | `train_lora_qwen_image_edit_2509_32gb.yaml` |
| Qwen Image Edit legacy | `train_lora_qwen_image_edit_32gb.yaml` |

其他模型先视为扩展目标。不要在第一版自动化里默认生成视频或音频训练配置。

## Qwen Image 标准配置要点

基于 `train_lora_qwen_image_24gb.yaml`：

```yaml
model:
  name_or_path: "Qwen/Qwen-Image"
  arch: "qwen_image"
  quantize: true
  qtype: "uint3|ostris/accuracy_recovery_adapters/qwen_image_torchao_uint3.safetensors"
  quantize_te: true
  qtype_te: "qfloat8"
  low_vram: true
train:
  batch_size: 1
  cache_text_embeddings: true
  train_text_encoder: false
```

## Qwen Image Edit 标准配置要点

优先使用 `train_lora_qwen_image_edit_2509_32gb.yaml`：

```yaml
model:
  name_or_path: "Qwen/Qwen-Image-Edit-2509"
  arch: "qwen_image_edit_plus"
  quantize: true
  qtype: "uint3|ostris/accuracy_recovery_adapters/qwen_image_edit_2509_torchao_uint3.safetensors"
  quantize_te: true
  qtype_te: "qfloat8"
  low_vram: true
train:
  batch_size: 1
  cache_text_embeddings: true
  train_text_encoder: false
```

如果用户明确要旧版 `Qwen/Qwen-Image-Edit`，使用：

```yaml
model:
  name_or_path: "Qwen/Qwen-Image-Edit"
  arch: "qwen_image_edit"
```

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
- 图像编辑必须修改 `control_path` 和 `sample.samples[*].ctrl_img*`

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
| Qwen Edit 报 `Missing control images` | 检查 `control_path` 是否存在、target/control basename 是否一致、扩展名是否小写、是否启用 `cache_text_embeddings: true` |
| Qwen Edit 学得随机 | 检查 target 与 control 是否错配；caption 是否是编辑指令而不是目标图描述 |
| 训练跑在系统盘 | 检查 `training_folder` 是否为 `/root/autodl-tmp/output` |
| SSH 断开训练停了 | 没用 tmux，重新按 tmux 方式启动 |

## Agent 工作流

当用户说“帮我训练一个模型”时：

1. 询问训练类型：图像生成还是图像编辑
2. 若图像生成，默认使用 `Qwen/Qwen-Image`
3. 若图像编辑，默认使用 `Qwen/Qwen-Image-Edit-2509`
4. 询问数据集路径、job 名、训练步数、触发词、样例 prompt
5. 图像编辑还要询问 control 图目录数量和路径
6. 检查数据集目录、caption 数量、control 文件名匹配情况
7. 选择对应 Qwen 官方示例配置
8. 复制到 `/root/autodl-tmp/jobs/<job_name>.yaml`
9. 修改必改字段
10. 执行 `/root/update-aitoolkitmodel.sh`
11. 用 tmux 启动训练
12. 返回 tmux 会话名、日志路径、输出路径
