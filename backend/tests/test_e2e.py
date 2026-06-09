"""Day 22 全量回归测试脚本"""
import asyncio
import sys
import io
import time
import struct
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from httpx import AsyncClient

async def test():
    results = []
    base = 'http://localhost:8000'

    async with AsyncClient(base_url=base, timeout=15) as c:
        # ====== A. Login ======
        r = await c.post('/api/auth/login', json={'username':'boss','password':'hequn123'})
        bh = {'Authorization': f'Bearer {r.json()["data"]["token"]}'}
        assert r.json()['data']['role'] == 'boss'
        results.append(('A1', 'boss登录', True))

        r = await c.post('/api/auth/login', json={'username':'admin','password':'hequn123'})
        ah = {'Authorization': f'Bearer {r.json()["data"]["token"]}'}
        results.append(('A2', 'admin登录', True))

        r = await c.post('/api/auth/login', json={'username':'sales01','password':'hequn123'})
        sh = {'Authorization': f'Bearer {r.json()["data"]["token"]}'}
        results.append(('A3', 'staff销售登录', True))

        r = await c.post('/api/auth/login', json={'username':'tech01','password':'hequn123'})
        th = {'Authorization': f'Bearer {r.json()["data"]["token"]}'}
        results.append(('A4', 'staff技术登录', True))

        r = await c.post('/api/auth/login', json={'username':'service01','password':'hequn123'})
        svh = {'Authorization': f'Bearer {r.json()["data"]["token"]}'}
        results.append(('A5', 'staff客服登录', True))

        # ====== A: 权限 ======
        r = await c.get('/api/dashboard/global', headers=bh)
        results.append(('A6', 'boss->BI大屏', r.status_code == 200))
        r = await c.get('/api/dashboard/global', headers=ah)
        results.append(('A7', 'admin->BI大屏(403)', r.status_code == 403))
        r = await c.get('/api/users/list', headers=sh)
        results.append(('A8', 'staff->用户管理(403)', r.status_code == 403))

        # ====== B: Knowledge ======
        r = await c.get('/api/knowledge', headers=ah)
        results.append(('B1', f'知识列表({r.json()["data"]["total"]}条)', r.json()["data"]["total"] >= 200))

        r = await c.get('/api/knowledge', headers=sh)
        items = r.json()['data']['items']
        all_ok = items and all(i['knowledge_base'] in ('public','sales') for i in items)
        results.append(('B2', '岗位隔离(sales)', all_ok))

        r = await c.get('/api/knowledge?keyword=安全', headers=ah)
        results.append(('B3', '关键词搜索', r.json()['data']['total'] >= 1))

        r = await c.get('/api/categories')
        results.append(('B4', '分类列表', len(r.json()['data']) == 30))

        r = await c.get('/api/knowledge/1', headers=ah)
        d = r.json()['data']
        results.append(('B5', '知识详情+相关推荐', d['title'] and d['related'] is not None))

        r = await c.get('/api/knowledge/hot', headers=ah)
        results.append(('B6', '热门TOP10', len(r.json()['data']) > 0))

        # ====== C: CRUD ======
        r = await c.post('/api/knowledge', headers=ah, json={'title':'E2E测试','content':'test','category_id':7,'knowledge_base':'sales'})
        nid = r.json()['data']['id']
        results.append(('C1', '新增知识', True))

        r = await c.put(f'/api/knowledge/{nid}', headers=ah, json={'title':'已修改'})
        results.append(('C2', '编辑知识', r.json()['code'] == 0))

        r = await c.delete(f'/api/knowledge/{nid}', headers=ah)
        results.append(('C3', '软删除', r.json()['code'] == 0))

        # ====== D: Review ======
        r = await c.post('/api/knowledge/submit-experience', headers=sh, json={'title':'E2E经验','content':'test','category_id':7,'knowledge_base':'sales'})
        eid = r.json()['data']['id']
        results.append(('D1', '提交经验', True))

        r = await c.post(f'/api/review/{eid}/approve', headers=ah)
        results.append(('D2', '审核通过+10', r.json()['code'] == 0))

        r = await c.post(f'/api/knowledge/{eid}/useful', headers=sh)
        results.append(('D3', '标记有用+2', r.json()['code'] == 0))

        r = await c.get('/api/review/history', headers=ah)
        results.append(('D4', '审核历史', r.json()['data']['total'] >= 1))

        # ====== E: Dashboard ======
        r = await c.get('/api/dashboard/personal', headers=sh)
        results.append(('E1', '个人看板', 'radar_data' in r.json()['data']))

        r = await c.get('/api/dashboard/team', headers=ah)
        results.append(('F1', '团队看板', 'dept_name' in r.json()['data']))

        r = await c.get('/api/dashboard/global', headers=bh)
        results.append(('G1', 'BI大屏', r.json()['data']['knowledge_total'] >= 200))

        # ====== H: Questions ======
        r = await c.get('/api/questions/today', headers=sh)
        results.append(('H1', '每日一题', r.json()['data'] is not None))

        r = await c.get('/api/learning/history', headers=sh)
        results.append(('H2', '学习历史', r.json()['code'] == 0))

        # ====== I: Profile ======
        r = await c.get('/api/users/ranking', headers=sh)
        results.append(('I1', '积分排行', r.json()['code'] == 0))

        r = await c.get('/api/users/list', headers=ah)
        results.append(('I2', '用户列表', r.json()['data']['total'] >= 5))

        # ====== J: LLM ======
        r = await c.get('/api/llm/providers', headers=ah)
        results.append(('J1', 'LLM列表', len(r.json()['data']) >= 8))

        r = await c.put('/api/llm/providers/1/set-default', headers=ah)
        results.append(('J2', '切换默认LLM', r.json()['code'] == 0))

        # ====== K: Chat ======
        r = await c.post('/api/chat/ask?question=测试&mode=knowledge_qa', headers=sh)
        results.append(('K1', '阿能对话', r.status_code == 200))

        # ====== L: Settings ======
        r = await c.get('/api/settings', headers=ah)
        results.append(('L1', '系统设置', len(r.json()['data']) == 10))

        # ====== M: Audit ======
        r = await c.get('/api/logs/audit', headers=ah)
        results.append(('M1', '审计日志', r.json()['code'] == 0))

        # ====== N: Skin ======
        r = await c.put('/api/auth/skin', headers=sh, json={'skin_id': 3})
        results.append(('N1', '皮肤切换', r.json()['code'] == 0))

        # ====== O: Performance ======
        t1 = time.time()
        await c.get('/api/knowledge?page_size=10', headers=ah)
        ms1 = int((time.time()-t1)*1000)
        results.append(('O1', f'知识列表 {ms1}ms (<500ms)', ms1 < 500))

        t1 = time.time()
        await c.get('/api/health')
        ms2 = int((time.time()-t1)*1000)
        results.append(('O2', f'健康检查 {ms2}ms', ms2 < 100))

        t1 = time.time()
        await c.get('/api/categories')
        ms3 = int((time.time()-t1)*1000)
        results.append(('O3', f'分类列表 {ms3}ms (<50ms)', ms3 < 50))

        # ====== P: Voice ======
        r = await c.post('/api/voice/upload', files={'file': ('test.wav', b'\x00'*100, 'audio/wav')}, headers=sh)
        results.append(('P1', '语音上传', r.json()['code'] == 0))

        # ====== Q: Flywheel ======
        r = await c.get('/api/dashboard/flywheel', headers=ah)
        results.append(('Q1', '飞轮指标', r.json()['code'] == 0))

        # ====== R: Home ======
        r = await c.get('/api/dashboard/home', headers=sh)
        results.append(('R1', '职员首页', r.json()['data']['role_view'] == 'staff'))

        r = await c.get('/api/dashboard/home', headers=ah)
        results.append(('R2', '管理员首页', r.json()['data']['role_view'] == 'admin'))

        r = await c.get('/api/dashboard/home', headers=bh)
        results.append(('R3', '老板首页', r.json()['data']['role_view'] == 'boss'))

        # ====== Summary ======
        passed = sum(1 for _,_,ok in results if ok)
        total = len(results)
        print(f'\n{"="*60}')
        print(f'Day 22 E2E: {passed}/{total} PASSED')
        print(f'{"="*60}')
        for rid, desc, ok in results:
            print(f'  [{"PASS" if ok else "FAIL"}] {rid}: {desc}')
        print(f'\n{"ALL PASSED!" if passed==total else f"{total-passed} FAILED!"} ')
        return passed, total

if __name__ == '__main__':
    p, t = asyncio.run(test())
    sys.exit(0 if p == t else 1)
