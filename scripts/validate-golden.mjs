// Validates the grader golden cases in golden/practice-graders/: each file against
// schema.json, its file name against its grader id, and every case's item_key and
// response against the OpenAPI practice schemas, so the cases can't drift from the
// contract the clients send.

import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import Ajv2020 from 'ajv/dist/2020.js'
import addFormats from 'ajv-formats'
import { parse } from 'yaml'

const dir = 'golden/practice-graders'
const ajv = new Ajv2020({ allErrors: true, strict: false })
addFormats(ajv)

const validateFile = ajv.compile(JSON.parse(readFileSync(join(dir, 'schema.json'), 'utf8')))

// practice.yaml is a set of OpenAPI 3.1 schemas with local refs ('#/Name'); register it
// as one JSON Schema document so those refs resolve.
const practice = parse(readFileSync('openapi/components/schemas/practice.yaml', 'utf8'))
ajv.addSchema({ $id: 'practice.yaml', $defs: practice })
const rewriteRefs = (node) => {
  if (Array.isArray(node)) return node.forEach(rewriteRefs)
  if (node && typeof node === 'object') {
    if (typeof node.$ref === 'string') node.$ref = node.$ref.replace(/^#\//, 'practice.yaml#/$defs/')
    delete node.discriminator
    delete node.example
    Object.values(node).forEach(rewriteRefs)
  }
}
rewriteRefs(practice)
const validateKey = ajv.compile({ $ref: 'practice.yaml#/$defs/PracticeItemKey' })
const validateResponse = ajv.compile({ $ref: 'practice.yaml#/$defs/PracticeResponse' })

let failures = 0
const fail = (msg, errors) => {
  failures++
  console.error(`✗ ${msg}`)
  if (errors) console.error(ajv.errorsText(errors, { separator: '\n    ' }).replace(/^/, '    '))
}

const files = readdirSync(dir).filter((f) => f.endsWith('.json') && f !== 'schema.json')
for (const file of files) {
  const golden = JSON.parse(readFileSync(join(dir, file), 'utf8'))
  if (!validateFile(golden)) {
    fail(`${file}: not a valid golden-case file`, validateFile.errors)
    continue
  }
  if (`${golden.grader}.json` !== file) fail(`${file}: grader "${golden.grader}" doesn't match the file name`)
  for (const c of golden.cases) {
    if (!validateKey(c.item_key)) fail(`${file} / ${c.name}: item_key`, validateKey.errors)
    if (!validateResponse(c.response)) fail(`${file} / ${c.name}: response`, validateResponse.errors)
  }
  console.log(`${file}: ${golden.cases.length} cases`)
}

if (files.length === 0) fail(`no golden-case files in ${dir}`)

// Chord symbol parser cases in golden/chord-symbols/: each file against its schema.json, its
// file name against its parser id, and every parsed result against ParsedChordSymbol in the
// Core Domain Service schemas, so the cases can't drift from what searchChords returns.
const chordDir = 'golden/chord-symbols'
const validateChordFile = ajv.compile(JSON.parse(readFileSync(join(chordDir, 'schema.json'), 'utf8')))
const coreSchemas = parse(readFileSync('openapi/core-domain-service.yaml', 'utf8')).components.schemas
const rewriteCoreRefs = (node) => {
  if (Array.isArray(node)) return node.forEach(rewriteCoreRefs)
  if (node && typeof node === 'object') {
    if (typeof node.$ref === 'string') node.$ref = node.$ref.replace(/^#\/components\/schemas\//, 'core.yaml#/$defs/')
    delete node.discriminator
    delete node.example
    Object.values(node).forEach(rewriteCoreRefs)
  }
}
rewriteCoreRefs(coreSchemas)
ajv.addSchema({ $id: 'core.yaml', $defs: coreSchemas })
const validateParsed = ajv.compile({ $ref: 'core.yaml#/$defs/ParsedChordSymbol' })

const chordFiles = readdirSync(chordDir).filter((f) => f.endsWith('.json') && f !== 'schema.json')
for (const file of chordFiles) {
  const golden = JSON.parse(readFileSync(join(chordDir, file), 'utf8'))
  if (!validateChordFile(golden)) {
    fail(`${file}: not a valid chord-symbol golden-case file`, validateChordFile.errors)
    continue
  }
  if (`${golden.parser}.json` !== file) fail(`${file}: parser "${golden.parser}" doesn't match the file name`)
  for (const c of golden.cases) {
    if (c.expected.status === 'parsed' && !validateParsed(c.expected.parsed)) {
      fail(`${file} / ${c.name}: parsed`, validateParsed.errors)
    }
  }
  console.log(`${file}: ${golden.cases.length} cases`)
}
if (chordFiles.length === 0) fail(`no golden-case files in ${chordDir}`)

// ChordPro import/export cases in golden/chordpro/: each file against its schema.json, its file
// name against its format id, every imported body against SongChartDocument and every warning
// against ChordProImportWarning, so the cases can't drift from what the import returns.
const chordProDir = 'golden/chordpro'
const validateChordProFile = ajv.compile(JSON.parse(readFileSync(join(chordProDir, 'schema.json'), 'utf8')))
const validateDocument = ajv.compile({ $ref: 'core.yaml#/$defs/SongChartDocument' })
const validateImportWarning = ajv.compile({ $ref: 'core.yaml#/$defs/ChordProImportWarning' })

const chordProFiles = readdirSync(chordProDir).filter((f) => f.endsWith('.json') && f !== 'schema.json')
for (const file of chordProFiles) {
  const golden = JSON.parse(readFileSync(join(chordProDir, file), 'utf8'))
  if (!validateChordProFile(golden)) {
    fail(`${file}: not a valid ChordPro golden-case file`, validateChordProFile.errors)
    continue
  }
  if (`${golden.format}.json` !== file) fail(`${file}: format "${golden.format}" doesn't match the file name`)
  for (const c of golden.cases) {
    if (!validateDocument(c.expected.body)) fail(`${file} / ${c.name}: body`, validateDocument.errors)
    for (const w of c.expected.import_warnings) {
      if (!validateImportWarning(w)) fail(`${file} / ${c.name}: import warning`, validateImportWarning.errors)
    }
  }
  console.log(`${file}: ${golden.cases.length} cases`)
}
if (chordProFiles.length === 0) fail(`no golden-case files in ${chordProDir}`)

if (failures > 0) {
  console.error(`${failures} problem(s)`)
  process.exit(1)
}
