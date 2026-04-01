"""
ComfyUI Qwen Image ControlNet Nodes
"""

import torch
import torch.nn.functional as F
import numpy as np
from pathlib import Path
import os

from .models import (
    QwenImageControlNet, 
    SimpleQwenImageModel, 
    load_qwen_controlnet,
    tensor_to_pil,
    pil_to_tensor
)


class QwenControlNetLoader:
    """加载Qwen ControlNet模型的节点"""
    
    @classmethod
    def INPUT_TYPES(s):
        return {
            "required": {
                "checkpoint_path": ("STRING", {
                    "default": "D:/ai/ai-toolkit/output/qwen_controlnet_gpu/qwen_controlnet_final.pt",
                    "multiline": False
                }),
                "device": (["auto", "cpu", "cuda:0", "cuda:1"], {"default": "auto"}),
            }
        }
    
    RETURN_TYPES = ("QWEN_CONTROLNET_MODEL",)
    RETURN_NAMES = ("qwen_controlnet_model",)
    FUNCTION = "load_model"
    CATEGORY = "Qwen/ControlNet"
    
    def load_model(self, checkpoint_path, device):
        # 自动检测设备
        if device == "auto":
            device = "cuda:0" if torch.cuda.is_available() else "cpu"
        
        # 检查文件是否存在
        if not os.path.exists(checkpoint_path):
            raise FileNotFoundError(f"ControlNet checkpoint not found: {checkpoint_path}")
        
        # 加载模型
        base_model, controlnet = load_qwen_controlnet(checkpoint_path, device)
        
        # 返回模型字典
        model_dict = {
            "base_model": base_model,
            "controlnet": controlnet,
            "device": device,
            "checkpoint_path": checkpoint_path
        }
        
        print(f"✅ Qwen ControlNet loaded from: {checkpoint_path}")
        print(f"🔧 Device: {device}")
        
        return (model_dict,)


class QwenControlNetApply:
    """应用Qwen ControlNet的节点"""
    
    @classmethod
    def INPUT_TYPES(s):
        return {
            "required": {
                "qwen_controlnet_model": ("QWEN_CONTROLNET_MODEL",),
                "image": ("IMAGE",),
                "control_image": ("IMAGE",),
                "control_strength": ("FLOAT", {
                    "default": 1.0,
                    "min": 0.0,
                    "max": 2.0,
                    "step": 0.1
                }),
                "size": ("INT", {
                    "default": 512,
                    "min": 64,
                    "max": 2048,
                    "step": 64
                }),
            }
        }
    
    RETURN_TYPES = ("IMAGE",)
    RETURN_NAMES = ("controlled_image",)
    FUNCTION = "apply_controlnet"
    CATEGORY = "Qwen/ControlNet"
    
    def apply_controlnet(self, qwen_controlnet_model, image, control_image, control_strength, size):
        # 提取模型
        base_model = qwen_controlnet_model["base_model"]
        controlnet = qwen_controlnet_model["controlnet"]
        device = qwen_controlnet_model["device"]
        
        # 转换ComfyUI图像格式 [B, H, W, C] -> [B, C, H, W]
        def comfy_to_torch(img_tensor):
            if img_tensor.dim() == 4:
                img_tensor = img_tensor[0]  # 取第一张图像
            # [H, W, C] -> [C, H, W] -> [1, C, H, W]
            return img_tensor.permute(2, 0, 1).unsqueeze(0).contiguous()
        
        # 转换图像
        input_image = comfy_to_torch(image).to(device)
        control_img = comfy_to_torch(control_image).to(device)
        
        # 调整尺寸
        input_image = F.interpolate(input_image, size=(size, size), mode='bilinear', align_corners=False)
        control_img = F.interpolate(control_img, size=(size, size), mode='bilinear', align_corners=False)
        
        # 推理
        with torch.no_grad():
            # 获取控制特征
            control_features = controlnet(control_img)
            
            # 应用控制强度
            if control_strength != 1.0:
                control_features = [feat * control_strength for feat in control_features]
            
            # 生成受控图像
            controlled_output = base_model(input_image, control_features)
            
            # 确保输出在合理范围内
            controlled_output = torch.clamp(controlled_output, 0, 1)
        
        # 转换回ComfyUI格式 [1, C, H, W] -> [1, H, W, C]
        output_image = controlled_output[0].permute(1, 2, 0).unsqueeze(0).contiguous().cpu()
        
        return (output_image,)


class QwenControlNetCompare:
    """对比原图和受控图像的节点"""
    
    @classmethod
    def INPUT_TYPES(s):
        return {
            "required": {
                "qwen_controlnet_model": ("QWEN_CONTROLNET_MODEL",),
                "image": ("IMAGE",),
                "control_image": ("IMAGE",),
                "control_strength": ("FLOAT", {
                    "default": 1.0,
                    "min": 0.0,
                    "max": 2.0,
                    "step": 0.1
                }),
                "size": ("INT", {
                    "default": 512,
                    "min": 64,
                    "max": 2048,
                    "step": 64
                }),
            }
        }
    
    RETURN_TYPES = ("IMAGE", "IMAGE", "IMAGE")
    RETURN_NAMES = ("original_output", "controlled_output", "comparison_grid")
    FUNCTION = "compare_outputs"
    CATEGORY = "Qwen/ControlNet"
    
    def compare_outputs(self, qwen_controlnet_model, image, control_image, control_strength, size):
        # 提取模型
        base_model = qwen_controlnet_model["base_model"]
        controlnet = qwen_controlnet_model["controlnet"]
        device = qwen_controlnet_model["device"]
        
        # 转换图像格式
        def comfy_to_torch(img_tensor):
            if img_tensor.dim() == 4:
                img_tensor = img_tensor[0]
            return img_tensor.permute(2, 0, 1).unsqueeze(0).contiguous()
        
        input_image = comfy_to_torch(image).to(device)
        control_img = comfy_to_torch(control_image).to(device)
        
        # 调整尺寸
        input_image = F.interpolate(input_image, size=(size, size), mode='bilinear', align_corners=False)
        control_img = F.interpolate(control_img, size=(size, size), mode='bilinear', align_corners=False)
        
        with torch.no_grad():
            # 原始输出（无控制）
            original_output = base_model(input_image, None)
            
            # 获取控制特征
            control_features = controlnet(control_img)
            if control_strength != 1.0:
                control_features = [feat * control_strength for feat in control_features]
            
            # 受控输出
            controlled_output = base_model(input_image, control_features)
            
            # 确保输出在合理范围内
            original_output = torch.clamp(original_output, 0, 1)
            controlled_output = torch.clamp(controlled_output, 0, 1)
        
        # 创建对比网格 [原图|控制图|原始输出|受控输出]
        grid_images = []
        
        # 调整所有图像到相同尺寸
        input_resized = F.interpolate(input_image, size=(size, size), mode='bilinear', align_corners=False)
        control_resized = F.interpolate(control_img, size=(size, size), mode='bilinear', align_corners=False)
        
        # 水平拼接
        comparison_row = torch.cat([
            input_resized[0],          # 原图
            control_resized[0],        # 控制图
            original_output[0],        # 原始输出
            controlled_output[0]       # 受控输出
        ], dim=2)  # 在宽度维度拼接
        
        # 转换回ComfyUI格式
        def torch_to_comfy(tensor):
            return tensor.permute(1, 2, 0).unsqueeze(0).contiguous().cpu()
        
        original_comfy = torch_to_comfy(original_output[0])
        controlled_comfy = torch_to_comfy(controlled_output[0])
        comparison_comfy = torch_to_comfy(comparison_row)
        
        return (original_comfy, controlled_comfy, comparison_comfy)


class QwenControlNetInfo:
    """显示Qwen ControlNet模型信息的节点"""
    
    @classmethod
    def INPUT_TYPES(s):
        return {
            "required": {
                "qwen_controlnet_model": ("QWEN_CONTROLNET_MODEL",),
            }
        }
    
    RETURN_TYPES = ("STRING",)
    RETURN_NAMES = ("model_info",)
    FUNCTION = "get_info"
    CATEGORY = "Qwen/ControlNet"
    
    def get_info(self, qwen_controlnet_model):
        base_model = qwen_controlnet_model["base_model"]
        controlnet = qwen_controlnet_model["controlnet"]
        device = qwen_controlnet_model["device"]
        checkpoint_path = qwen_controlnet_model["checkpoint_path"]
        
        # 计算参数数量
        controlnet_params = sum(p.numel() for p in controlnet.parameters())
        base_params = sum(p.numel() for p in base_model.parameters())
        
        info = f"""🎯 Qwen Image ControlNet Model Info

📁 Checkpoint: {checkpoint_path}
🔧 Device: {device}

📊 Model Parameters:
  • ControlNet: {controlnet_params:,} parameters
  • Base Model: {base_params:,} parameters
  • Total: {controlnet_params + base_params:,} parameters

🎮 ControlNet Architecture:
  • Base Channels: {controlnet.base_channels}
  • Conditioning Channels: {controlnet.conditioning_channels}
  • Control Blocks: {len(controlnet.control_blocks)}
  • Zero Convolutions: {len(controlnet.zero_convs)}

✅ Model Status: Loaded and Ready"""
        
        print(info)
        return (info,)


# 节点注册
NODE_CLASS_MAPPINGS = {
    "QwenControlNetLoader": QwenControlNetLoader,
    "QwenControlNetApply": QwenControlNetApply,
    "QwenControlNetCompare": QwenControlNetCompare,
    "QwenControlNetInfo": QwenControlNetInfo,
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "QwenControlNetLoader": "🎯 Qwen ControlNet Loader",
    "QwenControlNetApply": "🎮 Qwen ControlNet Apply",
    "QwenControlNetCompare": "📊 Qwen ControlNet Compare", 
    "QwenControlNetInfo": "ℹ️ Qwen ControlNet Info",
} 