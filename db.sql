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

-- [2026-06-14] 导入 position_capabilities 初始数据（52条）
-- 来源：GitHub db_full.sql，覆盖 sales/tech/service/clerk 四岗位
INSERT INTO position_capabilities (id, "position", category_id) VALUES
(4,'sales',1),(5,'sales',2),(6,'sales',3),(7,'sales',4),(8,'sales',5),
(9,'sales',6),(10,'sales',7),(11,'sales',8),(12,'sales',9),(13,'sales',10),
(14,'sales',11),(15,'sales',12),(16,'sales',13),(17,'sales',14),
(18,'tech',15),(19,'tech',16),(20,'tech',17),(21,'tech',18),(22,'tech',19),
(23,'tech',20),(24,'tech',21),(25,'tech',22),(26,'tech',1),(27,'tech',2),
(28,'tech',3),(29,'tech',4),(30,'tech',5),(31,'tech',6),
(32,'service',1),(33,'service',2),(34,'service',3),(35,'service',4),(36,'service',5),
(37,'service',6),(38,'service',23),(39,'service',25),(40,'service',24),(41,'service',26),
(42,'service',27),(43,'service',28),(44,'service',29),(45,'service',30),
(46,'clerk',1),(47,'clerk',2),(48,'clerk',3),(49,'clerk',4),(50,'clerk',5),
(51,'clerk',6),(52,'clerk',7),(53,'clerk',8),(54,'clerk',13),(55,'clerk',12);

SELECT setval('position_capabilities_id_seq', (SELECT max(id) FROM position_capabilities));

-- [2026-06-14] 修复 daily_questions.category_id 全部为 NULL 的问题
-- 原因：seed_data.py 创建试题时未设置 category_id，导致个人看板分类统计全部为 0/0
-- 解决：从 GitHub db_full.sql 提取 category_id 映射并更新（87题覆盖86题，1题手动补）
-- 影响：_calc_mastery_by_category → coalesce(category_id, knowledge_entry.category_id) 链路恢复

-- [2026-06-14] 补 asr_provider 系统配置
-- 原因：seed_data 未包含此配置，get_active_asr_provider() 查不到值，默认回退 whisper
INSERT INTO system_config (config_key, config_value, config_type, description)
VALUES ('asr_provider', 'whisper', 'string', 'ASR engine: whisper(local) or tencent(cloud)')
ON CONFLICT (config_key) DO NOTHING;

-- [2026-06-14] 补腾讯云 ASR 加密密钥
-- 来源：GitHub db_full.sql (id=11,12)，本地缺失导致切换 tencent 时 ASR 无密钥可用
INSERT INTO system_config (config_key, config_value, config_type, description)
VALUES ('asr_secret_id', 'gAAAAABqLW39xDgTnn0jjWj1UR40OHjCkmiNtmyW-WjFzJAJ9NF7LsxyUGWPrA2XllJAwWe_YDX-4rQwMWEPHUoncYKVKAxaVwZc7VeJ_ovVNCizK1LkseNjmyaFvrZIRc7XIxnlmQbP', 'encrypted', 'Tencent Cloud ASR SecretId')
ON CONFLICT (config_key) DO NOTHING;

INSERT INTO system_config (config_key, config_value, config_type, description)
VALUES ('asr_secret_key', 'gAAAAABqLW-ok8tqNul0E0FH1K-6K39CoUXIyh9P1-MGyCX9ITT2v_a39AfshcSGmi1hF8GWMQLrxUUCdgNt2RK2BhVY6_CwSOlle0yu4ZnKKLa7CWbDeclLGIpD2WMJYXgY2ltDj48D', 'encrypted', 'Tencent Cloud ASR SecretKey')
ON CONFLICT (config_key) DO NOTHING;

-- [2026-06-18] FW-01 知识缺口飞轮：knowledge_gaps 表
-- 原因：把阿能问答中 is_hit=0（知识库未命中）的问题沉淀为可指派/可关闭的知识缺口工单
--       懒持久化——仅"指派建单"时插行；候选缺口实时从 chat_logs 聚合算出，不改 chat_logs
-- 闭环：候选缺口(列表) → 指派(建单) → 补知识审核通过 → 关闭(关联补充知识)
CREATE TABLE IF NOT EXISTS knowledge_gaps (
    id SERIAL PRIMARY KEY,
    question             TEXT NOT NULL,                  -- 缺口代表问题（精确文本=聚类键）
    hit_count            INT  DEFAULT 0,                 -- 建单时"被问次数"快照
    target_kb            VARCHAR(20),                    -- 目标库 public/sales/tech/service
    suggest_category_id  INT REFERENCES knowledge_categories(id) ON DELETE SET NULL,
    status               VARCHAR(20) DEFAULT 'assigned', -- assigned / closed
    assignee_id          INT REFERENCES users(id) ON DELETE SET NULL,            -- 指派给谁补
    related_knowledge_id INT REFERENCES knowledge_entries(id) ON DELETE SET NULL,-- 关闭时关联的补充知识
    created_by           INT REFERENCES users(id) ON DELETE SET NULL,            -- 建单人
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    closed_at            TIMESTAMPTZ
);

-- 授权 hqevoai 用户（非 postgres 创建时需单独执行）
-- GRANT ALL ON TABLE knowledge_gaps TO hqevoai;
-- GRANT USAGE ON SEQUENCE knowledge_gaps_id_seq TO hqevoai;

-- [2026-06-18] FW-04 知识时效中心：knowledge_entries 增加保质期相关列
ALTER TABLE knowledge_entries ADD COLUMN IF NOT EXISTS expire_at TIMESTAMPTZ;
ALTER TABLE knowledge_entries ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMPTZ;

-- [2026-06-18] FW-05 销售飞轮·赢单复盘台
-- 成交单暂存表（🔌 手动 Excel 导入，对接 CRM 后可改为 API 写入）
CREATE TABLE IF NOT EXISTS sales_deals_import (
    id              SERIAL PRIMARY KEY,
    deal_date       DATE,
    car_brand       VARCHAR(50),
    car_model       VARCHAR(100),
    deal_price      NUMERIC(12,2),
    gross_margin    NUMERIC(12,2),
    consultant_name VARCHAR(50),
    consultant_id   INT REFERENCES users(id) ON DELETE SET NULL,
    knowledge_id    INT REFERENCES knowledge_entries(id) ON DELETE SET NULL,
    source_file     VARCHAR(200),
    imported_by     INT REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
-- knowledge_entries 增加毛利影响标注（FW-05 赢单话术质量评估用）
ALTER TABLE knowledge_entries ADD COLUMN IF NOT EXISTS gross_margin_impact VARCHAR(20);

-- [2026-06-18] FW-06 维修飞轮·故障案例库
-- knowledge_entries 增加安全关键标记（新能源高压/制动系统触发技术总监二次签核）
ALTER TABLE knowledge_entries ADD COLUMN IF NOT EXISTS safety_critical BOOLEAN DEFAULT FALSE;
-- repair_orders_import 表（🔌 DMS 工单导入，暂不建，待 DMS 对接时再创建）
-- CREATE TABLE IF NOT EXISTS repair_orders_import (...)

-- [2026-06-18] FW-08 跨线协同任务中心
-- 跨业务线整改任务表（客服/销售/维修/知识缺口 均可发起）
CREATE TABLE IF NOT EXISTS cross_line_tasks (
    id              SERIAL PRIMARY KEY,
    source_entry_id INT REFERENCES knowledge_entries(id) ON DELETE SET NULL,
    source_line     VARCHAR(20) NOT NULL,   -- 发起方：service/sales/tech/gap
    target_line     VARCHAR(20) NOT NULL,   -- 接收方：sales/tech/pdi/factory/service
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- pending=待处理 / accepted=已接收 / resolved=已处理 / closed=已关闭
    priority        SMALLINT DEFAULT 2,    -- 1=低 2=中 3=高
    created_by      INT REFERENCES users(id) ON DELETE SET NULL,
    note            TEXT,
    resolve_note    TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    resolved_at     TIMESTAMPTZ
);

-- [2026-06-18] 知识分类图标全部改为A风格Unicode符号（替换emoji）
UPDATE knowledge_categories SET icon = '▤' WHERE name = '公司制度与规范';
UPDATE knowledge_categories SET icon = '⊟' WHERE name = '企业文化与价值观';
UPDATE knowledge_categories SET icon = '△' WHERE name = '安全生产与消防';
UPDATE knowledge_categories SET icon = '⇄' WHERE name = '通用商务礼仪';
UPDATE knowledge_categories SET icon = '⌘' WHERE name = 'IT系统操作指南';
UPDATE knowledge_categories SET icon = '☐' WHERE name = '法律法规合规';
UPDATE knowledge_categories SET icon = '◈' WHERE name = '产品知识库';
UPDATE knowledge_categories SET icon = '◱' WHERE name = '竞品对比分析';
UPDATE knowledge_categories SET icon = '◎' WHERE name = '销售话术技巧';
UPDATE knowledge_categories SET icon = '◇' WHERE name = '价格谈判策略';
UPDATE knowledge_categories SET icon = '✎' WHERE name = '客户跟进管理';
UPDATE knowledge_categories SET icon = '⊕' WHERE name = '金融按揭方案';
UPDATE knowledge_categories SET icon = '↺' WHERE name = '二手车评估';
UPDATE knowledge_categories SET icon = '▷' WHERE name = '试驾流程标准';
UPDATE knowledge_categories SET icon = '⚙' WHERE name = '发动机系统维修';
UPDATE knowledge_categories SET icon = '⊗' WHERE name = '变速箱维修技术';
UPDATE knowledge_categories SET icon = '▲' WHERE name = '电气电子系统';
UPDATE knowledge_categories SET icon = '✦' WHERE name = '空调暖风系统';
UPDATE knowledge_categories SET icon = '◉' WHERE name = '底盘悬挂转向';
UPDATE knowledge_categories SET icon = '⊞' WHERE name = '新能源车维修';
UPDATE knowledge_categories SET icon = '◫' WHERE name = '钣金喷漆工艺';
UPDATE knowledge_categories SET icon = '⊘' WHERE name = '故障诊断方法';
UPDATE knowledge_categories SET icon = '◷' WHERE name = '预约接待流程';
UPDATE knowledge_categories SET icon = '⌖' WHERE name = '保养服务标准';
UPDATE knowledge_categories SET icon = '◁' WHERE name = '客户投诉处理';
UPDATE knowledge_categories SET icon = '≡' WHERE name = '保险理赔服务';
UPDATE knowledge_categories SET icon = '↻' WHERE name = '续保业务技巧';
UPDATE knowledge_categories SET icon = '☏' WHERE name = '客户回访规范';
UPDATE knowledge_categories SET icon = '◆' WHERE name = '会员服务管理';
UPDATE knowledge_categories SET icon = '□' WHERE name = '配件仓储管理';
