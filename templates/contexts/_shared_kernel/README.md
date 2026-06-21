# Shared Kernel

> ⚠️ **极高准入门槛**。这里放跨 context 共享的**纯值对象**。
> 新增任何类型必须先在 `docs/adr/` 写一篇 ADR 论证它真的是所有上下文共享的概念。

## 为什么这么严

跨 context 共享 = 强耦合。一旦放进来，任何 context 改它都要协调所有其他 context。99% "看起来要共享"的情况，其实是**上下文边界画错了** —— 正确做法是重新切上下文，而不是塞进 shared kernel。

## 允许放什么

- **纯值对象**（无 ID、不可变、按属性等价）
- **完全无业务行为**（像 `Money`、`Timestamp` 这种通用度量单位）
- **绝对不依赖任何外部包**（只能用 Python 标准库）

## 模板示例（来自原型 LLM 用量追踪项目）

这些是 plugin 自带的示例 VO，**按需保留 / 删除 / 替换**：

- `Money` —— 金额（amount + currency），不可变。**通用**，建议保留
- `Timestamp` —— UTC 时间戳，标准化。**通用**，建议保留
- `ModelName` —— LLM 模型名格式（如 `claude-opus-4-8`）。LLM 项目可留，其他项目可删
- `TokenCount` —— 非负 token 计数。LLM 项目可留，其他项目可删

> 删除任何示例 VO 后，记得同步：
> - `INVARIANTS.md` 删对应行
> - `__init__.py` 删对应 import
> - `tests/unit/test_<vo>.py` 删对应文件

## 不变量

详见 [INVARIANTS.md](./INVARIANTS.md)。
