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
if (failures > 0) {
  console.error(`${failures} problem(s)`)
  process.exit(1)
}
