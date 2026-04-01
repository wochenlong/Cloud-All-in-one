"""
ComfyUI Qwen Image ControlNet Plugin
真正的Qwen Image ControlNet插件 - 不是LoRA！
"""

from .nodes import NODE_CLASS_MAPPINGS, NODE_DISPLAY_NAME_MAPPINGS

__all__ = ['NODE_CLASS_MAPPINGS', 'NODE_DISPLAY_NAME_MAPPINGS']

WEB_DIRECTORY = "./web" 