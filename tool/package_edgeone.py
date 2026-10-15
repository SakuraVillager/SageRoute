"""Package the complete static site, including Android's .well-known directory."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import json

root = Path('build/web')
assert (root / 'index.html').is_file(), 'Build Web first'
assert (root / 'edgeone.json').is_file(), 'Missing EdgeOne routing rules'
association = root / '.well-known/assetlinks.json'
assert association.is_file(), 'Generate Android app links before building Web'
assert json.loads(association.read_text())[0]['target']['sha256_cert_fingerprints']
output = Path('build/sageroute-edgeone.zip')
with ZipFile(output, 'w', compression=ZIP_DEFLATED) as archive:
    for file in sorted(root.rglob('*')):
        if file.is_file() and file.name != 'README.md':
            archive.write(file, file.relative_to(root).as_posix())
with ZipFile(output) as archive:
    assert 'index.html' in archive.namelist()
    assert '.well-known/assetlinks.json' in archive.namelist()
print(f'{output}: {output.stat().st_size:,} bytes; includes Android domain association')
