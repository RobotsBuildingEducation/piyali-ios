#!/usr/bin/env python3
"""Pair the source/native component attachments exported by xcresulttool."""
import argparse, json
from pathlib import Path
from PIL import Image, ImageDraw
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('attachments',type=Path)
parser.add_argument('--output',type=Path,default=Path('docs/native'))
args=parser.parse_args()
attachments=[a for test in json.loads((args.attachments/'manifest.json').read_text()) for a in test['attachments']]
args.output.mkdir(parents=True,exist_ok=True)
for language in ('en','ar'):
    for state in ('deck','initial','wrong','correct'):
        def find(prefix):
            name=f'{prefix} flashcard {state} {language}_'
            matches=[a for a in attachments if a['suggestedHumanReadableName'].startswith(name) and a['exportedFileName'].endswith('.png')]
            if len(matches)!=1: raise ValueError(f'Expected one attachment for {name}, found {len(matches)}')
            return Image.open(args.attachments/matches[0]['exportedFileName']).convert('RGB').resize((402,874),Image.Resampling.LANCZOS)
        source,native=find('Source'),find('Native')
        output=Image.new('RGB',(804,902),'white');output.paste(source,(0,28));output.paste(native,(402,28))
        labels=ImageDraw.Draw(output);labels.text((12,8),'Web reference',fill='black');labels.text((414,8),'Native Swift',fill='black')
        path=args.output/f'flashcards-{state}-{language}.png';output.save(path,optimize=True);print(path)
