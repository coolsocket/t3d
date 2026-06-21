#!/usr/bin/env bash
# .claude/hooks/classify-prompt.sh
# UserPromptSubmit hook — 按信号词把 prompt 归类，注入工作流提醒
#
# Requires: bash, jq
# Input (stdin): UserPromptSubmit JSON payload
# Output (stdout): additionalContext JSON (or silent if no class matched)

set -euo pipefail

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty')
[ -z "$prompt" ] && exit 0

mode=""
guidance=""

# 顺序重要：bug > playground > feature > refactor（特化优先）
if echo "$prompt" | grep -qiE "(bug|不对|报错|复现|挂了|broken|stack ?trace|exception|失败|fail)"; then
  mode="🐞 Bug 修复模式"
  guidance="必须先在对应 context 的 tests/unit/ 写一个【复现 Bug 的红灯测试】→ 跑测试看 RED ✗ → 再修代码 → GREEN ✓ → 重构。不写红灯直接改代码 = 没有回归保护。"
elif echo "$prompt" | grep -qiE "(spike|原型|调研|试一下|玩玩|玩一下|prototype|explore|throw[- ]?away|看看能不能)"; then
  mode="🟢 Playground 模式"
  guidance="走 playground/<topic>/ 子目录，不需要 DDD/TDD 仪式。但仍要：1) 子目录有 README.md 写明在试什么；2) 不要 import contexts.*。"
elif echo "$prompt" | grep -qiE "(实现|加功能|新需求|上线|新建.*context|add[- ]?invariant|new context|implement|feature|build)"; then
  mode="🔴 正式功能模式（DDD + TDD 完整流程）"
  guidance="按红绿循环走：1) 澄清上下文/聚合根/不变量/术语；2) 在 contexts/<ctx>/INVARIANTS.md 加 INV-NNN；3) 在 tests/unit/ 写红灯断言 INV-NNN；4) 跑测试看 RED ✗；5) 写最少 domain 代码转 GREEN；6) 重构；7) 下一条 INV 循环。不要跳步。"
elif echo "$prompt" | grep -qiE "(重构|改名|抽取|refactor|rename|extract|tidy|clean[- ]?up)"; then
  mode="🔵 重构模式"
  guidance="既有测试必须保持 GREEN ✓。每改一小步重跑一次测试。一旦变红立刻回退或修复，绝不带红重构。"
fi

if [ -n "$mode" ]; then
  jq -n --arg m "$mode" --arg g "$guidance" '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: ("【任务分类】" + $m + "\n【工作流】" + $g)
    }
  }'
fi

exit 0
