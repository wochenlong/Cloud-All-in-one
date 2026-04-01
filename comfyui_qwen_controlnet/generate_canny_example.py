#!/usr/bin/env python3
"""
快速生成Canny边缘图像示例
适用于小白用户快速准备测试数据
"""

import cv2
import numpy as np
from PIL import Image
import argparse
import os
from pathlib import Path


def generate_canny(input_path, output_path=None, low_threshold=50, high_threshold=150):
    """
    生成Canny边缘图像
    
    Args:
        input_path: 输入图像路径
        output_path: 输出图像路径（可选）
        low_threshold: Canny低阈值
        high_threshold: Canny高阈值
    """
    # 读取图像
    image = cv2.imread(input_path)
    if image is None:
        raise ValueError(f"无法读取图像: {input_path}")
    
    # 转换为灰度图
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # 应用高斯模糊减少噪声
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    
    # 生成Canny边缘
    edges = cv2.Canny(blurred, low_threshold, high_threshold)
    
    # 转换为3通道RGB图像
    edges_3ch = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)
    
    # 确定输出路径
    if output_path is None:
        input_path_obj = Path(input_path)
        output_path = input_path_obj.parent / f"{input_path_obj.stem}_canny{input_path_obj.suffix}"
    
    # 保存图像
    cv2.imwrite(str(output_path), edges_3ch)
    print(f"✅ Canny边缘图已保存: {output_path}")
    
    return str(output_path)


def batch_generate_canny(input_dir, output_dir=None):
    """
    批量生成Canny边缘图像
    
    Args:
        input_dir: 输入图像目录
        output_dir: 输出图像目录（可选）
    """
    input_path = Path(input_dir)
    if not input_path.exists():
        raise ValueError(f"输入目录不存在: {input_dir}")
    
    # 设置输出目录
    if output_dir is None:
        output_path = input_path.parent / f"{input_path.name}_canny"
    else:
        output_path = Path(output_dir)
    
    output_path.mkdir(parents=True, exist_ok=True)
    
    # 支持的图像格式
    image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff'}
    
    # 查找图像文件
    image_files = []
    for ext in image_extensions:
        image_files.extend(list(input_path.glob(f"*{ext}")))
        image_files.extend(list(input_path.glob(f"*{ext.upper()}")))
    
    if not image_files:
        print("⚠️ 未找到图像文件")
        return
    
    print(f"📄 找到 {len(image_files)} 张图像")
    
    # 批量处理
    success_count = 0
    for img_file in image_files:
        try:
            output_file = output_path / f"{img_file.stem}_canny{img_file.suffix}"
            generate_canny(str(img_file), str(output_file))
            success_count += 1
        except Exception as e:
            print(f"❌ 处理失败 {img_file.name}: {e}")
    
    print(f"🎉 批量处理完成! 成功: {success_count}/{len(image_files)}")


def create_example_pair():
    """
    为ComfyUI创建示例图像对
    """
    # 检查是否有可用的示例图像
    current_dir = Path(__file__).parent
    
    # 查找可能的示例图像
    possible_sources = [
        Path("../data/1_standing_new"),
        Path("../output/eval"),
        current_dir.parent / "data" / "1_standing_new",
    ]
    
    source_image = None
    for source_dir in possible_sources:
        if source_dir.exists():
            image_files = list(source_dir.glob("*.jpg")) + list(source_dir.glob("*.png"))
            if image_files:
                source_image = image_files[0]
                break
    
    if source_image is None:
        print("⚠️ 未找到示例图像，请手动准备 example.jpg")
        return
    
    # 复制并重命名为example.jpg
    example_path = current_dir / "example.jpg"
    import shutil
    shutil.copy2(source_image, example_path)
    
    # 生成Canny图像
    canny_path = current_dir / "example_canny.jpg"
    generate_canny(str(example_path), str(canny_path))
    
    print(f"✅ 示例图像对已创建:")
    print(f"   原图: {example_path}")
    print(f"   Canny: {canny_path}")
    print(f"🎯 请将这两个文件复制到 ComfyUI/input/ 目录")


def main():
    parser = argparse.ArgumentParser(description="生成Canny边缘图像")
    parser.add_argument("input", nargs="?", help="输入图像/目录路径")
    parser.add_argument("-o", "--output", help="输出图像/目录路径")
    parser.add_argument("--low", type=int, default=50, help="Canny低阈值")
    parser.add_argument("--high", type=int, default=150, help="Canny高阈值")
    parser.add_argument("--batch", action="store_true", help="批量处理模式")
    parser.add_argument("--create-example", action="store_true", help="创建ComfyUI示例图像对")
    
    args = parser.parse_args()
    
    if args.create_example:
        create_example_pair()
        return
    
    if not args.input:
        print("❌ 请提供输入图像路径，或使用 --create-example 创建示例")
        parser.print_help()
        return
    
    try:
        if args.batch:
            batch_generate_canny(args.input, args.output)
        else:
            generate_canny(args.input, args.output, args.low, args.high)
    except Exception as e:
        print(f"❌ 错误: {e}")


if __name__ == "__main__":
    main() 