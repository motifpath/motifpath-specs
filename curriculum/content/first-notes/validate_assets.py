"""Offline QA for authored pitch references and practice answer invariants."""
import json, math, struct, wave
from pathlib import Path
ROOT=Path(__file__).parent
m=json.loads((ROOT/'assets/manifest.json').read_text())
assert m['reference_tuning']=={'system':'12-TET','A4_hz':440}
clips={x['id']:x for x in m['audio']}
for c in clips.values():
 p=ROOT/c['path']
 with wave.open(str(p),'rb') as w:
  assert (w.getnchannels(),w.getsampwidth(),w.getframerate())==(1,2,44100)
  a=struct.unpack('<'+'h'*w.getnframes(),w.readframes(w.getnframes()))
  assert max(map(abs,a))<32767 and a[0]==0 and a[-1]==0
  assert len(a)/44100>0.4
  # Single-note references: measure positive-going zero crossings away from fades.
  if len(c['midi'])==1:
   b=a[4410:-4410]; crossings=[i for i in range(1,len(b)) if b[i-1]<=0<b[i]]
   f=(len(crossings)-1)*44100/(crossings[-1]-crossings[0])
   target=440*2**((c['midi'][0]-69)/12)
   assert abs(1200*math.log2(f/target))<2,(c['id'],f,target)
for file in ['practice.json']:
 qs=json.loads((ROOT/file).read_text())['questions']
 for q in qs:
  assert q['correct_option'] in [x['id'] for x in q['options']]
  assert q['rationale'] and q['retry'] and all(x['feedback'] for x in q['options'])
  for x in q['options']:
   if 'audio' in x:assert x['audio'] in clips
 q=next(x for x in qs if x['id']=='A-match-1');r=clips[q['reference_audio']]['midi']
 assert [x['id'] for x in q['options'] if clips[x['audio']]['midi']==r]==[q['correct_option']]
 q=next(x for x in qs if x['id']=='A-match-retry');r=clips[q['reference_audio']]['midi']
 assert [x['id'] for x in q['options'] if clips[x['audio']]['midi']==r]==[q['correct_option']]
 for q in qs:
  if 'expected_fret' in q:assert q['expected_midi']==40+q['expected_fret']
print(f"PASS: {len(clips)} WAV references, measured pitch within 2 cents, no clipping, answer/retry invariants")

# Regeneration must retain non-audio provenance, too.
import tempfile, shutil, subprocess, sys
with tempfile.TemporaryDirectory() as d:
 target=Path(d)
 shutil.copy(ROOT/'assets/generate_audio.py',target/'generate_audio.py')
 shutil.copy(ROOT/'assets/media-metadata.json',target/'media-metadata.json')
 subprocess.run([sys.executable,str(target/'generate_audio.py')],check=True)
 regenerated=json.loads((target/'manifest.json').read_text())
 assert regenerated==m, 'Regeneration changed the committed manifest'
print('PASS: complete manifest is reproducible')
