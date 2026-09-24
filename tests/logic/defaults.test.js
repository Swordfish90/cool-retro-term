'use strict'
/**
 * Tests for retro settings defaults + tolerant merging
 * (app/qml/logic/defaults.js) and for the chrome visibility rules.
 */
const { test } = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

const Defaults = require(path.join(__dirname, '..', '..', 'app', 'qml', 'logic', 'defaults.js'))

test('nostalgic mode is on by default: no chrome at all', () => {
  const d = Defaults.defaults()
  assert.equal(d.nostalgicMode, true, 'zero-chrome is the default experience')
  assert.equal(d.showPfKeys, false, 'PF bar is opt-in')
  assert.equal(d.audioEnabled, false, 'key click is opt-in')
  assert.equal(d.highlightActiveLine, false, 'line highlight is opt-in')
  assert.equal(d.cursorStyle, 'block')
})

test('merge keeps defaults for missing keys', () => {
  assert.deepEqual(Defaults.merge(undefined), Defaults.defaults())
  assert.deepEqual(Defaults.merge(null), Defaults.defaults())
  assert.deepEqual(Defaults.merge('a string'), Defaults.defaults())
  assert.deepEqual(Defaults.merge({}), Defaults.defaults())
  assert.deepEqual(Defaults.merge({ nonsense: 42 }), Defaults.defaults())
})

test('merge accepts valid values', () => {
  const out = Defaults.merge({
    nostalgicMode: false,
    showPfKeys: true,
    pfKeys: '[{"action":"newWindow"}]',
    audioEnabled: true,
    keyClick: false,
    bell: false,
    keyClickVolume: 0.75,
    bellVolume: 0.25,
    highlightActiveLine: true,
    activeLineOpacity: 0.4,
    cursorStyle: 'half'
  })
  assert.equal(out.nostalgicMode, false)
  assert.equal(out.showPfKeys, true)
  assert.equal(out.pfKeys, '[{"action":"newWindow"}]')
  assert.equal(out.audioEnabled, true)
  assert.equal(out.keyClick, false)
  assert.equal(out.bell, false)
  assert.equal(out.keyClickVolume, 0.75)
  assert.equal(out.bellVolume, 0.25)
  assert.equal(out.highlightActiveLine, true)
  assert.equal(out.activeLineOpacity, 0.4)
  assert.equal(out.cursorStyle, 'half')
})

test('merge repairs wrong types instead of trusting them', () => {
  const out = Defaults.merge({
    nostalgicMode: 'yes',
    showPfKeys: 1,
    pfKeys: 42,
    keyClickVolume: 'loud',
    bellVolume: 9000,
    activeLineOpacity: -5,
    cursorStyle: 'rainbow'
  })
  assert.equal(out.nostalgicMode, Defaults.defaults().nostalgicMode, 'non-boolean ignored')
  assert.equal(out.showPfKeys, Defaults.defaults().showPfKeys, 'non-boolean ignored')
  assert.equal(out.pfKeys, Defaults.defaults().pfKeys, 'non-string ignored')
  assert.equal(out.keyClickVolume, 0.5, 'unparseable volume falls back')
  assert.equal(out.bellVolume, 1, 'clamped to 1')
  assert.equal(out.activeLineOpacity, 0, 'clamped to 0')
  assert.equal(out.cursorStyle, 'block', 'unknown style rejected')
})

test('volumes are clamped to the 0..1 range', () => {
  assert.equal(Defaults.merge({ keyClickVolume: -1 }).keyClickVolume, 0)
  assert.equal(Defaults.merge({ keyClickVolume: 2 }).keyClickVolume, 1)
  assert.equal(Defaults.clampNumber(5, 0.5, 0, 1), 1)
  assert.equal(Defaults.clampNumber('x', 0.5, 0, 1), 0.5)
})

test('serialize/parse round trips', () => {
  const settings = {
    nostalgicMode: false,
    showPfKeys: true,
    pfKeys: '[]',
    audioEnabled: true,
    keyClickVolume: 0.9,
    cursorStyle: 'half'
  }
  const restored = Defaults.parse(Defaults.serialize(settings))
  assert.deepEqual(restored, Defaults.merge(settings))
})

test('parse tolerates corrupt stored values', () => {
  assert.deepEqual(Defaults.parse(undefined), Defaults.defaults())
  assert.deepEqual(Defaults.parse(''), Defaults.defaults())
  assert.deepEqual(Defaults.parse('{{{'), Defaults.defaults())
  assert.deepEqual(Defaults.parse('[1,2,3]'), Defaults.defaults())
})

test('defaults() returns a fresh object each call', () => {
  const a = Defaults.defaults()
  a.nostalgicMode = false
  assert.equal(Defaults.defaults().nostalgicMode, true, 'no shared mutable state')
})
