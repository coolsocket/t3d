# _shared_kernel 不变量清单

| ID | 不变量 | 守护它的测试 |
|----|--------|------------|
| INV-001 | `Money.amount` 必须 ≥ 0 | `tests/unit/test_money.py::test_amount_non_negative` |
| INV-002 | `Money` 不可变（frozen） | `tests/unit/test_money.py::test_money_is_immutable` |
| INV-003 | `Money` 加法仅允许同币种 | `tests/unit/test_money.py::test_addition_requires_same_currency` |
| INV-004 | `Money` 按值等价 | `tests/unit/test_money.py::test_equality_by_value` |
| INV-005 | `TokenCount` 必须 ≥ 0 | `tests/unit/test_token_count.py::test_token_count_non_negative` |
| INV-006 | `ModelName` 必须匹配 `^[a-z0-9._-]+$` 且非空 | `tests/unit/test_model_name.py::test_format_validation` |
| INV-007 | `Timestamp` 必须是 UTC | `tests/unit/test_timestamp.py::test_timestamp_is_utc` |
