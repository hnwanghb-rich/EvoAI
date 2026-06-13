-- ============================================================
-- HQEVOAI 数据库变更记录
-- 每次对数据库结构的修改，在此文件末尾追加对应的 SQL 语句
-- ============================================================

-- [2026-06-12] daily_questions 表补 category_id、tags 列及外键
-- 原因：ORM 模型(models.py)已包含这些字段，但 init.sql 缺失导致报错
--       ProgrammingError: column "category_id" does not exist
ALTER TABLE daily_questions ADD COLUMN IF NOT EXISTS category_id INT;
ALTER TABLE daily_questions ADD COLUMN IF NOT EXISTS tags VARCHAR(500);
ALTER TABLE daily_questions
    ADD CONSTRAINT IF NOT EXISTS fk_dq_category
    FOREIGN KEY (category_id) REFERENCES knowledge_categories(id) ON DELETE SET NULL;

-- [2026-06-12] knowledge_categories 表补 description 列
-- 原因：雷达图维度需要中文描述，鼠标悬停时展示
ALTER TABLE knowledge_categories ADD COLUMN IF NOT EXISTS description VARCHAR(200);

-- [2026-06-12] 更新知识分类描述（30条）
UPDATE knowledge_categories SET description = '考勤、报销、用车、办公等公司内部管理制度与流程规范' WHERE name = '公司制度与规范';
UPDATE knowledge_categories SET description = '集团使命愿景、核心价值观、服务理念与企业文化宣导' WHERE name = '企业文化与价值观';
UPDATE knowledge_categories SET description = '车间安全操作、消防应急、危化品管理、职业病防护等安全知识' WHERE name = '安全生产与消防';
UPDATE knowledge_categories SET description = '客户接待礼仪、电话沟通规范、职业形象与行为准则' WHERE name = '通用商务礼仪';
UPDATE knowledge_categories SET description = 'DMS系统、OA办公、企业微信、邮件等信息化工具使用教程' WHERE name = 'IT系统操作指南';
UPDATE knowledge_categories SET description = '汽车三包法、消费者权益保护、个人信息保护、反商业贿赂等法规' WHERE name = '法律法规合规';
UPDATE knowledge_categories SET description = '在售车型参数配置、核心卖点、产品定位及目标客群分析' WHERE name = '产品知识库';
UPDATE knowledge_categories SET description = '同级别竞品车型优劣势对比、攻防话术与差异化卖点提炼' WHERE name = '竞品对比分析';
UPDATE knowledge_categories SET description = '展厅接待、需求挖掘、试驾引导、异议处理及逼单成交的实战话术' WHERE name = '销售话术技巧';
UPDATE knowledge_categories SET description = '报价策略、优惠政策组合、金融方案推荐、赠品谈判与价格异议化解' WHERE name = '价格谈判策略';
UPDATE knowledge_categories SET description = '潜客分级跟进、战败客户分析、老客户转介绍及客户生命周期管理' WHERE name = '客户跟进管理';
UPDATE knowledge_categories SET description = '银行/厂家金融产品对比、按揭计算、征信预审及放款流程指导' WHERE name = '金融按揭方案';
UPDATE knowledge_categories SET description = '二手车检测评估方法、置换话术、残值预估与二手车销售策略' WHERE name = '二手车评估';
UPDATE knowledge_categories SET description = '试驾路线规划、动态体验引导、安全注意事项及试驾后促单流程' WHERE name = '试驾流程标准';
UPDATE knowledge_categories SET description = '涵盖发动机机械、燃油供给、进排气、冷却润滑系统的诊断与维修技术' WHERE name = '发动机系统维修';
UPDATE knowledge_categories SET description = 'MT/AT/CVT/DCT各类型变速箱的工作原理、常见故障与维修工艺' WHERE name = '变速箱维修技术';
UPDATE knowledge_categories SET description = '车载网络、灯光仪表、舒适电子、ADAS辅助驾驶系统的诊断与编程' WHERE name = '电气电子系统';
UPDATE knowledge_categories SET description = '制冷循环原理、压缩机/蒸发器检修、自动空调控制逻辑及故障排查' WHERE name = '空调暖风系统';
UPDATE knowledge_categories SET description = '悬挂系统、转向机、制动系统、轮胎四轮定位的检查调整与维修' WHERE name = '底盘悬挂转向';
UPDATE knowledge_categories SET description = '三电系统(电池/电机/电控)维修、高压安全操作、充电系统诊断与均衡维护' WHERE name = '新能源车维修';
UPDATE knowledge_categories SET description = '车身钣金修复、漆面处理、涂装工艺流程及色彩调配技术' WHERE name = '钣金喷漆工艺';
UPDATE knowledge_categories SET description = '故障码读取分析、数据流判断、示波器使用、异响定位及疑难故障排查思路' WHERE name = '故障诊断方法';
UPDATE knowledge_categories SET description = '客户预约管理、到店接待、环车检查、工单开单及交车流程标准' WHERE name = '预约接待流程';
UPDATE knowledge_categories SET description = '各车型保养周期、保养项目标准、油液规格及保养提醒话术' WHERE name = '保养服务标准';
UPDATE knowledge_categories SET description = '投诉分类分级、情绪安抚技巧、快速响应机制及投诉闭环处理流程' WHERE name = '客户投诉处理';
UPDATE knowledge_categories SET description = '车险定损流程、理赔资料指导、保险公司对接及事故车维修跟进' WHERE name = '保险理赔服务';
UPDATE knowledge_categories SET description = '续保客户筛选、保险产品对比推荐、续保话术及套餐组合策略' WHERE name = '续保业务技巧';
UPDATE knowledge_categories SET description = '售后三日回访、保养到期提醒、满意度调研及客户关怀活动标准' WHERE name = '客户回访规范';
UPDATE knowledge_categories SET description = '会员权益体系、积分规则、会员日活动策划及VIP客户专属服务标准' WHERE name = '会员服务管理';
UPDATE knowledge_categories SET description = '配件入库出库流程、库存预警、常用件备货策略及呆滞件处理规范' WHERE name = '配件仓储管理';

-- [2026-06-13] knowledge_categories 补 is_active 列
-- 原因：知识类别管理 Tab 需要软删除（停用）能力
--       有试题/知识引用的分类只能停用不能物理删除
ALTER TABLE knowledge_categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- [2026-06-13] 组卷出题系统：exam_papers / exam_papers_questions / exam_attempts
-- 原因：AI出题改为组卷出题，需要试卷管理 + 答卷记录
CREATE TABLE IF NOT EXISTS exam_papers (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    target_type VARCHAR(20) DEFAULT 'all',
    target_value VARCHAR(50),
    time_mode VARCHAR(20) DEFAULT 'anytime',
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    duration_minutes INT DEFAULT 60,
    total_questions INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_by INT REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exam_papers_questions (
    id SERIAL PRIMARY KEY,
    paper_id INT REFERENCES exam_papers(id) ON DELETE CASCADE,
    question_id INT REFERENCES daily_questions(id) ON DELETE CASCADE,
    sort_order INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS exam_attempts (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    paper_id INT REFERENCES exam_papers(id) ON DELETE CASCADE,
    answers JSONB DEFAULT '{}',
    score INT DEFAULT 0,
    total_questions INT DEFAULT 0,
    correct_count INT DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'started'
);

-- 授权 hqevoai 用户（非 postgres 创建时需单独执行）
-- GRANT ALL ON TABLE exam_papers TO hqevoai;
-- GRANT ALL ON TABLE exam_papers_questions TO hqevoai;
-- GRANT ALL ON TABLE exam_attempts TO hqevoai;
-- GRANT USAGE ON SEQUENCE exam_papers_id_seq TO hqevoai;
-- GRANT USAGE ON SEQUENCE exam_papers_questions_id_seq TO hqevoai;
-- GRANT USAGE ON SEQUENCE exam_attempts_id_seq TO hqevoai;

-- [2026-06-13] 岗位知识能力：position_capabilities
-- 原因：用户管理需要配置各岗位对应掌握的知识分类
CREATE TABLE IF NOT EXISTS position_capabilities (
    id SERIAL PRIMARY KEY,
    position VARCHAR(20) NOT NULL,
    category_id INT NOT NULL REFERENCES knowledge_categories(id) ON DELETE CASCADE,
    UNIQUE (position, category_id)
);
