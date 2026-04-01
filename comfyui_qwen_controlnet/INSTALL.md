# 📦 ComfyUI Qwen ControlNet 插件安装指南

## 🎯 插件概述

这是一个**真正的Qwen Image ControlNet插件**，而不是LoRA！它可以让你在ComfyUI中使用自己训练的Qwen ControlNet模型。

## ✅ 系统要求

- **ComfyUI**: 已安装并能正常运行
- **Python**: 3.8+ (ComfyUI的Python环境)
- **PyTorch**: 与ComfyUI兼容的版本
- **显卡**: 推荐NVIDIA GPU，支持CUDA (可选，也支持CPU)
- **内存**: 推荐8GB+ RAM，4GB+ VRAM

## 📁 插件文件结构

```
comfyui_qwen_controlnet/
├── __init__.py              # 插件初始化
├── models.py               # 模型定义
├── nodes.py               # ComfyUI节点
├── workflow_basic.json    # 基础工作流
├── generate_canny_example.py # Canny图像生成工具
├── example.jpg            # 示例原图
├── example_canny.jpg      # 示例Canny图
├── README.md              # 详细说明
├── QUICK_START.md         # 快速上手
└── INSTALL.md             # 安装指南
```

## 🚀 安装步骤

### 方法1: 直接复制（推荐）

1. **下载插件文件夹**
   ```bash
   # 如果从git仓库
   git clone https://github.com/your-repo/ai-toolkit.git
   cd ai-toolkit
   ```

2. **复制到ComfyUI**
   ```bash
   # Windows
   copy /S comfyui_qwen_controlnet "C:\ComfyUI\custom_nodes\"
   
   # Linux/Mac
   cp -r comfyui_qwen_controlnet /path/to/ComfyUI/custom_nodes/
   ```

3. **重启ComfyUI**
   - 关闭ComfyUI
   - 重新启动
   - 检查控制台是否有错误信息

### 方法2: 符号链接

如果你想保持文件在原始位置：

```bash
# Windows (管理员权限CMD/PowerShell)
mklink /D "C:\ComfyUI\custom_nodes\comfyui_qwen_controlnet" "D:\ai\ai-toolkit\comfyui_qwen_controlnet"

# Linux/Mac
ln -s /path/to/ai-toolkit/comfyui_qwen_controlnet /path/to/ComfyUI/custom_nodes/
```

### 方法3: Git子模块

如果ComfyUI也在git管理下：

```bash
cd ComfyUI/custom_nodes
git submodule add https://github.com/your-repo/ai-toolkit.git
ln -s ai-toolkit/comfyui_qwen_controlnet ./
```

## 🔧 验证安装

### 1. 检查节点加载

启动ComfyUI后，检查：
- 控制台没有红色错误信息
- 节点面板中出现 "Qwen/ControlNet" 分类
- 包含4个节点：
  - 🎯 Qwen ControlNet Loader
  - 🎮 Qwen ControlNet Apply
  - 📊 Qwen ControlNet Compare
  - ℹ️ Qwen ControlNet Info

### 2. 加载基础工作流

1. 点击ComfyUI的 "Load" 按钮
2. 选择 `workflow_basic.json`
3. 工作流应该正确加载，显示完整的节点布局

### 3. 准备测试数据

1. **复制示例图像到ComfyUI输入目录**：
   ```bash
   # 复制插件目录中的示例图像
   copy comfyui_qwen_controlnet\example.jpg ComfyUI\input\
   copy comfyui_qwen_controlnet\example_canny.jpg ComfyUI\input\
   ```

2. **或者生成自己的Canny图像**：
   ```bash
   cd comfyui_qwen_controlnet
   python generate_canny_example.py your_image.jpg
   ```

## ⚙️ 配置模型路径

### 1. 准备模型文件

确保你有训练好的Qwen ControlNet模型：
- `qwen_controlnet_final.pt` (最终模型)
- 或 `controlnet_checkpoint_*.pt` (训练检查点)

### 2. 设置路径

在 "🎯 Qwen ControlNet Loader" 节点中：
- 修改 `checkpoint_path` 为你的模型路径
- 建议使用绝对路径
- 示例：`D:/ai/ai-toolkit/output/qwen_controlnet_gpu/qwen_controlnet_final.pt`

## 🧪 测试运行

### 基础测试

1. **加载工作流**: `workflow_basic.json`
2. **设置图像**: 在LoadImage节点中选择 `example.jpg` 和 `example_canny.jpg`
3. **设置模型路径**: 确保ControlNet模型路径正确
4. **运行**: 点击 "Queue Prompt"
5. **查看结果**: 检查输出图像

### 预期结果

- **没有错误信息**
- **生成两张输出图像**:
  - `qwen_controlnet_output_*.png` - 受控制的图像
  - `qwen_controlnet_comparison_*.png` - 四宫格对比图
- **控制效果明显**: 输出图像应该受到Canny边缘的控制

## 🐛 常见安装问题

### ❌ 节点未出现

**原因**: 
- 文件路径错误
- 文件权限问题
- Python导入错误

**解决**:
1. 检查文件是否正确复制到 `ComfyUI/custom_nodes/`
2. 查看ComfyUI控制台错误信息
3. 重启ComfyUI
4. 检查Python环境是否有必要的依赖

### ❌ 导入错误

**错误示例**: `ImportError: No module named 'torch'`

**解决**:
1. 确认ComfyUI的Python环境包含PyTorch
2. 如果使用虚拟环境，确保激活正确
3. 手动安装缺失的依赖：
   ```bash
   pip install torch torchvision opencv-python pillow numpy
   ```

### ❌ 模型加载失败

**错误示例**: `FileNotFoundError: ControlNet checkpoint not found`

**解决**:
1. 检查模型文件路径是否正确
2. 确认文件确实存在
3. 使用绝对路径而不是相对路径
4. 检查文件权限

### ❌ CUDA错误

**错误示例**: `CUDA out of memory`

**解决**:
1. 减小图像尺寸 (256x256)
2. 设置设备为 `cpu`
3. 关闭其他GPU程序
4. 重启ComfyUI

## 📋 依赖列表

插件需要以下Python包（通常ComfyUI已包含）：

```
torch>=1.12.0
torchvision>=0.13.0
opencv-python>=4.5.0
pillow>=8.3.0
numpy>=1.21.0
pathlib  # Python标准库
```

## 🔄 更新插件

### Git更新
```bash
cd ai-toolkit
git pull origin main
# 重启ComfyUI
```

### 手动更新
1. 下载新版本文件
2. 覆盖旧文件
3. 重启ComfyUI

## ❓ 获取帮助

### 文档资源
- `README.md` - 完整功能说明
- `QUICK_START.md` - 快速上手指南
- 插件内置工作流示例

### 问题排查
1. 查看ComfyUI控制台错误信息
2. 确认模型文件有效性
3. 测试简单示例工作流
4. 检查系统资源使用情况

### 技术支持
- GitHub Issues: 提交问题报告
- 提供详细的错误日志
- 包含系统环境信息

---

🎯 **恭喜！你现在可以在ComfyUI中使用Qwen Image ControlNet了！**

有问题？参考 `QUICK_START.md` 获取快速使用指南。 