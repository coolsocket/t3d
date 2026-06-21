---
paths:
  - "contexts/**/domain/**"
---

# Domain Layer 规则（强制）

你正在编辑 Domain 层。Domain 层是系统灵魂，**零外部依赖**。

## 🚫 禁止的 import（PreToolUse hook 会硬拦截）

任何 web 框架 / ORM / HTTP 客户端 / 消息队列 / 第三方 SDK：

```
fastapi  flask  django  starlette  aiohttp  httpx  requests  urllib
sqlalchemy  peewee  tortoise  pymongo  redis  asyncpg  psycopg
celery  rq  kombu  boto3  google.cloud  litellm  openai  anthropic
```

只允许：
- Python 标准库（`dataclasses`, `typing`, `abc`, `decimal`, `datetime`, `enum`, `uuid`, `collections.abc`, ...）
- 本 context 的 `domain/` 子模块
- `contexts._shared_kernel.*`（仅纯值对象）

## 📂 子模块约定

```
domain/
├── model/              # 聚合根 + 实体 + 值对象（一个聚合一个文件）
├── service/            # 领域服务（无状态，跨实体逻辑）
├── policy/             # 显式业务策略（如 LateFeePolicy）
├── event/              # 领域事件
├── port/               # 六边形端口接口（Repository / EventPublisher）
└── error/              # 领域专属异常
```

## 🎯 写代码前自检清单

1. **业务术语在 `../CONTEXT.md` 里吗？** 没有先加条目（中英文 + 定义 + `_Avoid_` 同义词）再写
2. **要表达的不变量在 `../INVARIANTS.md` 里吗？** 没有先加 INV-NNN 一行再写
3. **先在 `../tests/unit/` 写红灯测试断言 INV-NNN，跑测试看到 RED ✗，再来写实现**

## 🏛️ 设计原则

- **能写值对象就绝不写实体**（无 ID、不可变、按属性等价）
- **聚合之间只用 ID 关联**，禁止持有对象引用
- **所有外部访问必须经过聚合根方法**，不允许跨过聚合根直接改内部实体
- **`Port` 接口在 Domain 层定义，实现在 Infrastructure 层**（依赖倒置）

## 反模式（立刻指出）

- ❌ Domain 类用 `@router.post` / `@app.route` / `@dataclass` 之外的框架注解
- ❌ Domain 方法接收 `dict`/`json` 当参数（应该接收强类型值对象）
- ❌ 一个测试塞多个断言（一测一断言对应一个 INV）
- ❌ 在 Domain 层做 IO（读文件、查 DB、发请求）—— 通过 Port 委托给 Infra
