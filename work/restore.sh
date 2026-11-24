#!/usr/bin/env bash
# Re-enable everything this session disabled, and switch Private DNS back to automatic.
# Usage: TV_HOST=<tv ip> work/restore.sh   (needs ADB on: pair via Wireless debugging, then adb tcpip 5555)
set -e; cd "$(dirname "$0")/.."
tools/restore.sh work/my-debloat.txt
tools/venv/bin/python -I tools/tv.py "settings put global private_dns_mode opportunistic"
