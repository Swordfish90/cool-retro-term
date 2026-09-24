/*******************************************************************************
* Active line (cursor row) highlight geometry.
*
* The terminal widget reports the cursor cell as a rectangle in its own local
* coordinate system.  This module turns that into the rectangle of the band we
* draw across the screen, in the coordinate system of the item that is captured
* into the CRT shader.
*******************************************************************************/

/**
 * @param {Object} cursorRect  {x, y, width, height} in terminal local coords,
 *                             or null/undefined when unavailable.
 * @param {Object} geom        { screenX, screenWidth, terminalY }
 *   screenX      left edge of the visible screen area (usually -margin)
 *   screenWidth  width of the visible screen area
 *   terminalY    y offset of the terminal item inside the capturing item
 * @return {Object|null} {x, y, width, height} or null when nothing to draw.
 */
function bandRect(cursorRect, geom) {
    if (!cursorRect)
        return null
    if (cursorRect.width === undefined || cursorRect.width <= 0)
        return null
    if (cursorRect.height === undefined || cursorRect.height <= 0)
        return null

    var g = geom || {}
    var screenX = g.screenX !== undefined ? g.screenX : 0
    var screenWidth = g.screenWidth !== undefined ? g.screenWidth : cursorRect.width
    var terminalY = g.terminalY !== undefined ? g.terminalY : 0

    return {
        x: screenX,
        y: cursorRect.y + terminalY,
        width: screenWidth,
        height: cursorRect.height
    }
}

/** Row index of the cursor, derived from the cell rectangle. */
function cursorRow(cursorRect) {
    if (!cursorRect || !(cursorRect.height > 0))
        return -1
    return Math.floor(cursorRect.y / cursorRect.height)
}

/** Column index of the cursor, derived from the cell rectangle. */
function cursorColumn(cursorRect) {
    if (!cursorRect || !(cursorRect.width > 0))
        return -1
    return Math.floor(cursorRect.x / cursorRect.width)
}

/** Blend the highlight over the phosphor colour without washing text out. */
function bandOpacity(requested) {
    var v = Number(requested)
    if (isNaN(v))
        return 0
    return Math.max(0, Math.min(1, v))
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        bandRect: bandRect,
        cursorRow: cursorRow,
        cursorColumn: cursorColumn,
        bandOpacity: bandOpacity
    }
}
