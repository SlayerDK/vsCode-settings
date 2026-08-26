#!/usr/bin/env bash

input=$(cat)

# Git branch
git_branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir')" --no-optional-locks branch --show-current 2>/dev/null)

# 5-hour session usage percentage
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Context window usage percentage
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Model display name
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')

# Effort level
effort=$(echo "$input" | jq -r '.effort.level // empty')

# --- Build output parts ---
parts=()

# 🌿 Git branch
if [ -n "$git_branch" ]; then
  parts+=("🌿 $git_branch")
fi

# ⚡ Context window usage
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf '%.0f' "$ctx_pct")
  parts+=("⚡ ctx:${ctx_int}%")
fi

# 📊 Session usage (text color goes green -> red as it nears 100%)
if [ -n "$five_pct" ]; then
  pct_int=$(printf '%.0f' "$five_pct")
  # Clamp 0-100
  [ "$pct_int" -lt 0 ] && pct_int=0
  [ "$pct_int" -gt 100 ] && pct_int=100
  # Interpolate red up, green down
  r=$(( pct_int * 255 / 100 ))
  g=$(( (100 - pct_int) * 255 / 100 ))
  parts+=("$(printf '📊 \033[38;2;%d;%d;0m%d%%\033[0m' "$r" "$g" "$pct_int")")
fi

# ⏰ Next session start (when 5h window resets)
if [ -n "$five_resets" ]; then
  reset_time=$(date -d "@$five_resets" +"%H:%M" 2>/dev/null || date -r "$five_resets" +"%H:%M" 2>/dev/null)
  [ -n "$reset_time" ] && parts+=("⏰ $reset_time")
fi

# 🤖 Model
if [ -n "$model" ]; then
  parts+=("🤖 $model")
fi

# Effort level
if [ -n "$effort" ]; then
  parts+=("effort: $effort")
fi

# Join with separator
printf '%s' "$(IFS=' | '; echo "${parts[*]}")"
