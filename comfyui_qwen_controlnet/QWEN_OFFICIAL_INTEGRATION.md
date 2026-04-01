# 🎯 Qwen Image官方模型 + ControlNet 整合指南

## 🎊 什么是这个整合工作流？

这是一个**革命性的工作流**，它将：
- ✅ **Qwen Image官方模型** (UNET + CLIP + VAE)
- ✅ **你自训练的ControlNet** 
- ✅ **完美融合在一起**

让你既能享受官方模型的强大生成能力，又能实现精确的ControlNet控制！

## 📋 工作流组成

### 🎯 官方Qwen模型部分
| 节点 | 功能 | 说明 |
|------|------|------|
| 🎯 Qwen Image UNET | 加载官方UNET模型 | `Qimg_1.0.safetensors` |
| 📝 Qwen CLIP | 加载官方文本编码器 | `qwen_2.5_vl_7b_fp8_scaled.safetensors` |
| 🎨 Qwen VAE | 加载官方VAE | `qwen_image_vae.safetensors` |
| 🔄 模型采样配置 | AuraFlow采样配置 | 官方推荐参数 |

### 🎮 ControlNet控制部分
| 节点 | 功能 | 说明 |
|------|------|------|
| 🎯 Qwen ControlNet 加载器 | 加载你训练的ControlNet | 自训练模型 |
| 🎮 应用 ControlNet | 生成受控图像 | 独立的ControlNet推理 |
| 📊 ControlNet对比 | 对比控制效果 | 四宫格对比图 |

### 🎨 双路输出
- **官方输出**: 使用Qwen官方模型的标准生成流程
- **ControlNet输出**: 使用你的ControlNet进行控制生成
- **对比图**: 展示两种方法的差异

## 🚀 使用步骤

### 第1步: 准备官方模型文件

确保你有以下Qwen Image官方文件：
```
models/unet/
├── Qimg_1.0.safetensors          # 官方UNET模型

models/clip/
├── qwen_2.5_vl_7b_fp8_scaled.safetensors  # 官方CLIP

models/vae/
├── qwen_image_vae.safetensors    # 官方VAE
```

### 第2步: 安装ControlNet插件

1. **安装插件**:
   ```bash
   copy /S "D:\ai\comfyui_qwen_controlnet" "C:\ComfyUI\custom_nodes\"
   ```

2. **重启ComfyUI**

### 第3步: 加载整合工作流

1. 在ComfyUI中点击 "Load"
2. 选择 `workflow_qwen_official_with_controlnet.json`
3. 工作流自动加载

### 第4步: 配置路径

1. **检查官方模型路径** - 确保ComfyUI能找到官方文件
2. **设置ControlNet路径** - 在 "🎯 Qwen ControlNet 加载器" 中设置:
   ```
   D:/ai/ai-toolkit/output/qwen_controlnet_gpu/qwen_controlnet_final.pt
   ```

### 第5步: 准备图像

1. **原始图像**: 放入 `ComfyUI/input/example.jpg`
2. **控制图像**: 放入 `ComfyUI/input/example_canny.jpg`

### 第6步: 运行生成

1. **设置提示词** - 在正面/负面提示词框中输入
2. **调整参数** - 控制强度、图像尺寸等
3. **点击 "Queue Prompt"**
4. **等待生成完成**

## 📊 输出结果

运行完成后，你会得到：

| 输出文件 | 内容 | 说明 |
|----------|------|------|
| `qwen_official_output_*.png` | 官方模型生成 | 标准Qwen Image输出 |
| `controlnet_output_*.png` | ControlNet控制生成 | 你的ControlNet效果 |
| `controlnet_comparison_*.png` | 四宫格对比图 | [原图\|控制图\|原始\|受控] |

## 🔧 参数调优

### 🎚️ ControlNet控制强度
- `0.5` - 轻微控制，更多保留原始特征
- `1.0` - 标准控制（推荐）
- `1.5` - 强控制，明显的结构引导
- `2.0` - 最强控制

### 📐 分辨率设置
按官方推荐：
- **1:1** - 1328×1328 (高质量) 或 512×512 (测试)
- **3:4** - 1140×1472
- **4:3** - 1472×1140
- **9:16** - 928×1664
- **16:9** - 1664×928

### 🎲 采样参数
- **Steps**: 20-50 (官方推荐20)
- **CFG Scale**: 2.5-7.5 (官方推荐2.5)
- **Sampler**: euler (官方推荐)
- **Scheduler**: normal

## 💡 使用技巧

### 🎯 提示词建议
```
正面: 高质量的数字艺术，精美的细节，专业摄影，清晰锐利，完美构图，[你的具体描述]

负面: worst quality, blurry, low quality, distorted, bad anatomy, watermark
```

### 🔄 工作流变体

**1. 仅ControlNet模式**:
- 禁用官方输出路径
- 专注ControlNet效果

**2. 仅官方模式**:
- 禁用ControlNet路径
- 使用纯官方生成

**3. A/B测试模式**:
- 同时启用两条路径
- 对比不同方法效果

### 📈 性能优化

**高端GPU (24GB+)**:
- 分辨率: 1328×1328
- 批大小: 可尝试增加
- 精度: fp16

**中端GPU (8-16GB)**:
- 分辨率: 512×512 或 1024×1024
- 使用fp8量化
- 关闭不需要的输出路径

**低端GPU (8GB以下)**:
- 分辨率: 512×512
- 使用CPU进行ControlNet
- 逐个运行不同路径

## 🐛 常见问题

### ❌ 官方模型加载失败
**解决**: 检查模型文件路径和权限

### ❌ ControlNet效果不明显
**解决**: 
1. 增加控制强度到1.5
2. 检查控制图像质量
3. 验证ControlNet训练效果

### ❌ 显存不足
**解决**:
1. 减小分辨率
2. 关闭一条输出路径
3. 使用fp8量化

### ❌ 生成速度慢
**解决**:
1. 检查GPU利用率
2. 减少采样步数
3. 使用较小分辨率测试

## 🎉 预期效果

### ✅ 成功的标志
- 官方输出：高质量的Qwen风格图像
- ControlNet输出：明显受控制图引导
- 对比图：清晰显示控制差异
- 无错误信息

### 📈 效果评判
1. **官方输出质量** - 应该达到Qwen官方水准
2. **ControlNet控制度** - 明显受边缘结构引导
3. **一致性** - 两种输出风格相似但结构不同
4. **稳定性** - 多次运行结果稳定

## 🎯 总结

这个整合工作流的核心价值：

🔥 **最强组合**: 官方模型质量 + 自定义控制能力
📊 **效果对比**: 直观展示ControlNet价值
🎨 **灵活使用**: 可选择单独或组合使用
🚀 **生产就绪**: 稳定可靠的生成流程

---

🎊 **恭喜！你现在可以在ComfyUI中体验官方Qwen Image + 自训练ControlNet的完美融合了！** 