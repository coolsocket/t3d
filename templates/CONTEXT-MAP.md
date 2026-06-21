# Context Map

> 本仓库的限界上下文清单 + 关系图。
> 新建 / 删除 / 重命名 context 必须更新此文件。

## Contexts

<!-- FILL IN: 每个 context 一行。例：
- [`billing`](./contexts/billing/CONTEXT.md) — 一句话职责描述
- [`user`](./contexts/user/CONTEXT.md) — 用户身份、登录、profile
-->

_（用 `/t3d-new-context <name>` 创建后，把它加到这里）_

## 关系图

<!-- FILL IN: 画一张 ASCII 图说明 context 之间事件 / 同步调用关系。
     例：

     ┌─────────┐  OrderPlaced   ┌──────────┐
     │ ordering│───────────────▶│ billing  │
     └─────────┘                └──────────┘
-->

## 关系详解

| 上游 → 下游 | 通道 | 事件 / 调用 |
|------------|------|-----------|
| 例：`ctxA` → `ctxB` | 异步事件 | `SomethingHappened` |
| 例：`ctxA` → `ctxB` | 同步只读 | `ctxB.application.api.get_x(...)` |

## 共享内核

`contexts/_shared_kernel/` 包含跨 context 复用的纯值对象。

模板示例（可保留 / 删除 / 替换）：
- `Money` — 金额（amount + currency），不可变；同币种才能加减
- `Timestamp` — UTC 时间戳，标准化

**新增 shared kernel 类型必须写 ADR**（理由：跨 context 共享 = 高耦合，慎重）。

## 同步调用 vs 异步事件 —— 选哪种

- **默认走异步事件**：写路径（修改 / 创建 / 删除）一律 emit 事件，让下游订阅。最弱耦合，未来拆微服务零成本。
- **只在 read-only 查询场景才走同步 api.py**：例如 `analytics` 生成报表时同步问 `pricing.application.api.get_current_price(...)` 取实时价。
- **绝不在写路径上做同步跨 context 调用**：会产生事务边界爆炸 + 强依赖。
