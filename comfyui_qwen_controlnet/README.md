# ComfyUI Qwen Image ControlNet Plugin

真正的 Qwen Image ControlNet 插件 - 不是 LoRA！

## 功能特性

- **真正的 ControlNet**: 基于 Qwen Image 模型的 ControlNet 实现
- **易于使用**: 简单的节点界面，拖拽即用
- **对比功能**: 可视化对比原始输出和受控输出
- **GPU 加速**: 支持 CUDA 加速推理
- **模型信息**: 显示详细的模型架构和参数信息

## 安装方法

### 方法 1: 直接复制
1. 将整个 `comfyui_qwen_controlnet` 文件夹复制到 ComfyUI 的 `custom_nodes` 目录
2. 重启 ComfyUI

### 方法 2: Git 克隆
```bash
cd ComfyUI/custom_nodes
git clone https://github.com/wochenlong/Cloud-All-in-one
# 或者只复制插件目录
cp -r Cloud-All-in-one/comfyui_qwen_controlnet .
```

### 方法 3: 符号链接
```bash
# Windows (管理员权限)
mklink /D "ComfyUI\custom_nodes\comfyui_qwen_controlnet" "D:\ai\comfyui_qwen_controlnet"

# Linux/Mac
ln -s /path/to/comfyui_qwen_controlnet ComfyUI/custom_nodes/
```

## 节点说明

### Qwen ControlNet Loader
加载训练好的 Qwen ControlNet 模型。

| 参数 | 说明 |
|---|---|
| `checkpoint_path` | ControlNet 权重文件路径 (.pt 文件) |
| `device` | 计算设备 (auto/cpu/cuda:0/cuda:1) |

**输出**: `qwen_controlnet_model` — 加载好的模型对象

### Qwen ControlNet Apply
应用 ControlNet 生成受控图像。

| 参数 | 说明 |
|---|---|
| `qwen_controlnet_model` | 加载的模型 |
| `image` | 原始输入图像 |
| `control_image` | 控制图像（如 Canny 边缘图）|
| `control_strength` | 控制强度 (0.0-2.0) |
| `size` | 输出图像尺寸 |

**输出**: `controlled_image` — 受 ControlNet 控制的输出图像

### Qwen ControlNet Compare
对比原始输出和受控输出。

**输出**:
- `original_output`: 无控制的原始输出
- `controlled_output`: 受控制的输出
- `comparison_grid`: 四宫格对比图（原图 | 控制图 | 原始输出 | 受控输出）

### Qwen ControlNet Info
显示模型详细信息，包括架构和参数信息。

## 使用流程

### 基础工作流
```
Load Image (原图) ────┐
                     ├─→ Qwen ControlNet Apply ─→ Save Image
Load Image (控制图) ──┤
                     │
Qwen ControlNet Loader ────┘
```

### 对比工作流
```
Load Image (原图) ────┐
                     ├─→ Qwen ControlNet Compare ─→ Save Image (对比图)
Load Image (控制图) ──┤
                     │
Qwen ControlNet Loader ────┘
```

## 文件结构

```
comfyui_qwen_controlnet/
├── __init__.py          # 插件初始化
├── models.py            # 模型定义
├── smart_loader.py      # 智能模型加载
├── nodes_backup.py      # 节点备份
└── README.md            # 使用说明
```

## 配置说明

### 检查点路径
默认路径: `D:/ai/ai-toolkit/output/qwen_controlnet_gpu/qwen_controlnet_final.pt`

支持的格式:
- 直接的 ControlNet 权重文件 (`qwen_controlnet_final.pt`)
- 完整的训练检查点 (`controlnet_checkpoint_*.pt`)

### 设备选择
| 选项 | 说明 |
|---|---|
| `auto` | 自动选择最佳设备 |
| `cpu` | 强制使用 CPU |
| `cuda:0` | 使用第一块 GPU |
| `cuda:1` | 使用第二块 GPU |

## 常见问题

**找不到检查点文件**: 确保路径正确，文件存在。支持绝对路径和相对路径。

**CUDA 内存不足**: 减小图像尺寸、使用 CPU、或关闭其他 GPU 程序。

**控制效果不明显**: 增加 `control_strength`、检查控制图像质量、验证模型训练效果。

**加载模型失败**: 检查 PyTorch 版本兼容性，确认权重文件完整性。

## 性能建议

- GPU: 推荐 RTX 20 系列以上，8GB+ 显存，512x512 分辨率
- CPU: 建议使用 256x256 分辨率，减少单次处理量

## 许可证

本项目采用 MIT 许可证。
