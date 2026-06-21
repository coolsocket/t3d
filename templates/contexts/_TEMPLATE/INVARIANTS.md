# {Context Name} 不变量清单

> 本 context 守护的业务不变量。每一条都对应至少一个测试，构成 DDD + TDD 的物质载体。
> 写新功能前：先在这里加一行 INV-NNN，再去 `tests/unit/` 写对应红灯测试，再写实现。

## 当前不变量

| ID | 不变量 | 守护它的测试 |
|----|--------|------------|
| INV-001 | {示例：金额必须 ≥ 0} | `tests/unit/test_money.py::test_amount_non_negative` |
| INV-002 | {示例：状态机不允许逆向跳转} | `tests/unit/test_workflow.py::test_no_reverse_transition` |

## 已废弃的不变量（保留作历史）

| ID | 不变量 | 废弃原因 | 废弃日期 |
|----|--------|---------|---------|
| — | — | — | — |
