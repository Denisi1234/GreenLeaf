"""Apply the reviewed catalog to literal UI messages; keep domain values intact."""
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
audit = json.loads((root / 'tool/localization_audit.json').read_text(encoding='utf-8'))
overrides = json.loads((root / 'tool/sw_overrides.json').read_text(encoding='utf-8'))
catalog = {**audit['existing'], **overrides}

def dart(value):
    return "'" + value.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\r', '\\r').replace('\n', '\\n') + "'"

missing = {e['key'] for e in audit['entries']} - catalog.keys()
assert not missing, sorted(missing)
for lang in ('en', 'sw'):
    lines = [f'const {lang}UiCatalog = <String, String>{{']
    for key, sw in sorted(catalog.items()):
        value = sw if lang == 'sw' else key.replace('\ufffd', '…')
        if lang == 'en' and key == 'TrackMauzo haikuweza kuanza':
            value = 'TrackMauzo could not start'
        lines.append(f'  {dart(key)}: {dart(value)},')
    lines.append('};\n')
    mode = 'w' if lang == 'en' else 'a'
    with (root / 'lib/l10n/ui_catalog.dart').open(mode, encoding='utf-8') as f:
        if lang == 'en':
            f.write('// Shared interface text. Keys remain stable across languages.\n')
        f.write('\n'.join(lines))

if '--catalog-only' in sys.argv:
    print(f'Generated {len(catalog)} catalog entries.')
    sys.exit(0)

files = {}
for entry in audit['entries']:
    if entry['context'] is not None and entry['file'] != 'lib/ui/payment/cash_register_page.dart':
        files.setdefault(entry['file'], []).append(entry)
for name, entries in files.items():
    path = root / name
    source = path.read_bytes().decode('utf-8')
    original_source = source
    # Analyzer offsets use UTF-16 code units, including emoji in preceding text.
    def index(offset):
        return len(original_source.encode('utf-16-le')[:offset * 2].decode('utf-16-le'))
    edits = {}
    for e in entries:
        args = ', '.join(f"'p{i}': {arg}" for i, arg in enumerate(e['args']))
        replacement = f"context.tr({dart(e['key'])}" + (f', args: {{{args}}}' if args else '') + ')'
        edits[e['offset'], e['length']] = replacement
        for c in e['constants']:
            edits[c['offset'], c['length']] = 'final' if c.get('final') else ''
    for (offset, length), text in sorted(edits.items(), reverse=True):
        start, end = index(offset), index(offset + length)
        source = source[:start] + text + source[end:]
    if 'package:track_mauzo/l10n/app_localization.dart' not in source:
        source = "import 'package:track_mauzo/l10n/app_localization.dart';\n" + source
    path.write_bytes(source.encode('utf-8'))
print(f'Localized {sum(map(len, files.values()))} messages in {len(files)} files; {len(catalog)} catalog entries.')
