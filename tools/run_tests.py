#!/usr/bin/env python3
"""
VMwareGet Visual Test Runner
Runs Flutter unit & widget tests and formats the output into a modern,
visually intuitive dashboard with pixel-perfect category alignment and metrics.
"""

import subprocess
import json
import time
import sys
import os
import re
import unicodedata

# ANSI Color Codes
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"

GREEN = "\033[38;5;82m"
RED = "\033[38;5;196m"
YELLOW = "\033[38;5;220m"
CYAN = "\033[38;5;51m"
BLUE = "\033[38;5;39m"
MAGENTA = "\033[38;5;207m"
WHITE = "\033[38;5;255m"
GRAY = "\033[38;5;244m"
BG_GREEN = "\033[48;5;28m\033[38;5;255m"
BG_RED = "\033[48;5;124m\033[38;5;255m"

ANSI_REGEX = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]')


def strip_ansi(s: str) -> str:
    return ANSI_REGEX.sub('', s)


def char_width(ch: str) -> int:
    # Zero-width variation selectors
    if ch in '\uFE0E\uFE0F':
        return 0
    # Wide characters (East Asian Wide / Fullwidth)
    if unicodedata.east_asian_width(ch) in ('W', 'F'):
        return 2
    # Emojis and miscellaneous symbols that render as 2 cells
    code = ord(ch)
    if 0x1F300 <= code <= 0x1FAFF or 0x2600 <= code <= 0x27BF:
        return 2
    return 1


def visible_width(s: str) -> int:
    clean = strip_ansi(s)
    return sum(char_width(c) for c in clean)


def pad_visible(s: str, width: int, align: str = 'left') -> str:
    vw = visible_width(s)
    pad = max(0, width - vw)
    if align == 'left':
        return s + (' ' * pad)
    elif align == 'right':
        return (' ' * pad) + s
    else:  # center
        left = pad // 2
        right = pad - left
        return (' ' * left) + s + (' ' * right)


SUITE_CATEGORIES = {
    'auth_service_test.dart': ('🔐 Authentication & Session Security', CYAN),
    'catalog_service_test.dart': ('📦 Product Catalog & Dynamic Sync', BLUE),
    'download_provider_dir_test.dart': ('⚡ Multi-Threaded Download Engine', YELLOW),
    'checksum_service_test.dart': ('🛡️ Cryptographic Checksum Verification', GREEN),
    'locale_test.dart': ('🌐 Internationalization & Localization (I18n)', MAGENTA),
    'diagnostic_service_test.dart': ('🩺 Diagnostics & Logging Buffer', BLUE),
    'json_utils_test.dart': ('🧩 Data Utilities & JSON Serialization', GRAY),
    'widget_test.dart': ('📱 UI Component & App Smoke Test', CYAN),
}


def print_banner():
    width = 82
    print(f"\n{BOLD}{CYAN}╔{'═' * (width - 2)}╗{RESET}")
    title = "VMwareGet Automated Test Suite"
    subtitle = "Live Flutter Verification & Quality Assurance"
    print(f"{BOLD}{CYAN}║{RESET}{BOLD}{WHITE}{title.center(width - 2)}{RESET}{BOLD}{CYAN}║{RESET}")
    print(f"{BOLD}{CYAN}║{RESET}{DIM}{subtitle.center(width - 2)}{RESET}{BOLD}{CYAN}║{RESET}")
    print(f"{BOLD}{CYAN}╚{'═' * (width - 2)}╝{RESET}\n")


def run_tests():
    print_banner()

    start_wall_time = time.time()
    cmd = ["flutter", "test", "--reporter=json"]

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
    )

    suites = {}        # suiteID -> filename
    tests = {}         # testID -> {'name': str, 'suiteID': int, 'startTime': int}
    suite_stats = {}   # filename -> {'total': 0, 'passed': 0, 'failed': 0, 'tests': []}
    failures = []

    current_suite_file = None

    for line in iter(process.stdout.readline, ''):
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        evt_type = event.get('type')

        if evt_type == 'suite':
            suite_data = event.get('suite', {})
            s_id = suite_data.get('id')
            path = suite_data.get('path', '')
            fname = os.path.basename(path)
            suites[s_id] = fname
            if fname not in suite_stats:
                suite_stats[fname] = {'total': 0, 'passed': 0, 'failed': 0, 'tests': []}

        elif evt_type == 'testStart':
            test_data = event.get('test', {})
            t_id = test_data.get('id')
            t_name = test_data.get('name', '')
            s_id = test_data.get('suiteID')
            tests[t_id] = {
                'name': t_name,
                'suiteID': s_id,
                'startTime': event.get('time', 0),
            }

        elif evt_type == 'testDone':
            t_id = event.get('testID')
            t_info = tests.get(t_id)
            if not t_info:
                continue

            name = t_info['name']
            s_id = t_info['suiteID']
            fname = suites.get(s_id, 'unknown')

            # Filter out framework internal loading/smoke meta-tests
            if name.startswith('loading /') or not fname or fname == 'unknown':
                continue

            # Strip full path prefixes that flutter test adds to test names
            if ': ' in name:
                parts = name.split(': ', 1)
                clean_name = parts[1]
            else:
                clean_name = name

            is_hidden = event.get('hidden', False)
            if is_hidden:
                continue

            result = event.get('result')  # 'success', 'failure', 'error'
            duration_ms = event.get('time', 0) - t_info.get('startTime', 0)
            if duration_ms < 0:
                duration_ms = 0

            # Switch category banner if new suite
            if current_suite_file != fname:
                current_suite_file = fname
                meta = SUITE_CATEGORIES.get(fname, (f'📄 {fname}', WHITE))
                category_title, cat_color = meta
                print(f"\n{BOLD}{cat_color}▶ {category_title}{RESET} {DIM}(test/{fname}){RESET}")

            stats = suite_stats[fname]
            stats['total'] += 1

            if result == 'success':
                stats['passed'] += 1
                badge = f"{GREEN}✔ PASS{RESET}"
                time_str = f"{DIM}{duration_ms}ms{RESET}"
                print(f"  {badge}  {WHITE}{clean_name}{RESET}  {time_str}")
            else:
                stats['failed'] += 1
                badge = f"{RED}✖ FAIL{RESET}"
                print(f"  {badge}  {BOLD}{RED}{clean_name}{RESET}  ({duration_ms}ms)")
                failures.append((fname, clean_name))

        elif evt_type == 'error':
            err_msg = event.get('error', '')
            if err_msg:
                failures.append(('Error', err_msg))

    process.wait()
    total_elapsed = time.time() - start_wall_time

    # Calculate overall aggregates
    total_tests = sum(s['total'] for s in suite_stats.values())
    total_passed = sum(s['passed'] for s in suite_stats.values())
    total_failed = sum(s['failed'] for s in suite_stats.values())

    pass_rate = (total_passed / total_tests * 100) if total_tests > 0 else 0.0

    # Layout Column Dimensions
    col1_w = 48
    col2_w = 7
    col3_w = 7
    col4_w = 7
    total_inner = col1_w + col2_w + col3_w + col4_w + 9  # 78 cells between outer borders

    # Print Summary Table
    print("\n")
    top_border = f"{BOLD}{GRAY}┌{'─' * (total_inner + 2)}┐{RESET}"
    div_header = f"{BOLD}{GRAY}├{'─' * (col1_w + 2)}┬{'─' * (col2_w + 2)}┬{'─' * (col3_w + 2)}┬{'─' * (col4_w + 2)}┤{RESET}"
    div_cross = f"{BOLD}{GRAY}├{'─' * (col1_w + 2)}┼{'─' * (col2_w + 2)}┼{'─' * (col3_w + 2)}┼{'─' * (col4_w + 2)}┤{RESET}"
    div_mid = f"{BOLD}{GRAY}├{'─' * (total_inner + 2)}┤{RESET}"
    bot_border = f"{BOLD}{GRAY}└{'─' * (total_inner + 2)}┘{RESET}"

    print(top_border)
    dash_title = pad_visible("TEST EXECUTION SUMMARY DASHBOARD", total_inner, 'center')
    print(f"{BOLD}{GRAY}│{RESET} {BOLD}{WHITE}{dash_title}{RESET} {BOLD}{GRAY}│{RESET}")
    print(div_header)

    h1 = pad_visible("Test Suite Category", col1_w, 'left')
    h2 = pad_visible("Total", col2_w, 'right')
    h3 = pad_visible("Pass", col3_w, 'right')
    h4 = pad_visible("Fail", col4_w, 'right')
    print(f"{BOLD}{GRAY}│{RESET} {BOLD}{WHITE}{h1}{RESET} {BOLD}{GRAY}│{RESET} {BOLD}{WHITE}{h2}{RESET} {BOLD}{GRAY}│{RESET} {BOLD}{GREEN}{h3}{RESET} {BOLD}{GRAY}│{RESET} {BOLD}{RED}{h4}{RESET} {BOLD}{GRAY}│{RESET}")
    print(div_cross)

    for fname, stats in suite_stats.items():
        if stats['total'] == 0:
            continue
        meta = SUITE_CATEGORIES.get(fname, (f'📄 {fname}', WHITE))
        category_title = meta[0]

        c1 = pad_visible(category_title, col1_w, 'left')
        c2 = pad_visible(str(stats['total']), col2_w, 'right')
        c3 = pad_visible(str(stats['passed']), col3_w, 'right')
        c4 = pad_visible(str(stats['failed']), col4_w, 'right')

        fail_color = RED if stats['failed'] > 0 else GRAY
        print(f"{BOLD}{GRAY}│{RESET} {WHITE}{c1}{RESET} {BOLD}{GRAY}│{RESET} {c2} {BOLD}{GRAY}│{RESET} {GREEN}{c3}{RESET} {BOLD}{GRAY}│{RESET} {fail_color}{c4}{RESET} {BOLD}{GRAY}│{RESET}")

    print(div_mid)

    # Overall Verdict Line
    if total_failed == 0 and total_tests > 0:
        verdict = f"{BG_GREEN}  ALL {total_passed} TESTS PASSED  {RESET} {BOLD}{GREEN}✓ 100% Quality Gate Satisfied{RESET}"
    else:
        verdict = f"{BG_RED}  {total_failed} TESTS FAILED  {RESET} {BOLD}{RED}✖ Needs Attention{RESET}"

    metrics = f"Passed: {BOLD}{GREEN}{total_passed}{RESET}  Failed: {BOLD}{RED}{total_failed}{RESET}  Rate: {BOLD}{CYAN}{pass_rate:.1f}%{RESET}  Time: {BOLD}{YELLOW}{total_elapsed:.2f}s{RESET}"

    line_verdict = pad_visible(verdict, total_inner, 'left')
    line_metrics = pad_visible(metrics, total_inner, 'left')

    print(f"{BOLD}{GRAY}│{RESET} {line_verdict} {BOLD}{GRAY}│{RESET}")
    print(f"{BOLD}{GRAY}│{RESET} {line_metrics} {BOLD}{GRAY}│{RESET}")
    print(bot_border)
    print("\n")

    return 0 if total_failed == 0 else 1


if __name__ == '__main__':
    sys.exit(run_tests())
