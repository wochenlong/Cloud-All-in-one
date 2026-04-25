---
name: autodl-common
description: AutoDL 所有镜像通用操作。用于端口、数据盘、网络加速、SSH/tmux、镜像保存前检查和镜像 profile 识别。
---

# AutoDL 通用操作

本 skill 适用于所有 AutoDL 镜像，不绑定 AI-Toolkit、lora-scripts、kohya 或其他训练框架。

## 适用边界

负责：

- AutoDL 平台通用路径和端口规则
- `/root/autodl-tmp` 数据盘使用规范
- `/etc/network_turbo` 网络加速
- `tmux` / `screen` 长任务保护
- SSH、Jupyter、自定义服务访问
- 镜像保存前的通用检查
- 读取 `autodl/image-profiles/` 判断当前镜像类型

不负责：

- 具体训练框架的训练参数
- 某个项目的代码更新策略
- AI-Toolkit 模型链接脚本
- AutoDL 实例创建/释放 API 编排

## 通用环境规则

| 项目 | AutoDL 通用约定 |
|---|---|
| 系统盘 | `/`，常见为 30G，保存到镜像 |
| 数据盘 | `/root/autodl-tmp`，不随镜像保存，放数据集、输出、大文件 |
| 共享模型 | `/.autodl-model/data/`，只读，是否可用取决于镜像/平台 |
| Web 端口 | 优先使用 AutoDL 开放端口，当前常用 `6006` |
| 长任务 | 必须使用 `tmux` 或 `screen` |
| 网络加速 | 外网操作前执行 `source /etc/network_turbo` |

## 镜像 profile

镜像差异写在：

```bash
autodl/image-profiles/
```

Agent 处理任务前先判断用户当前镜像属于哪个 profile：

1. 如果用户明确说明镜像名，直接选择对应 profile。
2. 如果没说明，检查常见目录，例如 `/root/ai-toolkit`、`/root/lora-scripts`。
3. 如果无法判断，只执行通用 AutoDL 操作，不主动套用某个训练框架。

## 通用检查命令

```bash
# 确认端口
echo "${PORT:-未设置}"

# 确认数据盘
df -h / /root/autodl-tmp

# 查看 GPU
nvidia-smi

# 查看 tmux 会话
tmux ls || true

# 系统盘大文件排查
du -sh /root/* 2>/dev/null | sort -rh | head
```

## 网络加速

开启：

```bash
source /etc/network_turbo
```

关闭：

```bash
unset http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY
```

## 镜像保存前通用检查

保存任何 AutoDL 镜像前：

1. 停止长期任务和 Web 服务。
2. 确认 token、密码、私钥没有写入仓库或 `/root/` 下的配置文件。
3. 清理 pip/conda/HuggingFace 临时缓存。
4. 确认正式数据集和训练输出在 `/root/autodl-tmp`，不是系统盘。
5. 记录当前镜像 profile 和关键启动命令。

常用命令：

```bash
pip cache purge || true
conda clean -a -y || true
df -h /
```

## 与其他 skill 的关系

- 平台通用问题先用本 skill。
- 创建/释放实例、上传下载文件用 `cloud-training`。
- AI-Toolkit 镜像专属模型链接用 `scripts-update`。
- AI-Toolkit 训练用外部 `aitoolkit-trainer`。
- 其他训练镜像先补 `image-profiles/<name>.toml`，再决定是否需要独立 trainer。
