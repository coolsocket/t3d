# {Context Name}

> 复制本目录为 `contexts/<your-ctx>/` 即可开始新建限界上下文。
> 复制后请把所有 `{占位符}` 替换成真实内容，删除本提示框。

## 这个 context 负责什么

{1-2 句话描述。}

## 这个 context **不**负责什么

{对应避免 scope creep —— 明确边界，未来想塞东西时可以指着这里说"不"。}

## 关键聚合根

- `AggregateOne` —— 1 句话说它的职责
- `AggregateTwo` —— ...

## 对外暴露（`application/api.py`）

其他 context **只能**通过 `application/api.py` 调用本 context。当前公开的命令/查询：

- `do_something(cmd: SomeCommand) -> SomeResult`
- `query_something(q: SomeQuery) -> SomeView`

## 发出的领域事件

- `SomethingHappened` —— 在 X 时刻触发
- ...

## 订阅的外部事件

- `OtherContextEvent` —— 来自 `contexts/other`，触发 Y 行为
- ...

## 与其他 context 的关系

详见根 `CONTEXT-MAP.md`。

## 内部 ADR

详见 `./docs/adr/`。Context 内部决策走嵌套 ADR；系统级决策走根 `docs/adr/`。
