/*******************************************************************************
* Qt Quick test: iTerm2 style highlight of the cursor's row.
*
* The band must follow the cursor cell, obey the settings switch, clamp its
* opacity to something readable over the phosphor, hide itself whenever the
* cursor rectangle is unknown, and recover cleanly when the feature is turned
* off and on again.  It must never be reachable by the cursor.
*******************************************************************************/
import QtQuick
import QtTest

import "../app/qml" as App
import "../app/qml/logic/linehighlight.js" as LineLogic
import "helpers.js" as Helpers

Rectangle {
    id: host
    width: 640
    height: 480
    color: "black"

    App.LineHighlight {
        id: band
        objectName: "band"
        screenX: 8
        screenWidth: 624
        terminalY: 4
        highlightEnabled: false
        cursorRect: ({ x: 40, y: 180, width: 10, height: 18 })
    }

    TestCase {
        name: "LineHighlightTests"
        when: windowShown

        function init() {
            band.highlightEnabled = false
            band.requestedOpacity = 0.18
            band.tint = "#ffffff"
            band.cursorRect = ({ x: 40, y: 180, width: 10, height: 18 })
        }

        function test_disabledStaysInvisible() {
            band.highlightEnabled = false
            compare(band.hasBand, true)     // we do know the cursor row...
            compare(band.visible, false)    // ...but the feature is off
            compare(band.opacity, 0)
        }

        function test_enabledDrawsTheCursorRow() {
            band.highlightEnabled = true

            compare(band.visible, true)
            compare(band.x, 8)              // full width of the screen area
            compare(band.y, 184)            // cursor cell + terminal offset
            compare(band.width, 624)
            compare(band.height, 18)
            compare(band.row, 10)           // floor(180 / 18)
            compare(band.opacity, LineLogic.bandOpacity(0.18))
            compare(band.color, Qt.color("#ffffff"))
        }

        function test_geometryMatchesThePureLogic() {
            band.highlightEnabled = true
            var expected = LineLogic.bandRect(
                        { x: 40, y: 180, width: 10, height: 18 },
                        { screenX: 8, screenWidth: 624, terminalY: 4 })
            verify(expected !== null)
            compare(band.x, expected.x)
            compare(band.y, expected.y)
            compare(band.width, expected.width)
            compare(band.height, expected.height)
        }

        function test_unknownCursorKeepsItHidden() {
            band.cursorRect = null
            band.highlightEnabled = true

            compare(band.hasBand, false)
            compare(band.visible, false)
            compare(band.opacity, 0)
            compare(band.width, 0)
            compare(band.height, 0)
            compare(band.row, -1)
        }

        function test_degenerateCursorKeepsItHidden() {
            band.cursorRect = ({ x: 0, y: 0, width: 0, height: 18 })
            band.highlightEnabled = true

            compare(band.hasBand, false)
            compare(band.visible, false)
        }

        function test_survivesBeingSwitchedOffAndOnAgain() {
            band.highlightEnabled = true
            verify(band.visible)

            band.highlightEnabled = false
            compare(band.visible, false)
            compare(band.opacity, 0)

            band.highlightEnabled = true
            compare(band.visible, true)
            compare(band.opacity, LineLogic.bandOpacity(0.18))
        }

        function test_cursorRowReturningBringsTheBandBack() {
            band.highlightEnabled = true
            band.cursorRect = null
            compare(band.visible, false)

            band.cursorRect = ({ x: 40, y: 180, width: 10, height: 18 })
            compare(band.visible, true)
            compare(band.height, 18)
        }

        function test_opacityIsClampedToThePhosphorRange() {
            band.highlightEnabled = true

            band.requestedOpacity = 5
            compare(band.opacity, 1)
            compare(band.visible, true)

            band.requestedOpacity = -3
            compare(band.opacity, 0)
            compare(band.visible, true)     // dim, but still the cursor row

            band.requestedOpacity = 0.4
            compare(band.opacity, 0.4)
        }

        function test_isUnreachableByCursor() {
            compare(Helpers.mouseTargets(band), 0)
        }
    }
}
