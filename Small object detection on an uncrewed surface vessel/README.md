# Small Object Detection on an Uncrewed Surface Vessel

本项目探索了在复杂海上环境中对小目标（船只、浮标等）的自动检测与跟踪方法，结合 **传统雷达算法** 与 **深度学习目标检测模型**，提升无人艇（USV）的环境感知与避障能力。研究使用了 **MOANA 数据集**（多模态海事雷达与视觉数据），并比较了多种方法的性能。

---

## 项目概述
- **研究背景**：海面小目标检测受到光照反射、杂波干扰和低能见度等挑战，仅依赖视觉模型往往误报率高。本项目结合雷达与视觉方法，提升检测鲁棒性。
- **目标**：
  1. 使用多种模型检测与跟踪海面小目标  
  2. 对比深度学习与传统方法的性能  
  3. 为无人艇提供可部署的感知方案  

---

## 方法
本仓库包含以下模型代码：

- **CFAR (Cell-Averaging Constant False Alarm Rate)**  
  传统雷达检测方法，自适应阈值抑制噪声，但在复杂海杂波条件下表现有限。

- **Faster R-CNN**  
  双阶段目标检测模型，基于区域提议网络 (RPN)，在精度上具有较好基准表现。

- **MHT & MOT (Multiple Hypothesis Tracking / Multi-Object Tracking)**  
  结合卡尔曼滤波与多假设追踪，解决目标遮挡与数据关联问题，用于多目标连续跟踪。

- **YOLO (YOLOv8 & YOLOv11)**  
  单阶段检测模型，适合实时检测任务，YOLOv11 在 mAP 上表现最优 (mAP@50≈0.88)。

---

## 数据集
主要使用 **[MOANA Dataset](https://github.com/moana-dataset)**，包含：
- X-band 和 W-band 雷达图像  
- 双目相机与 LiDAR  
- 1655 张带标注的 X-band 雷达图像（船只与浮标）  

---

## 实验结果
在 MOANA 数据集上的对比结果 (验证集 mAP@50)：

| 模型       | mAP@50 | mAP@50-90 |
|------------|--------|-----------|
| YOLOv11s   | **0.880** | 0.770 |
| YOLOv8n    | 0.880 | 0.749 |
| Faster R-CNN | 0.837 | 0.653 |
| EfficientDet | 0.380 | 0.296 |
| CFAR       | 0.003 | 0.002 |

结论：  
- **YOLOv11s** 在准确率与推理速度上表现最佳，适合部署在无人艇平台  
- **Faster R-CNN** 可作为基准参考  
- **CFAR** 和 **EfficientDet** 在此场景下表现有限  

---

## 依赖环境
- Python 3.10+  
- PyTorch / TensorFlow
- OpenCV, NumPy, Matplotlib  
- mmcv, mmdetection (Faster R-CNN)  
- ultralytics (YOLOv8/YOLOv11)  
