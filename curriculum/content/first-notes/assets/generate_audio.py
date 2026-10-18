"""Original synthetic pitch references. Standard library only; no speech or guitar samples."""
import json,math,struct,wave
from pathlib import Path
ROOT=Path(__file__).parent
SR=44100
SPECS=[('A-phrase',[60,62,64],.65),('A-direction',[64,60],.9),('A-octave',[60,72],1.0),('A-semitone',[64,65],1.0),('A-tone',[60,62],1.0),('A-enharmonic',[61,61],1.0),('A-twelve',list(range(60,73)),.45),('q1-ref',[60],1.2),('q1-a',[62],1.2),('q1-b',[59],1.2),('q1-c',[60],1.2),('q2-ref',[64],1.2),('q2-a',[64],1.2),('q2-b',[62],1.2),('q2-c',[65],1.2),('B-phrase',[40,41,43,41,40],.85)]+[(f'B-fret-{f}',[40+f],1.2)for f in range(6)]
manifest={'version':'1.0.0-draft','reference_tuning':{'system':'12-TET','A4_hz':440},'source':'Original sine-wave synthesis. Electronic reference tones, not recordings of an instrument or human performance.','rights':'Created for MotifPath internal editorial pilot; no third-party samples. Publication clearance pending human review.','audio':[]}
(ROOT/'audio').mkdir(exist_ok=True)
for ident,midis,duration in SPECS:
 samples=[0]*int(.15*SR)
 for midi in midis:
  hz=440*2**((midi-69)/12);n=int(duration*SR);fade=int(.025*SR)
  for i in range(n):
   env=min(1,i/fade,(n-1-i)/fade)
   samples.append(round(7000*env*math.sin(2*math.pi*hz*i/SR)))
  samples.extend([0]*int(.2*SR))
 with wave.open(str(ROOT/'audio'/f'{ident}.wav'),'wb')as w:
  w.setparams((1,2,SR,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(samples),*samples))
 manifest['audio'].append({'id':ident,'path':f'assets/audio/{ident}.wav','midi':midis,'frequency_hz':[round(440*2**((v-69)/12),6)for v in midis],'note_duration_seconds':duration,'duration_seconds':len(samples)/SR,'accessible_description':f'Electronic pitch reference; MIDI sequence {midis}; no speech.','learner_labels_hidden':ident.startswith('q'),'source':'generate_audio.py','rights':'Original synthesis for this internal pilot; no third-party samples.'})
manifest.update(json.loads((ROOT/'media-metadata.json').read_text()))
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
