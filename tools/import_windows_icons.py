#!/usr/bin/env python3
"""Copies the Fugue icons of UpLa for Windows into App/Resources/Assets.xcassets/Fugue (decision 5).

tools/windows-icons.txt lists the icons by their Windows resource name (Resources.<name>). The
name is looked up in the Windows Properties/Resources.resx files, which point at the PNG. Each icon
becomes the image set "Fugue/<name>". When the Windows repo also has "<name>_white" (used on the
dark theme there), it becomes the dark appearance of the same image set, so the Mac picks it in dark
mode by itself. A "<file>@2x.png" next to the Windows file is used as the 2x image; Fugue in the
Windows repo is 16 px only, so there is normally none.

Image sets in the Fugue folder that are no longer listed are removed, so the folder always matches
the list. The icons are CC BY 3.0 by Yusuke Kamiyamane (docs/licenses).

Usage: python -I tools/import_windows_icons.py [WINDOWS_REPO]
WINDOWS_REPO defaults to the UPLA_WINDOWS_REPO environment variable.
"""

import argparse
import json
import os
import re
import shutil
import struct
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIST = os.path.join(ROOT, 'tools', 'windows-icons.txt')
FOLDER = os.path.join(ROOT, 'App', 'Resources', 'Assets.xcassets', 'Fugue')
# Searched in this order; the ShareX project has the menu icons.
RESX_FILES = [
    'ShareX/Properties/Resources.resx',
    'ShareX.HelpersLib/Properties/Resources.resx',
    'ShareX.ScreenCaptureLib/Properties/Resources.resx',
    'ShareX.UploadersLib/Properties/Resources.resx',
    'ShareX.HistoryLib/Properties/Resources.resx',
    'ShareX.ImageEffectsLib/Properties/Resources.resx',
]
INFO = {'author': 'xcode', 'version': 1}


def dump(obj):
    # The way Xcode writes asset catalog JSON.
    return json.dumps(obj, indent=2, separators=(',', ' : '), sort_keys=True) + '\n'


def read_resources(windows_repo):
    """Resource name -> absolute PNG path, first project wins."""
    files = {}
    for resx in RESX_FILES:
        path = os.path.join(windows_repo, resx)
        if not os.path.exists(path):
            continue
        for data in ET.parse(path).getroot().iter('data'):
            value = data.findtext('value') or ''
            if 'ResXFileRef' not in (data.get('type') or '') or not value.lower().split(';')[0].endswith('.png'):
                continue
            relative = value.split(';')[0].replace('\\', '/')
            # The generated C# property turns "picture-sunset" into Resources.picture_sunset.
            name = re.sub(r'[^0-9A-Za-z_]', '_', data.get('name'))
            files.setdefault(name, os.path.normpath(os.path.join(os.path.dirname(path), relative)))
    return files


def png_size(path):
    with open(path, 'rb') as f:
        header = f.read(24)
    if header[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError('not a PNG: ' + path)
    return struct.unpack('>II', header[16:24])


def write(path, text):
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(text)


def main():
    parser = argparse.ArgumentParser(description='Copies the Fugue icons of UpLa for Windows into the asset catalog.')
    parser.add_argument('windows_repo', nargs='?', default=os.environ.get('UPLA_WINDOWS_REPO'),
                        help='the UpLa for Windows repository (default: $UPLA_WINDOWS_REPO)')
    windows_repo = parser.parse_args().windows_repo
    if not windows_repo:
        parser.error('give the Windows repository or set UPLA_WINDOWS_REPO')
    if not os.path.isdir(windows_repo):
        sys.exit('Windows repository not found: ' + windows_repo)
    with open(LIST, encoding='utf-8') as f:
        names = [line.strip() for line in f if line.strip() and not line.startswith('#')]
    if len(set(names)) != len(names):
        sys.exit('Duplicate names in ' + LIST)

    resources = read_resources(windows_repo)
    missing = [name for name in names if name not in resources or not os.path.exists(resources[name])]
    if missing:
        sys.exit('Not found in the Windows resources: ' + ', '.join(missing))

    os.makedirs(FOLDER, exist_ok=True)
    write(os.path.join(FOLDER, 'Contents.json'), dump({'info': INFO, 'properties': {'provides-namespace': True}}))

    dark, retina, problems = [], [], []
    for name in names:
        imageset = os.path.join(FOLDER, name + '.imageset')
        if os.path.isdir(imageset):
            shutil.rmtree(imageset)
        os.makedirs(imageset)
        variants = [(name, None)]
        if name + '_white' in resources:
            variants.append((name + '_white', [{'appearance': 'luminosity', 'value': 'dark'}]))
            dark.append(name)
        images = []
        for resource, appearances in variants:
            source = resources[resource]
            if png_size(source) != (16, 16):
                problems.append('%s is %dx%d, not 16x16' % (resource, *png_size(source)))
            for scale, path in (('1x', source), ('2x', os.path.splitext(source)[0] + '@2x.png')):
                image = {'idiom': 'universal', 'scale': scale}
                if appearances:
                    image['appearances'] = appearances
                if os.path.exists(path):
                    filename = resource + ('' if scale == '1x' else '@2x') + '.png'
                    shutil.copyfile(path, os.path.join(imageset, filename))
                    image['filename'] = filename
                    if scale == '2x':
                        retina.append(resource)
                images.append(image)
        write(os.path.join(imageset, 'Contents.json'), dump({'images': images, 'info': INFO}))

    removed = []
    for entry in sorted(os.listdir(FOLDER)):
        if entry.endswith('.imageset') and entry[:-len('.imageset')] not in names:
            shutil.rmtree(os.path.join(FOLDER, entry))
            removed.append(entry)

    print('Copied %d icons into %s' % (len(names), os.path.relpath(FOLDER, ROOT)))
    print('Dark variants (%d): %s' % (len(dark), ', '.join(dark) or '-'))
    print('2x images (%d): %s' % (len(retina), ', '.join(retina) or '-'))
    if removed:
        print('Removed image sets no longer listed: ' + ', '.join(removed))
    for line in problems:
        print('Problem: ' + line)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
