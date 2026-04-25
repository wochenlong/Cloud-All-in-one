---
name: cloud-training
description: 使用 AutoDL 官方 API 编排云端训练。用于从本地数据集一键创建实例、上传数据、启动训练、下载结果、关机/释放实例。
---

# 云端训练编排

## 目标

让用户只准备本地训练集、镜像 profile 和 AutoDL 开发者 Token，就能由 agent 自动完成：

1. 创建 AutoDL 应用实例
2. 等待实例进入 `running`
3. 获取 SSH/Jupyter/6006 服务信息
4. 上传训练集和配置
5. 启动训练
6. 下载 LoRA/模型输出
7. 关机或释放实例

本 skill 是 AutoDL 云端编排层，不绑定某一个训练镜像。具体镜像差异读取：

```bash
autodl/image-profiles/<profile>.toml
```

## AutoDL API 能力边界

官方应用实例 API 负责**实例生命周期**：

- 创建实例：`POST /api/v1/adl_dev/dev/instance/pro/create`
- 获取详情：`GET /api/v1/adl_dev/dev/instance/pro/snapshot`
- 获取状态：`GET /api/v1/adl_dev/dev/instance/pro/status`
- 获取列表：`POST /api/v1/adl_dev/dev/instance/pro/list`
- 开机：`POST /api/v1/adl_dev/dev/instance/pro/power_on`
- 关机：`POST /api/v1/adl_dev/dev/instance/pro/power_off`
- 释放：`POST /api/v1/adl_dev/dev/instance/pro/release`

API host: `https://www.autodl.art`

鉴权方式：

```python
headers = {"Authorization": os.environ["AUTODL_TOKEN"]}
```

Token 获取位置：AutoDL 控制台 → 账号 → 设置 → 开发者 Token。

## 文件传输方案

当前官方 API 文档未提供通用文件上传/下载接口。备用方案：

1. 通过 `snapshot` 接口获取 `proxy_host`、`ssh_port`、`root_password`
2. 使用 `scp` / `rsync` / `sftp` 上传训练集到远端 `/root/autodl-tmp/datasets/`
3. 使用 `ssh` 在远端执行训练命令
4. 使用 `scp` / `rsync` 下载 `/root/autodl-tmp/output/` 结果

如果未来 AutoDL 提供文件传输 API，优先替换 SSH/SCP 层，实例生命周期逻辑保持不变。

## 与 trainer 的交接

`cloud-training` 只负责编排云实例和文件传输；训练本身交给 profile 指定的 trainer。

交接契约：

| 阶段 | cloud-training 负责 | trainer 负责 |
|---|---|---|
| 准备实例 | 创建/开机/等待 `running` | 不参与 |
| 准备数据 | 上传数据集到远端数据盘 | 验证数据集结构 |
| 准备配置 | 传入 job 名、数据集路径、训练类型 | 生成 AI-Toolkit YAML |
| 启动任务 | 通过 SSH 执行远端脚本 | 用 tmux 启动训练 |
| 结果处理 | 下载输出、关机/释放实例 | 输出日志路径、tmux 会话名、输出目录 |

### AI-Toolkit profile

`image-profiles/ai-toolkit.toml` 指向独立仓库 [aitoolkit-trainer](https://github.com/wochenlong/aitoolkit-trainer)。

如果训练工具仓库未部署到远端，应先执行：

```bash
git clone https://github.com/wochenlong/aitoolkit-trainer.git /root/aitoolkit-trainer
```

### 其他 profile

如果 profile 的 `[trainer] type = "manual"`，说明还没有自动训练工具。此时 cloud-training 只应完成：

1. 创建实例
2. 上传数据
3. 打印 SSH/Jupyter/6006 信息
4. 提醒用户按该镜像官方流程手动训练

不要强行套用 `aitoolkit-trainer`。

## 安全规则

- **不要**把 `AUTODL_TOKEN` 写入镜像、仓库、脚本默认值或日志
- token 只从本地环境变量读取
- 远端实例里的 `/root/` 会进镜像，临时 token 不要写入 `/root/`
- 数据集和训练输出放 `/root/autodl-tmp/`，避免污染系统盘镜像
- 训练完成后默认关机；确认无需保留实例时再释放

## 推荐本地命令形态

未来脚本应支持类似：

```bash
export AUTODL_TOKEN="..."

python train_on_autodl.py \
  --application-uuid "J1c7lsvbq5" \
  --gpu-spec "5090-p" \
  --profile ai-toolkit \
  --dataset ./dataset \
  --output ./outputs \
  --shutdown
```

## 编排流程

### 1. 创建实例

请求体关键字段：

```json
{
  "req_gpu_amount": 1,
  "expand_system_disk_by_gb": 0,
  "gpu_spec_uuid": "5090-p",
  "application_uuid": "应用UUID",
  "application_version": "latest",
  "instance_name": "训练任务名",
  "start_command": "sleep 1"
}
```

### 2. 轮询状态

调用 status，等待返回：

```text
running
```

### 3. 获取连接信息

调用 snapshot，读取：

- `proxy_host`
- `ssh_port`
- `root_password`
- `service_6006_domain`

### 4. 上传数据

优先用 `rsync`，失败再退回 `scp`：

```bash
rsync -avP -e "ssh -p ${SSH_PORT}" ./dataset/ root@${PROXY_HOST}:/root/autodl-tmp/datasets/job/
scp -P "${SSH_PORT}" ./train.yaml root@${PROXY_HOST}:/root/autodl-tmp/jobs/train.yaml
```

如果本地没有配置免密 SSH，需要用 `sshpass` 或交互式输入密码。自动化脚本应优先提示用户配置 SSH key。

### 5. 启动训练

先读取 `image-profiles/<profile>.toml` 的 `[trainer]`。

如果是 `ai-toolkit` profile，远端优先调用 `aitoolkit-trainer`，不直接手写 `python run.py`：

```bash
cd /root/aitoolkit-trainer

python scripts/validate_qwen_dataset.py \
  --profile autodl \
  --mode image \
  --dataset /root/autodl-tmp/datasets/job

python scripts/generate_qwen_config.py \
  --profile autodl \
  --mode image \
  --job-name job \
  --dataset /root/autodl-tmp/datasets/job

bash scripts/start_ai_toolkit_training.sh \
  --profile autodl \
  --job-name job \
  --config-yaml /root/autodl-tmp/jobs/job.yaml
```

图像编辑任务改用：

```bash
python scripts/validate_qwen_dataset.py \
  --profile autodl \
  --mode edit \
  --target /root/autodl-tmp/datasets/job/target \
  --control /root/autodl-tmp/datasets/job/control
```

训练启动脚本会按 `training.defaults.toml` 使用 tmux，并返回会话名和日志路径。

如果是 `lora-scripts` 等尚未接入 trainer 的 profile，先不要自动启动训练，只打印远端连接信息和已上传路径。

### 6. 下载结果

```bash
rsync -avP -e "ssh -p ${SSH_PORT}" root@${PROXY_HOST}:/root/autodl-tmp/output/ ./outputs/
```

### 7. 关机/释放

默认关机，避免继续计费。只有用户明确确认后再释放实例。

## 最小可行版本

第一版脚本只需要实现：

1. 创建实例
2. 等待 running
3. 打印 SSH 命令和 6006 访问地址

之后再逐步加入上传、训练、下载和自动关机。
