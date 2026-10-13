#!/bin/bash
set -e

# Run VMwareGet Visual Test Suite
python3 "$(dirname "$0")/tools/run_tests.py" "$@"
