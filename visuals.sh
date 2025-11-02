#!/usr/bin/env bash
# visuals.sh – Foxly ASCII + ruhige Pull-Ansicht + Mini-Progressbar (TTY-safe)

# ---------- Config ----------
SCRIPT_ANIM="${SCRIPT_ANIM:-1}"      # 1 = Animation an, 0 = aus
NO_COLOR="${NO_COLOR:-0}"            # 1 = keine Farben
FORCE_NO_COLOR="${FORCE_NO_COLOR:-0}"

# ---------- TTY / Colors ----------
_is_tty() { [ -t 1 ]; }
_term_cols() { tput cols 2>/dev/null || echo 80; }

if [ "$NO_COLOR" = "1" ] || [ "$FORCE_NO_COLOR" = "1" ] || ! _is_tty; then
  C_RESET=""; C_DIM=""; C_BOLD=""
  C_TEXT=""; C_WATER=""; C_FOX=""; C_ACCENT=""
else
  C_RESET="$(printf '\033[0m')"
  C_DIM="$(printf '\033[2m')"
  C_BOLD="$(printf '\033[1m')"
  C_TEXT="$(printf '\033[38;5;250m')"   # hellgrau
  C_WATER="$(printf '\033[38;5;45m')"   # türkis/blau (Container/Wasser)
  C_FOX="$(printf '\033[38;5;214m')"    # orange (Fox)
  C_ACCENT="$(printf '\033[38;5;223m')" # creme (Gesicht/Markierung)
fi

# ---------- Center helpers ----------
_center_print() { # single line center
  local cols pad line plain width left
  cols="$(_term_cols)"
  while IFS= read -r line; do
    plain="${line//\033\[[0-9;]*m/}"
    width=${#plain}
    if [ "$width" -lt "$cols" ]; then
      pad=$(( (cols - width) / 2 ))
      left="$(printf '%*s' "$pad" '')"
    else
      left=""
    fi
    printf "%s%s\n" "$left" "$line"
  done
}

_center_block() { # multi-line block center (gleiche linke Kante)
  local lines=() line plain width max=0
  while IFS= read -r line; do
    lines+=("$line")
    plain="${line//\033\[[0-9;]*m/}"
    width=${#plain}
    (( width > max )) && max=$width
  done
  local cols pad left; cols="$(_term_cols)"
  if (( max < cols )); then
    pad=$(( (cols - max) / 2 ))
    left="$(printf '%*s' "$pad" '')"
  else
    left=""
  fi
  for line in "${lines[@]}"; do
    printf "%s%s\n" "$left" "$line"
  done
}

# ---------- Tiny bubbles ----------
_bubbles_frame() {
  case "$1" in
    0) printf "   ·    \n";;
    1) printf "    ·   \n";;
    2) printf "     ·  \n";;
    3) printf "      · \n";;
  esac
}

parse_no_color_flag() { for a in "$@"; do [ "$a" = "--no-color" ] && FORCE_NO_COLOR=1; done; }

# ---------- Foxly ASCII (Install / Uninstall) ----------
_fox_art() {
  local mode="${1:-install}"
  local E="^_^" M="^"
  if [ "$mode" = "uninstall" ]; then E="x_x"; M="_"; fi

  cat <<EOF
                         ${C_WATER}~   ~    ~~~    ~   ~${C_RESET}
                   ${C_WATER}~~~~${C_RESET}                        ${C_WATER}~~~~${C_RESET}
                         ${C_FOX}/\\     /\\${C_RESET}
                        ${C_FOX}{  \`---'  }${C_RESET}
                        ${C_FOX}{  ${C_ACCENT}${E}${C_FOX}   }${C_RESET}
                        ${C_FOX}~~>  ${C_ACCENT}${M}${C_FOX}  <~~${C_RESET}
                         ${C_FOX}\\  \\|/  /${C_RESET}
                          ${C_FOX}\`-----'${C_RESET}
                        ${C_WATER}[ ][ ][ ]${C_RESET}
                        ${C_WATER}[ ][ ][ ]${C_RESET}
                         ${C_WATER}\`-----'${C_RESET}
EOF
}

# ---------- Banner (Name beibehalten) ----------
whale_banner() {
  local mode="${1:-install}" arg
  shift || true
  for arg in "$@"; do [ "$arg" = "--no-color" ] && FORCE_NO_COLOR=1; done

  local title
  if [ "$mode" = "uninstall" ]; then
    title="${C_BOLD}${C_TEXT}Uninstall dockerinstall – The Fox takes a bow.${C_RESET}"
  else
    title="${C_BOLD}${C_TEXT}Install dockerinstall – Foxly is on duty!${C_RESET}"
  fi

  printf "%s\n" "$title" | _center_print
  if [ "$SCRIPT_ANIM" = "1" ] && _is_tty; then
    for f in 0 1 2 3; do _bubbles_frame "$f" | _center_print; sleep 0.05; done
  fi
  _fox_art "$mode" | _center_block

  if [ "$mode" = "uninstall" ]; then
    printf "%s\n" "${C_DIM}(Foxly nickt – bis zum nächsten Run.)${C_RESET}" | _center_print
  else
    printf "%s\n" "${C_DIM}(Scharfe Krallen, sauberes Setup … los geht’s!)${C_RESET}" | _center_print
  fi
}

# ---------- Mini Progressbar ----------
PROG_TOTAL=0; PROG_CUR=0; PROG_ACTIVE=0
progress__hide_cursor() { _is_tty && tput civis 2>/dev/null || true; }
progress__show_cursor() { _is_tty && tput cnorm 2>/dev/null || true; }

progress__draw() {
  local p="${1:-0}" label="${2:-}" cols barw filled empty
  cols="$(_term_cols)"; barw=40
  [ "$cols" -lt 70 ] && barw=28
  [ "$cols" -lt 50 ] && barw=20
  [ "$barw" -lt 10 ] && barw=10
  local filled_len=$(( (p * barw) / 100 )); (( filled_len > barw )) && filled_len="$barw"
  local empty_len=$(( barw - filled_len ))
  filled="$(printf '%*s' "$filled_len" '' | tr ' ' '#')"
  empty="$(printf '%*s' "$empty_len" '' | tr ' ' '-')"
  printf "\r%s ${C_WATER}[${C_RESET}%s%s${C_WATER}]${C_RESET} ${C_TEXT}%3d%%${C_RESET}  ${C_DIM}%s${C_RESET}" \
    "${C_BOLD}${C_TEXT}▶${C_RESET}" "$filled" "$empty" "$p" "$label"
}

progress_init() {
  PROG_TOTAL="${1:-0}"; PROG_CUR=0; PROG_ACTIVE=1
  if _is_tty; then
    progress__hide_cursor
    printf "%s\n" "${C_BOLD}${C_TEXT}${2:-Progress}${C_RESET}"
    progress__draw 0 "Startet …"
  else
    echo "[INFO] ${2:-Progress}"
  fi
  trap 'progress_cleanup' EXIT
}

progress_step() {
  local label="${1:-}"
  if [ "$PROG_ACTIVE" -ne 1 ]; then echo "[STEP] $label"; return; fi
  PROG_CUR=$(( PROG_CUR + 1 ))
  local pct=$(( (PROG_CUR * 100) / PROG_TOTAL )); (( pct > 100 )) && pct=100
  if _is_tty; then progress__draw "$pct" "$label"; else echo "[${PROG_CUR}/${PROG_TOTAL}] $label"; fi
}

progress_set() {
  local pct="${1:-0}" label="${2:-}"
  (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
  if _is_tty; then progress__draw "$pct" "$label"; else echo "[${pct}%%] $label"; fi
}

progress_done() {
  local end="${1:-Fertig}"
  if _is_tty; then progress__draw 100 "$end"; printf "\n"; else echo "[DONE] $end"; fi
  progress__show_cursor; PROG_ACTIVE=0; trap - EXIT
}

progress_cleanup() {
  if [ "$PROG_ACTIVE" -eq 1 ]; then _is_tty && printf "\n"; progress__show_cursor; PROG_ACTIVE=0; fi
}

# ================= Compact compose pull (3 calm lines) =======================
_COMPACT_NAMES=(); _COMPACT_TOTALS=(); _COMPACT_CURS=(); _COMPACT_DONE=()
_COMPACT_IDXMAP=""; _COMPACT_LINES=3

_compact__index_of() {
  local nm="$1" pair
  for pair in $_COMPACT_IDXMAP; do
    case "$pair" in "$nm":*) echo "${pair##*:}"; return 0;; esac
  done
  echo "-1"
}

_compact__fmt_bytes() {
  local b="${1:-0}"
  if [ "$b" -lt 1024 ]; then printf "%dB" "$b"; return; fi
  local kb=$(( b / 1024 ))
  if [ "$kb" -lt 1024 ]; then printf "%dKB" "$kb"; return; fi
  local mb=$(( kb / 1024 ))
  if [ "$mb" -lt 1024 ]; then printf "%dMB" "$mb"; return; fi
  local gb=$(( mb / 1024 ))
  printf "%dGB" "$gb"
}

_compact__bar() {
  local p=$1 w=$2 f e
  (( p<0 )) && p=0; (( p>100 )) && p=100
  (( w<10 )) && w=10
  f=$(( (p * w) / 100 )); (( f>w )) && f=$w
  e=$(( w - f ))
  printf "[%s%s]" "$(printf '%*s' "$f" '' | tr ' ' '=')" "$(printf '%*s' "$e" '' | tr ' ' ' ')"
}

_compact__line() {
  local i="$1"
  local nm="${_COMPACT_NAMES[$i]}"
  local tot="${_COMPACT_TOTALS[$i]}"
  local cur="${_COMPACT_CURS[$i]}"
  local dn="${_COMPACT_DONE[$i]}"

  local mark bar pct right cols text
  cols="$(_term_cols)"

  if [ "$dn" -eq 1 ]; then
    mark="✓"; bar="$(_compact__bar 100 22)"; right="done"
    text=$(printf " %s  %-18s  ${C_WATER}%s${C_RESET}  %s" "$mark" "$nm" "$bar" "$right")
  else
    mark="⣿"
    if [ "$tot" -gt 0 ]; then
      local p=$(( (100 * cur) / tot )); (( p>100 )) && p=100
      bar="$(_compact__bar "$p" 22)"
      pct="$(printf "%3d%%" "$p")"
      right="$(printf "%s/%s  (%s)" "$(_compact__fmt_bytes "$cur")" "$(_compact__fmt_bytes "$tot")" "$pct")"
    else
      bar="$(_compact__bar 0 22)"; right="waiting"
    fi
    text=$(printf " %s  %-18s  ${C_WATER}%s${C_RESET}  %s" "$mark" "$nm" "$bar" "$right")
  fi
  printf "%-*s\n" "$cols" "$text"
}

compose_pull_compact_init() {
  _COMPACT_NAMES=(); _COMPACT_TOTALS=(); _COMPACT_CURS=(); _COMPACT_DONE=(); _COMPACT_IDXMAP=""
  local i nm tot
  for i in 1 2 3; do
    nm="${1:-item$i}"; tot="${2:-0}"; shift 2 || true
    _COMPACT_NAMES+=("$nm"); _COMPACT_TOTALS+=("$tot"); _COMPACT_CURS+=(0); _COMPACT_DONE+=(0)
  done
  for i in 0 1 2; do _COMPACT_IDXMAP="$_COMPACT_IDXMAP ${_COMPACT_NAMES[$i]}:$i"; done
  for i in 0 1 2; do _compact__line "$i"; done
}

compose_pull_compact_set() {
  local nm="$1" cur="${2:-0}" idx
  idx="$(_compact__index_of "$nm")"; [ "$idx" -lt 0 ] && return 0
  _COMPACT_CURS[$idx]="$cur"
  tput cuu "$_COMPACT_LINES" 2>/dev/null || printf "\033[%dA" "$_COMPACT_LINES"
  _compact__line 0; _compact__line 1; _compact__line 2
}

compose_pull_compact_done() {
  local nm="$1" idx
  idx="$(_compact__index_of "$nm")"; [ "$idx" -lt 0 ] && return 0
  _COMPACT_DONE[$idx]=1; _COMPACT_CURS[$idx]="${_COMPACT_TOTALS[$idx]}"
  tput cuu "$_COMPACT_LINES" 2>/dev/null || printf "\033[%dA" "$_COMPACT_LINES"
  _compact__line 0; _compact__line 1; _compact__line 2
}

compose_pull_compact_finish() { printf "\n"; }
# ================= End compact compose pull ==================================
