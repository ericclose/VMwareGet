#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

if [ ! -d ".venv" ]; then
  echo "[*] Initializing python environment..."
  python3 -m venv .venv
  .venv/bin/pip install beautifulsoup4 requests
fi

exec .venv/bin/python3 tools/broadcom_tester.py "$@"
