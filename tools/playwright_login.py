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
LOGIN_START_URL = 'https://access.broadcom.com/'
SUPPORT_PORTAL_URL = 'https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true'


def verify_session_against_broadcom(cookies_dict, csrf_token='', email=''):
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
        'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
        'Content-Type': 'application/json;charset=UTF-8',
        'Origin': 'https://support.broadcom.com',
        'Referer': SUPPORT_PORTAL_URL,
        'x-csrf-token': csrf_token,
    })
    s.cookies.update(cookies_dict)

    # Bootstrap Liferay portal session & fresh CSRF token
    try:
        r_page = s.get(SUPPORT_PORTAL_URL, timeout=25)
        import re
        m_token = re.search(r'Liferay\.authToken\s*=\s*[\'\"]([^\'\"]+)[\'\"]', r_page.text)
        if m_token:
            csrf_token = m_token.group(1)
            s.headers['x-csrf-token'] = csrf_token
            print(f" [*] Refreshed Liferay CSRF Token from live portal: {csrf_token}")
    except Exception as e:
        print(f" [!] Note on portal bootstrap: {e}")

    # 1. 100% Online dynamic product discovery (zero hardcoded versions)
    sku_url = 'https://support.broadcom.com/group/ecx/productdownloads/-/productDownloadsList/getProductSkuDetails?pageNumber=0&pageSize=50'
    try:
        r_sku = s.post(sku_url, json={
            'subFamily': 'VMware Workstation Pro',
            'searchVal': '',
            'language': 'EN',
            'freeDownloads': True,
        }, timeout=25)
        print(f" -> getProductSkuDetails status: HTTP {r_sku.status_code}")
        if r_sku.status_code != 200 or not r_sku.text.strip():
            print(f" [!] Product SKU discovery failed: {r_sku.text[:200]}")
            return False

        sku_data = r_sku.json()
        if not sku_data.get('success'):
            print(f" [!] SKU API response: {sku_data.get('errors')}")
            return False

        content = sku_data.get('data', {}).get('productDetails', {}).get('content', [])
        if not content:
            print(" [!] No product groups returned from online discovery.")
            return False

        target_group = content[0]
        display_group = target_group.get('description', '')
        phantoms = target_group.get('phantomDetails', [])
        if not phantoms:
            print(" [!] No release items under discovered group.")
            return False

        chosen_phantom = phantoms[0]
        release_ver = chosen_phantom.get('release', '')
        gen_level = chosen_phantom.get('genLevel') or chosen_phantom.get('servicePk') or ''
        print(f" [+] Dynamically discovered: {display_group} (Release: {release_ver}, genLevel: {gen_level})")
    except Exception as e:
        print(f" [!] Error during dynamic product discovery: {e}")
        return False

    # 2. Dynamic catalog files
    cat_url = 'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50'
    cat_payload = {
        'primaryDownloads': True,
        'otherDownloads': '',
        'searchQuery': '',
        'freeDownloads': True,
        'displayGroup': display_group,
        'skuCode': '',
        'release': release_ver,
        'genLevel': str(gen_level),
        'language': 'EN',
        'os': '',
    }

    discovered_file = None
    try:
        r_cat = s.post(cat_url, json=cat_payload, timeout=25)
        print(f" -> getDownloadableFiles status: HTTP {r_cat.status_code}")
        if r_cat.status_code == 200:
            if not r_cat.text.strip():
                print(" [!] Catalog response body is empty.")
            else:
                data = r_cat.json()
                if data.get('success'):
                    packlist = data.get('data', {}).get('packlistDetails', {}).get('content', [])
                    if packlist:
                        discovered_file = packlist[0].get('fileDetails', [])[0]
                        print(" [+] Successfully retrieved online file metadata!")
                        print(f"     - File:   {discovered_file.get('fileName')}")
                        print(f"     - Size:   {discovered_file.get('fileSize')} bytes")
                        print(f"     - SHA256: {discovered_file.get('sha2Chksum')}")
                        print(f"     - MD5:    {discovered_file.get('md5Chksum')}")
                else:
                    print(f" [!] API response: {data.get('message')}")
        else:
            print(f" [!] Catalog request failed: HTTP {r_cat.status_code}")
    except Exception as e:
        print(f" [!] Error verifying catalog: {e}")

    if not discovered_file:
        return False

    # 3. Dynamic download order creation
    order_url = 'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/createProductDownloadOrder'
    order_payload = {
        'downloadType': 'HTTP',
        'productName': 'VMware Workstation Pro',
        'releaseDescription': display_group,
        'skuCode': '',
        'displayGroup': display_group,
        'release': release_ver,
        'genLevel': str(gen_level),
        'language': 'EN',
        'os': '',
        'eulaId': 17290717,
        'accessToken': False,
        'siteId': '105246',
        'orderedFiles': [{
            'filePath': discovered_file.get('filePath'),
            'fileSize': discovered_file.get('fileSize'),
        }],
    }

    try:
        r_order = s.post(order_url, json=order_payload, timeout=25)
        print(f" -> createProductDownloadOrder status: HTTP {r_order.status_code}")
        if r_order.status_code == 200:
            if not r_order.text.strip():
                print(" [!] Download order response body is empty.")
            else:
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
                    print(f" [!] Download order response: {order_data}")
        else:
            print(f" [!] Order request failed: HTTP {r_order.status_code}")
    except Exception as e:
        print(f" [!] Error testing download order: {e}")

    return False


def save_session(cookies_dict, csrf_token='', email=''):
    try:
        data = {
            'email': email,
            'cookies': cookies_dict,
            'headers': {
                'x-csrf-token': csrf_token,
                'referer': 'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro&displayGroup=VMware%20Workstation%20Pro%2026H1%20for%20Windows&release=26H1u1&os=&servicePk=546859&language=EN&freeDownloads=true',
            },
            'saved_at': time.strftime('%Y-%m-%dT%H:%M:%SZ'),
        }
        with open(SESSION_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        print(f" [✓] Authenticated session written to {SESSION_FILE}")
    except Exception as e:
        print(f" [!] Failed writing session file: {e}")


def run_playwright_login(email='', password=''):
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

    print("\n [*] Launching Chromium browser (Interactive Real GUI Engine)...")

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=False,
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

        # 3. Wait for settlement on access.broadcom.com and bridge to support.broadcom.com
        print(" [*] Waiting for login callback and session completion (up to 90s)...")
        print("     (If you have 2FA/SMS/VIP code enabled, please approve it now)")

        authenticated = False
        cookies_dict = {}

        for _ in range(90):
            time.sleep(1)
            raw_cookies = context.cookies()
            cookies_dict = {c['name']: c['value'] for c in raw_cookies}
            cur_url = page.url.lower()

            # Check if user already reached support portal directly
            if 'support.broadcom.com' in cur_url and ('JSESSIONID' in cookies_dict or 'SAML_SP_SESSION_KEY' in cookies_dict):
                authenticated = True
                print("\n [✓] Successfully landed on support.broadcom.com with authenticated session!")
                time.sleep(3)
                break

            # Check if login settled on access.broadcom.com (passed the signin/login form)
            passed_signin = (
                '/signin' not in cur_url and
                'idp/login' not in cur_url and
                (
                    'dashboard' in cur_url or
                    'landing' in cur_url or
                    'home' in cur_url or
                    any(k for k in cookies_dict if 'session' in k.lower() or 'token' in k.lower() or '__secure' in k.lower() or 'auth' in k.lower())
                )
            )

            if passed_signin and 'support.broadcom.com' not in cur_url:
                print(f"\n [✓] Sign-in settled on {cur_url}! Navigating to Support Portal to establish Liferay SSO session...")
                try:
                    page.goto(SUPPORT_PORTAL_URL, timeout=45000)
                    time.sleep(4)
                except Exception as e:
                    print(f" [!] Note navigating to support portal: {e}")
                break

        # If navigated to support portal, wait for Liferay & SAML cookies to finish settling
        if not authenticated:
            for _ in range(30):
                time.sleep(1)
                raw_cookies = context.cookies()
                cookies_dict = {c['name']: c['value'] for c in raw_cookies}
                cur_url = page.url.lower()
                has_auth_cookies = 'SAML_SP_SESSION_KEY' in cookies_dict or 'JSESSIONID' in cookies_dict
                if 'support.broadcom.com' in cur_url and has_auth_cookies:
                    authenticated = True
                    print("\n [✓] Successfully landed on support.broadcom.com with authenticated session!")
                    time.sleep(3)
                    break

        # Extract CSRF token from page DOM if available
        csrf_token = ''
        try:
            dom_csrf = page.evaluate("() => (window.Liferay && window.Liferay.authToken) || (window.themeDisplay && typeof window.themeDisplay.getAuthToken === 'function' ? window.themeDisplay.getAuthToken() : '')")
            if dom_csrf:
                csrf_token = dom_csrf
        except Exception:
            pass
        if not csrf_token:
            try:
                import re
                html = page.content()
                m = re.search(r'Liferay\.authToken\s*=\s*[\'\"]([^\'\"]+)[\'\"]', html)
                if m:
                    csrf_token = m.group(1)
            except Exception:
                pass
        if not csrf_token:
            csrf_token = '2avZ8Ufi'
        print(f" [*] Extracted Liferay CSRF Token: {csrf_token}")

        # Retrieve final settled cookies before closing
        raw_cookies = context.cookies()
        cookies_dict = {c['name']: c['value'] for c in raw_cookies}

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

    # Immediately save captured session so it is preserved for Flutter & CLI tools
    save_session(cookies_dict, csrf_token=csrf_token, email=email)

    # Verify captured cookies with live APIs
    success = verify_session_against_broadcom(cookies_dict, csrf_token=csrf_token, email=email)
    if success:
        print("\n [✓] COMPLETE! Session verified and ready for Flutter application.")
        return True

    print("\n [!] Session saved to tools/.session.json. You may test with './test_broadcom.sh test'.")
    return False


def main():
    parser = argparse.ArgumentParser(description='Broadcom Playwright Real Browser Login')
    parser.add_argument('--email', help='Broadcom account email')
    parser.add_argument('--password', help='Broadcom account password')
    args = parser.parse_args()

    run_playwright_login(
        email=args.email or '',
        password=args.password or '',
    )


if __name__ == '__main__':
    main()
