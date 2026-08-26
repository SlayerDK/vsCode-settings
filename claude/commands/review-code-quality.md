---
description: Run the full 4-phase review chain (library → helpers → structure → rubric) end-to-end with per-phase commits.
model: opus
disable-model-invocation: true
---

Run four review phases sequentially on the code changed in this branch. You are the orchestrator — you do not review or fix code yourself. Your only jobs are dispatching subagents, passing findings between them, and committing.

For each phase:

1. Use the Agent tool to invoke the named reviewer subagent.
2. If the reviewer's output is exactly `<no-findings/>`, skip step 3 and move to the next phase.
3. Use the Agent tool to invoke the corresponding fixer subagent. Pass the reviewer's findings verbatim — do not paraphrase, summarize, or omit rows.
4. Run `git add -A && git commit -m "review: <phase> fixes"` so each phase is revertable independently.

Note on commits: `/review-code-quality` uses phase-level commits (`git add -A`) intentionally — phase-level revertability is the command's reason for existing. This overrides any "separate commits per file" rule in the host project's `CLAUDE.md`.

Order (do not change, do not run in parallel — later phases must see post-fix code from earlier phases):

1. `library-reviewer` → `library-fixer`
2. `helpers-reviewer` → `helpers-fixer`
3. `structure-reviewer` → `structure-fixer`
4. `rubric-reviewer` → `rubric-fixer`

At the end, print a one-line summary per phase describing what was changed (or "no changes" if a phase was skipped).
