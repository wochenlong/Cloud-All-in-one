# 安全导入folder_paths
try:
    import folder_paths
    COMFYUI_AVAILABLE = True
except ImportError:
    COMFYUI_AVAILABLE = False
    print(" folder_paths未找到，将使用传统路径模式")

def get_qwen_controlnet_models():
    \"\"\"扫描ComfyUI的controlnet目录，获取Qwen ControlNet模型列表\"\"\"
    qwen_models = []
    
    if COMFYUI_AVAILABLE:
        try:
            # 获取ComfyUI的controlnet模型目录
            controlnet_dirs = folder_paths.get_folder_paths("controlnet")
            if controlnet_dirs:
                controlnet_dir = controlnet_dirs[0]
                
                if os.path.exists(controlnet_dir):
                    for file in os.listdir(controlnet_dir):
                        # 查找包含qwen/controlnet相关关键词的.pt或.pth文件
                        if file.lower().endswith(('.pt', '.pth', '.safetensors')):
                            if any(keyword in file.lower() for keyword in ['qwen', 'controlnet', 'control']):
                                qwen_models.append(file)
                    
                    print(f" 扫描ControlNet目录: {controlnet_dir}")
                    print(f" 找到{len(qwen_models)}个相关模型")
        
        except Exception as e:
            print(f" 无法扫描ControlNet目录: {e}")
    
    # 如果没找到，返回默认选项
    if not qwen_models:
        qwen_models = ["[请将模型放入 ComfyUI/models/controlnet/]", "[或使用自定义路径]"]
    
    return qwen_models
