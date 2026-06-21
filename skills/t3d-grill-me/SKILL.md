---
name: t3d-grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use BEFORE writing code on any non-trivial feature — bounded context selection, aggregate boundaries, invariants, ubiquitous language. The harness assumes you grill-me first.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

When working in a t3d-harnessed project, prioritize grilling on:
1. **Which bounded context** does this feature belong to? (Look at `CONTEXT-MAP.md`.)
2. **Which aggregate root** owns the state change? Are we introducing a new aggregate?
3. **What invariants** must hold? List them — they'll go in `INVARIANTS.md` and each gets one failing test.
4. **What ubiquitous language terms** does this introduce? Are any of them already in `contexts/<ctx>/CONTEXT.md`? Are we redefining a term used in another context (that's fine — contexts have local languages)?
5. **Are there cross-context calls?** If yes, they MUST go through `contexts.<other>.application.api` (not internal domain imports). The PreToolUse hook will enforce this.
