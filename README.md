# Cloud-All-in-one

面向 Agent 的云端推理与训练资料库。

这个仓库目前重点维护 **AutoDL 多镜像训练工作流**：让 Agent 知道怎么使用 AutoDL、怎么区分不同训练镜像、怎么维护镜像，以及什么时候调用独立训练工具。

## 当前支持什么

### AutoDL 训练镜像

| 镜像 | 状态 | 说明 | 地址 |
|---|---|---|---|
| AI-Toolkit | 已接入 | 支持 Qwen Image/Edit、FLUX、Wan、LTX 等 AI-Toolkit 训练流程；训练自动化由外部 `aitoolkit-trainer` 负责 | https://www.autodl.art/app/market/13 |
| 秋叶训练包（Akegarasu/lora-scripts） | profile 草案 | 已建立 AutoDL 镜像 profile；实际训练命令和自动化流程待挂载镜像后校准 | https://www.autodl.art/app/market/11? |

### 独立训练工具

AI-Toolkit 的训练逻辑已经拆到独立仓库：

https://github.com/wochenlong/aitoolkit-trainer

`Cloud-All-in-one/autodl` 负责 AutoDL 平台和镜像编排，`aitoolkit-trainer` 负责 AI-Toolkit 数据集验证、训练配置生成和 tmux 启动训练。

## 给 Agent 怎么用

克隆本仓库后，Agent 先读：

```bash
autodl/AGENTS.md
```

然后按任务分流：

| 用户要做什么 | 看哪里 |
|---|---|
| 不确定当前是什么镜像，只想了解 AutoDL 通用规则 | `autodl/skills/autodl-common/SKILL.md` |
| 启动 UI、开关网络加速、检查数据盘、排查常见问题 | `autodl/skills/daily-ops/SKILL.md` |
| 用 AutoDL API 创建实例、上传数据、下载结果 | `autodl/skills/cloud-training/SKILL.md` |
| 判断某个镜像的路径、环境、启动命令和 trainer | `autodl/image-profiles/*.toml` |
| 维护 AI-Toolkit 镜像里的模型链接脚本 | `autodl/skills/scripts-update/SKILL.md` |
| 更新 AI-Toolkit 镜像、保存镜像前检查 | `autodl/skills/image-maintenance/SKILL.md` |
| 在 AI-Toolkit 里真正开始训练 | https://github.com/wochenlong/aitoolkit-trainer |

## 设计思路

这个仓库把 AutoDL 工作流拆成四层：

1. **怎么用云端**  
   `cloud-training` 负责 AutoDL API、实例创建、SSH/SCP/rsync、上传下载、关机释放。

2. **怎么用 AutoDL**  
   `autodl-common` 负责所有 AutoDL 镜像都通用的规则，例如 6006 端口、`/root/autodl-tmp` 数据盘、`/etc/network_turbo`、tmux 长任务。

3. **怎么用/更新某个镜像**  
   `image-profiles/` 描述不同镜像的路径和环境；AI-Toolkit 专属维护由 `image-maintenance` 和 `scripts-update` 处理。

4. **怎么用镜像训练**  
   训练逻辑不强行塞进 AutoDL 通用层。AI-Toolkit 使用独立的 `aitoolkit-trainer`；其他镜像以后可以有自己的 trainer。

## 仓库结构

```text
Cloud-All-in-one/
├── autodl/
│   ├── AGENTS.md                    # Agent 入口：层级说明和任务路由
│   ├── config/
│   │   └── env.sh                   # AutoDL 环境变量
│   ├── docs/
│   │   └── autodl-model-request.md  # 请求 AutoDL 补充共享模型的清单
│   ├── image-profiles/              # 不同 AutoDL 镜像的路径、环境和 trainer 配置
│   │   ├── ai-toolkit.toml
│   │   └── lora-scripts.toml
│   └── skills/
│       ├── autodl-common/           # 所有 AutoDL 镜像通用规则
│       ├── cloud-training/          # API 创建实例、上传训练集、调用 trainer、下载结果
│       ├── daily-ops/               # 日常启动、网络加速、磁盘和常见问题
│       ├── image-maintenance/       # AI-Toolkit 镜像维护
│       └── scripts-update/          # AI-Toolkit 模型链接脚本维护
└── README.md
```

## 镜像 Profiles

AutoDL 通用能力和具体训练镜像解耦。镜像差异写在：

```bash
autodl/image-profiles/
```

| Profile | 状态 | 用途 |
|---|---|---|
| `ai-toolkit.toml` | active | 当前 AI-Toolkit AutoDL 镜像，调用外部 `aitoolkit-trainer` |
| `lora-scripts.toml` | draft | 秋叶训练包镜像草案，待实际镜像确认 conda 环境、启动命令和训练流程 |

## AI-Toolkit 镜像专属内容

AI-Toolkit 镜像使用 AutoDL 共享模型目录，模型链接脚本位于：

```bash
autodl/skills/scripts-update/scripts/update-aitoolkitmodel.sh
```

作用是将 AutoDL 共享目录 `/.autodl-model/data/` 中的模型链接到 `/root/ai-toolkit/`，避免重复下载。

在 AutoDL AI-Toolkit 实例中执行：

```bash
bash autodl/skills/scripts-update/scripts/update-aitoolkitmodel.sh
```

当前脚本覆盖的主要共享模型包括 FLUX.1/2、Qwen Image/Edit、ERNIE-Image、Z-Image、Zeta-Chroma、LTX、Wan2.2、Mistral 和相关精度恢复适配器。

## 相关项目

- [aitoolkit-trainer](https://github.com/wochenlong/aitoolkit-trainer) — 面向 Agent 的 AI-Toolkit 训练助手
- [ostris/ai-toolkit](https://github.com/ostris/ai-toolkit) — AI-Toolkit 上游项目
- [Akegarasu/lora-scripts](https://github.com/Akegarasu/lora-scripts) — 秋叶训练包上游项目
- [AutoDL](https://www.autodl.com/home) — GPU 云平台
