/*******************************************************************************
* Highlight of the row the cursor is sitting on.
*
* Drawn as a translucent band over the terminal inside the item that is
* captured by the CRT shader, so it picks up the same glow, curvature and
* flicker as the phosphor itself.
*
* Geometry comes from logic/linehighlight.js, which is pure and unit tested;
* this file only binds it.  It contains no MouseArea, so the band can never be
* clicked or hovered.
*******************************************************************************/
import QtQuick

import "logic/linehighlight.js" as LineLogic

Rectangle {
    id: band

    /**
     * Cursor cell rectangle in terminal local coordinates, e.g.
     *   { x: 40, y: 180, width: 10, height: 18 }
     * or null/empty when it cannot be determined (band stays hidden).
     */
    property var cursorRect: null

    /** Switch that owns the feature; independent of whether we know a rect. */
    property bool highlightEnabled: false

    /** Geometry of the captured screen area. */
    property real screenX: 0
    property real screenWidth: 0
    property real terminalY: 0

    /** Phosphor tint and strength. */
    property color tint: "#ffffff"
    property real requestedOpacity: 0.18

    readonly property var rect: LineLogic.bandRect(cursorRect, {
        screenX: screenX,
        screenWidth: screenWidth,
        terminalY: terminalY
    })

    readonly property bool hasBand: rect !== null
    readonly property int row: LineLogic.cursorRow(cursorRect)

    // Deliberately not derived from `opacity`: visibility and opacity must
    // depend on the same inputs, otherwise a disabled band could never come
    // back once it had been hidden once.
    visible: highlightEnabled && hasBand
    opacity: highlightEnabled && hasBand
             ? LineLogic.bandOpacity(requestedOpacity) : 0

    x: hasBand ? rect.x : 0
    y: hasBand ? rect.y : 0
    width: hasBand ? rect.width : 0
    height: hasBand ? rect.height : 0

    color: tint
}
