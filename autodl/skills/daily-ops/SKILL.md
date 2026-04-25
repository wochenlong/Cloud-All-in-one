---
name: daily-ops
description: AutoDL 日常操作速查。用于启动 UI、网络加速、存储检查和常见问题；具体命令需结合 image-profiles。
---

# 日常操作

本 skill 是速查层。执行前先读取 [autodl-common](../autodl-common/SKILL.md) 和对应 `image-profiles/<profile>.toml`。

## 启动 UI

优先使用当前 profile 的 `runtime.ui_command`。AI-Toolkit 镜像默认：

```bash
bash /root/start.sh
# 自动创建 tmux 会话 "aiui"，查看: tmux attach -t aiui
```

## 网络加速

任何外网操作前必须开启，否则极慢：

```bash
source /etc/network_turbo        # 开启
unset http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY  # 关闭
```

## 存储规则

- **系统盘** `/root/`（30G，随镜像保存）→ 放代码、配置
- **数据盘** `/root/autodl-tmp`（大，不保存）→ 放模型、数据集
- **共享目录** `/.autodl-model/data/`（只读）→ AutoDL 预置的 HF 模型

## 检查模型可用性

共享模型检查是 AutoDL 通用能力，但具体模型列表由当前镜像决定。AI-Toolkit 示例：

```bash
# 某个模型是否在共享目录
ls /.autodl-model/data/black-forest-labs/FLUX.2-dev

# 批量检查
for p in "baidu/ERNIE-Image" "NucleusAI/Nucleus-Image" "lodestones/Chroma1-Base"; do
  [ -d "/.autodl-model/data/$p" ] && echo "✅ $p" || echo "❌ $p"
done
```

## 常见问题

| 问题 | 解决 |
|---|---|
| UI 启动后访问不了 | 确认端口 6006: `echo $PORT`，通过 AutoDL「自定义服务」访问 |
| AI-Toolkit 模型加载失败 | 检查符号链接: `ls -la /root/ai-toolkit/<org>/<model>`，运行 `bash /root/update-aitoolkitmodel.sh` |
| pip/git 超时 | 忘了开加速: `source /etc/network_turbo` |
| 系统盘满 | `du -sh /root/*/ \| sort -rh \| head`，清理 `.cache/` |
| 训练中断 | 确认是否在 tmux/screen 中运行 |
