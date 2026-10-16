"""Check the static release boundary without displaying client credentials."""
import gzip
import json
from pathlib import Path

root = Path('build/web')
assert root.is_dir(), 'Build Web first'
for forbidden in ('assets/dart_define.json', 'assets/assets/env.env', 'dart_define.web.json'):
    assert not (root / forbidden).exists(), f'Local configuration was bundled: {forbidden}'
for required in ('index.html', 'main.dart.js', 'sage_maps.js', 'sage_startup.js', 'canvaskit/canvaskit.wasm', 'assets/FontManifest.json'):
    assert (root / required).is_file(), f'Missing static resource: {required}'
fonts = json.loads((root / 'assets/FontManifest.json').read_text())
assert any(font['family'] == 'Roboto' for font in fonts), 'Default font would require an external download'
files = [p for p in root.rglob('*') if p.is_file()]
metrics = {
    'files': len(files),
    'total_bytes_uncompressed': sum(p.stat().st_size for p in files),
    'main_js_bytes': (root / 'main.dart.js').stat().st_size,
    'main_js_gzip_bytes': len(gzip.compress((root / 'main.dart.js').read_bytes())),
    'bundled_ui_font_bytes': sum(p.stat().st_size for p in (root / 'assets/assets/fonts').glob('*.otf')),
    'configuration_assets_excluded': True,
}
Path('.dart_tool/web_build_metrics.json').write_text(json.dumps(metrics, indent=2))
print(json.dumps(metrics, indent=2))
