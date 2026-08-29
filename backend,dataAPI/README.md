后端接口在分支 mike，已经推上去了。

启动:
  cd "backend,dataAPI"
  python3 -m venv .venv
  .venv/bin/pip install -r requirements.txt
  .venv/bin/uvicorn main:app --port 8000

完整接口文档:
  http://localhost:8000/docs        (自动生成，能直接点着试)
  backend,dataAPI/docs/API.md       (字段说明，已冻结，别改字段名)

主要端点:
  POST /api/survey              问卷 -> 分配比例 + 人格
  GET  /api/plan                预算 vs 实际 + adherence 分数
  GET  /api/missions            任务列表
  POST /api/missions/{id}/claim 领奖励 -> XP/金币
  GET  /api/tower               塔的状态(层数/健康度/天气)
  GET  /api/progression         等级、金币、皮肤
  GET  /api/shop                商店

Flutter 那边不用自己写 http:
  flutter pub get
  final api = ApiClient();
  final data = await api.home();   // 一次拿到 plan + tower + missions + progression
  客户端在 lib/data/api_client.dart，所有请求都走它

数据源三选一，随时切换，不用改代码:
  mock(假数据，最丰富，演示用) / csv(我的真实银行导出) / basiq(真实开放银行)
  现在不连银行也能跑，你们直接开发就行