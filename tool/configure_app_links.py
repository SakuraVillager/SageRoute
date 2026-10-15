"""Generate public domain association files from real signing identities.

No private key or password is needed. Run BEFORE flutter build web.
"""
import argparse
import json
from pathlib import Path
import re
import os
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--android-sha256', action='append', default=[], help='Release certificate SHA-256; repeat for multiple signatures')
parser.add_argument('--apk', type=Path, help='Extract the public signing fingerprint from an existing APK')
parser.add_argument('--android-sdk', type=Path, help='SDK path; defaults to android/local.properties or ANDROID_HOME')
parser.add_argument('--output', type=Path, default=Path('web/.well-known'))
args = parser.parse_args()
if args.apk:
    if not args.apk.is_file():
        parser.error('APK file does not exist')
    sdk = args.android_sdk
    if sdk is None and Path('android/local.properties').is_file():
        for line in Path('android/local.properties').read_text(encoding='utf-8').splitlines():
            if line.startswith('sdk.dir='):
                sdk = Path(line.split('=', 1)[1].replace('\\\\', '\\').replace('\\:', ':'))
    if sdk is None and os.environ.get('ANDROID_HOME'):
        sdk = Path(os.environ['ANDROID_HOME'])
    signing_tools = list((sdk / 'build-tools').glob('*/lib/apksigner.jar')) if sdk else []
    if not signing_tools:
        parser.error('No apksigner.jar found; supply --android-sdk')
    tool = max(signing_tools, key=lambda p: tuple(int(x) for x in re.findall(r'\d+', p.parent.parent.name)))
    java = shutil.which('java')
    if not java:
        parser.error('Java is not available in PATH')
    result = subprocess.run([java, '-jar', str(tool), 'verify', '--print-certs', str(args.apk)], capture_output=True, text=True)
    if result.returncode:
        parser.error('APK signature verification failed; check the APK and JDK configuration')
    extracted = re.findall(r'^Signer #\d+ certificate SHA-256 digest:\s*([0-9a-fA-F]+)\s*$', result.stdout, re.MULTILINE)
    if not extracted:
        parser.error('APK has no recognised signing certificate')
    args.android_sha256.extend(extracted)
if not args.android_sha256:
    parser.error('Provide at least one actual signing identity')
fingerprints = []
for value in args.android_sha256:
    compact = value.replace(':', '').strip().upper()
    if not re.fullmatch(r'[0-9A-F]{64}', compact):
        parser.error('Android SHA-256 must contain 64 hexadecimal digits')
    fingerprints.append(':'.join(compact[n:n+2] for n in range(0, 64, 2)))
args.output.mkdir(parents=True, exist_ok=True)
if fingerprints:
    (args.output / 'assetlinks.json').write_text(json.dumps([{
        'relation': ['delegate_permission/common.handle_all_urls'],
        'target': {'namespace': 'android_app', 'package_name': 'com.sageroute.sageroute',
                   'sha256_cert_fingerprints': sorted(set(fingerprints))},
    }], indent=2) + '\n', encoding='utf-8')
print(f'Public association files written to {args.output}')
