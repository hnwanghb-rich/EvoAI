"""
种子数据初始化 —— 首次启动时自动写入
检查 users 表是否有数据，无则插入全部种子数据
"""
import logging
from datetime import datetime

from passlib.context import CryptContext
from sqlalchemy import text, select, func

from database import async_session
from models import (
    Department, Store, User, KnowledgeCategory, KnowledgeEntry,
    LLMProvider, SystemConfig, SkinPreference, DailyQuestion,
    UserRoleEnum, UserPositionEnum, KnowledgeBaseEnum,
    LLMProviderTypeEnum, EntryStatusEnum, SourceTypeEnum,
    ContentTypeEnum, QuestionTypeEnum,
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

logger = logging.getLogger(__name__)

# 默认密码
DEFAULT_PASSWORD = "hequn123"


async def seed_all():
    """主入口：检查并按序执行种子数据插入"""
    async with async_session() as db:
        # 检查是否已有种子数据
        result = await db.execute(select(func.count()).select_from(User))
        if result.scalar() > 0:
            logger.info("种子数据已存在，跳过")
            return

        logger.info("开始写入种子数据...")
        await _seed_departments(db)
        await _seed_stores(db)
        await db.flush()
        await _seed_categories(db)
        await _seed_users(db)
        await _seed_llm_providers(db)
        await _seed_system_config(db)
        await _seed_skin_preferences(db)
        await db.flush()
        await _seed_knowledge_entries(db)
        await db.flush()
        await _seed_questions(db)

        await db.commit()
        logger.info("种子数据写入完成")


async def _seed_departments(db):
    depts = [
        Department(name="销售部"),
        Department(name="技术部"),
        Department(name="客服部"),
        Department(name="行政部"),
    ]
    db.add_all(depts)
    logger.info("  部门: 3 条")


async def _seed_stores(db):
    stores = [
        Store(name="合群旗舰店", address="市中心主干道888号"),
        Store(name="合群城西店", address="城西开发区汽车城A区"),
    ]
    db.add_all(stores)
    logger.info("  门店: 2 条")


async def _seed_categories(db):
    """30条知识分类，覆盖4大知识库"""
    categories = [
        # === 公共通用 (public) ===
        KnowledgeCategory(name="公司制度与规范", knowledge_base=KnowledgeBaseEnum.public, sort_order=1, icon="▤", description="考勤、报销、用车、办公等公司内部管理制度与流程规范"),
        KnowledgeCategory(name="企业文化与价值观", knowledge_base=KnowledgeBaseEnum.public, sort_order=2, icon="⊟", description="集团使命愿景、核心价值观、服务理念与企业文化宣导"),
        KnowledgeCategory(name="安全生产与消防", knowledge_base=KnowledgeBaseEnum.public, sort_order=3, icon="△", description="车间安全操作、消防应急、危化品管理、职业病防护等安全知识"),
        KnowledgeCategory(name="通用商务礼仪", knowledge_base=KnowledgeBaseEnum.public, sort_order=4, icon="⇄", description="客户接待礼仪、电话沟通规范、职业形象与行为准则"),
        KnowledgeCategory(name="IT系统操作指南", knowledge_base=KnowledgeBaseEnum.public, sort_order=5, icon="⌘", description="DMS系统、OA办公、企业微信、邮件等信息化工具使用教程"),
        KnowledgeCategory(name="法律法规合规", knowledge_base=KnowledgeBaseEnum.public, sort_order=6, icon="☐", description="汽车三包法、消费者权益保护、个人信息保护、反商业贿赂等法规"),
        # === 销售专属 (sales) ===
        KnowledgeCategory(name="产品知识库", knowledge_base=KnowledgeBaseEnum.sales, sort_order=1, icon="◈", description="在售车型参数配置、核心卖点、产品定位及目标客群分析"),
        KnowledgeCategory(name="竞品对比分析", knowledge_base=KnowledgeBaseEnum.sales, sort_order=2, icon="◱", description="同级别竞品车型优劣势对比、攻防话术与差异化卖点提炼"),
        KnowledgeCategory(name="销售话术技巧", knowledge_base=KnowledgeBaseEnum.sales, sort_order=3, icon="◎", description="展厅接待、需求挖掘、试驾引导、异议处理及逼单成交的实战话术"),
        KnowledgeCategory(name="价格谈判策略", knowledge_base=KnowledgeBaseEnum.sales, sort_order=4, icon="◇", description="报价策略、优惠政策组合、金融方案推荐、赠品谈判与价格异议化解"),
        KnowledgeCategory(name="客户跟进管理", knowledge_base=KnowledgeBaseEnum.sales, sort_order=5, icon="✎", description="潜客分级跟进、战败客户分析、老客户转介绍及客户生命周期管理"),
        KnowledgeCategory(name="金融按揭方案", knowledge_base=KnowledgeBaseEnum.sales, sort_order=6, icon="⊕", description="银行/厂家金融产品对比、按揭计算、征信预审及放款流程指导"),
        KnowledgeCategory(name="二手车评估", knowledge_base=KnowledgeBaseEnum.sales, sort_order=7, icon="↺", description="二手车检测评估方法、置换话术、残值预估与二手车销售策略"),
        KnowledgeCategory(name="试驾流程标准", knowledge_base=KnowledgeBaseEnum.sales, sort_order=8, icon="▷", description="试驾路线规划、动态体验引导、安全注意事项及试驾后促单流程"),
        # === 技术服务 (tech) ===
        KnowledgeCategory(name="发动机系统维修", knowledge_base=KnowledgeBaseEnum.tech, sort_order=1, icon="⚙", description="涵盖发动机机械、燃油供给、进排气、冷却润滑系统的诊断与维修技术"),
        KnowledgeCategory(name="变速箱维修技术", knowledge_base=KnowledgeBaseEnum.tech, sort_order=2, icon="⊗", description="MT/AT/CVT/DCT各类型变速箱的工作原理、常见故障与维修工艺"),
        KnowledgeCategory(name="电气电子系统", knowledge_base=KnowledgeBaseEnum.tech, sort_order=3, icon="▲", description="车载网络、灯光仪表、舒适电子、ADAS辅助驾驶系统的诊断与编程"),
        KnowledgeCategory(name="空调暖风系统", knowledge_base=KnowledgeBaseEnum.tech, sort_order=4, icon="✦", description="制冷循环原理、压缩机/蒸发器检修、自动空调控制逻辑及故障排查"),
        KnowledgeCategory(name="底盘悬挂转向", knowledge_base=KnowledgeBaseEnum.tech, sort_order=5, icon="◉", description="悬挂系统、转向机、制动系统、轮胎四轮定位的检查调整与维修"),
        KnowledgeCategory(name="新能源车维修", knowledge_base=KnowledgeBaseEnum.tech, sort_order=6, icon="⊞", description="三电系统(电池/电机/电控)维修、高压安全操作、充电系统诊断与均衡维护"),
        KnowledgeCategory(name="钣金喷漆工艺", knowledge_base=KnowledgeBaseEnum.tech, sort_order=7, icon="◫", description="车身钣金修复、漆面处理、涂装工艺流程及色彩调配技术"),
        KnowledgeCategory(name="故障诊断方法", knowledge_base=KnowledgeBaseEnum.tech, sort_order=8, icon="⊘", description="故障码读取分析、数据流判断、示波器使用、异响定位及疑难故障排查思路"),
        # === 售后客服 (service) ===
        KnowledgeCategory(name="预约接待流程", knowledge_base=KnowledgeBaseEnum.service, sort_order=1, icon="◷", description="客户预约管理、到店接待、环车检查、工单开单及交车流程标准"),
        KnowledgeCategory(name="保养服务标准", knowledge_base=KnowledgeBaseEnum.service, sort_order=2, icon="⌖", description="各车型保养周期、保养项目标准、油液规格及保养提醒话术"),
        KnowledgeCategory(name="客户投诉处理", knowledge_base=KnowledgeBaseEnum.service, sort_order=3, icon="◁", description="投诉分类分级、情绪安抚技巧、快速响应机制及投诉闭环处理流程"),
        KnowledgeCategory(name="保险理赔服务", knowledge_base=KnowledgeBaseEnum.service, sort_order=4, icon="≡", description="车险定损流程、理赔资料指导、保险公司对接及事故车维修跟进"),
        KnowledgeCategory(name="续保业务技巧", knowledge_base=KnowledgeBaseEnum.service, sort_order=5, icon="↻", description="续保客户筛选、保险产品对比推荐、续保话术及套餐组合策略"),
        KnowledgeCategory(name="客户回访规范", knowledge_base=KnowledgeBaseEnum.service, sort_order=6, icon="☏", description="售后三日回访、保养到期提醒、满意度调研及客户关怀活动标准"),
        KnowledgeCategory(name="会员服务管理", knowledge_base=KnowledgeBaseEnum.service, sort_order=7, icon="◆", description="会员权益体系、积分规则、会员日活动策划及VIP客户专属服务标准"),
        KnowledgeCategory(name="配件仓储管理", knowledge_base=KnowledgeBaseEnum.service, sort_order=8, icon="□", description="配件入库出库流程、库存预警、常用件备货策略及呆滞件处理规范"),
    ]
    db.add_all(categories)
    logger.info(f"  分类: {len(categories)} 条")


async def _seed_users(db):
    # 先取部门ID
    result = await db.execute(select(Department))
    depts = {d.name: d.id for d in result.scalars().all()}

    users = [
        User(
            username="boss",
            real_name="张总裁",
            password_hash=pwd_context.hash(DEFAULT_PASSWORD),
            role=UserRoleEnum.boss,
            position=None,
            dept_id=None,
        ),
        User(
            username="admin",
            real_name="李管理",
            password_hash=pwd_context.hash(DEFAULT_PASSWORD),
            role=UserRoleEnum.admin,
            position=None,
            dept_id=None,
        ),
        User(
            username="sales01",
            real_name="王销售",
            password_hash=pwd_context.hash(DEFAULT_PASSWORD),
            role=UserRoleEnum.staff,
            position=UserPositionEnum.sales,
            dept_id=depts.get("销售部"),
        ),
        User(
            username="tech01",
            real_name="赵技师",
            password_hash=pwd_context.hash(DEFAULT_PASSWORD),
            role=UserRoleEnum.staff,
            position=UserPositionEnum.tech,
            dept_id=depts.get("技术部"),
        ),
        User(
            username="service01",
            real_name="陈客服",
            password_hash=pwd_context.hash(DEFAULT_PASSWORD),
            role=UserRoleEnum.staff,
            position=UserPositionEnum.service,
            dept_id=depts.get("客服部"),
        ),
        User(
            username="clerk01",
            real_name="刘文员",
            password_hash=pwd_context.hash(DEFAULT_PASSWORD),
            role=UserRoleEnum.staff,
            position=UserPositionEnum.clerk,
            dept_id=depts.get("行政部"),
        ),
    ]
    db.add_all(users)
    logger.info(f"  用户: {len(users)} 条")


async def _seed_llm_providers(db):
    """8个预设LLM模型，api_key留空，is_active=false"""
    providers = [
        LLMProvider(name="通义千问", provider_type=LLMProviderTypeEnum.tongyi,
                    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
                    model_name="qwen-plus"),
        LLMProvider(name="DeepSeek", provider_type=LLMProviderTypeEnum.deepseek,
                    base_url="https://api.deepseek.com/v1",
                    model_name="deepseek-chat"),
        LLMProvider(name="智谱GLM", provider_type=LLMProviderTypeEnum.zhipu,
                    base_url="https://open.bigmodel.cn/api/paas/v4",
                    model_name="glm-4-flash"),
        LLMProvider(name="月之暗面Kimi", provider_type=LLMProviderTypeEnum.kimi,
                    base_url="https://api.moonshot.cn/v1",
                    model_name="moonshot-v1-8k"),
        LLMProvider(name="百川智能", provider_type=LLMProviderTypeEnum.baichuan,
                    base_url="https://api.baichuan-ai.com/v1",
                    model_name="Baichuan4"),
        LLMProvider(name="讯飞星火", provider_type=LLMProviderTypeEnum.xfyun,
                    base_url="https://spark-api-open.xf-yun.com/v1",
                    model_name="generalv3.5"),
        LLMProvider(name="硅基流动", provider_type=LLMProviderTypeEnum.siliconflow,
                    base_url="https://api.siliconflow.cn/v1",
                    model_name="Qwen/Qwen2.5-7B-Instruct"),
        LLMProvider(name="Dify平台", provider_type=LLMProviderTypeEnum.dify,
                    base_url="https://api.dify.ai/v1",
                    model_name="chat-messages"),
    ]
    db.add_all(providers)
    logger.info(f"  LLM: {len(providers)} 条")


async def _seed_system_config(db):
    """默认积分规则和飞轮阈值"""
    configs = [
        SystemConfig(config_key="points_submit", config_value="1",
                     config_type="int", description="提交经验积分"),
        SystemConfig(config_key="points_approved", config_value="10",
                     config_type="int", description="审核通过积分"),
        SystemConfig(config_key="points_useful", config_value="2",
                     config_type="int", description="被标记有用积分"),
        SystemConfig(config_key="points_monthly_top5", config_value="50",
                     config_type="int", description="月度TOP5积分"),
        SystemConfig(config_key="points_daily_question", config_value="1",
                     config_type="int", description="每次一题答对积分"),
        SystemConfig(config_key="points_complete_course", config_value="3",
                     config_type="int", description="完成课程积分"),
        SystemConfig(config_key="flywheel_view_threshold", config_value="5",
                     config_type="int", description="低效经验浏览阈值(<N次)"),
        SystemConfig(config_key="flywheel_month_threshold", config_value="6",
                     config_type="int", description="知识更新周期(月)"),
        SystemConfig(config_key="flywheel_useful_rate", config_value="0.7",
                     config_type="float", description="有效经验有用率阈值"),
        SystemConfig(config_key="flywheel_low_useful_rate", config_value="0.3",
                     config_type="float", description="待优化经验有用率阈值"),
        SystemConfig(config_key="asr_provider", config_value="whisper",
                     config_type="string", description="语音识别引擎: whisper(本地离线) 或 tencent(腾讯云)"),
    ]
    db.add_all(configs)
    logger.info(f"  系统配置: {len(configs)} 条")


async def _seed_skin_preferences(db):
    """所有用户默认 skin_id=1"""
    result = await db.execute(select(User.id))
    user_ids = [r[0] for r in result.all()]
    prefs = [SkinPreference(user_id=uid, skin_id=1) for uid in user_ids]
    db.add_all(prefs)
    logger.info(f"  皮肤偏好: {len(prefs)} 条")


async def _seed_knowledge_entries(db):
    """4条示例知识（覆盖4大知识库，status=approved 可直接浏览）"""
    # 取分类ID
    cat_result = await db.execute(select(KnowledgeCategory))
    cats = {f"{c.knowledge_base.value}:{c.name}": c.id for c in cat_result.scalars().all()}

    entries = [
        KnowledgeEntry(
            title="星瑞L6产品核心卖点",
            content="""星瑞L6作为合群汽车集团旗舰新能源轿车，核心卖点包括：
1. **续航里程**：CLTC综合续航1200km，纯电续航200km
2. **智能座舱**：搭载15.6英寸中控屏，支持语音控制、手势识别
3. **安全配置**：L2+级智能驾驶辅助，全车6气囊
4. **动力系统**：1.5T混动专用发动机 + 前置电机，综合功率230kW
5. **质保政策**：整车5年/15万公里，三电系统终身质保（首任车主）

销售话术要点：重点强调续航和质保这两个差异化优势，与比亚迪汉DM-i对比突出了更高功率和更长整车质保。""",
            content_type=ContentTypeEnum.text,
            category_id=cats.get("sales:产品知识库", 7),
            knowledge_base=KnowledgeBaseEnum.sales,
            source_type=SourceTypeEnum.manual,
            source_person="李管理",
            source_dept="销售部",
            tags="星瑞L6,产品卖点,新能源,轿车",
            car_brand="星瑞",
            car_model="L6",
            difficulty_level=2,
            status=EntryStatusEnum.approved,
            view_count=128,
            useful_count=15,
        ),
        KnowledgeEntry(
            title="国六B排放发动机怠速抖动故障诊断",
            content="""故障现象：国六B排放标准车辆，冷启动后怠速不稳，转速波动±150rpm，伴随轻微抖动。

诊断步骤：
1. **读取故障码**：使用诊断仪读取ECU，常见故障码P0300(随机失火)、P0171(混合气过稀)
2. **检查火花塞**：国六B发动机对火花塞间隙要求更严，标准0.7-0.8mm，超过0.9mm需更换
3. **检查燃油系统**：测量燃油压力，怠速时应为350-400kPa
4. **检查碳罐电磁阀**：国六B车型碳罐电磁阀容易卡滞在常开位置，导致混合气过稀
5. **检查进气系统**：曲轴箱通风PCV阀、进气歧管密封

典型维修案例：星瑞X5 SUV，行驶3万公里，怠速抖动。最终确认碳罐电磁阀故障，更换后问题解决。维修时间约1.5小时，材料费240元。""",
            content_type=ContentTypeEnum.text,
            category_id=cats.get("tech:故障诊断方法", 22),
            knowledge_base=KnowledgeBaseEnum.tech,
            source_type=SourceTypeEnum.experience,
            source_person="赵技师",
            source_dept="技术部",
            tags="怠速抖动,国六B,碳罐电磁阀,故障诊断",
            car_brand="星瑞",
            car_model="X5",
            difficulty_level=4,
            status=EntryStatusEnum.approved,
            view_count=89,
            useful_count=23,
        ),
        KnowledgeEntry(
            title="客户投诉三步骤化解法",
            content="""面对客户投诉，客服人员应遵循"听-认-行"三步法：

**第一步：倾听（2-3分钟）**
- 保持耐心，不打岔，让客户完整表达不满
- 使用积极倾听话术："嗯，我明白了""请您继续说"
- 注意记录关键信息：订单号、车牌号、投诉核心问题

**第二步：认可情绪（1分钟）**
- 共情话术："我完全理解您现在的心情，换作是我也会很着急"
- 不要急于解释或推卸，先让客户感受到被重视
- 确认问题："让我确认一下，您的主要问题是……对吗？"

**第三步：行动承诺（1分钟）**
- 给出明确时间承诺："我会在30分钟内给您回复"
- 告知具体处理方案："我们会安排技师重新检查"
- 留下联系方式，确保客户能找到您

典型案例：客户因保养时间过长投诉，客服使用三步法，从最初要求退款的对抗转为接受补偿方案（免费下次保养），客户后续续保率达85%。""",
            content_type=ContentTypeEnum.text,
            category_id=cats.get("service:客户投诉处理", 25),
            knowledge_base=KnowledgeBaseEnum.service,
            source_type=SourceTypeEnum.experience,
            source_person="陈客服",
            source_dept="客服部",
            tags="投诉处理,客服话术,客户关系",
            difficulty_level=2,
            status=EntryStatusEnum.approved,
            view_count=156,
            useful_count=31,
        ),
        KnowledgeEntry(
            title="合群汽车集团安全生产规范（2025版）",
            content="""**合群汽车集团安全生产管理制度（2025年修订版）**

一、车间安全
1. 维修作业必须佩戴防护用具（安全帽、防护手套、护目镜）
2. 举升机操作必须两人协作，严禁单人操作
3. 电气设备检修前必须断开电源并挂警示牌
4. 油品、涂料等易燃物品存放于专用防爆柜

二、消防管理
1. 每月15日进行消防器材点检，填写检查记录
2. 严禁在车间内吸烟或使用明火
3. 消防通道时刻保持畅通，禁止堆放杂物
4. 每季度进行一次全员消防演练

三、事故报告
1. 发生安全事故后，15分钟内向安全主管报告
2. 事故现场保护，不得擅自破坏
3. 72小时内提交书面事故分析报告
4. 隐瞒不报者按集团纪律处分条例处理

四、环保要求
1. 废机油、废电池等危废交由合规处置单位处理
2. 烤漆房废气处理设备每月维护一次
3. 噪音超标区域必须佩戴耳塞""",
            content_type=ContentTypeEnum.text,
            category_id=cats.get("public:安全生产与消防", 3),
            knowledge_base=KnowledgeBaseEnum.public,
            source_type=SourceTypeEnum.policy,
            source_person="李管理",
            source_dept="销售部",
            tags="安全生产,消防,管理制度,2025版",
            difficulty_level=1,
            status=EntryStatusEnum.approved,
            view_count=312,
            useful_count=8,
        ),
    ]
    db.add_all(entries)
    logger.info(f"  示例知识: {len(entries)} 条")


async def _seed_questions(db):
    """35道种子题目（销售10 + 技术10 + 客服10 + 公共5）
    注意：category_id 必须设置，否则个人看板统计全为 0/0
    映射：销售→产品知识库(7) 技术→发动机系统维修(15) 客服→预约接待流程(23) 公共→公司制度与规范(1)
    """
    questions = [
        # === 销售 10 题 (category_id=7 产品知识库) ===
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="星瑞L6的CLTC综合续航里程是多少？", options={"A":"800km","B":"1000km","C":"1200km","D":"1500km"}, answer="C", explanation="星瑞L6 CLTC综合续航1200km，纯电续航200km。", target_position=UserPositionEnum.sales, difficulty_level=1, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="星瑞L6的整车质保政策是？", options={"A":"3年/10万公里","B":"4年/12万公里","C":"5年/15万公里","D":"6年/20万公里"}, answer="C", explanation="整车5年/15万公里，三电系统终身质保（首任车主）。", target_position=UserPositionEnum.sales, difficulty_level=2, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="销售顾问可以对客户承诺三电系统终身质保适用于所有车主。", options=None, answer="false", explanation="三电系统终身质保仅适用于首任车主。", target_position=UserPositionEnum.sales, difficulty_level=1, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="销售过程中，遇到客户提出超出权限的价格折扣要求，应该？", options={"A":"直接拒绝","B":"请示销售经理","C":"自行降价","D":"忽略客户"}, answer="B", explanation="超出权限的价格折扣应请示销售经理，由管理层决策。", target_position=UserPositionEnum.sales, difficulty_level=2, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="下列哪项属于合群汽车集团金融按揭方案的特色？", options={"A":"仅合作一家银行","B":"支持多渠道银行按揭","C":"不提供金融服务","D":"仅支持全款购车"}, answer="B", explanation="集团支持多渠道银行按揭方案，为客户提供灵活金融选择。", target_position=UserPositionEnum.sales, difficulty_level=2, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="试驾过程中，销售顾问首先应该做什么？", options={"A":"直接让客户上高速","B":"讲解试驾路线和安全注意事项","C":"让客户自行驾驶","D":"播放音乐"}, answer="B", explanation="试驾前必须先讲解路线和安全注意事项，确保客户了解操作。", target_position=UserPositionEnum.sales, difficulty_level=1, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.multi_choice, question_content="以下哪些是星瑞L6的智能座舱功能？（多选）", options={"A":"15.6英寸中控屏","B":"语音控制","C":"手势识别","D":"全自动驾驶"}, answer="ABC", explanation="星瑞L6支持15.6英寸中控屏、语音控制、手势识别，但无全自动驾驶。", target_position=UserPositionEnum.sales, difficulty_level=3, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="客户跟进管理中，首次接触后应在多长时间内进行回访？", options={"A":"1小时内","B":"24小时内","C":"3天内","D":"1周内"}, answer="B", explanation="客户首次接触后建议24小时内回访，保持沟通热度。", target_position=UserPositionEnum.sales, difficulty_level=2, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="二手车评估只看外观和里程数即可定价。", options=None, answer="false", explanation="二手车评估需综合考虑品牌、车型、车龄、里程、事故维修记录等多维因素。", target_position=UserPositionEnum.sales, difficulty_level=1, category_id=7),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="与比亚迪汉DM-i对比，星瑞L6的差异化优势是什么？", options={"A":"更低功率","B":"更高功率和更长整车质保","C":"更低续航","D":"更少安全气囊"}, answer="B", explanation="星瑞L6综合功率230kW，高于汉DM-i；整车质保5年/15万公里也更长。", target_position=UserPositionEnum.sales, difficulty_level=3, category_id=7),

        # === 技术 10 题 (category_id=15 发动机系统维修) ===
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="国六B发动机怠速抖动时，常见的故障码是什么？", options={"A":"P0101","B":"P0300","C":"P0500","D":"P0700"}, answer="B", explanation="P0300(随机失火)和P0171(混合气过稀)是国六B怠速抖动常见故障码。", target_position=UserPositionEnum.tech, difficulty_level=3, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="国六B发动机火花塞的标准间隙是多少？", options={"A":"0.5-0.6mm","B":"0.7-0.8mm","C":"1.0-1.2mm","D":"1.5mm以上"}, answer="B", explanation="国六B发动机对火花塞间隙要求更严，标准0.7-0.8mm。", target_position=UserPositionEnum.tech, difficulty_level=2, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="发动机怠速时燃油压力应为多少？", options={"A":"200-250kPa","B":"350-400kPa","C":"500-600kPa","D":"700-800kPa"}, answer="B", explanation="怠速时燃油压力应为350-400kPa。", target_position=UserPositionEnum.tech, difficulty_level=3, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="举升机操作可以单人完成，无需两人协作。", options=None, answer="false", explanation="举升机操作必须两人协作，严禁单人操作，这是安全生产规范要求。", target_position=UserPositionEnum.tech, difficulty_level=1, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="国六B车型碳罐电磁阀常见故障是什么？", options={"A":"完全堵塞","B":"卡滞在常开位置","C":"电路短路","D":"物理断裂"}, answer="B", explanation="国六B车型碳罐电磁阀容易卡滞在常开位置，导致混合气过稀。", target_position=UserPositionEnum.tech, difficulty_level=4, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="新能源车维修中，高压系统断电后需等待多久才能操作？", options={"A":"1分钟","B":"5分钟","C":"至少10分钟","D":"立即操作"}, answer="C", explanation="高压系统断电后需等待至少10分钟，确保电容放电完毕，方可操作。", target_position=UserPositionEnum.tech, difficulty_level=3, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="钣金喷漆工艺中，底漆的主要作用是什么？", options={"A":"美观","B":"防锈和增加面漆附着力","C":"遮瑕","D":"增加重量"}, answer="B", explanation="底漆主要起防锈作用并为面漆提供良好的附着基础。", target_position=UserPositionEnum.tech, difficulty_level=2, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="电气设备检修前不需要断开电源，只需告知同事即可。", options=None, answer="false", explanation="电气设备检修前必须断开电源并挂警示牌，这是安全生产强制要求。", target_position=UserPositionEnum.tech, difficulty_level=1, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.multi_choice, question_content="以下哪些是故障诊断的基本步骤？（多选）", options={"A":"读取故障码","B":"目视检查","C":"直接更换全部零件","D":"使用诊断仪检查数据流"}, answer="ABD", explanation="故障诊断步骤包括读取故障码、目视检查和数据流分析，不应盲目更换零件。", target_position=UserPositionEnum.tech, difficulty_level=2, category_id=15),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="废机油应如何处理？", options={"A":"倒入下水道","B":"卖给废品站","C":"交由合规危废处置单位","D":"混入生活垃圾"}, answer="C", explanation="废机油属于危险废物，必须交由合规处置单位处理。", target_position=UserPositionEnum.tech, difficulty_level=1, category_id=15),

        # === 客服 10 题 (category_id=23 预约接待流程) ===
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="客户投诉'听-认-行'三步法中，第一步是什么？", options={"A":"行动解决","B":"耐心倾听","C":"马上解释","D":"直接拒绝"}, answer="B", explanation="三步法第一步是耐心倾听，让客户完整表达不满。", target_position=UserPositionEnum.service, difficulty_level=1, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="处理客户投诉时，以下哪种话术是共情式表达的体现？", options={"A":"这是你的问题","B":"我完全理解您现在的心情","C":"您说得不对","D":"您去找我们领导"}, answer="B", explanation="共情话术如'我完全理解您现在的心情'能有效缓解客户情绪。", target_position=UserPositionEnum.service, difficulty_level=1, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="客户投诉后，客服应在多长时间内给予回复？", options={"A":"24小时内","B":"30分钟内","C":"3天内","D":"1周内"}, answer="B", explanation="应给出明确时间承诺：'我会在30分钟内给您回复'。", target_position=UserPositionEnum.service, difficulty_level=2, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="客户投诉处理时，应该先解释原因，再倾听客户诉求。", options=None, answer="false", explanation="应先倾听客户诉求，认可情绪后再解释和处理，不可急于解释。", target_position=UserPositionEnum.service, difficulty_level=1, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="预约保养接待流程中，客户到店后首先应？", options={"A":"让客户自己找车位","B":"引导停车并接待登记","C":"让客户等待","D":"直接开进车间"}, answer="B", explanation="客户到店后首先应引导停车并完成接待登记。", target_position=UserPositionEnum.service, difficulty_level=1, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="保险理赔服务中，客服需要协助客户准备哪些材料？", options={"A":"仅驾驶证","B":"事故证明+定损单+驾驶证+行驶证","C":"仅发票","D":"仅身份证"}, answer="B", explanation="保险理赔需要事故证明、定损单、驾驶证、行驶证等全套材料。", target_position=UserPositionEnum.service, difficulty_level=2, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="续保业务技巧中，最佳续保时机是什么时候？", options={"A":"保险到期后","B":"保险到期前30天","C":"保险到期前1天","D":"任意时间"}, answer="B", explanation="保险到期前30天是最佳续保时机，给客户充足的比较和考虑时间。", target_position=UserPositionEnum.service, difficulty_level=2, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.multi_choice, question_content="以下哪些属于会员服务的权益？（多选）", options={"A":"优先预约","B":"消费积分兑换","C":"免费年度检测","D":"免费购车"}, answer="ABC", explanation="会员通常享有优先预约、消费积分兑换和免费年度检测等权益。", target_position=UserPositionEnum.service, difficulty_level=2, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="配件仓储管理可以采用先进先出原则降低库存损耗。", options=None, answer="true", explanation="先进先出(FIFO)原则可有效降低配件库存损耗和管理成本。", target_position=UserPositionEnum.service, difficulty_level=1, category_id=23),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="客户回访的最佳频次是？", options={"A":"每天一次","B":"保养后7-15天","C":"每年一次","D":"从不回访"}, answer="B", explanation="保养后7-15天回访可有效了解客户满意度和发现潜在问题。", target_position=UserPositionEnum.service, difficulty_level=2, category_id=23),

        # === 公共 5 题 (category_id=1 公司制度与规范) ===
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="合群汽车集团的消防器材点检频率是？", options={"A":"每月15日","B":"每季度一次","C":"每年一次","D":"不定期"}, answer="A", explanation="每月15日进行消防器材点检，填写检查记录。", target_position=None, difficulty_level=1, category_id=1),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="车间内可以吸烟，但需在指定区域。", options=None, answer="false", explanation="严禁在车间内吸烟或使用明火，这是消防安全强制规定。", target_position=None, difficulty_level=1, category_id=1),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="安全事故发生后，应在多长时间内向安全主管报告？", options={"A":"15分钟内","B":"1小时内","C":"24小时内","D":"72小时内"}, answer="A", explanation="发生安全事故后，15分钟内向安全主管报告。", target_position=None, difficulty_level=1, category_id=1),
        DailyQuestion(question_type=QuestionTypeEnum.single_choice, question_content="合群汽车集团的企业愿景核心是？", options={"A":"利润第一","B":"知识驱动、全员成长","C":"快速发展","D":"削减成本"}, answer="B", explanation="合群汽车集团以知识驱动飞轮、全员能力提升为企业成长的核心战略。", target_position=None, difficulty_level=1, category_id=1),
        DailyQuestion(question_type=QuestionTypeEnum.true_false, question_content="全员消防演练应每季度进行一次。", options=None, answer="true", explanation="每季度进行一次全员消防演练是集团安全管理制度的要求。", target_position=None, difficulty_level=1, category_id=1),
    ]
    db.add_all(questions)
    logger.info(f"  题库: {len(questions)} 条")

