# AutoDL Agent 系统维护指南

本文档说明如何维护 `Cloud-All-in-one/autodl`，包括新增 skill、新增镜像 profile、接入新的 trainer，以及什么时候需要重构。

## 维护原则

1. 通用 AutoDL 能力放在 `skills/autodl-common/`。
2. 云端实例、上传下载、远程执行放在 `skills/cloud-training/`。
3. 镜像差异放在 `image-profiles/`。
4. 具体训练逻辑优先放到独立 trainer 仓库，不要塞进 AutoDL 通用层。
5. 某个镜像专属逻辑必须在文档开头写明适用 profile，避免误用于其他镜像。

## 什么时候新增 skill

新增 skill 适合这些情况：

- 任务有明确边界，且会反复使用。
- 任务需要一套固定检查流程或操作流程。
- 任务不适合只写在 README 中。

不要新增 skill 的情况：

- 只是某个 profile 的一个路径差异。
- 只是某个 trainer 的训练参数。
- 只是一次性临时操作。

新增 skill 步骤：

1. 在 `autodl/skills/<skill-name>/SKILL.md` 新建文档。
2. 在 frontmatter 写清楚 `name` 和 `description`。
3. 写明适用边界：负责什么、不负责什么。
4. 写明输入、输出、检查命令和失败处理。
5. 更新 `autodl/AGENTS.md` 的 Skills 表和任务路由。
6. 如果对外部用户重要，更新根目录 `README.md`。

## 什么时候新增镜像 profile

新增 AutoDL 镜像时，优先新增 profile，而不是新增 skill。

profile 位置：

```bash
autodl/image-profiles/<image-id>.toml
```

建议至少包含：

```toml
id = "example"
display_name = "Example AutoDL 镜像"
status = "draft"

[paths]
project_dir = "/root/example"
dataset_root = "/root/autodl-tmp/datasets"
job_config_dir = "/root/autodl-tmp/jobs"
output_dir = "/root/autodl-tmp/output"
log_dir = "/root/autodl-tmp/logs"
shared_model_dir = "/.autodl-model/data"

[runtime]
conda_env = ""
setup_command = ""
ui_command = ""
ui_port = 6006
tmux_ui_session = ""

[maintenance]
update_skill = "autodl-common"
model_link_skill = ""
model_link_script = ""

[trainer]
type = "manual"
name = ""
repo = ""
install_dir = ""
profile = "autodl"
supported_tasks = []
```

profile 状态约定：

| 状态 | 含义 |
|---|---|
| `draft` | 只记录了预期路径，尚未在真实镜像验证 |
| `active` | 已在真实镜像验证，Agent 可以按它执行 |
| `deprecated` | 不再维护，但保留给历史镜像参考 |

## 什么时候接入独立 trainer

如果某个训练框架需要自动验证数据集、生成配置、启动训练，建议独立为 trainer 仓库。

适合独立 trainer 的情况：

- 训练逻辑不依赖 AutoDL，也可以本地或其他云平台使用。
- 需要脚本、TOML、数据集约定和启动流程。
- 后续可能被多个云平台调用。

命名建议：

```text
<framework>-trainer
```

例如：

- `aitoolkit-trainer`
- `lora-scripts-trainer`
- `kohya-trainer`

接入步骤：

1. 建立独立 trainer 仓库。
2. trainer 仓库提供 `AGENTS.md`、`SKILL.md`、默认 TOML 和脚本。
3. 在对应 `image-profiles/<image-id>.toml` 的 `[trainer]` 中填写：

```toml
[trainer]
type = "external"
name = "aitoolkit-trainer"
repo = "https://github.com/wochenlong/aitoolkit-trainer"
install_dir = "/root/aitoolkit-trainer"
profile = "autodl"
supported_tasks = ["image", "image_edit"]
```

4. 更新 `cloud-training`，说明该 profile 如何调用 trainer。
5. 更新根 README 的“当前支持什么”表格。

## 什么时候重构

出现以下情况时应该重构：

- 一个 skill 同时处理 AutoDL 通用逻辑和某个训练框架专属逻辑。
- 一个 profile 中开始出现大量流程说明，而不只是路径和环境。
- 两个以上镜像重复维护同一类脚本。
- README 开始解释太多执行细节，导致新读者看不出主线。
- 某个 trainer 可以脱离 AutoDL 使用，但仍放在 `autodl/skills/` 内。

重构方向：

| 问题 | 处理 |
|---|---|
| 通用逻辑和镜像逻辑混在一起 | 通用部分移到 `autodl-common`，镜像差异移到 profile |
| 训练逻辑太重 | 独立成 `<framework>-trainer` |
| 云端编排和训练执行混在一起 | `cloud-training` 只保留实例/传输/远程调用 |
| README 过长 | README 保留主线，细节移到 `autodl/docs/` |

## 修改后的检查流程

每次修改后至少检查：

```bash
# TOML 是否能解析
python - <<'PY'
import tomllib
from pathlib import Path
for p in Path("autodl/image-profiles").glob("*.toml"):
    with p.open("rb") as f:
        tomllib.load(f)
    print(f"OK {p}")
PY

# 搜索旧路径或旧 skill 名
rg "ai-toolkit-training|skills/ai-toolkit-training|/root/autodl-tmp/模型路径" autodl README.md

# 查看 git 状态
git status --short
```

如果修改了外部 trainer，还要在对应仓库运行它自己的脚本语法检查。

## 提交和同步

提交建议：

```bash
git status --short
git diff --stat
git add <changed-files>
git commit -m "docs(autodl): describe the change"
git push origin main
```

安全规则：

- 不要把 GitHub token、AutoDL token、SSH 私钥写入仓库。
- 不要把 token 写入 git config。
- 临时推送认证必须是一次性的，用完删除。
- 镜像要发给用户时，确认 `/root/` 下没有开发者私密凭据。

## 发布前检查清单

合并到 main 或同步云端前：

- `README.md` 能让新读者一眼理解当前主线。
- `autodl/AGENTS.md` 的任务路由仍然准确。
- 新镜像已经有 `image-profiles/<id>.toml`。
- 新 skill 已加入 `autodl/AGENTS.md`。
- 专属逻辑没有误写成通用逻辑。
- token、密码、私钥没有进入 git diff。
