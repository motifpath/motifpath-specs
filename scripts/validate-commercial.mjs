// Validate commercial contract fixtures and every private schema, including schemas not exposed
// through a public endpoint. This checks contract shapes; runtime behavior is covered by TDD later.
import { readFileSync } from 'node:fs'
import Ajv2020 from 'ajv/dist/2020.js'
import addFormats from 'ajv-formats'
import { parse } from 'yaml'
const ajv = new Ajv2020({ strict: false, allErrors: true })
addFormats(ajv)
const documents = ['commerce', 'commercial-messages', 'subscriptions', 'refunds',
  'stripe-checkout', 'commercial-access', 'commercial-audit']
for (const name of documents) {
  ajv.addSchema({ $id: `https://contracts.motifpath.invalid/${name}.yaml`,
    ...parse(readFileSync(`openapi/components/schemas/${name}.yaml`, 'utf8')) })
}
let schemas = 0
for (const name of documents) {
  const source = parse(readFileSync(`openapi/components/schemas/${name}.yaml`, 'utf8'))
  for (const key of Object.keys(source)) {
    ajv.compile({ $ref: `https://contracts.motifpath.invalid/${name}.yaml#/${key}` })
    schemas++
  }
}
const cases = JSON.parse(readFileSync('golden/commercial-contracts/schema-cases.json', 'utf8'))
if (!cases.length) throw new Error('No commercial schema cases')
for (const entry of cases) {
  const validate = ajv.compile({ $ref: `https://contracts.motifpath.invalid/${entry.schema}` })
  if (validate(entry.value) !== entry.valid) {
    throw new Error(`${entry.name}: expected valid=${entry.valid}; ${ajv.errorsText(validate.errors)}`)
  }
}
console.log(`Commercial contracts: ${schemas} schemas compiled; ${cases.length} fixture checks passed`)
