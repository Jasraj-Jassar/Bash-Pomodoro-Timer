#!/usr/bin/env bash
set -euo pipefail

# pomodoro_timer
# Usage:
#   pomodoro_timer          # 50m work / 10m break (infinite loop)
#   pomodoro_timer -test    # 5s work / 5s break (infinite loop)

WORK_SEC=$((50*60))
BREAK_SEC=$((10*60))

if [[ "${1:-}" == "-test" ]]; then
  WORK_SEC=5
  BREAK_SEC=5
fi

# --- helpers ---
have() { command -v "$1" >/dev/null 2>&1; }

notify() {
  local title="$1"
  local msg="$2"
  if have notify-send; then
    notify-send -u normal "$title" "$msg"
  else
    printf '%s: %s\n' "$title" "$msg"
  fi
}

beep() {
  # 1) terminal bell (works in many terminals)
  printf '\a'
  # 2) optional audio beep if available
  if have paplay; then
    # common system sound on many distros; if it doesn't exist, terminal bell still works
    local sound="/usr/share/sounds/freedesktop/stereo/complete.oga"
    [[ -f "$sound" ]] && paplay "$sound" >/dev/null 2>&1 || true
  elif have pw-play; then
    # PipeWire tool (rarely installed by default)
    local sound="/usr/share/sounds/freedesktop/stereo/complete.oga"
    [[ -f "$sound" ]] && pw-play "$sound" >/dev/null 2>&1 || true
  fi
}

fmt_time() {
  local s="$1"
  if (( s < 60 )); then
    printf "%ds" "$s"
  else
    printf "%dm %ds" $((s/60)) $((s%60))
  fi
}

countdown() {
  local total="$1"
  local label="$2"
  local end=$((SECONDS + total))

  # lightweight status line every second
  while (( SECONDS < end )); do
    local left=$((end - SECONDS))
    printf '\r%s: %s remaining  ' "$label" "$(fmt_time "$left")"
    sleep 1
  done
  printf '\r%s: done!%*s\n' "$label" 20 ""
}

trap 'printf "\nStopped.\n"; exit 0' INT TERM

cycle=1
while true; do
  notify "Pomodoro #$cycle" "Work started: $(fmt_time "$WORK_SEC")"
  beep
  countdown "$WORK_SEC" "WORK"

  notify "Pomodoro #$cycle" "Break time: $(fmt_time "$BREAK_SEC")"
  beep
  countdown "$BREAK_SEC" "BREAK"

  notify "Pomodoro #$cycle" "Break over — back to work."
  beep
  cycle=$((cycle + 1))
done

