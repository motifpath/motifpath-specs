import assert from 'node:assert/strict'
import { test } from 'node:test'
import { buildFixture } from './posthog-fixture.mjs'

test('activation includes duplicate delivery and excludes cross-visit exposure', () => {
  const { events, expected } = buildFixture('test', Date.parse('2026-11-08T12:00:00Z'))
  const ready = events.filter(event => event.event === 'mot30_app_ready')
  const items = events.filter(event => event.event === 'mot30_item_usable')
  assert.equal(ready.length, 3)
  assert.equal(items.length, 4)
  assert.deepEqual(items[0], items[1])
  const converted = ready.filter(start => items.some(item =>
    item.properties.distinct_id === start.properties.distinct_id &&
    item.properties.visit_key === start.properties.visit_key &&
    item.timestamp > start.timestamp
  ))
  assert.equal(converted.length, expected.activation.reached)
  assert.equal(ready.length, expected.activation.eligible)
})

test('the later snapshot replaces abandonment with open for the same run', () => {
  const { events, expected } = buildFixture('test', Date.parse('2026-11-08T12:00:00Z'))
  const outcomes = events.filter(event => event.event === 'mot30_practice_outcome')
  for (const [snapshot, counts] of Object.entries(expected.practice)) {
    const rows = outcomes.filter(event => event.properties.snapshot === snapshot)
    assert.equal(new Set(rows.map(event => event.properties.run_key)).size, 4)
    for (const [outcome, count] of Object.entries(counts)) {
      assert.equal(rows.filter(row => row.properties.outcome === outcome).length, count)
    }
  }
  const reopened = outcomes.filter(event => event.properties.run_key === 'test-run-3')
  assert.deepEqual(reopened.map(event => event.properties.outcome), ['abandoned', 'open'])
})
