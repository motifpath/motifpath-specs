// Builds curriculum/tree.html, the browsable tree of the curriculum plan, from
// curriculum/plan/ (tracks, paths and courses) and catalogs/knowledge-map.yaml. It flags
// what doesn't fit the map or the principles, but never fails: the plan is a guideline,
// not a contract.
//
// Usage: npm run curriculum:tree
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse } from 'yaml';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const TEMPLATE = join(ROOT, 'scripts/curriculum-tree.template.html');
const PLAN_DIR = join(ROOT, 'curriculum/plan');
const OUT = join(ROOT, 'curriculum/tree.html');

const INSTRUMENTS = {
  guitar: { en: 'Acoustic guitar', pt_BR: 'Violão' },
  'electric-guitar': { en: 'Electric guitar', pt_BR: 'Guitarra' },
  'electric-bass': { en: 'Electric bass', pt_BR: 'Baixo' },
};
const MAP_LEVELS = ['B', 'EI', 'I', 'A'];
const PATH_LEVELS = ['beginner', 'early_intermediate', 'intermediate', 'advanced', 'expert'];
const STATUSES = ['idea', 'planned', 'draft', 'published'];

// The knowledge map

const map = parse(readFileSync(join(ROOT, 'catalogs/knowledge-map.yaml'), 'utf8'));
const nodes = {};
for (const [kind, entries] of [['concept', map.concepts], ['skill', map.skills]]) {
  for (const e of entries) {
    nodes[e.key] = {
      kind, names: e.names, parent: e.parent ?? null, everyInstrument: e.instruments === 'all',
      instruments: e.instruments === 'all' ? Object.keys(INSTRUMENTS) : map.instruments[e.instruments],
      level: e.level ?? null, levels: e.levels ?? {},
    };
  }
}
const requires = {};
for (const e of map.requires) (requires[e.from] ??= []).push(e.to);
// A per-instrument level override is keyed by the alias that names only that instrument.
const soloAliases = Object.fromEntries(Object.keys(INSTRUMENTS).map(i => [i,
  Object.entries(map.instruments).filter(([, keys]) => keys.length === 1 && keys[0] === i).map(([a]) => a)]));

function levelOn(node, instrument) {
  const alias = soloAliases[instrument].find(a => a in node.levels);
  return alias ? node.levels[alias] : node.level;
}

function rootOf(key) {
  while (nodes[key].parent) key = nodes[key].parent;
  return key;
}

const instrumentName = key => INSTRUMENTS[key]?.en ?? key;

// The plan: every .yaml file under curriculum/plan/, merged. Keys are unique across files.

function yamlFiles(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap(e => {
    const p = join(dir, e.name);
    return e.isDirectory() ? yamlFiles(p) : e.name.endsWith('.yaml') ? [p] : [];
  }).sort();
}

const planIssues = [];
const plan = { tracks: [], paths: [], courses: [] };
for (const file of yamlFiles(PLAN_DIR)) {
  const part = parse(readFileSync(file, 'utf8')) ?? {};
  for (const kind of Object.keys(plan)) plan[kind].push(...(part[kind] ?? []));
  for (const kind of Object.keys(part)) {
    if (!(kind in plan)) planIssues.push(`${relative(ROOT, file)}: unknown section ${kind}`);
  }
}
for (const kind of Object.keys(plan)) {
  const seen = new Set();
  for (const { key } of plan[kind]) {
    if (seen.has(key)) planIssues.push(`${kind.slice(0, -1)} key ${key} appears more than once`);
    seen.add(key);
  }
}
const pathsByKey = Object.fromEntries(plan.paths.map(p => [p.key, p]));
const tracksByKey = Object.fromEntries(plan.tracks.map(t => [t.key, t]));
for (const c of plan.courses) {
  if (!tracksByKey[c.track]) planIssues.push(`course ${c.key} has unknown track ${c.track ?? '(none)'}`);
}

// Paths

// The app's classification rule: a node must be for every instrument, or for at least
// one of the content's instruments; content for every instrument may use only nodes for
// every instrument.
function fitIssue(node, contentInstruments) {
  if (node.everyInstrument) return null;
  if (!contentInstruments.length) return 'not for every instrument, as this content is';
  if (contentInstruments.some(i => node.instruments.includes(i))) return null;
  return `not for ${contentInstruments.map(instrumentName).join(' or ')}`;
}

function nodeRef(key, kind, contentInstruments, instrument) {
  const n = nodes[key];
  if (!n || n.kind !== kind) return { key, names: null, level: null, issues: [`not a ${kind} in the knowledge map`] };
  const fit = fitIssue(n, contentInstruments);
  return { key, names: n.names, level: kind === 'skill' ? levelOn(n, instrument) : null, issues: fit ? [fit] : [] };
}

// A path as seen on one instrument. `taughtBefore` holds the skills the track has taught
// before this path; requirements on skills it hasn't are flagged (ADR-043: they never
// lock anything, but a plan should teach in order).
function buildPath(p, instrument, taughtBefore) {
  const instruments = p.instruments ?? [];
  const intent = p.intent ?? {};
  const taughtHere = new Set();
  const outOfOrder = new Set();
  const lessons = (p.lessons ?? []).map(l => {
    const issues = [];
    if (!l.skills?.length) issues.push('needs at least one skill');
    if (!l.concepts?.length) issues.push('needs at least one concept');
    if (!['video', 'article'].includes(l.type)) issues.push(`type ${l.type ?? '(none)'} is not video or article`);
    if (l.level && !PATH_LEVELS.includes(l.level)) issues.push(`unknown level ${l.level}`);
    const skills = (l.skills ?? []).map(k => nodeRef(k, 'skill', instruments, instrument));
    for (const s of skills) {
      if (s.issues.length) continue;
      for (const t of requires[s.key] ?? []) {
        const target = nodes[t];
        if (target.kind !== 'skill' || !target.instruments.includes(instrument) || !nodes[s.key].instruments.includes(instrument)) continue;
        if (!taughtBefore.has(t) && !taughtHere.has(t)) outOfOrder.add(`${s.key} needs ${t}`);
      }
      taughtHere.add(s.key);
    }
    return {
      title: l.title, type: l.type, section: l.section ?? null, level: l.level ?? p.level ?? null, issues, skills,
      concepts: (l.concepts ?? []).map(k => nodeRef(k, 'concept', instruments, instrument)),
    };
  });
  const roles = [
    ...(intent.anchor ? [[intent.anchor, 'anchor']] : []),
    ...(intent.supporting ?? []).map(k => [k, 'supporting']),
    ...(intent.assumes ?? []).map(k => [k, 'assumes']),
    ...(intent.ends_with ? [[intent.ends_with, 'ends_with']] : []),
  ];
  const intentRefs = roles.map(([k, role]) => ({ ...nodeRef(k, 'skill', instruments, instrument), role, taught: taughtHere.has(k) }));

  const issues = [];
  if (!intent.anchor) issues.push('no anchor skill (principle 12)');
  const nSupporting = (intent.supporting ?? []).length;
  if (nSupporting < 2 || nSupporting > 5) issues.push(`${nSupporting} supporting skills; principle 12 asks for 2–5`);
  if (!intent.ends_with) issues.push('no closing play-along (principle 12)');
  if (!PATH_LEVELS.includes(p.level)) issues.push(`unknown level ${p.level ?? '(none)'}`);
  if (!STATUSES.includes(p.status ?? 'idea')) issues.push(`unknown status ${p.status}`);
  if (lessons.length) {
    const missing = intentRefs.filter(s => s.role !== 'assumes' && !s.issues.length && !s.taught).map(s => s.key);
    if (missing.length) issues.push(`no lesson teaches ${missing.join(', ')}`);
  } else if (['planned', 'draft', 'published'].includes(p.status)) {
    issues.push('planned without lessons');
  }
  if (outOfOrder.size) issues.push(`taught before its prerequisite in this track: ${[...outOfOrder].join('; ')}`);
  return {
    path: {
      key: p.key, title: p.title, language: p.language ?? null, level: p.level ?? null,
      shared: !instruments.length, status: p.status ?? 'idea', styles: intent.styles ?? [],
      issues, intent: intentRefs, lessons,
    },
    taught: taughtHere,
  };
}

// The tree: instrument → track → course → path. A track's courses follow its instrument's
// base-track courses, so prerequisites are checked along that whole sequence.

const forInstrument = (entity, i) => !(entity.instruments ?? []).length || entity.instruments.includes(i);
const baseTracks = plan.tracks.filter(t => t.base).map(t => t.key);

function buildCourse(c, instrument, taught) {
  const issues = [];
  const paths = [];
  for (const key of c.checkpoints ?? []) {
    const p = pathsByKey[key];
    if (!p) { issues.push(`checkpoint ${key} is not a path in the plan`); continue; }
    if (p.language !== c.language) issues.push(`${key} is in ${p.language}, the course in ${c.language}`);
    if (!forInstrument(p, instrument)) issues.push(`${key} is not for ${instrumentName(instrument)}`);
    const built = buildPath(p, instrument, taught);
    built.taught.forEach(k => taught.add(k));
    paths.push(built.path);
  }
  if (!paths.length) issues.push('no checkpoints');
  if (!PATH_LEVELS.includes(c.level)) issues.push(`unknown level ${c.level ?? '(none)'}`);
  return { key: c.key, title: c.title, language: c.language, level: c.level, status: c.status ?? 'idea', issues, paths };
}

const tree = Object.keys(INSTRUMENTS).map(instrument => {
  const coursesOf = trackKey => plan.courses.filter(c => c.track === trackKey && forInstrument(c, instrument));
  const baseTaught = new Set();
  for (const t of baseTracks) for (const c of coursesOf(t)) buildCourse(c, instrument, baseTaught);
  const tracks = plan.tracks.map(t => {
    const taught = new Set(t.base ? [] : baseTaught);
    const courses = coursesOf(t.key).map(c => buildCourse(c, instrument, taught));
    return { key: t.key, title: t.title, description: t.description ?? '', base: !!t.base, styles: t.styles ?? [], courses };
  }).filter(t => t.courses.length);
  const inCourse = new Set(plan.courses.filter(c => forInstrument(c, instrument)).flatMap(c => c.checkpoints ?? []));
  const standalone = plan.paths.filter(p => forInstrument(p, instrument) && !inCourse.has(p.key))
    .map(p => buildPath(p, instrument, new Set()).path);
  return { instrument, tracks, standalone };
});

// Coverage: for each instrument, every leaf skill of the map and how far the plan has got
// with it: taught by a planned lesson, only intended, or not yet in the plan.

const coverage = Object.fromEntries(tree.map(({ instrument, tracks, standalone }) => {
  const paths = [...tracks.flatMap(t => t.courses.flatMap(c => c.paths)), ...standalone];
  const state = {};
  for (const p of paths) {
    for (const s of p.intent) if (s.role !== 'assumes' && !s.issues.length) (state[s.key] ??= { lesson: new Set(), intent: new Set() }).intent.add(p.key);
    for (const l of p.lessons) for (const s of l.skills) if (!s.issues.length) (state[s.key] ??= { lesson: new Set(), intent: new Set() }).lesson.add(p.key);
  }
  const groups = new Map();
  for (const [key, n] of Object.entries(nodes)) {
    if (n.kind !== 'skill' || !n.level || !n.instruments.includes(instrument)) continue;
    const root = rootOf(key);
    if (!groups.has(root)) groups.set(root, { names: nodes[root].names, skills: [] });
    const st = state[key];
    groups.get(root).skills.push({
      key, names: n.names, level: levelOn(n, instrument),
      state: st?.lesson.size ? 'lesson' : st?.intent.size ? 'intent' : 'none',
      paths: [...new Set([...(st?.lesson ?? []), ...(st?.intent ?? [])])],
    });
  }
  for (const g of groups.values()) g.skills.sort((a, b) => MAP_LEVELS.indexOf(a.level) - MAP_LEVELS.indexOf(b.level));
  return [instrument, [...groups.values()]];
}));

const data = JSON.stringify({ instruments: INSTRUMENTS, tree, coverage, planIssues }).replaceAll('</', '<\\/');
writeFileSync(OUT, readFileSync(TEMPLATE, 'utf8').replace('/*DATA*/null', data));

function pathIssues(p) {
  return [...p.issues, ...p.intent.flatMap(s => s.issues), ...p.lessons.flatMap(l => [...l.issues, ...l.skills.flatMap(s => s.issues), ...l.concepts.flatMap(s => s.issues)])];
}
const flagged = tree.flatMap(t => [
  ...t.tracks.flatMap(tr => tr.courses.flatMap(c => [...c.issues, ...c.paths.flatMap(pathIssues)])),
  ...t.standalone.flatMap(pathIssues),
]).length + planIssues.length;
for (const issue of planIssues) console.warn(issue);
console.log(`Wrote ${relative(ROOT, OUT)}: ${plan.tracks.length} tracks, ${plan.courses.length} courses, ${plan.paths.length} paths, ${flagged} flagged (counted per instrument and track).`);
