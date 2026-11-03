import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const repo=path.resolve(root,'../../..');
const require=createRequire(path.join(repo,'package.json'));const {parse}=require('yaml');
const map=parse(fs.readFileSync(path.join(repo,'catalogs/knowledge-map.yaml'),'utf8'));
const nodes=new Map([...map.skills.map(x=>[x.key,{...x,kind:'skill'}]),...map.concepts.map(x=>[x.key,{...x,kind:'concept'}])]);
const activities=JSON.parse(fs.readFileSync(path.join(root,'activities.json'),'utf8'));
assert.equal(activities.length,9);
const seen=new Set();
function validateQuestion(q){
 assert.ok(!seen.has(q.key));seen.add(q.key);
 assert.equal(q.language,'pt_BR');assert.equal(q.difficulty,'beginner');assert.deepEqual(q.instruments,[]);
 assert.equal(q.exercise_type,'text_response');assert.ok(q.prompt&&q.hint&&q.rationale);
 assert.ok(q.options.length>=3);assert.equal(new Set(q.options.map(x=>x.key)).size,q.options.length);
 assert.equal(q.options.filter(x=>x.correct).length,1);
 for(const [kind,keys] of [['skill',q.skill_keys],['concept',q.concept_keys]]){
  assert.ok(keys.length);for(const key of keys){assert.equal(nodes.get(key)?.kind,kind,key);assert.equal(nodes.get(key)?.instruments,'all',key);}
 }
 if(q.evidence?.midi){const [from,to]=q.evidence.midi;assert.equal(to-from,q.evidence.semitones);assert.equal(q.options.find(x=>x.correct).value,q.evidence.semitones);}
 if(q.evidence?.scale){const values=q.evidence.scale;const steps=values.slice(1).map((v,i)=>v-values[i]);assert.deepEqual(steps,[2,2,1,2,2,2,1]);assert.equal(steps.reduce((a,b)=>a+b,0),12);assert.deepEqual(q.options.find(x=>x.correct).value,steps);}
}
for(const q of activities){validateQuestion(q);assert.ok(q.retry);validateQuestion({...q,...q.retry,retry:undefined});}
const assets=JSON.parse(fs.readFileSync(path.join(root,'assets/manifest.json'),'utf8'));
assert.equal(assets.length,8);
for(const asset of assets){const svg=fs.readFileSync(path.join(root,'assets',asset.file),'utf8');assert.ok(svg.includes('<title')&&svg.includes('<desc'));assert.ok(asset.text_alternative&&asset.source&&asset.rights);if(asset.positions){for(const p of asset.positions){assert.equal(p.midi,asset.open_midi+p.fret);if(p.fret>0)assert.ok(p.marker_x>asset.nut_x+(p.fret-1)*asset.fret_width&&p.marker_x<asset.nut_x+asset.fret_width*p.fret);}}
}
for(const file of ['lesson-a.pt-BR.md','lesson-b.pt-BR.md']){
 const text=fs.readFileSync(path.join(root,file),'utf8');const meta=parse(text.split('---')[1]);assert.equal(meta.language,'pt_BR');assert.equal(meta.status,'draft');assert.equal(meta.content_type,'article');assert.deepEqual(meta.instruments,[]);assert.equal(meta.difficulty,'beginner');for(const [kind,keys] of [['skill',meta.skill_keys],['concept',meta.concept_keys]]){assert.ok(keys.length);for(const key of keys){assert.equal(nodes.get(key)?.kind,kind,key);assert.equal(nodes.get(key)?.instruments,'all',key);}}
 for(const target of [...text.matchAll(/!?\[[^\]]*\]\(([^)]+)\)/g)].map(x=>x[1])){if(!target.startsWith('http')&&!target.startsWith('#'))assert.ok(fs.existsSync(path.resolve(root,target.split('#')[0])),target);}
 const ids=[...text.matchAll(/<!-- activity: ([\w-]+) -->/g)].map(x=>x[1]);assert.equal(ids.length,file.includes('lesson-a')?4:5);assert.ok(ids.every(id=>activities.some(q=>q.key===id)));
}
const html=fs.readFileSync(path.join(root,'preview.html'),'utf8');assert.ok(html.includes('lang="pt-BR"'));assert.equal((html.match(/data-activity=/g)||[]).length,18);assert.equal((html.match(/<svg\b/g)||[]).length,8);assert.ok(!/src="https?:/.test(html));assert.ok(!/TODO|\[Fill\]|\[TBD\]/.test(html));
assert.ok(!fs.readdirSync(path.join(root,'assets')).some(f=>/\.(wav|mp3|mp4)$/.test(f)));
console.log('PASS: 2 classified article drafts, 9 activities + 9 retries, pitch/distance metadata, 8 accessible diagrams, self-contained visual preview');
