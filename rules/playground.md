---
paths:
  - "playground/**"
---

# Playground 规则

你正在 playground 区。**这里不走 DDD / TDD**。

- ✅ 随便 import 任何包、任何写法
- ✅ hardcode、注释、TODO 都可以
- ✅ 单文件脚本无需架构

但仍有 3 条硬规则：

1. **一个主题一个子目录**：`playground/<topic>/`
2. **每个子目录需要 README.md** 写：在试什么 + 最终结论
3. **绝对禁止 `import contexts.*`** —— playground 是孤岛，不污染正式代码

如果实验跑通且值得保留 → 走晋升流程（见 `playground/README.md`），**重写**到 `contexts/<new-ctx>/` 走 DDD+TDD，不要 copy-paste。
