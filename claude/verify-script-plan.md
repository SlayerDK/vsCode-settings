# Plan: verify script + auto-verify hooks

## Goals

- `**verify:fast**` — runs in PostToolUse after every Edit/Write/MultiEdit. Must stay under ~5s on incremental runs so the agent loop doesn't drag.
- `**verify:full**` — runs in Stop. Catches everything `verify:fast` skipped. Target under 60s.
- `**verify:ci**` — runs on PR. Adds `next build`, e2e, full Fallow audit.

## Tool layout


| Tool                                                                | Job                                                      | Why this tier                                                                                  |
| ------------------------------------------------------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Prettier                                                            | Format only                                              | Cheap; runs in fast tier on changed files                                                      |
| ESLint (flat config, `next/core-web-vitals` + `@typescript-eslint`) | Lint                                                     | Fast tier on changed files; full tier on whole repo                                            |
| `tsc --noEmit` (project refs if monorepo, otherwise incremental)    | Types                                                    | Fast tier with `--incremental`; full tier clean run                                            |
| Fallow                                                              | Dead code, duplication, cycles, complexity, architecture | Sub-second — safe in fast tier with `dead-code --quiet`; full audit (`fallow`) in full/CI tier |


## Step 1 — Install and configure tools

1. `pnpm add -D prettier eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-config-next typescript`
2. `pnpm add -D fallow` (or `npx fallow` for one-off)
3. `npx prettier --write .` once to normalize.
4. ESLint flat config `eslint.config.mjs` extending `next/core-web-vitals`, `next/typescript`. Turn off Prettier-overlap rules.
5. `tsconfig.json`: `"strict": true`, `"noUncheckedIndexedAccess": true`, `"incremental": true`, `"tsBuildInfoFile": ".tsbuildinfo"`.
6. `fallow.config.*` — start with defaults; add `architecture` boundaries once you know your layer split (`app/`, `lib/`, `db/`).
7. Install the Fallow agent skill so subagents know how to call it: `/install fallow-rs/fallow-skills` (Claude Code).

## Step 2 — `package.json` scripts

```json
{
  "scripts": {
    "format": "prettier --write .",
    "format:check": "prettier --check .",

    "lint": "eslint .",
    "lint:changed": "node scripts/lint-changed.mjs",

    "typecheck": "tsc --noEmit",
    "typecheck:fast": "tsc --noEmit --incremental",

    "fallow:fast": "fallow dead-code --format json --quiet --unused-exports",
    "fallow:full": "fallow --format json --quiet",

    "verify:fast": "pnpm format:check && pnpm lint:changed && pnpm typecheck:fast && pnpm fallow:fast",
    "verify:full": "pnpm format:check && pnpm lint && pnpm typecheck && pnpm fallow:full",
    "verify:ci": "pnpm verify:full && next build && playwright test --grep @smoke"
  }
}
```

Notes:

- Prettier check (not write) in verify so the agent gets *told* about format violations and runs `pnpm format` itself.
- Fast Fallow only runs `dead-code --unused-exports` (the cheapest, highest-signal check). Full Fallow runs every analysis

## Step 3 — Hook configuration

`.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "pnpm -s verify:fast",
            "timeout": 30000
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "pnpm -s verify:full",
            "timeout": 180000
          }
        ]
      }
    ]
  }
}
```

Behavior:

- Non-zero exit feeds stderr back to the agent — it will retry.
- 30s PostToolUse timeout prevents the loop hanging on a runaway lint.
- Stop hook prevents the agent declaring victory on a broken state.

## Step 5 — `AGENTS.md` at repo root

Short document telling any agent (Claude Code, Codex, Cursor) the contract:

```md
# Verification
- After any edit: `pnpm verify:fast` must pass.
- Before declaring a task done: `pnpm verify:full` must pass.
- Auto-fix formatting with `pnpm format`. Never disable lint/type rules to silence errors.
- Fallow findings are not optional — fix dead code rather than ignoring it.
```

## Step 6 — Validate the loop

1. Make a deliberate TS error, save → confirm hook fires and agent self-corrects.
2. Add an unused export → confirm `fallow dead-code` flags it in the fast tier.
3. Add a Prettier violation → confirm verify fails until `pnpm format` runs.
4. Time each tier on a real edit. If `verify:fast` exceeds ~5s, drop `lint:changed` from PostToolUse and move it to Stop.

## Open decisions

- **Biome vs ESLint+Prettier**: ESLint+Prettier chosen — expect `verify:fast` to be 3-5× slower than Biome. Swap is easy if loop feels sluggish.
- **Where Vitest fits**: not in this plan yet. Add `vitest run --changed origin/main` to `verify:full` once domain tests exist.
- **Fallow `fix --dry-run`**: wire as a separate `pnpm fallow:fix` script the agent can run during refactors, but keep out of the hook.

## References

- fallow docs: [https://docs.fallow.tools/](https://docs.fallow.tools/)
- fallow-skills (agent integration): [https://github.com/fallow-rs/fallow-skills](https://github.com/fallow-rs/fallow-skills)
- fallow GitHub: [https://github.com/fallow-rs/fallow](https://github.com/fallow-rs/fallow)

