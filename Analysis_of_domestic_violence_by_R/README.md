# Domestic Violence Socioeconomic Analysis in NSW

## 项目简介
本项目旨在探究澳大利亚新南威尔士州（NSW）各地方政府辖区（LGA）家庭暴力发生率与关键社会经济因素之间的关系，重点考察失业率、住房租赁率、教育水平和收入水平的影响。  
通过多种统计建模方法（包括简单线性回归、多元逻辑回归和广义加性混合模型 GAMM），对 2011、2016、2021 年的家庭暴力数据及对应社会经济数据进行分析，以期为政府制定政策和干预措施提供数据支持。

---

## 数据来源
- **家庭暴力数据**：NSW Bureau of Crime Statistics and Research (BOCSAR)  
- **社会经济数据**：Australian Bureau of Statistics (ABS) Census Data (2011, 2016, 2021)  
- **空间数据**：ABS 提供的数字边界文件（ESRI Shapefile）

---

## 研究方法
1. **数据清洗与整合**  
   - 从 BOCSAR 获取家庭暴力相关攻击事件  
   - 从 ABS 获取失业率、租赁率、教育水平、收入水平等指标  
   - 使用人口数据标准化家庭暴力发生率（每10万人）

2. **模型分析**  
   - **简单线性回归**：分析单一因素与家庭暴力率的关系  
   - **多元逻辑回归**：同时考虑多因素的综合影响  
   - **广义加性混合模型 (GAMM)**：捕捉非线性关系，提升拟合效果  

3. **模型评估**  
   - 相关系数 (Correlation)  
   - 调整后 R²  
   - 方差膨胀因子 (VIF) 检测多重共线性  
   - 偏差解释率 (Deviance Explained)

---

## 主要结论
- 失业率与家庭暴力率呈 **正相关**，尤其在经济衰退年份相关性更高  
- 收入水平与家庭暴力率呈 **负相关**，较高收入可减少风险  
- 教育水平与家庭暴力率呈 **中度负相关**，高教育区域更可能降低暴力事件  
- 租赁住房率与家庭暴力率呈 **弱正相关**，住房不稳定性可能增加冲突风险  
- GAMM 在模型拟合优度上优于多元逻辑回归（调整 R² 提升至 0.30，解释率达 33.68%）

----------------------------------------------------------------------------------------

运行前，请先将 ABS 2021 Census 数据包 解压至本项目根目录下，将调用以下文件：
2021_TSP_LGA_for_NSW_short-header/2021 Census TSP Local Government Areas for NSW/2021Census_T01_NSW_LGA.csv
2021_TSP_LGA_for_NSW_short-header/2021 Census TSP Local Government Areas for NSW/2021Census_T33F_NSW_LGA.csv
2021_TSP_LGA_for_NSW_short-header/2021 Census TSP Local Government Areas for NSW/2021Census_T33G_NSW_LGA.csv
2021_TSP_LGA_for_NSW_short-header/2021 Census TSP Local Government Areas for NSW/2021Census_T33H_NSW_LGA.csv
2021_TSP_LGA_for_NSW_short-header/2021 Census TSP Local Government Areas for NSW/2021Census_T18A_NSW_LGA.csv
