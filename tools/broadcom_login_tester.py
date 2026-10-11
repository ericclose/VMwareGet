#!/usr/bin/env python3
"""
Broadcom Account Login Tester using BeautifulSoup & Requests
Interactive login tester: prompts for username/password, walks through the SAML 2.0
and Symantec Authentication Hub flow with BeautifulSoup form extraction, obtains cookies,
verifies live catalog retrieval and download order capability, and caches the session.
"""

import os
import sys
import json
import time
import getpass
import random
import base64
import urllib.parse
import argparse
import requests
from bs4 import BeautifulSoup
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.serialization import load_pem_public_key
from cryptography import x509

DEFAULT_HEADERS = {
    'User-Agent': (
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/155.0.0.0 Safari/537.36'
    ),
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

SESSION_FILE = os.path.join(os.path.dirname(__file__), '.session.json')


def do_obfuscate(s):
    chars = list('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
    random.shuffle(chars)
    ran = ''.join(chars)
    s1 = [118, 112, 90, 70, 79, 122, 89, 76, 115, 54, 111, 51, 97, 65, 55, 84, 77, 67, 105, 74, 80, 107, 119, 66, 110, 87, 116, 86, 83, 49, 98, 81, 100, 114, 82, 108, 73, 53, 101, 120, 75, 104, 121, 113, 88, 99, 57, 56, 106, 68, 102, 48, 72, 71, 103, 69, 117, 109, 85, 52, 50, 78]
    s2 = [103, 100, 57, 51, 99, 72, 55, 108, 56, 87, 119, 89, 80, 98, 70, 71, 82, 54, 111, 49, 114, 74, 83, 67, 101, 86, 84, 78, 117, 52, 112, 115, 88, 120, 118, 104, 109, 121, 75, 48, 116, 68, 81, 97, 50, 76, 113, 105, 106, 79, 85, 102, 122, 107, 90, 66, 77, 53, 73, 65, 110, 69]
    enc_map = {chr(c1): chr(c2) for c1, c2 in zip(s1, s2)}
    b64 = base64.b64encode((ran[:16] + s).encode('utf-8')).decode('utf-8')
    res = ''.join([enc_map.get(ch, ch) for ch in b64])
    return urllib.parse.quote(res)


def rsa_encrypt_password(password, public_key_obj):
    ciphertext = public_key_obj.encrypt(
        password.encode('utf-8'),
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None,
        )
    )
    return base64.b64encode(ciphertext).decode('utf-8')


def parse_cookie_string(cookie_str):
    cookies = {}
    for part in cookie_str.split(';'):
        part = part.strip()
        if '=' in part:
            k, v = part.split('=', 1)
            cookies[k.strip()] = v.strip()
    return cookies


def verify_session_against_broadcom(cookies, csrf_token='YaLAJUoR', email=''):
    print("\n" + "="*70)
    print(" [*] Verifying cookies against Broadcom live API...")
    print("="*70)

    session = requests.Session()
    session.headers.update({
        'User-Agent': DEFAULT_HEADERS['User-Agent'],
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json;charset=UTF-8',
        'Origin': 'https://support.broadcom.com',
        'x-csrf-token': csrf_token,
    })
    session.cookies.update(cookies)

    # 1. Test catalog retrieval for VMware Workstation Pro
    catalog_url = 'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/getDownloadableFiles?pageNumber=0&pageSize=50'
    catalog_payload = {
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
        r_cat = session.post(catalog_url, json=catalog_payload, timeout=25)
        print(f" -> getDownloadableFiles status: HTTP {r_cat.status_code}")
        if r_cat.status_code == 200:
            data = r_cat.json()
            if data.get('success'):
                content = data.get('data', {}).get('packlistDetails', {}).get('content', [])
                if content:
                    file_details = content[0].get('fileDetails', [])
                    if file_details:
                        f = file_details[0]
                        print(" [+] Successfully retrieved online file metadata!")
                        print(f"     - File: {f.get('fileName')}")
                        print(f"     - Size: {f.get('fileSize')} bytes")
                        print(f"     - SHA256: {f.get('sha2Chksum')}")
                        print(f"     - MD5:    {f.get('md5Chksum')}")
            else:
                print(f" [!] API returned non-success: {data.get('message')}")
        else:
            print(f" [!] Catalog request failed with HTTP {r_cat.status_code}")
    except Exception as e:
        print(f" [!] Error verifying catalog: {e}")

    # 2. Test dynamic download order creation
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
        r_order = session.post(order_url, json=order_payload, timeout=25)
        print(f" -> createProductDownloadOrder status: HTTP {r_order.status_code}")
        if r_order.status_code == 200:
            order_data = r_order.json()
            d_url = order_data.get('data', {}).get('downloadUrl')
            if d_url:
                print(f" [+] Successfully created authorized download order!")
                print(f"     - CDN Download URL: {d_url[:80]}...")

                # Test stream
                r_head = session.get(d_url, headers={'Range': 'bytes=0-10'}, stream=True, timeout=15)
                print(f"     - Live CDN Stream probe: HTTP {r_head.status_code} ({r_head.headers.get('Content-Type')})")
                if r_head.status_code in (200, 206):
                    print(" [✓] SESSION CONFIRMED FULLY FUNCTIONAL FOR ONLINE CATALOG & DOWNLOADS!")
                    return True
            else:
                print(f" [!] Order status non-200: {order_data}")
        else:
            print(f" [!] Order endpoint error: HTTP {r_order.status_code}")
    except Exception as e:
        print(f" [!] Error probing download order: {e}")

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
        print(f" [✓] Session saved to {SESSION_FILE}")
    except Exception as e:
        print(f" [!] Failed saving session file: {e}")


def main():
    print("""
========================================================================
   Broadcom Account Authentication Tester (BeautifulSoup + Requests)
   VMwareGet Companion Tool
========================================================================
""")
    parser = argparse.ArgumentParser(description='Broadcom Login Tester')
    parser.add_argument('--email', help='Broadcom account email')
    parser.add_argument('--password', help='Broadcom account password')
    parser.add_argument('--cookie', help='Optional cookie string or cURL command to verify directly')
    args = parser.parse_args()

    # If user provided a direct cookie string or curl
    if args.cookie:
        cookies = parse_cookie_string(args.cookie)
        if cookies:
            print(" [*] Provided cookie input detected. Testing directly...")
            verify_session_against_broadcom(cookies)
            save_session(cookies, email=args.email or '')
            return

    # Prompt user for credentials
    email = args.email
    if not email:
        email = input(" [?] Enter Broadcom Account Email: ").strip()

    if not email:
        print(" [!] Email cannot be empty.")
        sys.exit(1)

    password = args.password
    if not password:
        password = getpass.getpass(" [?] Enter Broadcom Account Password: ").strip()

    if not password:
        print(" [!] Password cannot be empty.")
        sys.exit(1)

    print(f"\n [*] Initiating authentication sequence for: {email}")

    s = requests.Session()
    s.headers.update(DEFAULT_HEADERS)

    # Step 1: Request portal entry
    print(" [1/8] Requesting Broadcom portal entry point...")
    portal_entry = 'https://support.broadcom.com/c/portal/login?redirect=%2Fgroup%2Fecx%2Fproductdownloads%3Fsubfamily%3DVMware%2520Workstation%2520Pro%26freeDownloads%3Dtrue&refererPlid=36&p_l_id=33047'
    r1 = s.get(portal_entry, timeout=20)
    soup1 = BeautifulSoup(r1.text, 'html.parser')
    form1 = soup1.find('form')

    if not form1:
        print(f" [!] Unable to locate login form at {portal_entry}. Status: {r1.status_code}")
        sys.exit(1)

    params1 = {inp.get('name'): inp.get('value') for inp in form1.find_all('input') if inp.get('name')}
    print(f"       -> Form 0 parsed: action={form1.get('action')}, {len(params1)} inputs")

    # Step 2: Portal redirect to SAML SP
    print(" [2/8] Generating SAML Authentication Request...")
    r2 = s.get(form1.get('action'), params=params1, allow_redirects=True, timeout=20)
    soup2 = BeautifulSoup(r2.text, 'html.parser')
    saml_form = soup2.find('form')

    if not saml_form:
        print(" [!] Unable to locate SAML form. Status:", r2.status_code)
        sys.exit(1)

    saml_action = saml_form.get('action')
    saml_data = {inp.get('name'): inp.get('value') for inp in saml_form.find_all('input') if inp.get('name')}
    print(f"       -> SAML Form parsed: target={saml_action}")

    # Step 3: Post SAML to Access IdP
    print(" [3/8] Contacting Broadcom Access IdP...")
    r3 = s.post(saml_action, data=saml_data, allow_redirects=True, timeout=20)
    soup3 = BeautifulSoup(r3.text, 'html.parser')
    form3 = soup3.find('form')

    if not form3:
        print(" [!] Unable to parse IdP auto-submit form. Status:", r3.status_code)
        sys.exit(1)

    action3 = form3.get('action')
    data3 = {inp.get('name'): inp.get('value') for inp in form3.find_all('input') if inp.get('name')}

    # Step 4: Post second SAML form
    print(" [4/8] Establishing authentication flow state...")
    r4 = s.post(action3, data=data3, allow_redirects=True, timeout=20)
    parsed_q = urllib.parse.parse_qs(urllib.parse.urlparse(r4.url).query)
    flow_state = parsed_q.get('x-flow-state', [''])[0]

    if not flow_state:
        print(" [!] Failed to extract x-flow-state from IdP redirect URL:", r4.url)
        sys.exit(1)

    print(f"       -> Flow state established (Length: {len(flow_state)})")

    # Step 5: Compute __Secure-rbu cookie and request signin SPA
    print(" [5/8] Initializing Sign-in Hub session...")
    base_url = '/default/ui/v1/signin/'
    obf_cookie = do_obfuscate(base_url)
    s.cookies.set('__Secure-rbu', obf_cookie, domain='access.broadcom.com', path=base_url)

    ts = int(time.time() * 1000)
    url5 = r4.url.replace('?', f'?_ts={ts}&') if '?' in r4.url else f'{r4.url}?_ts={ts}'
    r5 = s.get(url5, allow_redirects=True, timeout=20)

    # Step 6: Acquire client access token & JWKS
    print(" [6/8] Requesting Client Token and RSA Encryption Keys...")
    token_url = 'https://access.broadcom.com/default/ui/v1/signin/token'
    r_token = s.post(
        token_url,
        json={'x-flow-state': flow_state},
        headers={
            'Accept': 'application/json, text/plain, */*',
            'Content-Type': 'application/json',
            'Origin': 'https://access.broadcom.com',
            'Referer': r5.url,
        },
        timeout=20,
    )

    if r_token.status_code != 200:
        print(f" [!] Failed retrieving token: HTTP {r_token.status_code} ({r_token.text})")
        sys.exit(1)

    token_json = r_token.json()
    access_token = token_json.get('access_token')
    print("       -> Token acquired successfully.")

    # Fetch JWKS
    jwks_url = f'https://access.broadcom.com/default/oauth2/v1/jwks?ts={int(time.time()*1000)}'
    r_jwks = s.get(jwks_url, headers={'Authorization': f'Bearer {access_token}', 'Accept': 'application/json'}, timeout=20)
    encryption_pub_key = None

    if r_jwks.status_code == 200:
        keys = r_jwks.json().get('keys', [])
        for k in keys:
            if k.get('use') == 'enc' and k.get('x5c'):
                cert_der = base64.b64decode(k['x5c'][0])
                cert = x509.load_der_x509_certificate(cert_der)
                encryption_pub_key = cert.public_key()
                print(f"       -> Encryption Key loaded ({k.get('kid')})")
                break

    if not encryption_pub_key:
        print(" [!] Could not extract RSA Encryption Key from JWKS.")
        sys.exit(1)

    # Step 7: Submit username and authenticate
    print(" [7/8] Submitting credentials to Authentication Hub...")
    auth_hub_headers = {
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {access_token}',
        'Origin': 'https://access.broadcom.com',
        'Referer': r5.url,
    }

    # Authenticate Username
    user_payload = {
        'subject': email,
        'channel': 'web',
        'device': {'signature': ''},
        'action': 'authenticate',
        'actionType': 'USERNAME',
        'clientContext': [
            {'key': 'desktop', 'value': 'true'},
            {'key': 'mobile', 'value': 'false'},
            {'key': 'tablet', 'value': 'false'},
        ],
    }

    r_user = s.post(
        'https://access.broadcom.com/default/auth/v1/authenticate',
        json=user_payload,
        headers=auth_hub_headers,
        timeout=25,
    )

    print(f"       -> Username submission status: HTTP {r_user.status_code}")
    user_resp = r_user.json() if r_user.text.startswith('{') else {}
    next_action = user_resp.get('nextaction')
    print(f"       -> Next Action required by server: {next_action}")

    encrypted_pw = rsa_encrypt_password(password, encryption_pub_key)

    # Authenticate Password
    pw_payload = {
        'password': encrypted_pw,
        'actionType': 'PASSWORD_AUTH',
    }

    r_pw = s.post(
        'https://access.broadcom.com/default/factor/v1/PasswordAuthenticator',
        json=pw_payload,
        headers=auth_hub_headers,
        timeout=25,
    )

    print(f"       -> Password verification status: HTTP {r_pw.status_code}")
    pw_resp = r_pw.json() if r_pw.text.startswith('{') else {}
    pw_next = pw_resp.get('nextaction')
    print(f"       -> Result: {pw_next}")

    # Check for MFA / OTP
    if pw_next in ('SMS_OTP_AUTH', 'EMAIL_OTP_AUTH', 'OTP_AUTH'):
        print(f"\n [!] Two-Factor Authentication (2FA) Challenge: {pw_next}")
        otp = input(" [?] Enter verification code received via SMS/Email: ").strip()
        otp_payload = {'credId': '', 'otp': otp, 'actionType': pw_next}
        r_otp = s.post(
            'https://access.broadcom.com/default/factor/v1/OTPVerifier',
            json=otp_payload,
            headers=auth_hub_headers,
            timeout=25,
        )
        pw_resp = r_otp.json() if r_otp.text.startswith('{') else {}
        pw_next = pw_resp.get('nextaction')

    # Step 8: Finalize Session Cookies
    print(" [8/8] Completing SAML Assertion and extracting cookies...")
    auth_complete_url = pw_resp.get('authCompleteUrl')

    if auth_complete_url:
        r_comp = s.get(auth_complete_url, timeout=20)
        soup_comp = BeautifulSoup(r_comp.text, 'html.parser')
        form_comp = soup_comp.find('form')
        if form_comp:
            acs_url = form_comp.get('action')
            acs_data = {inp.get('name'): inp.get('value') for inp in form_comp.find_all('input') if inp.get('name')}
            r_acs = s.post(acs_url, data=acs_data, allow_redirects=True, timeout=20)
            print(f"       -> ACS Assertion status: HTTP {r_acs.status_code}")

    # Inspect cookies obtained in the session
    cookies_found = s.cookies.get_dict()
    print("\n" + "="*70)
    print(" [*] COOKIES RECEIVED IN SESSION:")
    print("="*70)
    for k, v in cookies_found.items():
        masked_val = v[:10] + "..." + v[-6:] if len(v) > 20 else v
        print(f"  • {k:30} = {masked_val}")

    if 'SAML_SP_SESSION_KEY' in cookies_found:
        print("\n [✓] Broadcom Authenticated Session cookies successfully acquired!")
        success = verify_session_against_broadcom(cookies_found, email=email)
        if success:
            save_session(cookies_found, email=email)
            print("\n [✓] Success! Session saved to tools/.session.json.")
            return
    else:
        print("\n [!] Notice: Symantec Access Hub returned HTTP 401 during direct password authentication.")
        print("     Explanation: Broadcom enforces browser client device fingerprinting (Akamai Bot Manager / IaDfp).")
        print("     The cookies above are currently anonymous visitor cookies, missing `SAML_SP_SESSION_KEY`.")
        print("\n [Interactive Fallback] You can paste the Cookie string or cURL command from your browser developer tools:")
        try:
            user_input = input(" [?] Paste Cookie string or cURL command (or press Enter to exit): ").strip()
        except (KeyboardInterrupt, EOFError):
            user_input = ''

        if user_input:
            pasted_cookies = {}
            csrf = 'YaLAJUoR'
            if user_input.startswith('curl'):
                import re
                cm = re.search(r"-[Hhb]\s+['\"](?:Cookie:\s*)?([^'\"]+)['\"]", user_input)
                if cm:
                    pasted_cookies = parse_cookie_string(cm.group(1))
                cs = re.search(r"-[Hh]\s+['\"]x-csrf-token:\s*([^'\"]+)['\"]", user_input, re.I)
                if cs:
                    csrf = cs.group(1)
            else:
                pasted_cookies = parse_cookie_string(user_input)

            if pasted_cookies:
                print(" [*] Verifying pasted session...")
                success = verify_session_against_broadcom(pasted_cookies, csrf_token=csrf, email=email)
                if success:
                    save_session(pasted_cookies, csrf_token=csrf, email=email)
                    print("\n [✓] Success! Authenticated session saved to tools/.session.json.")
                    return
                else:
                    print(" [!] Pasted session could not be verified against Broadcom live API.")
            else:
                print(" [!] Could not parse cookies from provided input.")


if __name__ == '__main__':
    main()
