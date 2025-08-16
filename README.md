# ZechenZhu – Project Portfolio

本仓库整理了多个研究与课程项目，涵盖 **数据分析、机器学习、深度学习、目标检测、仿真建模** 等方向，展示了在不同任务中的建模、实验与报告成果。

---

## 项目目录

### 1. [Analysis_of_domestic_violence_by_R](./Analysis_of_domestic_violence_by_R)
- **语言**: R (RMarkdown)  
- **内容**: 分析澳大利亚新南威尔士州（NSW）家庭暴力发生率与社会经济因素（失业率、收入、教育、租赁住房率）的关系  
- **方法**: 线性回归、多变量回归、广义加性模型 (GAM/GAMM)  
- **产出**: 可复现的 R 代码和 PDF 报告，核心结论表明收入/教育与暴力率呈负相关，失业率呈正相关  

---

### 2. [Housing_Model_Code_Netlogo](./Housing_Model_Code_Netlogo)
- **语言**: NetLogo  
- **内容**: 基于 Sugarscape 框架的住房市场多智能体模型  
- **功能**: 模拟居民迁徙、住房价格动态调整、政策干预（税收、补贴）对市场均衡的影响  
- **产出**: `.nlogo` 源码，README 说明运行与参数调节方式  

---

### 3. [Robust Noise-Tolerant Classification Model](./Robust%20Noise-Tolerant%20Classification%20Model)
- **语言**: Python (TensorFlow / Keras)  
- **内容**: 研究在标签噪声环境下的鲁棒分类模型  
- **方法**:  
  - 卷积神经网络 (CNN)  
  - Cross-Entropy, Reweighted Loss, Generalized Cross Entropy (GCE)  
  - EM 算法估计噪声转移矩阵  
- **结果**: GCE 和 Reweighted Loss 在中高噪声下表现优于普通交叉熵  

---

### 4. [Small object detection on an uncrewed surface vessel](./Small%20object%20detection%20on%20an%20uncrewed%20surface%20vessel)
- **语言**: Python (PyTorch, OpenCV)  
- **内容**: 无人艇（USV）环境下的小目标检测与跟踪  
- **模型**: CFAR, Faster R-CNN, YOLO (v8/v11), 多目标跟踪 (MHT & MOT)  
- **数据集**: MOANA (雷达 + 视觉)  
- **结果**: YOLOv11 在精度与速度上表现最佳 (mAP@50≈0.88)，适合实际部署  

---

### 5. [future electricity consumption prediction](./future%20electricity%20consumption%20prediction)
- **语言**: Python (TensorFlow / Scikit-learn)  
- **内容**: 电力负荷预测 (时间序列)  
- **方法**:  
  - MLP  
  - LSTM  
  - GRU  
- **数据集**: Electricity Load Diagrams 2011–2014 (UCI)  
- **结果**: MLP 训练速度与预测精度最佳 (MSE≈17)，LSTM/GRU 在复杂波动场景下更敏感但开销大  

---
