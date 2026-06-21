# CLAUDE.md —— 协作铁律（每轮加载）

## 🎯 项目身份

<!-- FILL IN: 一句话描述你的项目，例如「这是个 X 的服务，做 Y」。
     若同时是 DDD+TDD 范式的孵化场，也说一下；否则删掉这一句。 -->

**本项目强制走 DDD + TDD**，由 `t3d` plugin 提供 harness 支持
（hook / rules / skills / 模板）。

## 📂 任务三类分流（接到任务先决定走哪条）

| 信号词 | 类型 | 去哪 | 是否走 TDD/DDD |
|--------|------|------|---------------|
| spike / 原型 / 调研 / 试一下 / 玩玩 | Playground | `playground/<topic>/` | ❌ 自由 |
| 实现 / 加功能 / 上线 / 新需求 | 正式功能 | `contexts/<ctx>/` | ✅ 完整 |
| Bug / 不对 / 报错 / 复现 | Bug 修复 | 跟随原模块 | ✅ 必须先写复现红灯 |
| 不明确 | — | 反问用户 | — |

文档变更 / 重命名 / 改注释 → 原地改，保持既有测试绿。

## 🏛️ 仓库布局（推荐）

```
/
├── CLAUDE.md                  # 本文件
├── CONTEXT-MAP.md             # 限界上下文清单 + 关系图
├── README.md                  # 项目介绍
├── pyproject.toml             # Python 项目配置（推荐 uv）
├── apps/                      # 组合根
│   └── <app-name>/            # 例：api / cli / worker
├── contexts/                  # 限界上下文目录
│   ├── _shared_kernel/        # 极少数全局值对象
│   ├── _TEMPLATE/             # 新 context 的复制模板（来自 t3d plugin）
│   └── <your-contexts>/       # 由 /t3d-new-context 创建
├── playground/                # 自由探索区（不走 DDD/TDD）
└── docs/
    ├── adr/                   # 系统级架构决策记录
    └── TECH_DEBT.md           # 主动偏离规范的债务清单
```

每个 `contexts/<ctx>/` 内部是完整的 **DDD 四层 + tests + 文档**。
详见 `contexts/_TEMPLATE/README.md`。

## 🚫 跨上下文调用规则（多 context 共存最重要的事）

| 调用路径 | 允许？ |
|---------|------|
| `contexts.ctxA.domain.*` → `contexts.ctxB.*` | ❌ 永远禁止 |
| `contexts.ctxA.*` → `contexts.ctxB.application.api` | ✅ 唯一同步调用通道 |
| `contexts.ctxA.*` → `contexts._shared_kernel.*` | ✅ 限纯值对象 |
| 异步：`ctxA` 发事件 → `ctxB` 在 `ui/event_consumer/` 订阅 | ✅ 弱耦合首选 |

违反前两条会被 plugin 的 PreToolUse hook 在 Edit 阶段硬拦截。

## 🔴🟢🔵 正式功能必走的红绿循环

```
1. 澄清 → 哪个 context？聚合根是谁？不变量有哪些？术语在 CONTEXT.md 吗？
2. 在 contexts/<ctx>/INVARIANTS.md 加一行 INV-NNN
3. 写红灯测试断言 INV-NNN → 跑 → RED ✗
4. 写最少 domain 代码 → 跑 → GREEN ✓
5. 重构 → 持续 GREEN ✓
6. 下一条不变量，回 2
```

修 Bug 也走这个循环：**先写复现失败的红灯用例，再修代码**。

## 📖 CONTEXT.md / 统一语言使用规则

业务术语写代码前：
1. 先去对应 `contexts/<ctx>/CONTEXT.md` 查
2. 没有就先在 `CONTEXT.md` 加条目（中文 + 英文 + 1-2 句精确定义；同义词放 `_Avoid_`），再写代码
3. 代码里的类名 / 方法名 / DB 字段 / 日志输出**必须**与 CONTEXT.md 一致
4. 同一术语在不同 context 语义不同 → 各自 CONTEXT.md 各自定义，**不要**抽到 _shared_kernel

`_shared_kernel/` 新增任何值对象**必须先写 ADR**。

## 🏛️ ADR 何时写（Matt Pocock 三条件）

只在以下三条**全部成立**时才写 ADR：

1. **难撤回**（改回去成本高）
2. **无 context 会让人困惑**（未来读代码会问"为啥这么做"）
3. **是真实权衡的结果**（确实有备选方案被否）

三缺一就不写。文件命名：
- 系统级：`docs/adr/NNNN-short-kebab.md`
- Context 内部：`contexts/<ctx>/docs/adr/NNNN-*.md`

## 🪝 自动护栏（由 t3d plugin 提供）

- **UserPromptSubmit hook** —— 按信号词自动归类 prompt（spike / feature / bug），注入对应工作流提醒
- **PreToolUse hook (Edit/Write)** —— 两道硬拦截：
  1. 写 `contexts/**/domain/**` 时 import 禁用包（fastapi / sqlalchemy / requests / httpx / aiohttp / django / flask / peewee / pymongo / asyncpg / psycopg / redis / celery）→ DENY
  2. 写任意 `contexts/A/` 文件时 import `contexts.B.*` 但**非** `contexts.B.application.api` → DENY
- **PostToolUse hooks** —— Domain 编辑后标记 dirty + 测试运行后记录绿/红
- **Stop hook** —— 若 Domain dirty + 测试红 → block Stop，要求先跑绿
- **Skills**：
  - `/t3d-grill-me` —— 设计前自我拷打
  - `/t3d-new-context <name>` —— 复制 `_TEMPLATE` 创建新 context
  - `/t3d-init` —— 重新刷出/更新 harness 模板

## 🤝 我（Claude）的协作约定

主动做：
- 接需求先澄清 上下文 / 聚合根 / 不变量 / 术语
- 修 Bug 默认先写红灯
- Domain 编辑前自检禁用依赖

拒绝并提示：
- "在 application / ui 写业务规则" → 违反 Domain 边界
- "跳过测试直接改 Domain" → 先补红灯
- "跨 context 直接 import 内部" → 走 `application.api` 或事件

例外通道（你明说才生效）：
- "走 playground" / "spike 一下" → 跳过 TDD/DDD
- "技术债先记一下" → 执行 + 写入 `docs/TECH_DEBT.md`

---

> **本文件由 `t3d` plugin 提供。更新 plugin 后如需同步本模板**：
> 在项目根 `/t3d-init`，确认覆盖 CLAUDE.md。
