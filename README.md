## AI-Toolkit 当前支持模型一览

> 以下显存需求为 **LoRA 训练参考值**，实际占用会受分辨率、batch size、优化策略影响。

| 模型类型 | 模型名称 | LoRA 训练显存建议 |
|---------|----------|------------------|
| 🖼️ 图像生成 | **Z-Image** | 16 GB |
| 🖼️ 图像生成 | Z-Image-De-Turbo | 16 GB |
| 🖼️ 图像生成 | FLUX1 | 16–24 GB |
| 🖼️ 图像生成 | Qwen-Image | 24 GB |
| 🖼️ 图像生成 | SDXL | 8 GB |
| 🖼️ 图像生成 | Qwen-Image-2512 | 24 GB |
| 🖼️ 图像生成 | FLUX.2-klein-4B | 16 GB |
| 🖼️ 图像生成 | FLUX.2-klein-9B | 28 GB |
| 🖼️ 图像生成 | ERNIE-Image | 16 GB |
| 🎨 图像编辑 | FLUX.1-Kontext-dev | 16–24 GB |
| 🎨 图像编辑 | FLUX2 | 50 GB |
| 🎨 图像编辑 | Qwen-Image-Edit2509 | 24 GB |
| 🎨 图像编辑 | Qwen-Image-Edit2511 | 24 GB |
| 🎬 视频生成 | LTX-2 | 45 GB） |
| 🎬 视频生成 | LTX-2.3 | 45 GB |
| 🎬 视频生成 | wan2.2 | 24–48 GB |

> 

## 🚀 启动方式

**开机后在控制台访问 `6006` 端口即可进入训练 UI。**

![训练 UI](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-153588373-SHp9qdvsAQFaiXICHKJI.png)

---

进入训练UI后，在Model Architecture中选择自己想训练的模型，即可切换到对应的模型训练界面
![img_v3_02uc_47377f49ae044a158b21947e2adaeceg.jpg](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-108990519-aibkhX9x8CZu02PGVOUv.jpg)
在datasets界面，可以通过右上角新建数据集，上传自己已经处理好的训练图集
![image.png](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-743417363-QKeiWXDihB7utiXRHRW7.png)

## ⚠️ 显存说明

* **FLUX 2 DEV**
  * LoRA 训练需 **≈60 GB 显存**
  * 推荐显卡：**RTX PRO 6000 / H800**
* **LTX-2**
  * 训练需 **≈45 GB 显存（已实测）**
* **Qwen 系列**
  * 默认配置 **≥24 GB 显存**
  * 参数与训练策略优化后，24 GB 显存可稳定运行

---

## 🎥 镜像视频教程

### 2.1 主教程

[https://www.bilibili.com/video/BV1DXCaBEEGF/?spm_id_from=333.337.search-card.all.click](https://www.bilibili.com/video/BV1DXCaBEEGF/?spm_id_from=333.337.search-card.all.click)

### 2.2 Z-Image Turbo 训练教程（AI-Toolkit 作者）

[Z-image-Turbo LoRA 训练教程](https://www.bilibili.com/video/BV1TqSmBTEzn/)

---

## 📝 更新日志

### **2026.04.28**

1. ai-toolkit 同步至 **2026-04-28 主分支**
2. 新增 **ERNIE-Image**（百度文心图像生成）训练支持
3. 新增 **LTX-2.3**（视频生成升级版，含音频支持）训练支持
4. 新增 **Nucleus-Image**、**Zeta-Chroma**、**HiDream**、**OmniGen2** 模型架构支持（共享盘模型待补充）
5. 升级 **diffusers** 至 0.38.0、**transformers** 至 5.5.3 等核心依赖
6. 修复 Worker 训练进程 Python 环境识别问题
7. 修复上游 Prisma schema 变更导致的 UI 构建失败

---

### **2026.01.28**

1. 第一时间支持了 **Z-Image**的训练
   ![img_v3_02uc_87a8ef6fee794b0aa5a343a128f27a8g.jpg](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-567731952-VLDdgRBsorpFJAATyrgB.jpg)

### **2026.01.20**

1. 新增 **LFLUX.2-klein-4B** 和**LFLUX.2-klein-9B**训练支持
2. ai-toolkit 脚本同步至 **2026-01-18 主分支**

### **2026.01.15**

1. 新增 **LTX-2** 训练支持
2. ai-toolkit 脚本同步至 **2026-01-15 主分支**
3. 修复 **FLUX2 训练报错** 问题

---

### **2026.01.04**

1. 新增 **Qwen-Image-2512** 与 **Qwen-Image-Edit-2511** 训练支持
2. 新增  **Loss 曲线图表** ，支持训练过程可视化

![loss](https://pbs.twimg.com/media/G8d5lfOa4AAhqQN?format=jpg&name=small)

---

### **2025.12.16**

* 新增 **去蒸馏版本 Z-Image-De-Turbo 基础模型（社区）** 支持

---

### **2025.12.04**

* 集成 **Z-Image Turbo V2 训练适配器**
* 效果与稳定性进一步提升

---

### **2025.11.29**

1. 新增 **Z-Image Turbo LoRA 训练支持**
   * 基于 **去蒸馏训练适配器**
   * 保留 Turbo 推理能力
2. 镜像内置模型与训练适配器
3. FP8 训练 **最低 16 GB 显存**

---

### **2025.11.26**

1. 新增 **FLUX.2-dev** 训练支持
2. 内置 **Qwen-Image** 模型
3. 内置 **Mistral-Small-3.1-24B-Instruct-2503**
4. 内置 **WAN2.2 5B**

---

### **2025.10.12**

* 修复 NPM 在特殊环境下无法加载的问题
* 修复自定义服务 404 问题

---

### **2025.10.10**

* 支持 **FLUX.1-Kontext-dev** 训练
* 路径：

<pre class="overflow-visible! px-0!" data-start="2328" data-end="2393"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>/root/ai-toolkit/black-forest-labs/FLUX.1-Kontext-dev
</span></span></code></div></div></pre>

---

### **2025.09.30**

* 支持 FLUX / Qwen 2509 模型训练

<pre class="overflow-visible! px-0!" data-start="2448" data-end="2548"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>/root/ai-toolkit/black-forest-labs/FLUX.1-dev
/root/ai-toolkit/Qwen/Qwen-Image-Edit-2509
</span></span></code></div></div></pre>

---

## 🖼️ 界面预览

### FLUX2 LoRA

![FLUX2](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-664848033-vXxzGtAbI6gDLmkr8KrB.png)

### FLUX LoRA

![FLUX](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-836461696-rnEV7Xhp0cPmWmg3tGdz.jpg)

### Qwen-Image-Edit-2509 LoRA

![Qwen Edit](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-139090954-EXgisykJuMLMwdTjsBVo.jpg)

### Z-Image Turbo LoRA

![Z-Image Turbo](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-676957506-ohTUnaCwTo40NT2XUDob.png)

---

## 🤝 技术交流

* 云端镜像交流企鹅群：**852404741**![image.png](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-185428711-i2ZjSJsIOsTzWf1M2Rwv.png)
* 2026年：每天群内随机掉落 **AutoDL 代金券**

![group](https://codewithgpu-image-1310972338.cos.ap-beijing.myqcloud.com/40972-602556033-RNVkPQZXnmMwHth0Udu1.png)
