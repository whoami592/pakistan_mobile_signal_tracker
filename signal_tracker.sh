#!/usr/bin/env bash
# Pakistan Mobile Signal Tracker
# Coded by Cyber Security Engineer Mr Sabaz Ali Khan
# Purpose: Monitor signal quality and internet health on devices/networks you own or are authorized to test.

set -u

APP_NAME="Pakistan Mobile Signal Tracker"
VERSION="1.0.0"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$BASE_DIR/logs"
REPORT_DIR="$BASE_DIR/reports"
LOG_FILE="$LOG_DIR/signal_log_$(date +%Y-%m-%d).csv"
DEFAULT_INTERVAL=10
PING_TARGET="1.1.1.1"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

# ANSI colors (disabled automatically when output is not a terminal)
if [[ -t 1 ]]; then
  C1='\033[1;36m'; C2='\033[1;32m'; C3='\033[1;33m'; C4='\033[1;31m'; B='\033[1m'; R='\033[0m'
else
  C1=''; C2=''; C3=''; C4=''; B=''; R=''
fi

banner() {
  printf "%b" "$C1"
  cat <<'BANNER'
⠉⠉⠉⠉⠁⠀⠀⠀⠀⠒⠂⠰⠤⢤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠻⢤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠠⠀⠐⠒⠒⠀⠀⠈⠉⠉⠉⠉⢉⣉⣉⣉⣙⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⡀⠤⠒⠒⠉⠁⠀⠀⠀⠀⠳⣤⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⠛⠛⠉⠛⠛⠶⢦⣤⡐⢀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⠁⠀⠀⠀⠀⠀⠀⠀⠈⠉⢳⣦⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠳⡤⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢷⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠙⠛⠛⠳⠶⢶⣦⠤⣄⡀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠳⣄⠉⠑⢄⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⡀⠀⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠱⡄⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄
BANNER
  printf "%b\n" "$R${B}${APP_NAME} v${VERSION}${R}"
  printf "%b\n\n" "${C2}Coded by Cyber Security Engineer Mr Sabaz Ali Khan${R}"
}

have() { command -v "$1" >/dev/null 2>&1; }
trim() { awk '{$1=$1;print}' <<<"${1:-}"; }

platform() {
  if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == *com.termux* ]]; then
    echo "Termux/Android"
  elif [[ "$(uname -s 2>/dev/null || true)" == "Linux" ]]; then
    echo "Linux"
  else
    echo "Unknown"
  fi
}

signal_grade_dbm() {
  local dbm="${1:-}"
  [[ "$dbm" =~ ^-?[0-9]+$ ]] || { echo "Unknown"; return; }
  if (( dbm >= -85 )); then echo "Excellent"
  elif (( dbm >= -95 )); then echo "Good"
  elif (( dbm >= -105 )); then echo "Fair"
  elif (( dbm >= -115 )); then echo "Weak"
  else echo "Very Weak"
  fi
}

signal_grade_percent() {
  local p="${1:-}"
  [[ "$p" =~ ^[0-9]+$ ]] || { echo "Unknown"; return; }
  if (( p >= 80 )); then echo "Excellent"
  elif (( p >= 60 )); then echo "Good"
  elif (( p >= 40 )); then echo "Fair"
  elif (( p >= 20 )); then echo "Weak"
  else echo "Very Weak"
  fi
}

active_interface() {
  if have ip; then
    ip route 2>/dev/null | awk '/^default/ {print $5; exit}'
  else
    echo "N/A"
  fi
}

get_ip_local() {
  local iface
  iface="$(active_interface)"
  if have ip && [[ -n "$iface" && "$iface" != "N/A" ]]; then
    ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet / {print $2; exit}' | cut -d/ -f1
  else
    echo "N/A"
  fi
}

# Returns: carrier|technology|signal_value|unit|grade|source
get_mobile_signal_termux() {
  local cell="" dev="" carrier="N/A" tech="N/A" dbm="" grade="Unknown"

  if have termux-telephony-cellinfo; then
    cell="$(termux-telephony-cellinfo 2>/dev/null || true)"
  fi
  if have termux-telephony-deviceinfo; then
    dev="$(termux-telephony-deviceinfo 2>/dev/null || true)"
  fi

  if [[ -n "$dev" ]] && have jq; then
    carrier="$(jq -r '(.network_operator_name // .networkOperatorName // .sim_operator_name // .simOperatorName // empty)' <<<"$dev" 2>/dev/null | head -n1)"
    [[ -n "$carrier" ]] || carrier="N/A"
  fi

  if [[ -n "$cell" ]] && have jq; then
    # Flexible parsing across Termux:API versions. Deliberately ignores Cell ID/TAC/location fields.
    tech="$(jq -r 'if type=="array" then ([.[]|select(.registered==true)][0] // .[0]) else . end | (.type // .network_type // .networkType // empty)' <<<"$cell" 2>/dev/null | head -n1)"
    dbm="$(jq -r '.. | objects | select(has("dbm")) | .dbm' <<<"$cell" 2>/dev/null | head -n1)"
    [[ -n "$tech" ]] || tech="Mobile"
  fi

  if [[ "$dbm" =~ ^-?[0-9]+$ ]]; then
    grade="$(signal_grade_dbm "$dbm")"
    echo "$carrier|$tech|$dbm|dBm|$grade|Termux:API"
  else
    echo "$carrier|$tech|N/A|dBm|Unknown|Termux:API"
  fi
}

get_mobile_signal_linux() {
  local modem_id="" out="" carrier="N/A" tech="N/A" quality="" grade="Unknown"
  if have mmcli; then
    modem_id="$(mmcli -L 2>/dev/null | sed -n 's#.*Modem/\([0-9]\+\).*#\1#p' | head -n1)"
    if [[ -n "$modem_id" ]]; then
      out="$(mmcli -m "$modem_id" --output-keyvalue 2>/dev/null || true)"
      carrier="$(awk -F': ' '/modem\.3gpp\.operator-name/ {print $2; exit}' <<<"$out")"
      tech="$(awk -F': ' '/modem\.generic\.access-technologies/ {print $2; exit}' <<<"$out")"
      quality="$(awk -F': ' '/modem\.generic\.signal-quality\.value/ {gsub(/[^0-9]/,"",$2); print $2; exit}' <<<"$out")"
      [[ -n "$carrier" ]] || carrier="N/A"
      [[ -n "$tech" ]] || tech="Mobile"
      if [[ "$quality" =~ ^[0-9]+$ ]]; then
        grade="$(signal_grade_percent "$quality")"
        echo "$carrier|$tech|$quality|%|$grade|ModemManager"
        return
      fi
    fi
  fi
  echo "N/A|N/A|N/A|%|Unknown|No supported cellular modem API"
}

get_wifi_signal() {
  local line ssid sig grade
  if have nmcli; then
    line="$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes" {print; exit}')"
    if [[ -n "$line" ]]; then
      ssid="$(cut -d: -f2 <<<"$line")"
      sig="$(cut -d: -f3 <<<"$line")"
      grade="$(signal_grade_percent "$sig")"
      echo "$ssid|$sig|%|$grade|NetworkManager"
      return
    fi
  fi
  if have termux-wifi-connectioninfo && have jq; then
    local j rssi
    j="$(termux-wifi-connectioninfo 2>/dev/null || true)"
    ssid="$(jq -r '.ssid // "N/A"' <<<"$j" 2>/dev/null)"
    rssi="$(jq -r '.rssi // empty' <<<"$j" 2>/dev/null)"
    if [[ "$rssi" =~ ^-?[0-9]+$ ]]; then
      grade="$(signal_grade_dbm "$rssi")"
      echo "$ssid|$rssi|dBm|$grade|Termux:API"
      return
    fi
  fi
  echo "N/A|N/A|%|Unknown|Unavailable"
}

ping_metrics() {
  local out loss avg
  if ! have ping; then echo "N/A|N/A"; return; fi
  out="$(ping -c 4 -W 2 "$PING_TARGET" 2>/dev/null || true)"
  loss="$(sed -n 's/.* \([0-9][0-9]*\)% packet loss.*/\1/p' <<<"$out" | tail -n1)"
  avg="$(awk -F'/' '/^rtt|^round-trip/ {print $5; exit}' <<<"$out")"
  [[ -n "$loss" ]] || loss="100"
  [[ -n "$avg" ]] || avg="N/A"
  echo "$loss|$avg"
}

collect_snapshot() {
  local ts plat iface ip mobile wifi pingv
  local carrier tech sval sunit sgrade ssource
  local ssid wsig wunit wgrade wsource
  local loss latency

  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  plat="$(platform)"
  iface="$(active_interface)"; [[ -n "$iface" ]] || iface="N/A"
  ip="$(get_ip_local)"; [[ -n "$ip" ]] || ip="N/A"

  if [[ "$plat" == "Termux/Android" ]]; then
    mobile="$(get_mobile_signal_termux)"
  else
    mobile="$(get_mobile_signal_linux)"
  fi
  IFS='|' read -r carrier tech sval sunit sgrade ssource <<<"$mobile"

  wifi="$(get_wifi_signal)"
  IFS='|' read -r ssid wsig wunit wgrade wsource <<<"$wifi"

  pingv="$(ping_metrics)"
  IFS='|' read -r loss latency <<<"$pingv"

  SNAP_TS="$ts"; SNAP_PLATFORM="$plat"; SNAP_IFACE="$iface"; SNAP_IP="$ip"
  SNAP_CARRIER="$carrier"; SNAP_TECH="$tech"; SNAP_SIGNAL="$sval"; SNAP_SIGNAL_UNIT="$sunit"; SNAP_GRADE="$sgrade"; SNAP_SOURCE="$ssource"
  SNAP_SSID="$ssid"; SNAP_WIFI_SIGNAL="$wsig"; SNAP_WIFI_UNIT="$wunit"; SNAP_WIFI_GRADE="$wgrade"; SNAP_WIFI_SOURCE="$wsource"
  SNAP_LOSS="$loss"; SNAP_LATENCY="$latency"
}

show_snapshot() {
  collect_snapshot
  printf "%b\n" "${B}${C1}=== Signal & Internet Snapshot ===${R}"
  printf "Time              : %s\n" "$SNAP_TS"
  printf "Platform          : %s\n" "$SNAP_PLATFORM"
  printf "Active interface  : %s\n" "$SNAP_IFACE"
  printf "Local IPv4        : %s\n" "$SNAP_IP"
  printf "Mobile carrier    : %s\n" "$SNAP_CARRIER"
  printf "Mobile technology : %s\n" "$SNAP_TECH"
  printf "Mobile signal     : %s %s (%s)\n" "$SNAP_SIGNAL" "$SNAP_SIGNAL_UNIT" "$SNAP_GRADE"
  printf "Mobile source     : %s\n" "$SNAP_SOURCE"
  printf "Wi-Fi SSID        : %s\n" "$SNAP_SSID"
  printf "Wi-Fi signal      : %s %s (%s)\n" "$SNAP_WIFI_SIGNAL" "$SNAP_WIFI_UNIT" "$SNAP_WIFI_GRADE"
  printf "Packet loss       : %s%%\n" "$SNAP_LOSS"
  printf "Avg latency       : %s ms to %s\n" "$SNAP_LATENCY" "$PING_TARGET"
}

csv_escape() {
  local s="${1//\"/\"\"}"
  printf '"%s"' "$s"
}

ensure_csv_header() {
  if [[ ! -f "$LOG_FILE" ]]; then
    echo 'timestamp,platform,interface,local_ipv4,carrier,technology,mobile_signal,mobile_unit,mobile_grade,wifi_ssid,wifi_signal,wifi_unit,wifi_grade,packet_loss_percent,avg_latency_ms' > "$LOG_FILE"
  fi
}

log_snapshot() {
  collect_snapshot
  ensure_csv_header
  {
    csv_escape "$SNAP_TS"; printf ','
    csv_escape "$SNAP_PLATFORM"; printf ','
    csv_escape "$SNAP_IFACE"; printf ','
    csv_escape "$SNAP_IP"; printf ','
    csv_escape "$SNAP_CARRIER"; printf ','
    csv_escape "$SNAP_TECH"; printf ','
    csv_escape "$SNAP_SIGNAL"; printf ','
    csv_escape "$SNAP_SIGNAL_UNIT"; printf ','
    csv_escape "$SNAP_GRADE"; printf ','
    csv_escape "$SNAP_SSID"; printf ','
    csv_escape "$SNAP_WIFI_SIGNAL"; printf ','
    csv_escape "$SNAP_WIFI_UNIT"; printf ','
    csv_escape "$SNAP_WIFI_GRADE"; printf ','
    csv_escape "$SNAP_LOSS"; printf ','
    csv_escape "$SNAP_LATENCY"; printf '\n'
  } >> "$LOG_FILE"
}

live_dashboard() {
  local interval="${1:-$DEFAULT_INTERVAL}"
  [[ "$interval" =~ ^[0-9]+$ ]] || interval="$DEFAULT_INTERVAL"
  (( interval < 2 )) && interval=2
  trap 'printf "\nStopped.\n"; return' INT
  while true; do
    clear 2>/dev/null || true
    banner
    show_snapshot
    printf "\nRefreshing every %ss. Press Ctrl+C to stop.\n" "$interval"
    sleep "$interval"
  done
}

start_logging() {
  local interval="${1:-$DEFAULT_INTERVAL}"
  [[ "$interval" =~ ^[0-9]+$ ]] || interval="$DEFAULT_INTERVAL"
  (( interval < 5 )) && interval=5
  printf "Logging to: %s\nPress Ctrl+C to stop.\n" "$LOG_FILE"
  trap 'printf "\nLogging stopped.\n"; return' INT
  while true; do
    log_snapshot
    printf '[%s] saved signal sample\n' "$(date '+%H:%M:%S')"
    sleep "$interval"
  done
}

network_interfaces() {
  if have ip; then
    ip -brief address 2>/dev/null || true
  elif have ifconfig; then
    ifconfig
  else
    echo "Install 'iproute2' to list interfaces."
  fi
}

recent_logs() {
  if [[ -f "$LOG_FILE" ]]; then
    tail -n 15 "$LOG_FILE"
  else
    echo "No log file for today yet."
  fi
}

export_summary() {
  local report="$REPORT_DIR/summary_$(date +%Y%m%d_%H%M%S).txt"
  collect_snapshot
  {
    echo "$APP_NAME v$VERSION"
    echo "Coded by Cyber Security Engineer Mr Sabaz Ali Khan"
    echo "Generated: $SNAP_TS"
    echo
    echo "Platform: $SNAP_PLATFORM"
    echo "Interface: $SNAP_IFACE"
    echo "Local IPv4: $SNAP_IP"
    echo "Carrier: $SNAP_CARRIER"
    echo "Technology: $SNAP_TECH"
    echo "Mobile signal: $SNAP_SIGNAL $SNAP_SIGNAL_UNIT ($SNAP_GRADE)"
    echo "Wi-Fi: $SNAP_SSID / $SNAP_WIFI_SIGNAL $SNAP_WIFI_UNIT ($SNAP_WIFI_GRADE)"
    echo "Packet loss: $SNAP_LOSS%"
    echo "Average latency: $SNAP_LATENCY ms to $PING_TARGET"
    echo
    echo "Privacy note: this tool does not collect GPS coordinates, Cell ID, TAC, IMSI, phone numbers, messages, or call contents."
  } > "$report"
  echo "Saved report: $report"
}

check_dependencies() {
  echo "Platform: $(platform)"
  echo
  for cmd in bash ping ip jq; do
    if have "$cmd"; then printf '[OK]   %s\n' "$cmd"; else printf '[MISS] %s\n' "$cmd"; fi
  done
  if [[ "$(platform)" == "Termux/Android" ]]; then
    for cmd in termux-telephony-cellinfo termux-telephony-deviceinfo termux-wifi-connectioninfo; do
      if have "$cmd"; then printf '[OK]   %s\n' "$cmd"; else printf '[MISS] %s\n' "$cmd"; fi
    done
  else
    for cmd in mmcli nmcli; do
      if have "$cmd"; then printf '[OK]   %s\n' "$cmd"; else printf '[MISS] %s (optional)\n' "$cmd"; fi
    done
  fi
}

usage() {
  cat <<EOF2
Usage: $0 [option]

Options:
  --scan                 Run one signal/internet scan
  --live [seconds]       Live dashboard (default: $DEFAULT_INTERVAL seconds)
  --log [seconds]        Continuously log to CSV (minimum: 5 seconds)
  --interfaces           Show local network interfaces
  --recent               Show recent CSV records
  --report               Export a text summary report
  --check                Check dependencies
  --help                 Show this help

This utility monitors only the local device/network you run it on.
EOF2
}

menu() {
  while true; do
    clear 2>/dev/null || true
    banner
    cat <<'MENU'
[1] One-time signal scan
[2] Live dashboard
[3] Start CSV logging
[4] Show network interfaces
[5] Show recent logs
[6] Export summary report
[7] Check dependencies
[8] Exit
MENU
    printf "\nSelect: "
    read -r choice
    case "$choice" in
      1) show_snapshot; read -r -p "Press Enter..." _ ;;
      2) printf "Refresh interval seconds [10]: "; read -r i; live_dashboard "${i:-10}" ;;
      3) printf "Log interval seconds [10]: "; read -r i; start_logging "${i:-10}" ;;
      4) network_interfaces; read -r -p "Press Enter..." _ ;;
      5) recent_logs; read -r -p "Press Enter..." _ ;;
      6) export_summary; read -r -p "Press Enter..." _ ;;
      7) check_dependencies; read -r -p "Press Enter..." _ ;;
      8) exit 0 ;;
      *) echo "Invalid option"; sleep 1 ;;
    esac
  done
}

case "${1:-}" in
  --scan) show_snapshot ;;
  --live) live_dashboard "${2:-$DEFAULT_INTERVAL}" ;;
  --log) start_logging "${2:-$DEFAULT_INTERVAL}" ;;
  --interfaces) network_interfaces ;;
  --recent) recent_logs ;;
  --report) export_summary ;;
  --check) check_dependencies ;;
  --help|-h) usage ;;
  "") menu ;;
  *) usage; exit 1 ;;
esac
