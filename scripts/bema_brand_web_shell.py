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


def wordmark_png(size: int = 192) -> bytes:
    """Solid #2A2A2A tile. The in-app wordmark is text; this is only the favicon."""
    row = b'\x00' + bytes([0x2A, 0x2A, 0x2A]) * size
    raw = zlib.compress(row * size)
    return b''.join(
        [
            b'\x89PNG\r\n\x1a\n',
            _chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)),
            _chunk(b'IDAT', raw),
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
        '<h1>Belong on the Spectrum</h1>': '<h1>BEMA Discussion Group</h1>',
        '<p>You belong here.</p>': '<p>Discuss the BEMA podcast together.</p>',
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
