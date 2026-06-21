# t3d plugin — pitfalls

> 跨项目通用的"做 X 时容易踩 Y"经验。
> **只放 generalizable 的**——单项目特定经验请放该项目的 `.claude/PITFALLS.md`。
>
> 新增条目来源标注 session id + 日期；如果有多次复现，列出所有。
>
> 由 `t3d-sinkin` skill 的 Section 4 协助积累；条目须经用户确认后才写入。

---

## Shell / scripting

### `pkill -f <pattern>` 会杀掉自己的 shell

`pkill -f` 匹配整个命令行 argv。当父 shell 的命令行里恰好包含 `<pattern>`
（例如这条 pkill 命令本身），它会把父 shell 也连带杀掉，返回 exit 144。

**症状**：跑 `pkill -f uvicorn` 后整个 Bash 输出 `Exit 144`，但 server 还在。

**修复**：用 `pgrep -x <name>` 精确匹配名字 + 显式 `kill <pid>`：
```bash
for pid in $(pgrep -x uvicorn); do kill "$pid"; done
```

- _Source: session 1763c182…, 2026-06-18_

---

## LLM / token semantics

### Anthropic `input_tokens` 字段不包含 cache_*

Anthropic Messages API 的 `usage.input_tokens` **只算**"未命中 cache 的新输入"，
**不包含** `cache_read_input_tokens` 和 `cache_creation_input_tokens`。

**踩坑表现**：仪表盘把 `input_tokens` 显示为 "Input"，用户看到几十 K 但
cache 几十 M，怀疑数字坏了——其实是字段语义陷阱。

**修复**：
- UI 标签用 "Total Input" = input + cache_read + cache_write，给 "uncached input"
  单独显示子项
- Cache hit rate 公式分母应是 `input + cache_read + cache_write`，不是
  `input + cache_read`（漏掉 cache_write 会算出 ~100%）

- _Source: session 1763c182…, 2026-06-17（连续 3 轮"数字不对"反馈才定位）_

---

## Claude Code plugin development

### hooks.json 顶层结构需要 `"hooks"` wrapper

`.claude/settings.json` 的 hook 块和 plugin 的 `hooks/hooks.json` 长得像，
但**后者外层必须再包一层** `{"hooks": {...}}`。否则 `claude plugin validate`
报：
```
hooks: Invalid input: expected record, received undefined
```

**修复**：plugin 用：
```json
{ "hooks": { "PreToolUse": [...], "PostToolUse": [...] } }
```
而 settings.json 是平铺的 `{ "PreToolUse": [...], ... }`（少一层）。

- _Source: session 1763c182…, 2026-06-18_

### `claude plugin update` 在 local-marketplace 模式下可能失败

如果 marketplace source 是本地路径，发布新版本后 `claude plugin update <name>`
有时报 `Plugin not found`——本质是缓存没更新。

**修复**：
```bash
claude plugin marketplace update <marketplace-name>
claude plugin uninstall <plugin>
claude plugin install <plugin>
```

- _Source: session 1763c182…, 2026-06-18_

---

## DDD / TDD 实践

### Hooks 抓不到"已有的"违规

PreToolUse hook 只在**新 Edit/Write** 时拦截。**已经存在**于代码里的违规
（跨 context import、Domain 层 import 外部包等）需要靠 sinkin Section 2
扫一遍。

- _Source: t3d-sinkin Section 2 设计反思_

---

## 模板（新增条目用）

```markdown
### <一行标题：行为 / 现象>

<2-4 行：踩了什么 / 为什么会踩 / 怎么避免>

**修复**：
\`\`\`
<最小可复现 + 修复 snippet>
\`\`\`

- _Source: session <8 char id>…, YYYY-MM-DD（如多次复现，列全）_
```
