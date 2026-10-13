#!/usr/bin/env python3
"""
VMwareGet Visual Test Runner
Runs Flutter unit & widget tests and formats the output into a modern,
visually intuitive dashboard with mathematically guaranteed vertical alignment.
"""

import subprocess
import json
import time
import sys
import os

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

# Suite Categories:
# 1st item: Display heading for test execution stream (can use emojis)
# 2nd item: Table label inside the boxed dashboard (pure ASCII for 100% monospace font safety)
# 3rd item: Theme color
SUITE_CATEGORIES = {
    'auth_service_test.dart': (
        '🔐 Authentication & Session Security',
        '[AUTH]     Authentication & Session Security',
        CYAN,
    ),
    'catalog_service_test.dart': (
        '📦 Product Catalog & Dynamic Sync',
        '[CATALOG]  Product Catalog & Dynamic Sync',
        BLUE,
    ),
    'download_provider_dir_test.dart': (
        '⚡ Multi-Threaded Download Engine',
        '[DOWNLOAD] Multi-Threaded Download Engine',
        YELLOW,
    ),
    'checksum_service_test.dart': (
        '🛡️ Cryptographic Checksum Verification',
        '[CHECKSUM] Cryptographic Checksum Verification',
        GREEN,
    ),
    'locale_test.dart': (
        '🌐 Internationalization & Localization (I18n)',
        '[I18N]     Internationalization & Localization',
        MAGENTA,
    ),
    'diagnostic_service_test.dart': (
        '🩺 Diagnostics & Logging Buffer',
        '[DIAG]     Diagnostics & Logging Buffer',
        BLUE,
    ),
    'json_utils_test.dart': (
        '🧩 Data Utilities & JSON Serialization',
        '[UTILS]    Data Utilities & JSON Serialization',
        GRAY,
    ),
    'widget_test.dart': (
        '📱 UI Component & App Smoke Test',
        '[SMOKE]    UI Component & App Smoke Test',
        CYAN,
    ),
}


def pad_str(s: str, width: int, align: str = 'left') -> str:
    """Pad pure ASCII string to exact width."""
    if align == 'left':
        return s + ' ' * max(0, width - len(s))
    elif align == 'right':
        return ' ' * max(0, width - len(s)) + s
    else:  # center
        p = max(0, width - len(s))
        return ' ' * (p // 2) + s + ' ' * (p - p // 2)


def print_banner():
    width = 78
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
                meta = SUITE_CATEGORIES.get(
                    fname,
                    (f'📄 {fname}', f'[{fname}]', WHITE)
                )
                category_heading, _, cat_color = meta
                print(f"\n{BOLD}{cat_color}▶ {category_heading}{RESET} {DIM}(test/{fname}){RESET}")

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

    # Strict column dimensions for 100% monospace alignment
    col1_w = 46
    col2_w = 7
    col3_w = 7
    col4_w = 7
    total_inner = col1_w + col2_w + col3_w + col4_w + 9  # 76 columns between borders

    print("\n")
    top_border = f"{BOLD}{GRAY}┌{'─' * (total_inner + 2)}┐{RESET}"
    div_header = f"{BOLD}{GRAY}├{'─' * (col1_w + 2)}┬{'─' * (col2_w + 2)}┬{'─' * (col3_w + 2)}┬{'─' * (col4_w + 2)}┤{RESET}"
    div_cross = f"{BOLD}{GRAY}├{'─' * (col1_w + 2)}┼{'─' * (col2_w + 2)}┼{'─' * (col3_w + 2)}┼{'─' * (col4_w + 2)}┤{RESET}"
    div_mid = f"{BOLD}{GRAY}├{'─' * (total_inner + 2)}┤{RESET}"
    bot_border = f"{BOLD}{GRAY}└{'─' * (total_inner + 2)}┘{RESET}"
    v_border = f"{BOLD}{GRAY}│{RESET}"

    print(top_border)
    dash_title = pad_str("TEST EXECUTION SUMMARY DASHBOARD", total_inner, 'center')
    print(f"{v_border} {BOLD}{WHITE}{dash_title}{RESET} {v_border}")
    print(div_header)

    h1 = pad_str("Test Suite Category", col1_w, 'left')
    h2 = pad_str("Total", col2_w, 'right')
    h3 = pad_str("Pass", col3_w, 'right')
    h4 = pad_str("Fail", col4_w, 'right')
    print(f"{v_border} {BOLD}{WHITE}{h1}{RESET} {v_border} {BOLD}{WHITE}{h2}{RESET} {v_border} {BOLD}{GREEN}{h3}{RESET} {v_border} {BOLD}{RED}{h4}{RESET} {v_border}")
    print(div_cross)

    for fname, stats in suite_stats.items():
        if stats['total'] == 0:
            continue
        meta = SUITE_CATEGORIES.get(
            fname,
            (f'📄 {fname}', pad_str(f'[{fname}]', col1_w), WHITE)
        )
        table_label = meta[1]

        c1 = pad_str(table_label, col1_w, 'left')
        c2 = pad_str(str(stats['total']), col2_w, 'right')
        c3 = pad_str(str(stats['passed']), col3_w, 'right')
        c4 = pad_str(str(stats['failed']), col4_w, 'right')

        fail_color = RED if stats['failed'] > 0 else GRAY
        print(f"{v_border} {WHITE}{c1}{RESET} {v_border} {c2} {v_border} {GREEN}{c3}{RESET} {v_border} {fail_color}{c4}{RESET} {v_border}")

    print(div_mid)

    # Overall Verdict Line (computed length ensures exact alignment)
    if total_failed == 0 and total_tests > 0:
        v_plain = f"  ALL {total_passed} TESTS PASSED    [OK] 100% Quality Gate Satisfied"
        v_pad = " " * max(0, total_inner - len(v_plain))
        line_verdict = f"{BG_GREEN}  ALL {total_passed} TESTS PASSED  {RESET}  {BOLD}{GREEN}[OK] 100% Quality Gate Satisfied{RESET}{v_pad}"
    else:
        v_plain = f"  {total_failed} TESTS FAILED    [FAIL] Quality Gate Violated"
        v_pad = " " * max(0, total_inner - len(v_plain))
        line_verdict = f"{BG_RED}  {total_failed} TESTS FAILED  {RESET}  {BOLD}{RED}[FAIL] Quality Gate Violated{RESET}{v_pad}"

    # Metrics Line
    m_plain = f"Passed: {total_passed}   Failed: {total_failed}   Rate: {pass_rate:.1f}%   Time: {total_elapsed:.2f}s"
    m_pad = " " * max(0, total_inner - len(m_plain))
    f_color = RED if total_failed > 0 else GRAY
    line_metrics = f"Passed: {BOLD}{GREEN}{total_passed}{RESET}   Failed: {BOLD}{f_color}{total_failed}{RESET}   Rate: {BOLD}{CYAN}{pass_rate:.1f}%{RESET}   Time: {BOLD}{YELLOW}{total_elapsed:.2f}s{RESET}{m_pad}"

    print(f"{v_border} {line_verdict} {v_border}")
    print(f"{v_border} {line_metrics} {v_border}")
    print(bot_border)
    print("\n")

    return 0 if total_failed == 0 else 1


if __name__ == '__main__':
    sys.exit(run_tests())
