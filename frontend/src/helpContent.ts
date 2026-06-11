// 全部页面帮助文案 —— 附录C
// 每个页面组件引用：helpContent['路由名']

export interface HelpSection {
  title: string
  what?: string
  how?: string[]
  related?: { name: string; link: string; desc?: string }[]
  logic?: string
  note?: string
}

export const helpContent: Record<string, HelpSection> = {

  Login: {
    title: '登录页',
    what: '合群汽车集团AI+业务能力知识库系统的统一登录入口。所有员工使用公司分配的账号密码登录本系统。',
    how: [
      '输入您的用户名（由管理员分配）',
      '输入您的登录密码（首次登录后建议修改密码）',
      '点击"登录"按钮进入系统',
      '如果忘记密码，请联系系统管理员重置',
    ],
    related: [
      { name: '联系管理员', link: '' },
      { name: '修改密码', link: '/profile' },
    ],
    logic: '系统根据您的账号角色<b>自动判断权限</b>：<br>• <b>职员(staff)</b> → 查看本岗位知识、提交经验、个人学习看板<br>• <b>管理员(admin)</b> → 知识库管理、内容审核、用户管理、系统设置<br>• <b>老板(boss)</b> → 全局数据看板、BI大屏、战略配置<br><br>系统支持<b>三级岗位隔离</b>：销售岗、技术岗、客服岗各自只能看到所属知识库的内容。',
    note: '连续登录失败5次，账号将被临时锁定15分钟。',
  },

  Home: {
    title: '首页',
    what: '登录后的默认页面。根据您的角色（职员/管理员/老板）展示不同的内容卡片和数据摘要。是您每天工作的起点。',
    how: [
      '职员：查看今日知识推送、每日一题入口、个人学习进度、积分排名',
      '管理员：查看待审核数量、本周经验沉淀统计、团队学习达标率、知识库健康状态',
      '老板：查看知识总量、月新增、员工总数、学习达标率四大核心指标',
      '点击任意卡片即可跳转到对应的功能页面',
    ],
    related: [
      { name: '知识库浏览', link: '/knowledge' },
      { name: '数字老师阿能', link: '' },
      { name: '个人看板（职员）', link: '/personal-dashboard' },
      { name: '审核中心（管理员）', link: '/review' },
      { name: 'BI大屏（老板）', link: '/bi-board' },
    ],
    logic: '首页数据通过 <b>GET /api/dashboard/home</b> 接口获取，后端根据当前登录用户的角色返回不同数据。首页数据缓存5分钟，减少数据库查询压力。右下角的"召唤阿能"按钮始终可见，无论您在哪个页面都可以随时唤起对话。',
    note: '首页每日0点自动刷新统计数据。如有未读的审核任务或预警信息，会在对应卡片上显示红色角标。',
  },

  KnowledgeBase: {
    title: '知识库浏览',
    what: '浏览和搜索合群汽车集团的全部知识内容。知识按四大知识库分类存储：公共通用知识、销售专属知识、技术服务知识、售后客服知识。',
    how: [
      '在顶部搜索框输入关键词搜索知识（支持车型、故障描述、话术关键词等）',
      '左侧分类树可按知识库和子分类筛选浏览',
      '点击知识卡片进入详情页查看完整内容',
      '手机端点击顶部"筛选"按钮可展开分类抽屉',
      '搜索结果按匹配度和浏览量排序',
    ],
    related: [
      { name: '知识详情', link: '/knowledge/:id' },
      { name: '知识管理（管理员）', link: '/knowledge-manage' },
      { name: '提交经验', link: '/submit-experience' },
    ],
    logic: '<b>岗位知识隔离规则</b>：<br>• 销售职员 → 只能看到"公共通用"+"销售专属"知识库<br>• 技术职员 → 只能看到"公共通用"+"技术服务"知识库<br>• 客服职员 → 只能看到"公共通用"+"售后客服"知识库<br>• 管理员/老板 → 可以看到全部四个知识库<br><br><b>全文搜索原理</b>：系统使用PostgreSQL的全文搜索功能，对知识标题和正文做分词索引。搜索关键词支持空格分隔的多词组合搜索。',
    note: '涉密经验（如技师独家维修技术）默认不对非技术岗位开放，如需跨岗共享，需管理员在知识管理页面标记"可跨岗查看"。',
  },

  KnowledgeDetail: {
    title: '知识详情',
    what: '查看某条知识条目的完整内容，包括正文、视频、音频、来源信息、标签和相关推荐。',
    how: [
      '阅读知识正文内容',
      '视频类知识可在线播放，自动从关键时间点开始',
      '音频类知识可在线收听',
      '点击"收藏"可将知识加入个人收藏夹',
      '点击"有用"可为知识投票（影响知识排名和淘汰判断）',
      '浏览超过30秒系统自动记录为"已学习"',
    ],
    related: [
      { name: '知识库浏览', link: '/knowledge' },
      { name: '个人学习中心', link: '/learning' },
      { name: '阿能对话', link: '' },
    ],
    logic: '打开详情页自动 <b>+1浏览次数</b>。浏览≥30秒自动写入 <b>learning_records</b> 表(learn_type=\'view\')，计入个人学习统计。点击"有用"按钮写入 useful_count 字段，并给提交人+2积分（如果此知识是经验类知识）。底部"相关推荐"按同类目的热门知识TOP5展示。',
    note: '如果该知识有对应的视频/音频原始文件，且在阿能对话中通过引用跳转过来，页面会自动定位到对应的时间戳位置。',
  },

  KnowledgeManage: {
    title: '知识管理',
    what: '管理员对知识库条目的全生命周期管理。包括新增、编辑、删除（归档）、状态变更、批量导入知识。',
    how: [
      '使用搜索和筛选栏快速定位目标知识条目',
      '点击"新增知识"弹出表单，填写标题、内容、选择分类和知识库',
      '点击某条知识的"编辑"修改内容',
      '对过期或低质量知识，点击"归档"将其移出知识库（软删除）',
      '状态操作：可将知识标记为已通过(approved)/已驳回(rejected)/已归档(archived)',
      '批量导入：上传PDF/Word/Excel/视频文件，系统自动解析入库',
    ],
    related: [
      { name: '审核中心', link: '/review' },
      { name: '分类管理（在系统设置中）', link: '/system-settings' },
      { name: 'LLM模型配置', link: '/llm-settings' },
    ],
    logic: '<b>知识状态流转</b>：<br>草稿(draft) → 待审核(pending) → 已通过(approved) / 已驳回(rejected)<br>已通过的知识可随时归档(archived)。<br><br>归档不是物理删除，已归档的知识仅管理员可见，前端搜索不会返回。如需彻底删除，需要通过数据库直接操作。<br><br><b>批量导入原理</b>：PDF/DOCX → 提取文本 → 分块(500字/块) → 写入knowledge_entries。Excel → 每行模板化为自然语言段落。视频 → 上传后后台异步转写分段。',
    note: '编辑已通过的知识会自动创建新版本(version+1)，旧版本保留在数据库中。删除操作为软删除（status改为archived），不会真正删除数据。',
  },

  ReviewCenter: {
    title: '审核中心',
    what: '管理员审核员工提交的经验内容。经验只有通过审核才能正式进入企业知识库，被全员使用。',
    how: [
      '左侧待审核列表显示所有status=pending的知识条目',
      '点击某条，右侧展示该条目的完整内容',
      '审核通过：点击"通过"按钮→知识status变为approved→提交人自动获得+10积分',
      '驳回：点击"驳回"→填写驳回原因（必填）→知识status变为rejected',
      '审核历史可查看过往所有审核记录',
    ],
    related: [
      { name: '知识管理', link: '/knowledge-manage' },
      { name: '经验提交（职员端）', link: '/submit-experience' },
      { name: '积分排行榜', link: '/profile' },
    ],
    logic: '<b>审核通过的连锁动作</b>：<br>1. knowledge_entries.status → "approved"<br>2. experience_points 写入一条 action_type="approved", points=+10 的记录<br>3. 知识在前端知识库对相应岗位可见<br><br><b>驳回的连锁动作</b>：<br>1. status → "rejected"<br>2. audit_comment 记录驳回原因<br>3. 提交人在"我的提交"中可以看到驳回原因，可修改后重新提交',
    note: '审核操作不可撤销，请在确认内容质量后再点击通过。建议审核标准：内容真实、对业务有实际指导价值、不与已有知识重复。',
  },

  ExperienceSubmit: {
    title: '经验提交',
    what: '一线员工将自己的实战经验、技巧、话术沉淀为企业知识的入口。销售、技师、客服岗位均可在此提交。',
    how: [
      '填写经验标题（简洁概括，如"星瑞客户谈价三步法"）',
      '在内容区详细描述经验（支持Markdown格式）',
      '选择对应的知识分类',
      '添加标签（如"星瑞/谈判/价格"便于搜索）',
      '点击"语音录入"可通过录音+自动转写快速输入经验',
      '点击"提交审核"后经验进入管理员审核队列',
    ],
    related: [
      { name: '审核中心', link: '/review' },
      { name: '我的提交记录', link: '/profile' },
      { name: '积分排行榜', link: '/profile' },
    ],
    logic: '<b>提交经验的连锁动作</b>：<br>1. knowledge_entries 新建(status="pending", source_type="experience")<br>2. experience_points 写入 action_type="submit", points=+1<br>3. 审核通过后 → +10积分<br>4. 被同事点击"有用" → +2积分/次<br>5. 进入月度TOP5 → +50积分',
    note: '经验提交后不可直接修改，需等待管理员审核。如被驳回，可在"我的提交"中查看驳回原因，修改后重新提交。',
  },

  PersonalDashboard: {
    title: '个人看板',
    what: '查看您个人的知识掌握情况。通过雷达图直观展示您在各知识分类上的掌握程度，以及和岗位期望水平的差距。',
    how: [
      '雷达图：蓝色实线=您的掌握度，橙色虚线=岗位期望水平',
      '薄弱领域：自动标红掌握度最低的3个分类，点击可直接跳转学习',
      '学习进度：显示本周已学条目数、总学习时长',
      '积分和排名：显示当前积分和在全公司/本部门的排名',
      '最近学习记录：最近10条学习行为',
    ],
    related: [
      { name: '学习中心', link: '/learning' },
      { name: '每日一题', link: '/question' },
      { name: '知识库浏览', link: '/knowledge' },
    ],
    logic: '<b>掌握度计算公式</b>：<br>个人某分类掌握度 = 该分类下您已学习的条目数 / 该分类下您岗位应学的条目总数 × 100%<br><br>总掌握度 = 所有分类掌握度的加权平均。<br><br>"已学习"定义为：在learning_records表中有记录(learn_type="view"或"complete"或"test")。<br>"岗位应学条目"定义为：该知识库+该岗位分类下所有 status="approved" 的条目。<br><br>薄弱领域 = 掌握度最低的3个分类，按从低到高排列。',
    note: '雷达图的期望值线是根据初级岗位标准设定的默认值(80%)，管理员可在系统设置中调整。排名数据每30分钟刷新一次。',
  },

  TeamDashboard: {
    title: '团队看板',
    what: '查看本部门全员的整体知识掌握情况。可了解团队整体能力水平、各成员的知识掌握差异、团队薄弱领域。',
    how: [
      '顶部：团队总掌握度(环形图) + 部门人数 + 本月新增学习条目',
      '中部：团队雷达图（各分类平均掌握度）vs 岗位期望',
      '下部：团队成员排行榜（按掌握度排序）+ 薄弱领域提示',
      '可切换查看不同部门的数据（如有权限）',
    ],
    related: [
      { name: 'BI大屏（老板看全局）', link: '/bi-board' },
      { name: '个人看板', link: '/personal-dashboard' },
      { name: '用户管理', link: '/user-manage' },
    ],
    logic: '<b>部门掌握度</b> = 部门内所有职员个人掌握度的算术平均。<br><b>团队薄弱领域</b> = 部门平均值最低的3个分类。<br>数据统计口径：仅统计status="approved"的知识条目，不含已归档。<br>管理员默认看到自己所属部门的数据，可切换查看其他部门。',
    note: '团队看板数据每小时刷新一次。如发现某成员掌握度异常低，建议安排专项培训。',
  },

  BIBoard: {
    title: 'BI大屏',
    what: '集团级全景数据大屏，展示合群汽车集团知识库系统的整体运转状态和全员能力分布。',
    how: [
      '全屏大屏模式（建议在大屏幕显示器或投影上查看）',
      '按住F11或点击全屏按钮进入全屏模式',
      '所有图表自动刷新（每5分钟）',
      '鼠标悬停图表可查看详细数据',
      '支持按季度、按部门筛选数据',
    ],
    related: [
      { name: '团队看板', link: '/team-dashboard' },
      { name: '首页仪表盘', link: '/home' },
      { name: '用户管理', link: '/user-manage' },
    ],
    logic: '图表布局（4×2网格）：左上=知识库总量+月度增长趋势 / 中上=四大知识库占比饼图 / 右上=各门店×知识分类能力热力图 / 左下=经验贡献TOP10排行榜 / 中下=三大飞轮运转指标（新沉淀/迭代/复用率）/ 右下=预警区（长期无沉淀部门+高频未命中问题TOP5）',
    note: '大屏建议使用1920×1080及以上分辨率。首次加载数据可能需要2-3秒。按ESC退出全屏。',
  },

  LearningCenter: {
    title: '学习中心',
    what: '您的个人学习空间。包含岗位必修课进度、学习日历、错题本、学习时长统计。',
    how: [
      '必修课列表：该岗位分类下所有知识条目，已学标绿，未学标灰',
      '点击任一课程进入知识详情开始学习',
      '学习日历：每个日期方格颜色深浅表示当天学习条目数',
      '错题本：所有答错的每日一题，可重新作答',
      '学习时长：统计总学习时长和日均学习时长',
    ],
    related: [
      { name: '每日一题', link: '/question' },
      { name: '个人看板', link: '/personal-dashboard' },
      { name: '知识库浏览', link: '/knowledge' },
    ],
    logic: '"已学"判断标准：learning_records 中存在该知识条目+该用户的记录。<br>学习日历的颜色深浅 = 当天学习的条目数 / 单日最大学习条目数。<br>错题本数据 = daily_questions 中该用户回答过且score=0的记录。<br>学习时长 = sum(learning_records.duration_sec)。',
    note: '建议每天至少学习3条知识，每周20条以上。学习日历可帮助你发现学习的规律和盲区。',
  },

  QuestionAnswer: {
    title: '每次一题',
    what: '每次进入页面，系统根据您的岗位自动分配一道测试题。答对获得积分，答错进入错题本可复习重答。',
    how: [
      '页面根据您的岗位自动推送一道题',
      '选择题点击选项，判断题选对/错，填空题输入文字',
      '点击"提交答案"',
      '立即显示结果：正确/错误 + 详细解析',
      '答对自动+1积分，答错题目自动加入错题本',
      '点击"下一题"继续挑战下一道',
    ],
    related: [
      { name: '学习中心', link: '/learning' },
      { name: '考试管理（管理员）', link: '/exam-manage' },
      { name: '知识库浏览', link: '/knowledge' },
    ],
    logic: '<b>题目推送规则</b>：<br>1. 按用户岗位匹配 target_position 相同的题目<br>2. 排除该用户最近14天已经推送的题目<br>3. 按 difficulty_level 递增排序（先推简单的）<br>4. 如果岗位题目已轮完，推送公共知识库题目<br>5. 全部轮完则重置周期重新开始<br><br>答对：写 learning_records(learn_type="test", score=100)，写 experience_points(+1)<br>答错：写 learning_records(learn_type="test", score=0)，不加积分，题目入错题本',
    note: '每次进入页面都会分配一道新题。14天内已推送过的题目不会重复。',
  },

  ExamManage: {
    title: '考试管理',
    what: '管理每次一题的题库。可以新增、编辑、删除题目，支持批量导入和AI自动出题。',
    how: [
      '题目列表可按岗位、难度、题型筛选',
      '点击"新增题目"弹出表单',
      '选择题：填写题目、选项A/B/C/D、正确答案、解析',
      '判断题：填写题目、正确/错误、解析',
      '填空题：填写题目、标准答案、解析',
      '选择目标岗位（销售/技术/客服/全员）',
      '设置难度等级(1-5)',
      '可选择关联知识点（链接到某条knowledge_entry）',
      '批量导入：下载Excel模板→填充题目→上传导入',
    ],
    related: [
      { name: '每日一题（职员端）', link: '/question' },
      { name: '学习中心', link: '/learning' },
    ],
    logic: '题目类型支持4种：single_choice(单选)、multi_choice(多选)、true_false(判断)、fill_blank(填空)。关联知识点的作用：职员答错时，系统推荐先学习关联的知识条目。',
    note: '建议每周新增10-20道题，保持题库新鲜度。批量导入模板中的"关联知识点ID"可选填。',
  },

  Profile: {
    title: '个人中心',
    what: '您的个人信息、积分情况、提交记录、收藏列表、皮肤设置的总览页面。',
    how: [
      '顶部：头像 + 姓名 + 岗位 + 部门 + 门店',
      '积分区：总积分（大数字）+ 全公司排名 + 本部门排名',
      '提交记录：我提交的所有经验列表，状态标签（待审/通过/驳回），驳回可查看原因',
      '我的收藏：收藏的知识列表',
      '皮肤切换：点击进入皮肤选择面板',
      '底部：退出登录按钮',
    ],
    related: [
      { name: '经验提交', link: '/submit-experience' },
      { name: '知识库浏览', link: '/knowledge' },
      { name: '积分排行榜', link: '/profile' },
    ],
    logic: '积分统计 = SUM(experience_points.points) WHERE user_id = 当前用户。<br>排名 = 按积分降序排列的序号（全公司排名和本部门排名分别计算）。<br>提交记录 = knowledge_entries WHERE source_person = 当前用户姓名 ORDER BY created_at DESC。<br>收藏列表 = 前端localStorage存储的收藏ID数组。',
    note: '退出登录会清除本地token和对话历史。建议每次使用完毕后退出登录，尤其是在公共设备上。',
  },

  UserManage: {
    title: '用户管理',
    what: '管理系统的所有用户账号。包括创建新用户、编辑用户信息、启用/停用账号、分配岗位权限。',
    how: [
      '搜索和筛选：按用户名、角色、岗位、部门、门店筛选',
      '新增用户：填写用户名、真实姓名、密码、角色、岗位、部门、门店、手机号',
      '编辑用户：修改除用户名外的所有信息',
      '停用/启用：状态开关（停用后该用户无法登录，但历史数据保留）',
      '重置密码：为忘记密码的用户重置密码',
    ],
    related: [
      { name: '系统设置', link: '/system-settings' },
      { name: '审核中心', link: '/review' },
      { name: '团队看板', link: '/team-dashboard' },
    ],
    logic: '<b>角色与岗位的权限矩阵</b>：<br>• boss=老板→可查看所有数据，不可操作系统细节<br>• admin=管理员→可管理知识库、用户、审核、系统设置<br>• staff=职员→只能查看本岗位知识和自己的数据<br><br>岗位(position)决定知识库可见范围：sales→销售库 / tech→技术库 / service→客服库。<br>停用用户不会删除其历史贡献数据。',
    note: '新建用户的默认密码为 hequn123。请勿将管理员权限分配给不相关人员。',
  },

  LLMSettings: {
    title: 'LLM模型配置',
    what: '配置系统对接的大语言模型(LLM)。支持通义千问、DeepSeek、智谱GLM、月之暗面Kimi、百川智能、讯飞星火、硅基流动、Dify平台及自定义模型。',
    how: [
      '模型列表：8个预设模型 + 自定义模型',
      '点击编辑图标修改：Base URL / API Key / 模型名称 / Temperature / Max Tokens',
      '填入正确的API Key后，打开"启用"开关',
      '点击"设为默认"选择当前使用的模型（有且仅有一个默认）',
      '点击"测试连接"验证配置是否正确',
      '测试成功显示"连接成功，耗时XXms"；失败显示具体错误信息',
      '支持新增自定义模型（provider_type=custom）',
    ],
    related: [
      { name: '系统设置', link: '/system-settings' },
      { name: '阿能对话', link: '' },
      { name: '对话日志（在系统设置中）', link: '/system-settings' },
    ],
    logic: '<b>调用流程</b>：<br>1. 用户提问 → 2. 后端混合检索Top-5知识 → 3. 查 llm_providers 表 is_active=true AND is_default=true → 4. 发起 /chat/completions 请求（OpenAI兼容格式）→ 5. 流式返回答案',
    note: 'API Key以加密方式存储。Base URL必须以 https:// 开头（生产环境）。切换默认模型会立即影响所有用户的阿能对话体验。',
  },

  SystemSettings: {
    title: '系统设置',
    what: '管理系统的全局配置，包括积分规则、飞轮阈值、自动提醒、审计日志查看、数据导出。',
    how: [
      '积分规则页签：设置各行为对应的积分值',
      '飞轮阈值页签：设置低效经验阈值、知识更新周期',
      '自动提醒页签：开关每周萃取推送、每月迭代提醒',
      '审计日志页签：查看系统操作日志',
      '数据导出页签：导出知识库为CSV文件',
    ],
    related: [
      { name: 'LLM模型配置', link: '/llm-settings' },
      { name: '用户管理', link: '/user-manage' },
      { name: '审核中心', link: '/review' },
    ],
    logic: '积分规则存储：system_config 表，config_key 格式为 "points_{action}"。系统启动时从 system_config 读取并缓存到内存。<br><br>飞轮规则存储：flywheel_view_threshold=5 / flywheel_month_threshold=6 / flywheel_useful_rate=0.7 / flywheel_low_useful_rate=0.3<br><br>审计日志分类：login/logout/create_knowledge/edit_knowledge/delete_knowledge/review_approve/review_reject/create_user/edit_user/toggle_user/update_settings',
    note: '修改飞轮规则会影响后续的知识自动筛选和淘汰建议。修改积分规则不会追溯影响历史积分。',
  },
}

// 帮助标题映射到路由路径的 key
export function getHelpKey(path: string): string {
  const map: Record<string, string> = {
    '/login': 'Login',
    '/': 'Home',
    '/knowledge': 'KnowledgeBase',
    '/knowledge-manage': 'KnowledgeManage',
    '/review': 'ReviewCenter',
    '/submit-experience': 'ExperienceSubmit',
    '/personal-dashboard': 'PersonalDashboard',
    '/team-dashboard': 'TeamDashboard',
    '/bi-board': 'BIBoard',
    '/learning': 'LearningCenter',
    '/question': 'QuestionAnswer',
    '/exam-manage': 'ExamManage',
    '/profile': 'Profile',
    '/user-manage': 'UserManage',
    '/llm-settings': 'LLMSettings',
    '/system-settings': 'SystemSettings',
  }
  // 动态路由匹配
  if (path.startsWith('/knowledge/')) return 'KnowledgeDetail'
  return map[path] || ''
}
