import requests
import json

headers = {
    'accept': 'application/json, text/plain, */*',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
    'content-type': 'application/json;charset=UTF-8',
    'origin': 'https://support.broadcom.com',
    'referer': 'https://support.broadcom.com/group/ecx/productfiles?subFamily=VMware%20Workstation%20Pro&displayGroup=VMware%20Workstation%20Pro%2026H1%20for%20Windows&release=26H1u1&os=&servicePk=546859&language=EN&freeDownloads=true',
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
    'x-csrf-token': 'YaLAJUoR',
}

cookie_str = 'COOKIE_SUPPORT=true; ac_client_user_id=6d0e91fb-4660-41c2-ba1a-a06197238172; OptanonAlertBoxClosed=2026-10-10T14:17:51.784Z; liferay-ingress-prd-us=1791703651.136.46.652797|95b2e232c5e0be8e41c900a6b1ad87e6; SAML_SP_SESSION_KEY=_7b8bdd20ee7fb749c01480cbd12fa7e47cb23dc61b5195558c6b9df92d8a; LFR_SESSION_STATE_20102=1791703793193; JSESSIONID=AB1B752DEF07A9853E0B9AA3D1266162; OptanonConsent=isGpcEnabled=0&datestamp=Sun+Oct+11+2026+16%3A53%3A15+GMT%2B0800+(China+Standard+Time)&version=202603.1.0&browserGpcFlag=0&isDntEnabled=0&isIABGlobal=false&hosts=&consentId=edc9b2bb-03b7-4be9-a1f6-f80b4aead040&interactionCount=2&isAnonUser=1&prevHadToken=0&landingPath=NotLandingPage&groups=1%3A1%2CBG30%3A0%2C4%3A0%2C3%3A0%2C2%3A0&crTime=1791641882492&AwaitingReconsent=false&intType=3&geolocation=US%3BCA; LFR_SESSION_STATE_129183374=1791708798296'

cookies = {}
for p in cookie_str.split(';'):
    if '=' in p:
        k, v = p.strip().split('=', 1)
        cookies[k] = v

s = requests.Session()
s.headers.update(headers)
s.cookies.update(cookies)

url = 'https://support.broadcom.com/group/ecx/productfiles/-/productFiles/createProductDownloadOrder'

base_file = {
    'filePath': '546859/VMware-Workstation-Full-26H1u1-25688693.exe',
    'fileSize': 280609368,
}

variants = [
    {
        'downloadType': 'HTTPS',
        'productName': 'VMware Workstation Pro',
        'releaseDescription': 'VMware Workstation Pro (For Windows)',
        'skuCode': '',
        'displayGroup': 'VMware Workstation Pro 26H1 for Windows',
        'release': '26H1u1',
        'genLevel': '546859',
        'language': 'EN',
        'os': '',
        'eulaId': 'Broadcom Terms',
        'accessToken': False,
        'siteId': '105246',
        'orderedFiles': [base_file],
    },
    {
        'downloadType': 'HTTP',
        'productName': 'VMware Workstation Pro',
        'releaseDescription': 'VMware Workstation Pro (For Windows)',
        'skuCode': '',
        'displayGroup': 'VMware Workstation Pro 26H1 for Windows',
        'release': '26H1u1',
        'genLevel': '546859',
        'language': 'EN',
        'os': '',
        'eulaId': 'Broadcom Terms',
        'siteId': '105246',
        'orderedFiles': [{'filePath': '546859/VMware-Workstation-Full-26H1u1-25688693.exe', 'fileSize': '280609368'}],
    },
    {
        'downloadType': 'BROWSER',
        'productName': 'VMware Workstation Pro',
        'releaseDescription': 'VMware Workstation Pro (For Windows)',
        'skuCode': '',
        'displayGroup': 'VMware Workstation Pro 26H1 for Windows',
        'release': '26H1u1',
        'genLevel': 546859,
        'language': 'EN',
        'os': '',
        'eulaId': 'Broadcom Terms',
        'siteId': 105246,
        'orderedFiles': [base_file],
    }
]

for i, p in enumerate(variants):
    print(f"Testing variant #{i+1}...")
    r = s.post(url, json=p, timeout=20)
    print("Status:", r.status_code)
    print("Text:", r.text[:500])
    print("=" * 60)
