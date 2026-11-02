"""One public chemistry question through Ask ChemBuddy's existing guest path.

Uses only the public anon credential already shipped by the client. No provider
or project-server credential is read or stored. Does not change user allowances.
"""
import json
import pathlib
import re
import sys
import urllib.error
import urllib.request

source = pathlib.Path('lib/data/remote/supabase_service.dart').read_text(encoding='utf-8')
url = re.search(r"defaultUrl\s*=\s*'([^']+)'", source).group(1)
anon = re.search(r"defaultAnonKey\s*=\s*'([^']+)'", source).group(1)
payload = {'question': sys.argv[1] if len(sys.argv) > 1 else 'In two sentences, explain how an aldehyde differs from a ketone.', 'mode': sys.argv[2] if len(sys.argv) > 2 else 'quick'}
request = urllib.request.Request(url + '/functions/v1/ask-chembuddy',
    data=json.dumps(payload).encode(), method='POST',
    headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + anon, 'apikey': anon})
try:
    with urllib.request.urlopen(request, timeout=120) as response:
        status, body = response.status, response.read().decode()
except urllib.error.HTTPError as error:
    status, body = error.code, error.read().decode()
body = re.sub(r'AIza[A-Za-z0-9_-]{25,}|AQ\.[A-Za-z0-9_-]{25,}|sb_secret_[A-Za-z0-9_-]+', '[redacted]', body)
result = {'http_status': status, 'path': 'existing public guest API', 'question': payload['question'], 'response': json.loads(body)}
out = pathlib.Path('build/spectroscopy-review/ask-chembuddy-live-check.json')
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(result, ensure_ascii=True)[:1400])
