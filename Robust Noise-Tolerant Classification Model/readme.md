# Robust Noise-Tolerant Classification Model

本项目实现并评估了一个在标签噪声环境下依然保持稳健性能的分类模型，结合了卷积神经网络 (CNN)、多种鲁棒损失函数以及 Expectation-Maximization (EM) 算法估计噪声转移矩阵，以应对训练与验证数据集中存在的随机标注噪声。

---

## 项目概述
- 数据集  
  - CIFAR (4 类，32×32 彩色图像，20,000 训练 / 4,000 测试)  
  - FashionMNIST0.3 (30% 标签噪声，24,000 训练 / 4,000 测试)  
  - FashionMNIST0.6 (60% 标签噪声，24,000 训练 / 4,000 测试)  

- 方法  
  1. CNN 基线模型：两层卷积 + 池化 + Dropout + 全连接层  
  2. 损失函数  
     - Cross-Entropy  
     - Reweighted Loss  
     - Generalized Cross Entropy (GCE)  
  3. EM 算法：估计 CIFAR 数据集未知的噪声转移矩阵  

- 评估指标  
  - Top-1 Accuracy (多次运行取均值与方差)  
  - 可视化方式：折线图 / 柱状图 / 热力图  

---

## 依赖环境
- Python 3.10+  
- TensorFlow 2.17.0  
- Keras 3.4.1  
- NumPy, Pandas, Matplotlib, scikit-learn  
