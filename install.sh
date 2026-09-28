#!/usr/bin/env bash
set -e

echo "Pakistan Mobile Signal Tracker - dependency installer"

if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == *com.termux* ]]; then
  echo "Detected Termux/Android"
  pkg update -y
  pkg install -y bash iproute2 iputils jq termux-api
  echo
  echo "IMPORTANT: Install the matching Termux:API Android app and grant Phone/Wi-Fi permissions."
  echo "Then run: ./signal_tracker.sh --check"
elif command -v apt >/dev/null 2>&1; then
  echo "Detected Debian/Ubuntu/Kali style Linux"
  sudo apt update
  sudo apt install -y bash iproute2 iputils-ping jq network-manager modemmanager
  echo "Run: ./signal_tracker.sh --check"
else
  echo "Automatic installer supports Termux and apt-based Linux."
  echo "Please install: bash, iproute2, ping, jq; optional: NetworkManager and ModemManager."
fi
