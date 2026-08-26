---
name: verify-diff
description: >
  Diff-focused verification that audits the user's pending changes against three
  checklists: Clean Code principles, modern TypeScript type inference, and Next.js 16
  best practices. Use whenever the user asks to verify a diff, audit pending changes,
  review what they changed, check before commit, run a final pass, audit a branch or
  PR, or says "is this ready to commit?", "verify my changes", "check my work",
  "review my diff", "what should I fix before merging?". Always pulls the actual diff
  (working tree + staged + branch-vs-main) with git, reads enough surrounding context
  to judge honestly, and reports concrete findings with file:line references and
  severity. Distinct from the clean-code, solid, dry, and kiss skills (which review
  files or codebases) — this one is scoped specifically to the diff and combines the
  three axes most likely to matter for everyday changes in this codebase.
---

# verify-diff

A pre-commit / pre-PR audit of the user's current changes. The goal is to surface real issues before they reach review — lazy naming, undisciplined types, drift from Next.js 16 conventions — playing the role of a strict senior engineer doing a final pass.

## Scope

This skill verifies a diff, not the whole codebase. The unit of work is the set of lines the user just changed, plus enough surrounding context (the full changed files, sometimes their callers) to evaluate them honestly.

Do not nitpick code outside the diff. If something outside the diff is structurally bad, mention it once at the bottom under "Pre-existing issues" — don't bury the diff feedback under unrelated findings.

For deeper single-axis reviews, use the `clean-code`, `solid`, `dry`, or `kiss` skills directly. This skill is the breadth-first sweep across the three checklists most likely to matter for everyday changes here.

## Gathering the diff

Run these in parallel to capture the full picture:

- `git diff` — unstaged changes in the working tree
- `git diff --cached` — staged changes
- `git diff origin/main...HEAD` — the full branch diff if reviewing a branch or PR
- `git status --short` — untracked files (call them out if they look forgotten)

Then, for each changed file, read the full file (not just the hunk) so you can judge each change in context. Type-inference and Next.js findings frequently require seeing the imports, the surrounding declarations, and where the symbol is consumed.

If the diff is empty, say so and stop. Do not fabricate findings.

## Checklist — Clean Code (lightweight)

Compact pass — for deep analysis use the `clean-code` skill. In a diff context, focus on what's visible in the hunks:

- **Naming** — every new identifier should be descriptive on its own. Reject `data`, `info`, `tmp`, `x`, single-letter variables outside trivial scopes, and abbreviations the codebase doesn't already use.
- **Function size** — new or modified functions should fit on a screen. Flag anything over ~40 lines or with more than 3 levels of indentation.
- **Single responsibility** — if a function name needs "and", split it. If a file is past 80 lines (the project cap), check whether the additions are pulling it past a responsibility boundary.
- **Magic values** — new literal numbers/strings that should be named constants or come from configuration.
- **Dead code** — commented-out blocks, unused imports, unused variables, "just in case" parameters. Remove them.
- **Comment quality** — every new comment must explain *why*, not *what*. Restating the code in English is a removal.
- **Early returns** — nested `if` chains that could be flattened with guard clauses.
- **Boolean flag arguments** — a `doX(thing, true)` call is a signal the function does two things. Split it.

## Checklist — Modern TypeScript type inference

Rule of thumb: **let the compiler do the work.** Hand-written types belong at boundaries (public API, server actions, route handlers, schemas) and almost nowhere else. Flag the following:

- **`any`** — every `any` is a finding. Prefer `unknown` at a boundary, narrow with type guards or Zod.
- **`as` casts** — non-trivial assertions are escape hatches. `as unknown as T` is always a finding. Prefer narrowing or `satisfies`.
- **Redundant annotations** — explicit types where inference is obvious (`const x: number = 0`, `const items: User[] = users.filter(...)`). Remove them.
- **Missing `satisfies`** — config objects, route maps, theme objects, and similar should use `satisfies SomeSchema` so literal types survive instead of being widened to `string`/`number`.
- **Missing `as const`** — arrays/objects used as enums or option lists should be `as const` so member types are literal.
- **Duplicated types** — a type defined manually next to a Zod schema, Prisma model, or function it could be derived from. Use `z.infer<typeof Schema>`, `Prisma.UserGetPayload<...>`, `ReturnType<typeof fn>`, `Awaited<...>`, `Parameters<typeof fn>` instead.
- **Stringly-typed IDs** — accepting `userId: string` and `postId: string` in the same function is a footgun. Suggest branded types (`type UserId = string & { __brand: 'UserId' }`) at module boundaries.
- **Discriminated unions vs optional fields** — a type with several `?:` fields where only certain combinations are valid should be a discriminated union with a `kind` tag.
- **Public vs internal return types** — exported functions, server actions, and route handlers get explicit return types (documentation + accidental-change protection). Internal helpers let inference work.
- **Unconstrained generics** — `<T>` without `extends` when the body uses properties on `T`. Constrain it.
- **`Readonly` / `ReadonlyArray`** — function parameters the function doesn't mutate should be readonly, especially arrays passed across module boundaries.
- **`NoInfer` / const type params** — when generic inference picks the wrong site, prefer `NoInfer<T>` or `<const T>` over forcing the call site to annotate.
- **`interface` vs `type`** — `interface` for extensible object shapes, `type` for unions/intersections/mapped/conditional. Mixing inconsistently in new code is worth flagging.
- **Enums** — prefer `as const` objects + union types over `enum` (smaller, tree-shakable, plays better with inference).

## Checklist — Next.js 16 best practices

The project's hard rules from `CLAUDE.md` plus general Next.js 16 hygiene. Every item below is a finding when the diff violates it.

**Hard rules (blockers):**

- A `middleware.ts` file was added or modified — this project uses `app/proxy.ts`. Always.
- `params` or `searchParams` accessed without `await` — they are `Promise`s in Next.js 16.
- A server action without `.safeParse()` on its input (uses `.parse()` or no Zod at all).
- A new Prisma query without an explicit `select` — never return the full model.
- `prisma` or `db` imported directly into a server action, route handler, or cache function — go through `lib/repositories/`.
- `webpack` config touched — Turbopack is the bundler.
- Manual `useMemo` / `useCallback` added — the React Compiler handles memoization.
- A new module shipped without a co-located `__tests__/` file (Vitest).

**Strong conventions (warnings):**

- `'use client'` added to a component that doesn't need browser APIs, event handlers, or React hooks. Push the boundary down.
- A new `route.ts` for what should be a server action in a co-located `actions.ts`.
- A cached function (`'use cache'`) without `cacheTag` + `cacheLife` — Next.js 16 is dynamic by default, so caching must be deliberate and tagged for invalidation.
- Server-only code (DB clients, secrets, `process.env` reads) in a file without `import 'server-only'`.
- Mutation server action missing `revalidatePath` / `revalidateTag` for the data it changed.
- `<a href="/...">` for an internal link — should be `<Link>`.
- `<img>` for an asset Next could optimize — should be `<Image>`.
- New page/layout missing a `metadata` export when adjacent pages have one.
- File > 80 lines or more than one export — the project caps both.
- Env vars read without going through the central Zod-validated env schema.

## Output format

```
## Diff Verification

**Scope:** <branch or working tree>, <N> files changed, <added>/<removed> lines
**Verdict:** <Ready to commit | Fix blockers first | Major rework needed>

---

### Blockers (must fix before committing)

#### [Category] — <short title>
`path/to/file.ts:line`
> <quoted code>

<what's wrong, why it matters>

**Fix:** <concrete change, ideally a short rewrite>

---

### Warnings (should fix, won't block)
(same format)

---

### Suggestions (nice to have)
(same format)

---

### What's good
- <specific things done well in this diff — name them>

### Pre-existing issues (outside this diff)
- <optional — only if you noticed something serious>

### Top three fixes
1. <highest-impact change>
2. <second>
3. <third>
```

## Review philosophy

- **The diff is the deliverable.** If the diff is small and clean, the review should be small and clean. Don't manufacture findings.
- **Severity matters.** A real blocker drowns under a pile of nitpicks. Be selective with "warning" and even more selective with "blocker".
- **Concrete fixes always.** Every finding ships with the rewrite, not just the complaint.
- **Acknowledge good work.** "What's good" is not filler — it's how the user knows you actually read the diff.
- **Defer when appropriate.** If a deeper SOLID, DRY, or KISS review is warranted, recommend running that skill — don't half-do it here.
