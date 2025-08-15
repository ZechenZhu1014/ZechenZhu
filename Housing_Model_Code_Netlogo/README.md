# Sugarscape Housing Model

多智能体住房市场模拟（NetLogo）。模型基于经典 Sugarscape 框架，加入住房供需与价格动态、空间异质性与政策干预，用于分析不同政策/资源配置下的市场演化与福利影响。

> 文件：`Sugarscape_Housing_Model_final_code.nlogo`  
> 平台：NetLogo（推荐 6.2+）

---

## 主要特性
- 市场价格动态：房价受资源密度、人口分布与个体财富共同驱动，随供需变化自适应调整  
- 个体理性迁徙：代理在收益最大化与通勤/便利性之间权衡，形成空间集聚或扩散  
- 政策干预：支持税率、补贴等参数，评估政策对价格、交易量与福利分布的影响  
- 结果可视化：房价曲线、财富分布、交易量、空间热力等

---

## 步骤
1. 安装 NetLogo：<https://ccl.northwestern.edu/netlogo/>  
2. 打开 `Sugarscape_Housing_Model_final_code.nlogo`  
3. 在界面中：
   - 点击 **Setup** 初始化
   - 点击 **Go** 运行/暂停
4. 可调控参数（通过滑块/开关）：
   - `initial-population`：初始人口
   - `resource-regrowth`：资源再生速度
   - `tax-rate` / `subsidy`：税收与补贴
   - `move-radius` / `vision`：迁徙与视野
   - `market-elasticity`：价格弹性
   - `policy-toggle`：是否启用政策场景

---

## 输出与监控
- Price Index：市场价格指数/均价走势  
- Transactions：单位时间成交量  
- Wealth Gini / Histogram：财富不平等与分布  
- Spatial Map：居民/房价的空间格局  
- Welfare Metrics：效用/负担率/可负担性（如支付能力占收入比）

---
