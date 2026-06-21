# Architecture Decision Records (ADRs)

> 系统级架构决策记录。Context 内部决策放在 `contexts/<ctx>/docs/adr/`。

## 何时写 ADR（Matt Pocock 三条件）

只在以下三条**全部成立**时才写 ADR：

1. **难撤回**（改回去成本高）
2. **无 context 会让人困惑**（未来读代码会问"为啥这么做"）
3. **是真实权衡的结果**（确实有备选方案被否）

三缺一就**不写**。这避免 ADR 沦为"决策日记"。

## 文件命名

- 系统级：`docs/adr/NNNN-short-kebab.md`
- Context 内部：`contexts/<ctx>/docs/adr/NNNN-*.md`

`NNNN` 是 4 位顺序号（0001 / 0002 / ...）。

## 模板

见 [NNNN-template.md](./NNNN-template.md)。
