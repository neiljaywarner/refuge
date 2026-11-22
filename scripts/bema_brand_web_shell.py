#!/usr/bin/env python3
"""Rewrite the built web shell so the BEMA host does not say Belong.

Runs against build/web after `flutter build web`. Does not edit web/.
"""

import json
import struct
import sys
import zlib
from pathlib import Path


def _chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF)


# 5×7 bitmaps for a text mark. Not the BEMA Discipleship logo.
_GLYPHS = {
    'B': ('11110', '10001', '11110', '10001', '10001', '10001', '11110'),
    'E': ('11111', '10000', '10000', '11110', '10000', '10000', '11111'),
    'M': ('10001', '11011', '10101', '10001', '10001', '10001', '10001'),
    'A': ('01110', '10001', '10001', '11111', '10001', '10001', '10001'),
}


def wordmark_png(size: int = 192) -> bytes:
    """#2A2A2A tile with BEMA in #2EA4F9. Generated, not their trademark artwork."""
    bg = (0x2A, 0x2A, 0x2A)
    fg = (0x2E, 0xA4, 0xF9)
    pixels = [bg] * (size * size)
    word = 'BEMA'
    glyph_w, glyph_h = 5, 7
    gap = 1
    scale = max(1, size // 28)
    text_w = (glyph_w * len(word) + gap * (len(word) - 1)) * scale
    text_h = glyph_h * scale
    origin_x = (size - text_w) // 2
    origin_y = (size - text_h) // 2
    for index, char in enumerate(word):
        glyph = _GLYPHS[char]
        left = origin_x + index * (glyph_w + gap) * scale
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit != '1':
                    continue
                for dy in range(scale):
                    for dx in range(scale):
                        x = left + col * scale + dx
                        y = origin_y + row * scale + dy
                        if 0 <= x < size and 0 <= y < size:
                            pixels[y * size + x] = fg
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            raw.extend(pixels[y * size + x])
    return b''.join(
        [
            b'\x89PNG\r\n\x1a\n',
            _chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)),
            _chunk(b'IDAT', zlib.compress(bytes(raw), 9)),
            _chunk(b'IEND', b''),
        ]
    )


def main() -> None:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/web')
    index = root / 'index.html'
    text = index.read_text()
    replacements = {
        'Belong on the Spectrum — You belong here. A calm, neurodivergent-affirming Christian & autistic fellowship community.':
            'BEMA Discussion Group — Discuss the BEMA podcast together.',
        'content="#F2EEE2"': 'content="#222222"',
        'content="Belong"': 'content="BEMA Group"',
        '<title>Belong on the Spectrum</title>': '<title>BEMA Discussion Group</title>',
        'background-color: #F2EEE2;': 'background-color: #222222;',
        'color: #0F2336;': 'color: #FFFFFF;',
        'color: #4A635D;': 'color: #F2F2F2;',
        'aria-label="Loading Belong on the Spectrum"': 'aria-label="Loading BEMA Discussion Group"',
        '<h1>Belong on the Spectrum</h1>': '<h1>BEMA</h1>',
        '<p>You belong here.</p>': '<p>Discussion Group</p>',
        'alt="Belong on the Spectrum logo"': 'alt=""',
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    index.write_text(text)

    manifest_path = root / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    manifest['name'] = 'BEMA Discussion Group'
    manifest['short_name'] = 'BEMA Group'
    manifest['background_color'] = '#222222'
    manifest['theme_color'] = '#2A2A2A'
    manifest['description'] = 'Discuss the BEMA podcast together.'
    manifest_path.write_text(json.dumps(manifest, indent=4) + '\n')

    png = wordmark_png()
    for relative in [
        'favicon.png',
        'icons/Icon-192.png',
        'icons/Icon-512.png',
        'icons/Icon-maskable-192.png',
        'icons/Icon-maskable-512.png',
    ]:
        target = root / relative
        if target.parent.exists():
            target.write_bytes(png if '192' in relative or relative == 'favicon.png' else wordmark_png(512))


if __name__ == '__main__':
    main()
