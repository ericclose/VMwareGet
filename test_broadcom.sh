#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Suppress LibreSSL warnings on macOS
export PYTHONWARNINGS="ignore"

if [ ! -d ".venv" ]; then
  echo "[*] Initializing python environment..."
  python3 -m venv .venv
  .venv/bin/pip install "urllib3<2.0.0" beautifulsoup4 requests cryptography pycryptodome playwright
fi

if [ "$1" = "login-browser" ] || [ "$1" = "playwright" ]; then
  shift
  exec .venv/bin/python3 -W ignore tools/playwright_login.py "$@"
fi

if [ "$1" = "login" ]; then
  shift
  exec .venv/bin/python3 -W ignore tools/broadcom_login_tester.py "$@"
fi

exec .venv/bin/python3 -W ignore tools/broadcom_tester.py "$@"
