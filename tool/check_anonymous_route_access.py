"""Read-only target check: requests no rows, and never prints credentials."""
import base64
import json
import urllib.error
import urllib.request
from pathlib import Path

config = json.loads(Path('dart_define.web.json').read_text())
key = config['SUPABASE_ANON_KEY']
if key.startswith('eyJ'):
    payload = key.split('.')[1]
    claims = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4)))
    assert claims.get('role') == 'anon', 'Use only an anonymous/public client Key'
else:
    assert key.startswith('sb_publishable_'), 'Use only an anonymous/public client Key'
results = []
for table in ('user_routes', 'user_route_waypoints'):
    url = config['SUPABASE_URL'].rstrip('/') + f'/rest/v1/{table}?select=id&limit=0'
    headers = {'apikey': key}
    if key.startswith('eyJ'):
        headers['Authorization'] = 'Bearer ' + key
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=20) as response:
            results.append({'table': table, 'status': response.status, 'result': 'No rows requested; authenticated-user isolation still requires two-account verification'})
    except urllib.error.HTTPError as error:
        body = json.loads(error.read())
        results.append({'table': table, 'status': error.code, 'code': body.get('code')})
    except urllib.error.URLError:
        results.append({'table': table, 'result': 'Network unavailable; not verified'})
Path('.dart_tool/web_anonymous_access.json').write_text(json.dumps(results, indent=2))
print(json.dumps(results, indent=2))
