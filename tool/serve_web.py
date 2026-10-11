"""Local static preview with SPA fallback; no production backend is needed."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8080)
parser.add_argument('--root', type=Path, help='Optional local preview build directory')
args = parser.parse_args()
root = args.root.resolve() if args.root else Path(__file__).resolve().parents[1] / 'build' / 'web'


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(root), **kw)

    def do_GET(self):
        path = urlsplit(self.path).path
        file = Path(self.translate_path(path))
        if not file.exists() and '.' not in Path(path).name and not path.startswith(('/assets/', '/canvaskit/', '/icons/')):
            self.path = '/index.html'
        super().do_GET()

    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


ThreadingHTTPServer(('127.0.0.1', args.port), Handler).serve_forever()
