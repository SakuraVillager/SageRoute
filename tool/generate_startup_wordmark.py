"""Inline the bundled font's SageRoute outlines: no font download at startup.

Run from the repository root with fontTools installed. The font's OFL license
is retained in assets/fonts/OFL.txt. Regenerate when the wordmark font changes.
"""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

font = TTFont('assets/fonts/SageRouteSans-Bold.otf')
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
commands = []
x = 24
for character in 'SageRoute':
    glyph = glyphs[cmap[ord(character)]]
    pen = SVGPathPen(glyphs)
    glyph.draw(TransformPen(pen, (1, 0, 0, -1, x, 850)))
    commands.append(pen.getCommands())
    x += glyph.width + 10
path = ''.join(commands)
svg = (
    f'<svg class="sage-startup-wordmark" viewBox="0 0 {x + 14} 1100" '
    'xmlns="http://www.w3.org/2000/svg" role="img" aria-label="SageRoute">'
    f'<path class="sage-startup-track" d="{path}"/>'
    + ''.join(
        f'<path class="sage-startup-outline" pathLength="1" d="{glyph}"/>'
        for glyph in commands
    )
    + '</svg>'
)
target = Path('web/index.html')
source = target.read_text(encoding='utf-8')
start = '    <!-- STARTUP_WORDMARK -->'
end = '    <!-- /STARTUP_WORDMARK -->'
prefix, rest = source.split(start)
_, suffix = rest.split(end)
target.write_text(f'{prefix}{start}\n    {svg}\n{end}{suffix}', encoding='utf-8')
print(f'Inlined SageRoute vector outlines ({len(svg):,} bytes)')
