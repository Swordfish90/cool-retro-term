'use strict'
/** Tests for audible feedback gating (app/qml/logic/sound.js). */
const { test } = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

const Sound = require(path.join(__dirname, '..', '..', 'app', 'qml', 'logic', 'sound.js'))

test('nothing makes a noise unless the master switch is on', () => {
  assert.equal(Sound.audible({}), false)
  assert.equal(Sound.audible(undefined), false)
  assert.equal(Sound.audible({ keyClick: true, bell: true }), false)
  assert.equal(Sound.audible({ audioEnabled: true }), true)
})

test('key click requires both the master switch and the click switch', () => {
  const on = { audioEnabled: true, keyClick: true }
  assert.equal(Sound.shouldClick(on, {}), true)
  assert.equal(Sound.shouldClick({ audioEnabled: true, keyClick: false }, {}), false)
  assert.equal(Sound.shouldClick({ audioEnabled: false, keyClick: true }, {}), false)
  assert.equal(Sound.shouldClick(undefined, {}), false)
})

test('auto-repeat does not machine-gun the click', () => {
  const on = { audioEnabled: true, keyClick: true }
  assert.equal(Sound.shouldClick(on, { isAutoRepeat: true }), false)
  assert.equal(Sound.shouldClick(on, { isAutoRepeat: false }), true)
})

test('a paste does not click per character', () => {
  const on = { audioEnabled: true, keyClick: true }
  assert.equal(Sound.shouldClick(on, { fromPaste: true }), false)
})

test('modifier-only presses are silent', () => {
  const on = { audioEnabled: true, keyClick: true }
  assert.equal(Sound.shouldClick(on, { isModifierOnly: true }), false)
})

test('bell is gated independently of the key click', () => {
  assert.equal(Sound.shouldBell({ audioEnabled: true, bell: true }), true)
  assert.equal(Sound.shouldBell({ audioEnabled: true, bell: false }), false)
  assert.equal(Sound.shouldBell({ audioEnabled: false, bell: true }), false)
  assert.equal(Sound.shouldBell({ keyClick: true }), false)
})

test('volume is clamped to 0..1', () => {
  assert.equal(Sound.volume(0.5), 0.5)
  assert.equal(Sound.volume(-3), 0)
  assert.equal(Sound.volume(17), 1)
  assert.equal(Sound.volume('x'), 0.5, 'falls back to the default')
  assert.equal(Sound.volume('x', 0.25), 0.25)
  assert.equal(Sound.volume(NaN), 0.5)
  assert.equal(Sound.volume(null), 0.5)
  assert.equal(Sound.volume(undefined), 0.5)
})
