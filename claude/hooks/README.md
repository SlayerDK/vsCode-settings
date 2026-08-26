# verify-stop hook

A reusable Claude Code **Stop** hook that runs your repo's verification commands
(lint, test, `fallow audit`, …) before Claude is allowed to stop. On any failure,
the hook blocks the stop and returns the failing command's output so Claude can
fix it.

Inspired by `fallow-audit-stop.mjs`, generalized to a config-driven runner so a
new repo only needs to drop two files in and add one settings entry.

## Wire up in a new repo

1. **Copy the two files** into the repo:

   ```
   .claude/hooks/verify-stop.mjs
   .claude/hooks/verify.config.json
   ```

2. **Register the hook** in `.claude/settings.json`:

   ```json
   {
     "hooks": {
       "Stop": [
         {
           "matcher": "",
           "hooks": [
             { "type": "command", "command": "node .claude/hooks/verify-stop.mjs" }
           ]
         }
       ]
     }
   }
   ```

3. **Edit `verify.config.json`** for the repo. Remove commands the project
   doesn't use (e.g. no `fallow` yet → drop the `fallow audit` entry, or just
   leave it: missing executables are silently skipped unless `required: true`).

That's it. The hook does nothing if the config is missing or empty, so it's
safe to leave registered in repos that haven't filled it in yet.

## Config shape

```jsonc
{
  "commands": [
    {
      "name": "lint",                           // shown in the block reason
      "command": "pnpm",                        // executable
      "args": ["exec", "eslint", ".", "--max-warnings=0"],
      "mode": "exit-code"                       // non-zero → block
    },
    {
      "name": "fallow audit",
      "command": "pnpm",
      "args": ["exec", "fallow", "audit", "--format", "json"],
      "mode": "json-verdict",                   // parse stdout JSON
      "verdictField": "verdict",                // (default)
      "passValue": "pass"                       // (default)
    }
  ]
}
```

### Field reference

| Field          | Required | Notes                                                                                  |
| -------------- | -------- | -------------------------------------------------------------------------------------- |
| `name`         | yes      | Human label used in the block reason.                                                  |
| `command`      | yes      | Executable. On Windows, runs via shell so `pnpm` / `npm` / `git` resolve naturally.    |
| `args`         | no       | Array of args. Default `[]`.                                                           |
| `mode`         | no       | `"exit-code"` (default) or `"json-verdict"`.                                           |
| `verdictField` | no       | JSON field to inspect in `json-verdict` mode. Default `"verdict"`.                     |
| `passValue`    | no       | Value of `verdictField` that means "pass". Default `"pass"`.                           |
| `required`     | no       | If `true`, block when the executable is missing or returns unparseable JSON. Default skips so partially-configured repos stay green. |

## Behavior

- **Sequential.** Runs commands in config order; first failure blocks. Put the
  fast checks (lint) before the slow ones (tests, fallow) so feedback is quick.
- **Silent on `stop_hook_active`.** Won't recurse if Claude is already retrying.
- **Silent on missing config.** Safe to drop into a repo before filling it in.
- **Silent on missing executable** (unless `required: true`). Lets you keep
  `fallow audit` in the template even before `fallow` is installed.
- **Truncates output** to ~8 KB per failure so block reasons stay readable.

## Why a Stop hook?

The Stop hook fires when Claude tries to end its turn. Failing it forces Claude
to read the output and address the issues in the same conversation, instead of
the user discovering broken code after the fact.
