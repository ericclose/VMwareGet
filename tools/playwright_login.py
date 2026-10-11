#!/usr/bin/env python3
"""
Broadcom Account Login via Playwright (Real Browser Automation)
Uses a real browser (Chromium) to execute genuine client fingerprinting (Canvas, WebGL, TLS),
handles Symantec Authentication Hub and Akamai Bot Manager, captures authenticated session cookies,
verifies live catalog retrieval & download order generation, and saves the session.
"""

import os
import sys
import json
import time
import getpass
import argparse
import requests
from playwright.sync_api import sync_playwright

SESSION_FILE = os.path.join(os.path.dirname(__file__), '.session.json')
LOGIN_START_URL = 'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true'


def verify_session_against_broadcom(cookies_dict, csrf_token='YaLAJUoR', email=''):
    print("\n" + "="*70)
    print(" [*] Verifying captured browser cookies against Broadcom live API...")
    print("="*70)

    s = requests.Session()
    s.headers.update({
        'User-Agent': (
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/155.0.0.0 Safari/537.36'
        ),
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json;charset=UTF-8',
        'Origin': 'https://support.broadcom.com',
        'x-csrf-token': csrf_token,
    })
    s.cookies.update(cookies_dict)

    # 1. Test catalog retrieval
    cat_url = 'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50'
    cat_payload = {
        'primaryDownloads': True,
        'otherDownloads': '',
        'searchQuery': '',
        'freeDownloads': True,
        'displayGroup': 'VMware Workstation Pro 26H1 for Windows',
        'skuCode': '',
        'release': '26H1u1',
        'genLevel': '546859',
        'language': 'EN',
        'os': '',
    }

    try:
        r_cat = s.post(cat_url, json=cat_payload, timeout=25)
        print(f" -> getDownloadableFiles status: HTTP {r_cat.status_code}")
        if r_cat.status_code == 200:
            data = r_cat.json()
            if data.get('success'):
                content = data.get('data', {}).get('packlistDetails', {}).get('content', [])
                if content:
                    f = content[0].get('fileDetails', [])[0]
                    print(" [+] Successfully retrieved online file metadata!")
                    print(f"     - File:   {f.get('fileName')}")
                    print(f"     - Size:   {f.get('fileSize')} bytes")
                    print(f"     - SHA256: {f.get('sha2Chksum')}")
                    print(f"     - MD5:    {f.get('md5Chksum')}")
            else:
                print(f" [!] API response: {data.get('message')}")
        else:
            print(f" [!] Catalog request failed: HTTP {r_cat.status_code}")
    except Exception as e:
        print(f" [!] Error verifying catalog: {e}")

    # 2. Test download order creation
    order_url = 'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/createProductDownloadOrder'
    order_payload = {
        'downloadType': 'HTTP',
        'productName': 'VMware Workstation Pro',
        'releaseDescription': 'VMware Workstation Pro (For Windows)',
        'skuCode': '',
        'displayGroup': 'VMware Workstation Pro 26H1 for Windows',
        'release': '26H1u1',
        'genLevel': '546859',
        'language': 'EN',
        'os': '',
        'eulaId': 17290717,
        'accessToken': False,
        'siteId': '105246',
        'orderedFiles': [{
            'filePath': '546859/VMware-Workstation-Full-26H1u1-25688693.exe',
            'fileSize': 280609368,
        }],
    }

    try:
        r_order = s.post(order_url, json=order_payload, timeout=25)
        print(f" -> createProductDownloadOrder status: HTTP {r_order.status_code}")
        if r_order.status_code == 200:
            order_data = r_order.json()
            d_url = order_data.get('data', {}).get('downloadUrl')
            if d_url:
                print(f" [+] Successfully created authorized download order!")
                print(f"     - CDN Download URL: {d_url[:80]}...")
                r_probe = s.get(d_url, headers={'Range': 'bytes=0-10'}, stream=True, timeout=15)
                print(f"     - Live CDN Stream probe: HTTP {r_probe.status_code} ({r_probe.headers.get('Content-Type')})")
                if r_probe.status_code in (200, 206):
                    print(" [✓] SESSION CONFIRMED FULLY FUNCTIONAL FOR ONLINE CATALOG & DOWNLOADS!")
                    return True
            else:
                print(f" [!] Download order non-200 payload: {order_data}")
        else:
            print(f" [!] Order request failed: HTTP {r_order.status_code}")
    except Exception as e:
        print(f" [!] Error testing download order: {e}")

    return False


def save_session(cookies_dict, csrf_token='YaLAJUoR', email=''):
    try:
        data = {
            'email': email,
            'cookies': cookies_dict,
            'headers': {
                'x-csrf-token': csrf_token,
            },
            'saved_at': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        }
        with open(SESSION_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        print(f" [✓] Authenticated session written to {SESSION_FILE}")
    except Exception as e:
        print(f" [!] Failed writing session file: {e}")


def run_playwright_login(email='', password='', headless=False):
    print("""
========================================================================
   Broadcom Account Login via Playwright (Real Browser Engine)
   VMwareGet Companion Tool
========================================================================
""")
    if not email:
        email = input(" [?] Enter Broadcom Account Email: ").strip()
    if not password:
        password = getpass.getpass(" [?] Enter Broadcom Account Password: ").strip()

    print(f"\n [*] Launching Chromium browser (Headless={headless})...")

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=headless,
            args=[
                '--disable-blink-features=AutomationControlled',
                '--start-maximized',
            ],
        )

        context = browser.new_context(
            user_agent=(
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/155.0.0.0 Safari/537.36'
            ),
            viewport={'width': 1280, 'height': 800},
        )

        page = context.new_page()

        print(f" [*] Navigating to Broadcom portal: {LOGIN_START_URL}")
        page.goto(LOGIN_START_URL, timeout=45000)

        # 1. Fill Username if prompt appears
        print(" [*] Waiting for Broadcom authentication interface...")
        try:
            page.wait_for_selector('input#usernameInput, input[name="userName"]', timeout=30000)
            print(f" [*] Entering account email: {email}")
            user_input = page.locator('input#usernameInput, input[name="userName"]').first
            user_input.fill(email)
            time.sleep(0.5)

            # Click next / submit username
            submit_btn = page.locator('button[type="submit"], input[type="submit"], button:has-text("Next"), button:has-text("Sign In"), button:has-text("Login")').first
            if submit_btn.is_visible():
                submit_btn.click()
                print(" [*] Submitted username, waiting for password field...")
        except Exception as e:
            print(f" [!] Note on username step: {e}")

        # 2. Fill Password
        try:
            page.wait_for_selector('input#passwordInput, input[type="password"]', timeout=20000)
            print(" [*] Entering password...")
            pw_input = page.locator('input#passwordInput, input[type="password"]').first
            pw_input.fill(password)
            time.sleep(0.5)

            # Click sign in
            submit_btn = page.locator('button[type="submit"], input[type="submit"], button:has-text("Sign In"), button:has-text("Login"), button:has-text("Next")').first
            if submit_btn.is_visible():
                submit_btn.click()
                print(" [*] Submitted password, waiting for authentication settlement...")
        except Exception as e:
            print(f" [!] Note on password step: {e}")

        # 3. Wait for settlement back to support.broadcom.com
        print(" [*] Waiting for login callback and session completion (up to 60s)...")
        print("     (If you have 2FA/SMS/VIP code enabled, please approve it now)")

        authenticated = False
        cookies_dict = {}

        for _ in range(60):
            time.sleep(1)
            raw_cookies = context.cookies()
            cookies_dict = {c['name']: c['value'] for c in raw_cookies}

            if 'SAML_SP_SESSION_KEY' in cookies_dict or ('JSESSIONID' in cookies_dict and 'support.broadcom.com' in page.url and 'signin' not in page.url):
                authenticated = True
                print("\n [✓] Successfully detected authenticated session cookies!")
                break

        # Extract CSRF token from page DOM if available
        csrf_token = 'YaLAJUoR'
        try:
            dom_csrf = page.evaluate("() => (window.Liferay && window.Liferay.authToken) || ''")
            if dom_csrf:
                csrf_token = dom_csrf
                print(f" [*] Extracted page CSRF Token: {csrf_token}")
        except Exception:
            pass

        browser.close()

    if not authenticated and 'SAML_SP_SESSION_KEY' not in cookies_dict:
        print(" [!] Could not detect completed login session within timeout.")
        return False

    print("\n" + "="*70)
    print(" [*] CAPTURED AUTHENTICATED COOKIES:")
    print("="*70)
    for k, v in cookies_dict.items():
        if k in ('JSESSIONID', 'SAML_SP_SESSION_KEY', 'liferay-ingress-prd-us', 'COOKIE_SUPPORT'):
            masked = v[:10] + "..." + v[-6:] if len(v) > 20 else v
            print(f"  • {k:30} = {masked}")

    # Verify captured cookies with live APIs
    success = verify_session_against_broadcom(cookies_dict, csrf_token=csrf_token, email=email)
    if success:
        save_session(cookies_dict, csrf_token=csrf_token, email=email)
        print("\n [✓] COMPLETE! Session verified and ready for Flutter application.")
        return True

    return False


def main():
    parser = argparse.ArgumentParser(description='Broadcom Playwright Login Tester')
    parser.add_argument('--email', help='Broadcom account email')
    parser.add_argument('--password', help='Broadcom account password')
    parser.add_argument('--headless', action='store_true', help='Run browser in headless mode')
    args = parser.parse_args()

    run_playwright_login(
        email=args.email or '',
        password=args.password or '',
        headless=args.headless,
    )


if __name__ == '__main__':
    main()
