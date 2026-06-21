---
paths:
  - "contexts/**/application/**"
  - "contexts/**/infrastructure/**"
  - "contexts/**/ui/**"
---

# Application / Infrastructure / UI 层规则

你正在编辑非 Domain 层。这里**允许**外部依赖，但每层职责严格分开。

## 🔥 跨 Context 调用规则（PreToolUse hook 会拦截违规）

| 调用路径 | 允许？ |
|---------|------|
| `from contexts.A.domain import ...` 在 `contexts.B/` 任意文件 | ❌ 永远禁止 |
| `from contexts.A.application.api import ...` 在 `contexts.B/` | ✅ 唯一同步通道 |
| `from contexts._shared_kernel import ...` | ✅ 限纯值对象 |
| 异步：本 context 在 `ui/event_consumer/` 订阅 `contexts.A` 发的事件 | ✅ 弱耦合首选 |

写代码时如果要用其他 context 的东西，**只能 import `contexts.<other>.application.api`**，import 任何别的路径会被 hook deny。

## 📂 各层职责

### `application/` —— 用例编排，不写业务规则
```
application/
├── command/       # 写侧 Command DTO（例：IssueInvoiceCommand）
├── query/         # 读侧 Query DTO
├── use_case/      # 一个用例一个文件，纯编排（调 domain + repository + 发事件）
└── api.py         # ★ 对外公开门面，其他 context 只能看到这个
```

**反模式：** 在 `use_case/` 里写 if-else 业务判断 → 应该把判断挪到 domain。

### `infrastructure/` —— 实现 Domain 定义的 Port
```
infrastructure/
├── repository/    # SQLAlchemy / Mongo / 内存 实现 domain.port.*Repository
├── persistence/   # ORM models, Alembic migrations
├── event_bus/     # 入站 / 出站事件适配器
└── acl/           # 防腐层：外部系统（LiteLLM 等）的翻译器
```

**反模式：** 在 `repository/` 里调用其他 repository → 跨聚合，应该 use case 编排。

### `ui/` —— 协议翻译，不写业务逻辑
```
ui/
├── http/              # FastAPI router
├── cli/               # Typer command
└── event_consumer/    # 订阅其他 context 发的事件
```

`ui/http/` 的 handler 只做三件事：解析请求 → 调 `application/use_case/` → 包装响应。**绝不内联业务规则。**

## 🎯 写代码前自检清单

1. 这段逻辑是不是**业务规则**？是的话应该在 domain，不该在这里
2. 这段 IO 是不是**领域行为**？是的话先在 domain 加 Port 接口，infra 这里只是实现
3. 这个外部依赖如果有一天换掉（如 SQLAlchemy → asyncpg），domain 会被波及吗？应该不会
