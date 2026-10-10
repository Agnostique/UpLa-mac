#!/usr/bin/env python3
"""Imports the texts of UpLa for Windows into App/Resources/Localizable.xcstrings.

The Windows app is the single source of the menu texts (docs/parity, plan §2.7). Each line of
tools/windows-strings.txt names one Windows text:

    <resx base path relative to the Windows repo>|<resource key>[|<catalog key>]

for example "ShareX/Forms/MainForm|tsddbCapture.Text". English comes from <base>.resx and Turkish
from <base>.tr.resx. "UplaStrings|<Property>" reads T("tr", "en") from
ShareX.HelpersLib/Upla/UplaStrings.cs. The catalog key is the English text; the optional third
field gives a different key where two Windows texts share an English text but not a Turkish one.

The texts are adapted the same way every time: WinForms mnemonics are removed ("&&" -> "&"),
"..." becomes "…" (decision 6c), "{0}" becomes "%@", and the platform words of plan §3.2 are
replaced. Keys that are not in the manifest (the Mac-specific texts) are never touched. The imported
keys are marked "manual": the app looks them up at run time (MenuBuilder), so Xcode finds no literal
for them and must not mark them stale.

The English side of the platform table below is also written to UplaKit as MenuText.macReplacements,
so the app makes the same keys from the Windows texts (MenuSpec, HotkeyType).

Usage: python -I tools/import_windows_strings.py [WINDOWS_REPO] [--check]
WINDOWS_REPO defaults to the UPLA_WINDOWS_REPO environment variable.
--check only reports what would change and writes nothing. Nothing is written when there are problems.
"""

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, 'tools', 'windows-strings.txt')
CATALOG = os.path.join(ROOT, 'App', 'Resources', 'Localizable.xcstrings')
PLATFORM_SWIFT = os.path.join(ROOT, 'UplaKit', 'Sources', 'UplaKit', 'Parity', 'PlatformTexts.swift')
UPLA_STRINGS = os.path.join('ShareX.HelpersLib', 'Upla', 'UplaStrings.cs')

# Plan §3.2: the only Windows texts the Mac changes. Windows English -> (Mac English, Mac Turkish);
# None keeps the Windows Turkish. Rows for texts not in the manifest yet are kept for later steps.
PLATFORM_TEXTS = {
    'UpLa is minimized to the system tray.':
        ('UpLa keeps running in the menu bar.', 'UpLa menü çubuğunda çalışmaya devam ediyor.'),
    'Show tray icon': ('Show menu bar icon', 'Menü çubuğunda simge göster'),
    'Minimize to tray on start': ("Don't show the window at launch", 'Açılışta pencereyi gösterme'),
    'Show progress in tray icon': ('Show progress in menu bar icon', 'Menü çubuğu simgesinde durum göster'),
    'Show progress in taskbar button': ('Show progress in Dock icon', 'Dock simgesinde durum göster'),
    'On tray icon left click:':
        ('On menu bar icon left click:', 'Menü çubuğu simgesine bir kere tıklandığında:'),
    'On tray icon double left click:':
        ('On menu bar icon double left click:', 'Menü çubuğu simgesine çift tıklandığında:'),
    'On tray icon middle click:':
        ('On menu bar icon middle click:', 'Menü çubuğu simgesine orta tuş ile tıklandığında:'),
    'Toggle tray menu': ('Toggle menu bar menu', 'Menü çubuğu menüsünü aç/kapat'),
    'Show recent tasks in tray menu':
        ('Show recent tasks in menu bar menu', 'Menü çubuğu menüsünde son görevleri göster'),
    'In tray menu show most recent tasks first':
        ('In menu bar menu show most recent tasks first', 'Menü çubuğu menüsünde son görevleri ilk göster'),
    # NSMenuItem cannot tell a right click; ⌥ turns the row into its "open" alternate (plan §3.1).
    'Left click to copy URL to clipboard. Right click to open URL.':
        ('Click to copy URL to clipboard. Option-click to open URL.',
         'Adresi kopyalamak için tıklayın. Adresi açmak için ⌥ ile tıklayın.'),
    'Run UpLa when Windows starts': ('Run UpLa when you log in', "Oturum açıldığında UpLa'yı çalıştır"),
    'Show "Upload with UpLa" button in Windows Explorer context menu':
        ('Show "Upload with UpLa" in Finder Quick Actions',
         '"UpLa ile yükle"yi Finder\'ın Hızlı İşlemler menüsünde göster'),
    'Show "Edit with UpLa" button in Windows Explorer context menu':
        ('Show "Edit with UpLa" in Finder Quick Actions',
         '"UpLa ile düzenle"yi Finder\'ın Hızlı İşlemler menüsünde göster'),
    'Show UpLa in "Send to" menu': ('Show UpLa in the Share menu', 'Paylaş menüsünde UpLa göster'),
    "Don't show Windows print dialog": ("Don't show the system print dialog", 'Sistem yazdırma penceresini gösterme'),
    'Show file in explorer': ('Show file in Finder', None),
    'Your anti-virus software or the controlled folder access feature in Windows could be blocking UpLa.':
        ('UpLa may not be allowed to write to the folder; check System Settings › Privacy & Security.',
         'Klasöre yazma izni yok olabilir; Sistem Ayarları › Gizlilik ve Güvenlik\'i kontrol edin.'),
}

# Words that should not reach the Mac; a text that still has one after the table above is reported.
PLATFORM_WORDS = re.compile(r'Windows|Explorer|\btray\b|taskbar|\bCtrl\b|\bWin\b|Print Screen|Recycle Bin|'
                            r'Gezgin|[Tt]epsi|[Gg]örev çubuğu|Geri Dönüşüm|sistem tepsisi', re.UNICODE)


def dump(catalog):
    # Xcode's spacing, keys sorted by code point: the format the file has had so far (Xcode has not saved it yet and
    # may order the keys differently). The file is checked against it before anything is changed, so a catalog that
    # Xcode rewrote stops the script; then make this match Xcode's order.
    return json.dumps(catalog, indent=2, separators=(',', ' : '), sort_keys=True, ensure_ascii=False) + '\n'


def swift_literal(text):
    # JSON's escapes (\" \\ \n) are valid in Swift; ensure_ascii=False leaves the letters as they are.
    return json.dumps(text, ensure_ascii=False)


def platform_swift():
    lines = ['// Generated by tools/import_windows_strings.py from its PLATFORM_TEXTS table (plan §3.2); do not edit.',
             '',
             'extension MenuText {',
             '    /// The Windows English texts the Mac changes, and the Mac English text that is their catalog key.',
             '    public static let macReplacements: [String: String] = [']
    rows = sorted((windows, mac) for windows, (mac, _) in PLATFORM_TEXTS.items())
    for index, (windows, mac) in enumerate(rows):
        lines.append('        %s: %s%s' % (swift_literal(windows), swift_literal(mac), ',' if index < len(rows) - 1 else ''))
    lines += ['    ]', '}', '']
    return '\n'.join(lines)


_resx_cache = {}


def read_resx(path):
    if path not in _resx_cache:
        values = {}
        if os.path.exists(path):
            for data in ET.parse(path).getroot().iter('data'):
                value = data.find('value')
                if data.get('type') is None and value is not None:
                    values[data.get('name')] = value.text or ''
        _resx_cache[path] = values if os.path.exists(path) else None
    return _resx_cache[path]


def parse_cs_literal(text, pos):
    """Reads a regular C# string literal starting at text[pos] == '"'; returns (value, end)."""
    assert text[pos] == '"'
    out, i = [], pos + 1
    escapes = {'"': '"', '\\': '\\', 'n': '\n', 't': '\t', 'r': '\r', '0': '\0', "'": "'"}
    while text[i] != '"':
        if text[i] == '\\':
            out.append(escapes[text[i + 1]])
            i += 2
        else:
            out.append(text[i])
            i += 1
    return ''.join(out), i + 1


_upla_cache = {}


def read_upla_strings(windows_repo):
    if not _upla_cache:
        with open(os.path.join(windows_repo, UPLA_STRINGS), encoding='utf-8-sig') as f:
            source = f.read()
        for match in re.finditer(r'public static string (\w+) => ', source):
            name, pos = match.group(1), match.end()
            call = source.find('T(', pos)
            if call < 0 or ';' in source[pos:call]:
                continue
            i = call + 2
            literals = []
            while len(literals) < 2:
                while source[i] in ' \t\r\n,':
                    i += 1
                if source[i] != '"':
                    break
                value, i = parse_cs_literal(source, i)
                literals.append(value)
            if len(literals) == 2:
                # T(turkish, english); anything around the call (a prefix like "UpLa - ") is not part of the text.
                plain = source[pos:call].strip() == '' and re.match(r'\s*\)\s*;', source[i:]) is not None
                _upla_cache[name] = (literals[1], literals[0], plain)
    return _upla_cache


def strip_mnemonics(text):
    # WinForms: "&&" shows "&", a single "&" underlines the next letter.
    return re.sub(r'&(&?)', lambda m: '&' if m.group(1) else '', text)


def to_format(text):
    """{0} {1} -> %@ (positional when out of order); a literal % is doubled only in format strings."""
    indexes = [int(n) for n in re.findall(r'\{(\d+)\}', text)]
    if not indexes:
        return text
    text = text.replace('%', '%%')
    if indexes == list(range(len(indexes))):
        return re.sub(r'\{\d+\}', '%@', text)
    return re.sub(r'\{(\d+)\}', lambda m: '%%%d$@' % (int(m.group(1)) + 1), text)


def adapt(english, turkish):
    english, turkish = strip_mnemonics(english), strip_mnemonics(turkish)
    if english in PLATFORM_TEXTS:
        mac_english, mac_turkish = PLATFORM_TEXTS[english]
        english, turkish = mac_english, mac_turkish or turkish
    english, turkish = english.replace('...', '…'), turkish.replace('...', '…')
    return to_format(english), to_format(turkish)


def specifiers(text):
    return sorted(re.findall(r'%(?:\d+\$)?[@dlfsu]+', text.replace('%%', '')))


def read_manifest(path):
    entries = []
    with open(path, encoding='utf-8') as f:
        for number, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            fields = line.split('|')
            if len(fields) not in (2, 3) or not all(fields):
                sys.exit('%s:%d: expected "<resx base>|<key>[|<catalog key>]": %s' % (path, number, line))
            entries.append((number, fields[0], fields[1], fields[2] if len(fields) == 3 else None))
    return entries


def main():
    parser = argparse.ArgumentParser(description='Imports the texts of UpLa for Windows into Localizable.xcstrings.')
    parser.add_argument('windows_repo', nargs='?', default=os.environ.get('UPLA_WINDOWS_REPO'),
                        help='the UpLa for Windows repository (default: $UPLA_WINDOWS_REPO)')
    parser.add_argument('--check', action='store_true', help='only report what would change')
    options = parser.parse_args()
    check_only, windows_repo = options.check, options.windows_repo
    if not windows_repo:
        parser.error('give the Windows repository or set UPLA_WINDOWS_REPO')
    if not os.path.isdir(windows_repo):
        sys.exit('Windows repository not found: ' + windows_repo)

    problems, missing_turkish, notes = [], [], []
    imported = {}  # catalog key -> (english, turkish, source)
    for number, base, key, catalog_key in read_manifest(MANIFEST):
        source = '%s|%s' % (base, key)
        if base == 'UplaStrings':
            entry = read_upla_strings(windows_repo).get(key)
            if entry is None:
                problems.append('line %d: %s not found in %s' % (number, source, UPLA_STRINGS))
                continue
            english, turkish, plain = entry
            if not plain:
                notes.append('%s: only the T(...) part is imported' % source)
        else:
            neutral = read_resx(os.path.join(windows_repo, base + '.resx'))
            if neutral is None:
                problems.append('line %d: %s.resx not found' % (number, base))
                continue
            if key not in neutral:
                problems.append('line %d: %s not found' % (number, source))
                continue
            english = neutral[key]
            turkish = (read_resx(os.path.join(windows_repo, base + '.tr.resx')) or {}).get(key)
            if not turkish:
                missing_turkish.append(source + ' (' + english + ')')
                turkish = english
        english, turkish = adapt(english, turkish)
        for text in (english, turkish):
            if PLATFORM_WORDS.search(text):
                notes.append('%s: platform word left in "%s"' % (source, text))
        catalog_key = catalog_key or english
        if catalog_key in imported:
            previous = imported[catalog_key]
            if previous[:2] != (english, turkish):
                problems.append('line %d: %s gives "%s" a different text than %s (%s / %s); add a catalog key'
                                % (number, source, catalog_key, previous[2], previous[1], turkish))
            continue
        imported[catalog_key] = (english, turkish, source)

    with open(CATALOG, encoding='utf-8', newline='') as f:
        original = f.read()
    catalog = json.loads(original)
    if dump(catalog) != original:
        sys.exit('The catalog is not in the expected format; nothing was changed.')

    strings = catalog['strings']
    added, changed = [], []
    for key, (english, turkish, source) in sorted(imported.items()):
        if specifiers(english) != specifiers(turkish):
            problems.append('%s: format specifiers differ: "%s" / "%s"' % (source, english, turkish))
        entry = strings.setdefault(key, {})
        localizations = entry.setdefault('localizations', {})
        old = {lang: localizations.get(lang, {}).get('stringUnit', {}).get('value') for lang in ('en', 'tr')}
        if old['en'] is None and old['tr'] is None:
            added.append(key)
        elif old != {'en': english, 'tr': turkish}:
            changed.append('%s: en %r -> %r, tr %r -> %r' % (key, old['en'], english, old['tr'], turkish))
        localizations['en'] = {'stringUnit': {'state': 'translated', 'value': english}}
        localizations['tr'] = {'stringUnit': {'state': 'translated', 'value': turkish}}
        entry['extractionState'] = 'manual'
        if key != english:
            entry['comment'] = 'Same English as another menu text, different Turkish (%s).' % source

    output = dump(catalog)
    json.loads(output)
    swift = platform_swift()
    try:
        with open(PLATFORM_SWIFT, encoding='utf-8', newline='') as f:
            swift_changed = f.read() != swift
    except FileNotFoundError:
        swift_changed = True
    if swift_changed:
        notes.append('%s %s' % (os.path.relpath(PLATFORM_SWIFT, ROOT).replace(os.sep, '/'),
                                'would change' if check_only or problems else 'regenerated'))

    if not check_only and not problems:
        if output != original:
            with open(CATALOG, 'w', encoding='utf-8', newline='') as f:
                f.write(output)
        if swift_changed:
            with open(PLATFORM_SWIFT, 'w', encoding='utf-8', newline='') as f:
                f.write(swift)

    sys.stdout.reconfigure(encoding='utf-8')
    print('Imported %d texts: %d new keys, %d changed keys, %d unchanged%s.'
          % (len(imported), len(added), len(changed), len(imported) - len(added) - len(changed),
             ' (check only, nothing written)' if check_only else
             ' (nothing written because of the problems below)' if problems else ''))
    for title, lines in (('Missing Turkish (English used)', missing_turkish), ('Changed existing keys', changed),
                         ('Notes', notes), ('Problems', problems)):
        if lines:
            print('\n%s (%d):' % (title, len(lines)))
            for line in lines:
                print('  ' + line)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
