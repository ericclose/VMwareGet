import requests
import json

try:
    with open('tools/.session.json') as f:
        sess_data = json.load(f)
    cookies = sess_data.get('cookies', {})
    csrf_token = sess_data.get('headers', {}).get('x-csrf-token', '')
except Exception:
    cookies = {}
    csrf_token = ''

headers = {
    'accept': 'application/json, text/plain, */*',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8,zh-CN;q=0.7,zh;q=0.6',
    'content-type': 'application/json;charset=UTF-8',
    'origin': 'https://support.broadcom.com',
    'referer': 'https://support.broadcom.com/group/ecx/productfiles',
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36',
    'x-csrf-token': csrf_token,
}

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
