# 🚀 小白快速上手指南

## 📋 准备工作

### 1. ✅ 确认环境
- 安装了ComfyUI
- 有训练好的Qwen ControlNet模型文件 (`*.pt`)
- 有一张测试图像和对应的控制图像

### 2. 📦 安装插件
1. 将整个 `comfyui_qwen_controlnet` 文件夹复制到 `ComfyUI/custom_nodes/`
2. 重启ComfyUI
3. 在节点列表中找到 "Qwen/ControlNet" 分类

## 🎯 3分钟快速体验

### 第1步：导入工作流
1. 打开ComfyUI
2. 点击 "Load" 按钮
3. 选择 `workflow_basic.json` 文件
4. 工作流会自动加载完整的节点布局

### 第2步：准备测试图像
将以下图像放入 `ComfyUI/input/` 目录：
- `example.jpg` - 任意一张测试图像
- `example_canny.jpg` - 对应的Canny边缘图像

**🔧 快速生成Canny图像的方法:**
```python
import cv2
import numpy as np
from PIL import Image

# 读取图像
image = cv2.imread('example.jpg')
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# 生成Canny边缘
edges = cv2.Canny(gray, 50, 150)
edges_3ch = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)

# 保存
cv2.imwrite('example_canny.jpg', edges_3ch)
```

### 第3步：配置模型路径
1. 找到 "🎯 Qwen ControlNet 加载器" 节点
2. 修改 `checkpoint_path` 为你的模型文件路径:
   ```
   D:/ai/ai-toolkit/output/qwen_controlnet_gpu/qwen_controlnet_final.pt
   ```
3. 确保路径正确，文件存在

### 第4步：运行测试
1. 点击 "Queue Prompt" 按钮
2. 等待推理完成（首次加载模型会慢一些）
3. 查看输出图像：
   - `qwen_controlnet_output_*.png` - 受控制的图像
   - `qwen_controlnet_comparison_*.png` - 四宫格对比图

## 🎮 节点说明

### 📸 加载原始图像
- **作用**: 加载要处理的原始图像
- **设置**: 选择你的测试图像文件

### 🎮 加载控制图像 (Canny)
- **作用**: 加载Canny边缘控制图像
- **设置**: 选择对应的边缘图像文件

### 🎯 Qwen ControlNet 加载器
- **作用**: 加载训练好的ControlNet模型
- **重要设置**:
  - `checkpoint_path`: 模型文件路径（必须修改）
  - `device`: 自动选择GPU/CPU

### 🎮 应用 ControlNet
- **作用**: 使用ControlNet生成受控图像
- **可调参数**:
  - `control_strength`: 控制强度 (0.0-2.0)
  - `size`: 输出图像尺寸

### 📊 对比原图和受控图
- **作用**: 生成对比图，显示控制效果
- **输出**: 四宫格 [原图|控制图|无控制输出|有控制输出]

## 🔧 常见调优

### 🎚️ 控制强度调节
- `0.5` - 较弱控制，保持原图特征
- `1.0` - 标准控制强度（推荐）
- `1.5` - 较强控制，更明显的效果
- `2.0` - 最强控制，可能过度

### 📐 尺寸设置
- `256` - 快速测试，速度最快
- `512` - 标准尺寸，效果与速度平衡
- `1024` - 高质量，需要更多显存

### 🖥️ 设备选择
- `auto` - 自动选择最佳设备（推荐）
- `cpu` - 强制使用CPU（慢但稳定）
- `cuda:0` - 使用第一块GPU

## 🐛 问题排查

### ❌ 模型加载失败
**错误**: `FileNotFoundError: ControlNet checkpoint not found`
**解决**:
1. 检查模型文件路径是否正确
2. 确认文件确实存在
3. 使用绝对路径而不是相对路径

### ❌ CUDA内存不足
**错误**: `CUDA out of memory`
**解决**:
1. 减小图像尺寸到256或更小
2. 选择设备为 `cpu`
3. 关闭其他占用GPU的程序

### ❌ 控制效果不明显
**症状**: 输出图像与原图差别很小
**解决**:
1. 增加控制强度到1.5或2.0
2. 检查控制图像质量（边缘清晰度）
3. 验证模型训练效果

### ❌ 推理速度很慢
**解决**:
1. 确认使用GPU (`device: cuda:0`)
2. 减小图像尺寸
3. 升级显卡驱动

## 📊 效果评判

### ✅ 良好效果的标志
- 输出图像保持原图主要特征
- 明显受到控制图像的结构引导
- 对比图中能看到明显的控制差异

### ⚠️ 需要改进的情况
- 输出图像完全忽略控制信号
- 输出图像过度变形失真
- 控制效果过弱或过强

## 🎨 进阶使用

### 🔄 批量处理
1. 准备多张图像对（原图+控制图）
2. 使用 "Batch" 相关节点
3. 设置循环处理

### 🎛️ 参数实验
1. 复制基础工作流
2. 创建多个 "应用ControlNet" 节点
3. 设置不同的控制强度进行对比

### 📈 性能监控
- 观察GPU使用率 (`nvidia-smi`)
- 记录推理时间
- 监控显存占用

## 💡 小贴士

1. **首次使用建议用小图像**(256x256)快速验证
2. **保存好的参数组合**作为模板
3. **定期备份工作流文件**
4. **记录效果好的控制强度值**
5. **准备多种类型的测试图像**

---

🎯 **现在你可以开始体验真正的Qwen Image ControlNet了！**

有问题？查看完整的 `README.md` 获取更多详细信息。 