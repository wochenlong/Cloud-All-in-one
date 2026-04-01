"""
Qwen Image ControlNet Models
从训练代码中提取的模型定义
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from PIL import Image
from pathlib import Path


class QwenImageControlNet(nn.Module):
    """
    Qwen Image ControlNet
    专注核心ControlNet功能
    """
    
    def __init__(self, base_channels=320, conditioning_channels=3):
        super().__init__()
        
        self.conditioning_channels = conditioning_channels
        self.base_channels = base_channels
        
        # 控制信号预处理网络
        self.control_preprocessing = nn.Sequential(
            # 第一层：输入预处理
            nn.Conv2d(conditioning_channels, 32, 3, padding=1),
            nn.SiLU(),
            
            # 下采样层
            nn.Conv2d(32, 64, 3, stride=2, padding=1),  # 256x256
            nn.SiLU(),
            nn.Conv2d(64, 128, 3, stride=2, padding=1), # 128x128
            nn.SiLU(),
            nn.Conv2d(128, 256, 3, stride=2, padding=1), # 64x64
            nn.SiLU(),
            nn.Conv2d(256, base_channels, 3, stride=2, padding=1), # 32x32
            nn.SiLU(),
        )
        
        # ControlNet特征处理层
        self.control_blocks = nn.ModuleList([
            nn.Sequential(
                nn.Conv2d(base_channels, base_channels, 3, padding=1),
                nn.GroupNorm(32, base_channels),
                nn.SiLU(),
                nn.Conv2d(base_channels, base_channels, 3, padding=1),
            )
            for _ in range(4)  # 4个控制块
        ])
        
        # 零初始化输出层 - ControlNet的关键特性
        self.zero_convs = nn.ModuleList([
            nn.Conv2d(base_channels, base_channels, 1)
            for _ in range(4)
        ])
        
        # 零初始化所有zero_convs
        for zero_conv in self.zero_convs:
            nn.init.zeros_(zero_conv.weight)
            nn.init.zeros_(zero_conv.bias)
    
    def forward(self, control_input):
        """
        ControlNet前向传播
        
        Args:
            control_input: 控制图像 [B, 3, H, W]
            
        Returns:
            控制特征列表
        """
        # 预处理控制信号
        x = self.control_preprocessing(control_input)
        
        # 通过控制块处理
        control_features = []
        for i, (control_block, zero_conv) in enumerate(zip(self.control_blocks, self.zero_convs)):
            x = control_block(x)
            # 零卷积输出 - 确保训练开始时不影响原模型
            control_feat = zero_conv(x)
            control_features.append(control_feat)
        
        return control_features


class SimpleQwenImageModel(nn.Module):
    """
    简化的Qwen Image模型
    用于演示ControlNet效果
    """
    
    def __init__(self, base_channels=320):
        super().__init__()
        
        self.base_channels = base_channels
        
        # 简化的"transformer"块（占位符）
        self.input_proj = nn.Conv2d(3, base_channels, 3, padding=1)
        
        self.transformer_blocks = nn.ModuleList([
            nn.Sequential(
                nn.Conv2d(base_channels, base_channels, 3, padding=1),
                nn.GroupNorm(32, base_channels),
                nn.SiLU(),
                nn.Conv2d(base_channels, base_channels, 3, padding=1),
            )
            for _ in range(4)
        ])
        
        self.output_proj = nn.Conv2d(base_channels, 3, 3, padding=1)
    
    def forward(self, x, control_features=None):
        """
        简化的前向传播
        
        Args:
            x: 输入图像 [B, 3, H, W]
            control_features: ControlNet特征列表
        """
        x = self.input_proj(x)
        
        # 通过transformer块，注入控制特征
        for i, block in enumerate(self.transformer_blocks):
            x = block(x)
            
            # 注入ControlNet特征（需要上采样到匹配尺寸）
            if control_features and i < len(control_features):
                control_feat = control_features[i]
                # 上采样控制特征到匹配x的尺寸
                if control_feat.shape[-2:] != x.shape[-2:]:
                    control_feat = F.interpolate(
                        control_feat, 
                        size=x.shape[-2:], 
                        mode='bilinear', 
                        align_corners=False
                    )
                x = x + control_feat  # 残差连接
        
        x = self.output_proj(x)
        return x


def load_qwen_controlnet(checkpoint_path: str, device: str = "cpu"):
    """
    加载训练好的Qwen ControlNet模型
    
    Args:
        checkpoint_path: 检查点文件路径
        device: 设备 (cpu, cuda:0, etc.)
        
    Returns:
        (base_model, controlnet): 加载好的模型元组
    """
    # 初始化模型
    base_model = SimpleQwenImageModel().to(device).eval()
    controlnet = QwenImageControlNet().to(device).eval()
    
    # 加载权重
    checkpoint = torch.load(checkpoint_path, map_location=device)
    
    if isinstance(checkpoint, dict):
        if 'controlnet_state_dict' in checkpoint:
            # 从训练检查点加载
            controlnet.load_state_dict(checkpoint['controlnet_state_dict'])
        else:
            # 直接的state_dict
            controlnet.load_state_dict(checkpoint)
    else:
        # 直接的权重文件
        controlnet.load_state_dict(checkpoint)
    
    return base_model, controlnet


def tensor_to_pil(tensor: torch.Tensor) -> Image.Image:
    """
    将PyTorch tensor转换为PIL Image
    
    Args:
        tensor: 图像tensor [C, H, W] 或 [1, C, H, W]
        
    Returns:
        PIL Image
    """
    if tensor.dim() == 4:
        tensor = tensor[0]  # 移除批次维度
    
    # 确保在[0,1]范围
    if tensor.min() < 0:
        tensor = (tensor + 1) / 2  # 从[-1,1]转换到[0,1]
    tensor = torch.clamp(tensor, 0, 1)
    
    # 转换为numpy并调整维度顺序
    if tensor.dim() == 3:  # [C, H, W] -> [H, W, C]
        tensor = tensor.permute(1, 2, 0)
    
    # 转换为PIL图像
    image_array = (tensor.detach().cpu().numpy() * 255).astype(np.uint8)
    return Image.fromarray(image_array)


def pil_to_tensor(image: Image.Image, device: str = "cpu") -> torch.Tensor:
    """
    将PIL Image转换为PyTorch tensor
    
    Args:
        image: PIL Image
        device: 设备
        
    Returns:
        图像tensor [1, C, H, W]
    """
    # 确保是RGB格式
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # 转换为numpy数组
    image_array = np.array(image, dtype=np.float32) / 255.0
    
    # 转换为tensor并调整维度
    tensor = torch.from_numpy(image_array).permute(2, 0, 1).unsqueeze(0)
    
    return tensor.to(device) 