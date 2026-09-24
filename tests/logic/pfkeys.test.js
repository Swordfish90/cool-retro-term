'use strict'
/**
 * Tests for the IBM PF/PA key model (app/qml/logic/pfkeys.js).
 *
 * Run with:  node --test tests/logic
 */
const { test } = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

const PfKeys = require(path.join(__dirname, '..', '..', 'app', 'qml', 'logic', 'pfkeys.js'))

test('keyboard shape matches an IBM 3270 family terminal', () => {
  assert.equal(PfKeys.PF_COUNT, 12, 'twelve PF keys')
  assert.equal(PfKeys.PA_COUNT, 3, 'three Program Attention keys')
  assert.equal(PfKeys.KEY_COUNT, 15)
})

test('default PF slots are F1..F12 in order', () => {
  for (let i = 0; i < 12; i++) {
    assert.equal(PfKeys.defaultKeyFor(i), `F${i + 1}`)
    assert.equal(PfKeys.defaultLabelFor(i), `PF${i + 1}`)
    assert.ok(PfKeys.isPf(i))
  }
  assert.equal(PfKeys.isPf(12), false)
})

test('PA slots use the IBM PC/3270 default bindings', () => {
  // IBM: PA1 = Ctrl+F1, PA2 = Ctrl+F2, PA3 = Ctrl+F3.
  assert.equal(PfKeys.defaultKeyFor(12), 'Ctrl+F1')
  assert.equal(PfKeys.defaultKeyFor(13), 'Ctrl+F2')
  assert.equal(PfKeys.defaultKeyFor(14), 'Ctrl+F3')
  assert.equal(PfKeys.defaultLabelFor(12), 'PA1')
  assert.equal(PfKeys.defaultLabelFor(14), 'PA3')
})

test('defaults are pass-through for PF keys so enabling the bar changes nothing', () => {
  const defs = PfKeys.defaultAssignments()
  assert.equal(defs.length, PfKeys.KEY_COUNT)
  for (let i = 0; i < 12; i++) {
    assert.equal(defs[i].action, 'pass')
    assert.equal(PfKeys.intercepts(defs[i]), false,
      `PF${i + 1} must not be intercepted by default`)
  }

  // ... but the bar as a whole is NOT inert: PA1 ships as the 3270 attention
  // key, which is exactly what a real terminal does out of the box.
  assert.equal(PfKeys.anyIntercepting(defs), true)
  const allPass = defs.map(a => ({ ...a, action: 'pass' }))
  assert.equal(PfKeys.anyIntercepting(allPass), false)
})

test('PA1 defaults to the 3270 attention/break key', () => {
  const defs = PfKeys.defaultAssignments()
  const pa1 = defs[12]
  assert.equal(pa1.action, 'interrupt')
  assert.equal(PfKeys.intercepts(pa1), true)
  const act = PfKeys.actionById('interrupt')
  assert.equal(act.kind, 'term')
  // SIGINT == Ctrl+C
  assert.equal(act.payload, '\u0003')
})

test('attention and erase-input payloads are the POSIX equivalents', () => {
  assert.equal(PfKeys.actionById('interrupt').payload, '\u0003')
  assert.equal(PfKeys.actionById('eraseInput').payload, '\u0015') // Ctrl+U
})

test('every action id referenced by a slot exists in the catalogue', () => {
  const ids = PfKeys.actionIds()
  assert.ok(ids.includes('newWindow'))
  assert.ok(ids.includes('nextWindow'))
  assert.ok(ids.includes('closeWindow'))
  assert.ok(ids.includes('interrupt'))
  assert.ok(ids.includes('sendText'))
  for (const id of ids) {
    assert.ok(PfKeys.isKnownAction(id), `catalogue contains ${id}`)
  }
  assert.equal(PfKeys.isKnownAction('definitelyNotAnAction'), false)
})

test('normalize repairs short, null and unknown input', () => {
  assert.equal(PfKeys.normalize(null).length, PfKeys.KEY_COUNT)
  assert.equal(PfKeys.normalize(undefined).length, PfKeys.KEY_COUNT)
  assert.equal(PfKeys.normalize([]).length, PfKeys.KEY_COUNT)
  assert.equal(PfKeys.normalize('garbage').length, PfKeys.KEY_COUNT)

  const half = [{ action: 'newWindow' }]
  const out = PfKeys.normalize(half)
  assert.equal(out.length, PfKeys.KEY_COUNT)
  assert.equal(out[0].action, 'newWindow')
  assert.equal(out[0].key, 'F1', 'missing key falls back to the slot default')
  assert.equal(out[1].action, 'pass', 'missing slots fall back to defaults')
  assert.equal(out[0].label, 'PF1')
})

test('normalize replaces unknown action ids with the default', () => {
  const out = PfKeys.normalize([{ action: 'launchMissiles', key: 'F1' }])
  assert.equal(out[0].action, 'pass')
})

test('serialize/parse round trips', () => {
  const list = PfKeys.defaultAssignments()
  list[0] = { key: 'F1', label: 'PF1', action: 'nextWindow', payload: '' }
  list[3] = { key: 'Ctrl+Alt+N', label: 'PF4', action: 'sendText', payload: 'ls -la\\n' }

  const restored = PfKeys.parse(PfKeys.serialize(list))
  assert.equal(restored.length, PfKeys.KEY_COUNT)
  assert.deepEqual(restored[0], list[0])
  assert.deepEqual(restored[3], list[3])
  assert.equal(PfKeys.intercepts(restored[0]), true)
  assert.equal(PfKeys.anyIntercepting(restored), true)
})

test('parse tolerates corrupt stored values', () => {
  assert.equal(PfKeys.parse(undefined).length, PfKeys.KEY_COUNT)
  assert.equal(PfKeys.parse('').length, PfKeys.KEY_COUNT)
  assert.equal(PfKeys.parse('{ not json').length, PfKeys.KEY_COUNT)
  assert.equal(PfKeys.parse('[1,2,3]').length, PfKeys.KEY_COUNT)
})

test('legend only shows an entry when a function is assigned', () => {
  const pass = PfKeys.defaultAssignments()[0]
  assert.equal(PfKeys.legend(pass), '')

  const win = { action: 'newWindow' }
  assert.equal(PfKeys.legend(win), 'New Window')

  const text = { action: 'sendText', payload: 'clear' }
  assert.equal(PfKeys.legend(text), 'clear', 'sendText shows what it sends')

  assert.equal(PfKeys.legend(null), '')
  assert.equal(PfKeys.legend(undefined), '')
})

test('only assigned functions register a shortcut', () => {
  const pass = { action: 'pass' }
  const app = { action: 'nextWindow' }
  assert.equal(PfKeys.intercepts(pass), false)
  assert.equal(PfKeys.intercepts(app), true)
  assert.equal(PfKeys.intercepts(null), false)
  assert.equal(PfKeys.intercepts(undefined), false)
  assert.equal(PfKeys.intercepts({ action: 'bogus' }), false)
})

test('assignableActions can hide actions the OS owns', () => {
  const all = PfKeys.assignableActions(0, {})
  const blocked = PfKeys.assignableActions(0, { nextWindow: true })

  assert.ok(all.length > blocked.length, 'blocking removes entries')
  assert.equal(blocked.some(a => a.id === 'nextWindow'), false)
  assert.equal(blocked.some(a => a.id === 'newWindow'), true)
  // "Off" must always be offered so a key can be released back to the shell.
  assert.equal(blocked.some(a => a.id === 'pass'), true)
})

test('collisions find duplicate key sequences', () => {
  const clean = PfKeys.defaultAssignments()
  assert.deepEqual(PfKeys.collisions(clean), [])

  const dirty = PfKeys.defaultAssignments()
  dirty[0].key = 'F2'
  const groups = PfKeys.collisions(dirty)
  assert.equal(groups.length, 1)
  assert.deepEqual(groups[0].sort(), [0, 1])
})

test('decodePayload understands macro escapes', () => {
  assert.equal(PfKeys.decodePayload('ls\\n'), 'ls\n')
  assert.equal(PfKeys.decodePayload('a\\tb'), 'a\tb')
  assert.equal(PfKeys.decodePayload('\\e[31m'), '\u001b[31m')
  assert.equal(PfKeys.decodePayload('C:\\\\tmp'), 'C:\\tmp')
  assert.equal(PfKeys.decodePayload('plain'), 'plain')
  assert.equal(PfKeys.decodePayload(null), '')
  assert.equal(PfKeys.decodePayload(undefined), '')
  // Trailing lone backslash is preserved rather than swallowed.
  assert.equal(PfKeys.decodePayload('ends\\'), 'ends\\')
})

test('macroText decodes and turns line feeds into carriage returns', () => {
  // A macro that says "ls -la\n" must behave exactly like typing the
  // command and pressing Enter, and Enter on a terminal sends CR.
  assert.equal(PfKeys.macroText('ls -la\\n'), 'ls -la\r')
  assert.equal(PfKeys.macroText('pwd\\nwhoami\\n'), 'pwd\rwhoami\r')
  assert.equal(PfKeys.macroText('no newline'), 'no newline')
  assert.equal(PfKeys.macroText(null), '')
  // Escapes are decoded before the CR mapping, so \e[31m survives intact.
  assert.equal(PfKeys.macroText('\\e[31mred\\e[0m\\n'),
               '\u001b[31mred\u001b[0m\r')
})
