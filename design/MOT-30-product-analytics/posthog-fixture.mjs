import { createHash, randomUUID } from 'node:crypto'
import { pathToFileURL } from 'node:url'

export function buildFixture(batch, cutoff) {
  const events = []
  function add(event, student, minutesBeforeCutoff, properties) {
    const identity = createHash('sha256').update(`${batch}:${events.length}`).digest('hex')
    const uuid = `${identity.slice(0, 8)}-${identity.slice(8, 12)}-4${identity.slice(13, 16)}-8${identity.slice(17, 20)}-${identity.slice(20, 32)}`
    const row = {
      event,
      uuid,
      timestamp: new Date(cutoff - minutesBeforeCutoff * 60_000).toISOString(),
      properties: { distinct_id: `${batch}-${student}`, fixture_batch: batch, ...properties },
    }
    events.push(row)
    return row
  }

  for (const [student, surface, itemVisit] of [
    ['A', 'browser', 'A1'],
    ['B', 'native_ios', 'B1'],
    ['C', 'browser', 'C2'],
  ]) {
    add('mot30_app_ready', student, 10, { surface, visit_key: `${batch}-${student}1` })
    const item = add('mot30_item_usable', student, 9, { surface, visit_key: `${batch}-${itemVisit}` })
    if (student === 'A') events.push(item)
  }

  // The source supplies the derived run state at each cutoff.
  const initialOutcomes = ['finished', 'early_exit', 'abandoned', 'open']
  for (const [snapshot, minutes] of [['initial', 2], ['reconciled', 0]]) {
    for (const [index, initialOutcome] of initialOutcomes.entries()) {
      const outcome = snapshot === 'reconciled' && initialOutcome === 'abandoned' ? 'open' : initialOutcome
      add('mot30_practice_outcome', `practice-${index + 1}`, minutes, {
        snapshot,
        outcome,
        run_key: `${batch}-run-${index + 1}`,
        exercise_kind: 'authored_choice',
      })
    }
  }

  return {
    events,
    expected: {
      activation: { reached: 2, eligible: 3, browser: '1/2', native_ios: '1/1' },
      practice: {
        initial: { finished: 1, early_exit: 1, abandoned: 1, open: 1 },
        reconciled: { finished: 1, early_exit: 1, abandoned: 0, open: 2 },
      },
    },
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.stdout.write(JSON.stringify(buildFixture(`mot30-${randomUUID()}`, Date.now()), null, 2) + '\n')
}
