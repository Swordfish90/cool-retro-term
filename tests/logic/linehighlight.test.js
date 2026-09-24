'use strict'
/** Tests for active-line highlight geometry (app/qml/logic/linehighlight.js). */
const { test } = require('node:test')
const assert = require('node:assert/strict')
const path = require('node:path')

const Line = require(path.join(__dirname, '..', '..', 'app', 'qml', 'logic', 'linehighlight.js'))

const GEOM = { screenX: -16, screenWidth: 800, terminalY: 0 }

test('band spans the whole screen width on the cursor row', () => {
  const rect = Line.bandRect({ x: 40, y: 180, width: 10, height: 18 }, GEOM)
  assert.deepEqual(rect, { x: -16, y: 180, width: 800, height: 18 })
})

test('band honours the terminal offset inside the captured item', () => {
  const rect = Line.bandRect(
    { x: 0, y: 100, width: 10, height: 20 },
    { screenX: 0, screenWidth: 640, terminalY: 24 })
  assert.equal(rect.y, 124)
})

test('missing or degenerate cursor rect yields no band', () => {
  assert.equal(Line.bandRect(null, GEOM), null)
  assert.equal(Line.bandRect(undefined, GEOM), null)
  assert.equal(Line.bandRect({ x: 0, y: 0, width: 0, height: 10 }, GEOM), null)
  assert.equal(Line.bandRect({ x: 0, y: 0, width: 10, height: 0 }, GEOM), null)
  assert.equal(Line.bandRect({ x: 0, y: 0, width: 10 }, GEOM), null)
  assert.equal(Line.bandRect({ x: 0, y: 0, height: 10 }, GEOM), null)
})

test('band tolerates a missing geometry object', () => {
  const rect = Line.bandRect({ x: 0, y: 40, width: 8, height: 16 }, null)
  assert.equal(rect.x, 0)
  assert.equal(rect.y, 40)
  // With no screen geometry to go on the band degenerates to the cursor cell
  // rather than guessing a width; callers always supply screenWidth.
  assert.equal(rect.width, 8)
  assert.equal(rect.height, 16)
})

test('cursorRow / cursorColumn derive the grid position', () => {
  assert.equal(Line.cursorRow({ y: 0, height: 16 }), 0)
  assert.equal(Line.cursorRow({ y: 16, height: 16 }), 1)
  assert.equal(Line.cursorRow({ y: 15, height: 16 }), 0, 'rounds down, never up')
  assert.equal(Line.cursorRow({ y: 383, height: 16 }), 23, 'row 24 of an 80x24 screen')

  assert.equal(Line.cursorColumn({ x: 0, width: 9 }), 0)
  assert.equal(Line.cursorColumn({ x: 81, width: 9 }), 9)
  assert.equal(Line.cursorColumn({ x: 0 }), -1)
  assert.equal(Line.cursorRow(null), -1)
  assert.equal(Line.cursorRow({ y: 0, height: 0 }), -1)
})

test('bandOpacity clamps into the 0..1 range', () => {
  assert.equal(Line.bandOpacity(0.18), 0.18)
  assert.equal(Line.bandOpacity(-1), 0)
  assert.equal(Line.bandOpacity(2), 1)
  assert.equal(Line.bandOpacity('nonsense'), 0)
  assert.equal(Line.bandOpacity(undefined), 0)
  assert.equal(Line.bandOpacity(null), 0)
})
