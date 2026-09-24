'use strict'
/**
 * Tests for platform-aware key sequences (app/qml/logic/platform.js).
 *
 * These assert the "same functionality, exactly the same as the OS" rule:
 * each function must land on the sequence that is conventional for that OS.
 */
const { test } = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

const Platform = require(path.join(__dirname, '..', '..', 'app', 'qml', 'logic', 'platform.js'))

test('normalizeOs buckets every spelling Qt can produce', () => {
  assert.equal(Platform.normalizeOs('osx'), 'mac')
  assert.equal(Platform.normalizeOs('OSX'), 'mac')
  assert.equal(Platform.normalizeOs('macos'), 'mac')
  assert.equal(Platform.normalizeOs('darwin'), 'mac')
  assert.equal(Platform.normalizeOs('win32'), 'windows')
  assert.equal(Platform.normalizeOs('Windows'), 'windows')
  assert.equal(Platform.normalizeOs('win64'), 'windows')
  assert.equal(Platform.normalizeOs('x11'), 'linux')
  assert.equal(Platform.normalizeOs('wayland'), 'linux')
  assert.equal(Platform.normalizeOs('linux'), 'linux')
  assert.equal(Platform.normalizeOs('freebsd'), 'linux')
  assert.equal(Platform.normalizeOs(undefined), 'linux')
  assert.equal(Platform.normalizeOs(null), 'linux')
})

test('isMac', () => {
  assert.equal(Platform.isMac('osx'), true)
  assert.equal(Platform.isMac('x11'), false)
})

test('macOS uses the native Cmd based conventions', () => {
  const s = Platform.sequences('osx')
  assert.equal(s.newWindow, 'Meta+N')       // Cmd+N
  assert.equal(s.newTab, 'Meta+T')          // Cmd+T
  assert.equal(s.closeTab, 'Meta+W')        // Cmd+W
  assert.equal(s.closeWindow, 'Meta+Shift+W')
  assert.equal(s.nextWindow, 'Meta+`')      // Cmd+` is the native binding
  assert.equal(s.prevWindow, 'Meta+Shift+`')
  assert.equal(s.settings, 'Meta+,')        // Cmd+, is the convention
  assert.equal(s.quit, 'StandardKey.Quit')  // Cmd+Q
})

test('windows uses the terminal/browser conventions', () => {
  const s = Platform.sequences('win32')
  assert.equal(s.newWindow, 'Ctrl+Shift+N')
  assert.equal(s.newTab, 'Ctrl+Shift+T')
  assert.equal(s.closeTab, 'Ctrl+W')
  assert.equal(s.closeWindow, 'Ctrl+Shift+W')
  assert.equal(s.nextWindow, 'Alt+`')
  assert.equal(s.settings, 'Ctrl+,')
  assert.equal(s.quit, 'Ctrl+Shift+Q')
})

test('linux is identical to windows', () => {
  assert.deepEqual(Platform.sequences('x11'), Platform.sequences('win32'))
  assert.deepEqual(Platform.sequences('wayland'), Platform.sequences('win32'))
})

test('linux Alt+` matches GNOME/KDE "windows of this application"', () => {
  // GNOME default for switch-group / switch-windows-of-app is Alt+Above_Tab.
  assert.equal(Platform.sequence('linux', 'nextWindow'), 'Alt+`')
  assert.equal(Platform.sequence('linux', 'prevWindow'), 'Alt+Shift+`')
})

test('closeTab and closeWindow never collide on any platform', () => {
  for (const os of ['osx', 'win32', 'x11', 'wayland']) {
    const s = Platform.sequences(os)
    assert.notEqual(s.closeTab, s.closeWindow, `collision on ${os}`)
    assert.notEqual(s.newTab, s.newWindow, `collision on ${os}`)
    assert.notEqual(s.nextWindow, s.prevWindow, `collision on ${os}`)
  }
})

test('quit never collides with closeTab on any platform', () => {
  for (const os of ['osx', 'win32', 'x11']) {
    const s = Platform.sequences(os)
    assert.notEqual(s.quit, s.closeTab, `quit collides with closeTab on ${os}`)
    assert.notEqual(s.quit, s.closeWindow, `quit collides with closeWindow on ${os}`)
  }
})

test('every platform exposes the same set of functions', () => {
  const names = Object.keys(Platform.sequences('osx'))
  for (const os of ['win32', 'x11']) {
    assert.deepEqual(Object.keys(Platform.sequences(os)).sort(), names.sort())
  }
  for (const n of names) {
    assert.ok(Platform.sequence('osx', n).length > 0, `mac ${n} is set`)
    assert.ok(Platform.sequence('x11', n).length > 0, `linux ${n} is set`)
  }
})

test('sequence() rejects unknown names instead of inventing bindings', () => {
  assert.equal(Platform.sequence('osx', 'doesNotExist'), '')
  assert.equal(Platform.sequence('osx', undefined), '')
})

test('usableSequences filters out empty entries', () => {
  const out = Platform.usableSequences('osx', ['newWindow', 'nope', 'quit'])
  assert.deepEqual(Object.keys(out).sort(), ['newWindow', 'quit'])
  assert.equal(out.newWindow, 'Meta+N')
})
