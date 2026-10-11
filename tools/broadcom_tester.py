#!/usr/bin/env python3
"""
Broadcom VMware Software Catalog Scraper & Download Tester
Uses BeautifulSoup and requests to authenticate, inspect, parse metadata, and verify downloads.
"""

import os
import sys
import json
import re
import argparse
import subprocess
from urllib.parse import urljoin, parse_qs, urlparse
import requests
from bs4 import BeautifulSoup

DEFAULT_HEADERS = {
    'User-Agent': (
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/130.0.0.0 Safari/537.36'
    ),
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7',
}

WORKSTATION_URL = (
    'https://support.broadcom.com/group/ecx/productdownloads'
    '?subfamily=VMware%20Workstation%20Pro&freeDownloads=true'
)

FUSION_URL = (
    'https://support.broadcom.com/group/ecx/productdownloads'
    '?subfamily=VMware%20Fusion&freeDownloads=true'
)

SESSION_FILE = os.path.join(os.path.dirname(__file__), '.session.json')


def load_cached_session():
    if os.path.exists(SESSION_FILE):
        try:
            with open(SESSION_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get('cookies'), data.get('headers')
        except Exception:
            pass
    return None, None


def save_cached_session(cookies_dict, headers_dict=None):
    try:
        with open(SESSION_FILE, 'w', encoding='utf-8') as f:
            json.dump({'cookies': cookies_dict, 'headers': headers_dict or {}}, f, indent=2)
        print(f"[*] Session saved to {SESSION_FILE}")
    except Exception as e:
        print(f"[!] Warning: Could not save session: {e}")


def parse_cookie_string(cookie_str):
    cookies = {}
    for part in cookie_str.split(';'):
        part = part.strip()
        if '=' in part:
            key, val = part.split('=', 1)
            cookies[key.strip()] = val.strip()
    return cookies


def parse_curl_command(curl_command):
    cookies = {}
    headers = {}
    cookie_match = re.search(r"-[Hh]\s+['\"]Cookie:\s*([^'\"]+)['\"]", curl_command)
    if cookie_match:
        cookies = parse_cookie_string(cookie_match.group(1))

    # Also capture other authorization headers
    auth_match = re.search(r"-[Hh]\s+['\"]Authorization:\s*([^'\"]+)['\"]", curl_command)
    if auth_match:
        headers['Authorization'] = auth_match.group(1)

    return cookies, headers


def launch_browser_for_login():
    print("\n" + "=" * 60)
    print(" BROADCOM LOGIN HELPER ")
    print("=" * 60)
    print("Opening Google Chrome to the Broadcom VMware Workstation download portal...")
    print(f"URL: {WORKSTATION_URL}")
    print("=" * 60)
    try:
        subprocess.run(['open', '-a', 'Google Chrome', WORKSTATION_URL], check=False)
    except Exception:
        subprocess.run(['open', WORKSTATION_URL], check=False)

    print("\nInstructions:")
    print("1. Log in to your Broadcom account in the opened Chrome window.")
    print("2. Open Developer Tools (Cmd + Option + I) -> Network tab.")
    print("3. Refresh the page or click a VMware download item.")
    print("4. Right click any request to 'support.broadcom.com' -> Copy -> Copy as cURL (or copy 'Cookie' request header).")
    print("5. Paste the Cookie string or cURL command below.\n")


def test_broadcom_page(session, url, product_name):
    print(f"\n[*] Testing fetching {product_name}...")
    print(f"    Target URL: {url}")
    try:
        resp = session.get(url, timeout=25)
    except Exception as e:
        print(f"[!] Error fetching {url}: {e}")
        return None

    print(f"    Status Code: {resp.status_code}")
    print(f"    Final URL:   {resp.url}")

    if '/c/portal/login' in resp.url or 'login.broadcom.com' in resp.url:
        print(f"[!] Redirection detected! The current session is NOT authenticated for Broadcom downloads.")
        return None

    soup = BeautifulSoup(resp.text, 'html.parser')
    page_title = soup.title.string.strip() if soup.title else 'No Title'
    print(f"    Page Title:  {page_title}")

    # Inspect tables, release cards, accordions
    tables = soup.find_all('table')
    cards = soup.find_all(class_=re.compile(r'card|release|product|download|table|row', re.I))
    links = soup.find_all('a', href=re.compile(r'download|file|ecx|\.exe|\.dmg|\.bundle', re.I))

    print(f"    HTML Elements Found: {len(tables)} tables, {len(cards)} card/row elements, {len(links)} download links")

    extracted_items = []

    # 1. Look for download links
    for link in links:
        href = link.get('href', '')
        text = link.get_text(strip=True)
        full_url = urljoin(url, href)
        extracted_items.append({
            'source': 'anchor_tag',
            'text': text,
            'url': full_url,
            'attributes': dict(link.attrs),
        })

    # 2. Look for script tags with JSON / Liferay configuration
    scripts_with_json = []
    for script in soup.find_all('script'):
        content = script.string or ''
        if any(keyword in content for keyword in ['productdownloads', 'checksum', 'sha256', 'subfamily', 'downloadUrl', 'fileName']):
            scripts_with_json.append(content[:500])

    print(f"    Scripts containing metadata keywords: {len(scripts_with_json)}")

    # 3. Look for table data
    for i, table in enumerate(tables):
        rows = table.find_all('tr')
        print(f"    Table #{i+1} has {len(rows)} rows")
        for row in rows[:5]:
            cols = [col.get_text(strip=True) for col in row.find_all(['td', 'th'])]
            if cols:
                print(f"      Row: {' | '.join(cols[:6])}")

    return {
        'product': product_name,
        'status_code': resp.status_code,
        'final_url': resp.url,
        'soup': soup,
        'extracted_items': extracted_items,
        'raw_html': resp.text,
    }


def test_download_url(session, download_url):
    print(f"\n[*] Testing download stream...")
    print(f"    Download URL: {download_url}")
    headers = {
        'Range': 'bytes=0-1048575',  # Request first 1 MB chunk
    }
    try:
        resp = session.get(download_url, headers=headers, stream=True, timeout=30)
        print(f"    Response Status: {resp.status_code}")
        print(f"    Headers:")
        for h, v in resp.headers.items():
            if h.lower() in ['content-type', 'content-length', 'content-range', 'content-disposition', 'server']:
                print(f"      {h}: {v}")

        chunk = b''
        for part in resp.iter_content(chunk_size=65536):
            chunk += part
            if len(chunk) >= 1048576:
                break

        print(f"    Downloaded sample bytes: {len(chunk)} bytes")
        is_html = b'<html' in chunk.lower() or b'<!doctype' in chunk.lower()
        if is_html:
            print("    [!] WARNING: Downloaded content is HTML (likely an auth redirect or error page), not an installer binary.")
            soup = BeautifulSoup(chunk.decode('utf-8', errors='ignore'), 'html.parser')
            print(f"    HTML Title: {soup.title.string if soup.title else 'Unknown'}")
            return False
        else:
            print("    [+] SUCCESS! Download stream verified as binary data payload.")
            return True
    except Exception as e:
        print(f"    [!] Download test failed with error: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Broadcom VMware Catalog & Download Tester")
    parser.add_argument('--cookie', help="Cookie header string")
    parser.add_argument('--curl', help="cURL command string copied from browser DevTools")
    parser.add_argument('--test-url', help="Specific download URL to test directly")
    parser.add_argument('--no-browser', action='store_true', help="Do not open browser automatically")
    args = parser.parse_args()

    session = requests.Session()
    session.headers.update(DEFAULT_HEADERS)

    cookies = {}
    extra_headers = {}

    if args.curl:
        cookies, extra_headers = parse_curl_command(args.curl)
    elif args.cookie:
        cookies = parse_cookie_string(args.cookie)
    else:
        cached_cookies, cached_headers = load_cached_session()
        if cached_cookies:
            print(f"[*] Found cached session from {SESSION_FILE}")
            cookies = cached_cookies
            extra_headers = cached_headers or {}
        else:
            if not args.no_browser:
                launch_browser_for_login()
            user_input = input("Paste your Cookie string or cURL command (or press Enter to test unauthenticated): ").strip()
            if user_input.startswith('curl'):
                cookies, extra_headers = parse_curl_command(user_input)
            elif user_input:
                cookies = parse_cookie_string(user_input)

    if cookies:
        session.cookies.update(cookies)
        session.headers.update(extra_headers)
        save_cached_session(cookies, extra_headers)
        print(f"[*] Active session cookies configured ({len(cookies)} cookies)")
    else:
        print("[!] Proceeding with empty session (unauthenticated check)...")

    # Test Workstation Pro
    ws_result = test_broadcom_page(session, WORKSTATION_URL, "VMware Workstation Pro")

    # Test Fusion
    fusion_result = test_broadcom_page(session, FUSION_URL, "VMware Fusion")

    # Direct download test if specified or found
    test_dl_url = args.test_url
    if not test_dl_url and ws_result and ws_result.get('extracted_items'):
        test_dl_url = ws_result['extracted_items'][0]['url']
    elif not test_dl_url and fusion_result and fusion_result.get('extracted_items'):
        test_dl_url = fusion_result['extracted_items'][0]['url']

    if test_dl_url:
        test_download_url(session, test_dl_url)
    else:
        print("\n[*] No direct download link found yet on the landing pages to test stream.")

    print("\n" + "=" * 60)
    print(" TEST COMPLETED ")
    print("=" * 60)


if __name__ == '__main__':
    main()
