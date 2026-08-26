#!/usr/bin/env node
import { spawnSync } from "node:child_process";

const readStdin = () =>
  new Promise((resolve) => {
    let data = "";
    if (process.stdin.isTTY) return resolve("");
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => (data += chunk));
    process.stdin.on("end", () => resolve(data));
  });

const silentExit = () => process.exit(0);

const block = (reason) => {
  process.stdout.write(JSON.stringify({ decision: "block", reason }));
  process.exit(0);
};

const truncate = (s, max = 12000) =>
  s.length <= max ? s : s.slice(0, max) + `\n…[truncated ${s.length - max} chars]`;

try {
  const raw = await readStdin();
  let input = {};
  try {
    input = raw ? JSON.parse(raw) : {};
  } catch {
    input = {};
  }

  if (input.stop_hook_active === true) silentExit();

  const isWindows = process.platform === "win32";
  const result = spawnSync(
    isWindows ? "pnpm.cmd" : "pnpm",
    ["exec", "fallow", "audit", "--format", "json"],
    { encoding: "utf8", maxBuffer: 32 * 1024 * 1024 },
  );

  if (result.error) silentExit();

  const stdout = result.stdout ?? "";
  let parsed;
  try {
    parsed = JSON.parse(stdout);
  } catch {
    silentExit();
  }

  if (!parsed || typeof parsed !== "object") silentExit();
  if (parsed.verdict === "pass") silentExit();

  const reason = [
    `\`fallow audit\` verdict: ${parsed.verdict ?? "unknown"}. Fix the findings below before stopping.`,
    "",
    "```json",
    truncate(JSON.stringify(parsed, null, 2)),
    "```",
  ].join("\n");

  block(reason);
} catch {
  silentExit();
}
