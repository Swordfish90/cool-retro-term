/*******************************************************************************
* Shared helpers for the Qt Quick test suite.
*
* Imported by the tst_*.qml files with `import "helpers.js" as Helpers`.
* Plain ECMAScript only, so the same helpers could be loaded from Node too.
*******************************************************************************/

/**
 * Number of items in the tree (item included) that could react to a pointer.
 *
 * The PF legend and the active line highlight promise to be reachable by eye
 * only, and that promise is checked structurally instead of by reading the
 * source: any item exposing mouse handling counts as a target.
 *
 * @param {Item} item  root of the subtree to inspect
 * @return {number}
 */
function mouseTargets(item) {
    if (!item)
        return 0
    var count = isMouseTarget(item) ? 1 : 0
    var kids = item.children
    if (kids === undefined)
        return count
    for (var i = 0; i < kids.length; i++)
        count += mouseTargets(kids[i])
    return count
}

/**
 * Duck typed so that mouse handling types we have not written yet are caught
 * as well: MouseArea and TapArea expose acceptedButtons / hoverEnabled,
 * DragHandler style items expose cursorShape / canDrag.
 *
 * @param {Item} item
 * @return {boolean}
 */
function isMouseTarget(item) {
    if (item.acceptedButtons !== undefined)
        return true
    if (item.hoverEnabled !== undefined)
        return true
    if (item.cursorShape !== undefined)
        return true
    if (item.canDrag !== undefined)
        return true
    return false
}

/**
 * Number of items in the tree that hold (or could take) keyboard focus.
 *
 * @param {Item} item  root of the subtree to inspect
 * @return {number}
 */
function focusedItems(item) {
    if (!item)
        return 0
    var count = item.focus === true ? 1 : 0
    var kids = item.children
    if (kids === undefined)
        return count
    for (var i = 0; i < kids.length; i++)
        count += focusedItems(kids[i])
    return count
}
