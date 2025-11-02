#!/usr/bin/env bash
# visuals.sh – Foxly Whale + Mini-Progressbar (TTY-safe, no deps)

# ---------- Config ----------
SCRIPT_ANIM="${SCRIPT_ANIM:-1}"   # 1=Wal-Bubble-Animation
NO_COLOR="${NO_COLOR:-0}"         # 1=keine Farben
FORCE_NO_COLOR="${FORCE_NO_COLOR:-0}" # via --no-color

# ---------- TTY/Color ----------
_is_tty() { [ -t 1 ]; }
_term_cols() { tput cols 2>/dev/null || echo 80; }

if [ "$NO_COLOR" = "1" ] || [ "$FORCE_NO_COLOR" = "1" ] || ! _is_tty; then
  C_RESET=""; C_DIM=""; C_BOLD=""
  C_WHALE=""; C_WATER=""; C_TEXT=""
else
  C_RESET="$(printf '\033[0m')"
  C_DIM="$(printf '\033[2m')"
  C_BOLD="$(printf '\033[1m')"
  C_WHALE="$(printf '\033[38;5;39m')"     # blau
  C_WATER="$(printf '\033[38;5;45m')"     # türkis
  C_TEXT="$(printf '\033[38;5;250m')"     # hellgrau
fi

# ---------- Helpers ----------
_center_print() {
  local cols pad line plain width left
  cols="$(_term_cols)"
  while IFS= read -r line; do
    plain="${line//\033\[[0-9;]*m/}"
    width=${#plain}
    if [ "$width" -lt "$cols" ]; then pad=$(( (cols - width) / 2 )); left="$(printf '%*s' "$pad" '')"; else left=""; fi
    printf "%s%s\n" "$left" "$line"
  done
}

_bubbles_frame() {
  case "$1" in
    0) printf "   ·    \n";;
    1) printf "    ·   \n";;
    2) printf "     ·  \n";;
    3) printf "      · \n";;
  esac
}

_whale_art() {
  local eye="${1:-o}"
  cat <<'EOF'
               ~ ~    ~~~     ~ ~
EOF
  cat <<EOF
        ${C_WATER}~~~~${C_RESET}           ${C_WHALE}__         ${C_RESET}
                       ${C_WHALE}\ \_       ${C_RESET}
${C_WATER}~~~~${C_RESET}               ${C_WHALE}|${C_RESET}${C_TEXT}=====${C_RESET}${C_WHALE}\__   ${C_RESET}
                     ${C_WHALE}/  ${eye}  ${C_RESET}${C_WHALE}___/   ${C_RESET}
                    ${C_WHALE}/_________/    ${C_RESET}
                ${C_WATER}~~~~~${C_RESET}             ${C_WATER}~~~~~${C_RESET}
EOF
}

whale_banner() {
  local mode="${1:-install}" eye title
  shift || true
  for arg in "$@"; do [ "$arg" = "--no-color" ] && FORCE_NO_COLOR=1; done

  if [ "$mode" = "uninstall" ]; then
    eye="x"
    title="${C_BOLD}${C_TEXT}Uninstall dockerinstall – Goodbye, old friend.${C_RESET}"
  else
    eye="o"
    title="${C_BOLD}${C_TEXT}Install dockerinstall – Let’s set sail!${C_RESET}"
  fi

  printf "%s\n" "$title" | _center_print
  if [ "$SCRIPT_ANIM" = "1" ] && _is_tty; then
    for f in 0 1 2 3; do _bubbles_frame "$f" | _center_print; sleep 0.05; done
  fi
  _whale_art "$eye" | _center_print

  if [ "$mode" = "uninstall" ]; then
    printf "%s\n" "${C_DIM}(Der Wal schließt ein Auge … bis bald!)${C_RESET}" | _center_print
  else
    printf "%s\n" "${C_DIM}(Anker lichten – Docker wird vorbereitet…)${C_RESET}" | _center_print
  fi
}

parse_no_color_flag() { for a in "$@"; do [ "$a" = "--no-color" ] && FORCE_NO_COLOR=1; done; }

# ---------- Mini-Progressbar ----------
PROG_TOTAL=0; PROG_CUR=0; PROG_ACTIVE=0
progress__hide_cursor() { _is_tty && tput civis 2>/dev/null || true; }
progress__show_cursor() { _is_tty && tput cnorm 2>/dev/null || true; }
progress__cols() { _term_cols; }

progress__draw() {
  local p="${1:-0}" label="${2:-}" cols barw filled empty gauge
  cols="$(progress__cols)"; barw=40
  [ "$cols" -lt 70 ] && barw=28; [ "$cols" -lt 50 ] && barw=20; [ "$barw" -lt 10 ] && barw=10
  local filled_len=$(( (p * barw) / 100 )); [ "$filled_len" -gt "$barw" ] && filled_len="$barw"
  local empty_len=$(( barw - filled_len ))
  filled="$(printf '%*s' "$filled_len" '' | tr ' ' '#')"
  empty="$(printf '%*s' "$empty_len" '' | tr ' ' '-')"
  gauge="${C_WATER}[${C_RESET}${filled}${empty}${C_WATER}]${C_RESET} ${C_TEXT}$(printf '%3d' "$p")%%%${C_RESET}"
  printf "\r%s %s  %s" "${C_BOLD}${C_TEXT}▶${C_RESET}" "$gauge" "${C_DIM}${label}${C_RESET}"
}

progress_init() {
  PROG_TOTAL="${1:-0}"; PROG_CUR=0; PROG_ACTIVE=1
  if _is_tty; then progress__hide_cursor; printf "%s\n" "${C_BOLD}${C_TEXT}${2:-Progress}${C_RESET}"; progress__draw 0 "Startet …"
  else [ -n "${2:-}" ] && echo "[INFO] ${2}"; fi
  trap 'progress_cleanup' EXIT
}
progress_step() {
  [ "$PROG_ACTIVE" -ne 1 ] && { echo "[STEP] ${1}"; return; }
  PROG_CUR=$(( PROG_CUR + 1 ))
  local pct=0; [ "$PROG_TOTAL" -gt 0 ] && pct=$(( (PROG_CUR * 100) / PROG_TOTAL )); [ "$pct" -gt 100 ] && pct=100
  if _is_tty; then progress__draw "$pct" "${1:-}"; else echo "[${PROG_CUR}/${PROG_TOTAL}] ${1}"; fi
}
progress_set() {
  local pct="${1:-0}"; [ "$pct" -lt 0 ] && pct=0; [ "$pct" -gt 100 ] && pct=100
  if _is_tty; then progress__draw "$pct" "${2:-}"; else echo "[${pct}%%] ${2}"; fi
}
progress_done() {
  if _is_tty; then progress__draw 100 "${1:-Fertig}"; printf "\n"; else echo "[DONE] ${1:-Fertig}"; fi
  progress__show_cursor; PROG_ACTIVE=0; trap - EXIT
}
progress_cleanup() {
  if [ "$PROG_ACTIVE" -eq 1 ]; then _is_tty && printf "\n"; progress__show_cursor; PROG_ACTIVE=0; fi
}
