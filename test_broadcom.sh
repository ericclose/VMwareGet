#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# Prefer modern OpenSSL-backed Python 3 from Homebrew if available
PYTHON_BIN="python3"
if [ -x "/opt/homebrew/bin/python3.14" ]; then
  PYTHON_BIN="/opt/homebrew/bin/python3.14"
elif [ -x "/opt/homebrew/bin/python3" ]; then
  PYTHON_BIN="/opt/homebrew/bin/python3"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3)"
fi

if [ ! -d ".venv" ]; then
  echo "[*] Initializing python environment with $PYTHON_BIN..."
  "$PYTHON_BIN" -m venv .venv
  .venv/bin/pip install beautifulsoup4 requests urllib3 cryptography pycryptodome playwright
fi

if [ "$1" = "login-browser" ] || [ "$1" = "playwright" ]; then
  shift
  exec .venv/bin/python3 tools/playwright_login.py "$@"
fi

if [ "$1" = "login" ]; then
  shift
  exec .venv/bin/python3 tools/broadcom_login_tester.py "$@"
fi

exec .venv/bin/python3 tools/broadcom_tester.py "$@"
