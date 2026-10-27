/*******************************************************************************
* Copyright (c) 2013-2021 "Filippo Scognamiglio"
* https://github.com/Swordfish90/cool-retro-term
*
* This file is part of cool-retro-term.
*
* cool-retro-term is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/
import QtQuick

// A node of the tiling tree: two children (terminals or other splits) separated by a draggable handle.
// Qt.Horizontal places the children side by side, Qt.Vertical stacks them.
Item {
    id: split

    readonly property bool isSplit: true

    property int orientation: Qt.Horizontal
    property Item first: null
    property Item second: null
    property real ratio: 0.5

    readonly property int handleSize: 4
    readonly property int minimumPaneSize: 40
    readonly property bool horizontal: orientation === Qt.Horizontal
    readonly property real _available: Math.max(0, (horizontal ? width : height) - handleSize)
    readonly property real _firstSize: Math.round(_available * ratio)

    onFirstChanged: _attach(first, true)
    onSecondChanged: _attach(second, false)

    function _attach(item, isFirst) {
        if (!item)
            return

        item.parent = split
        if (isFirst) {
            item.x = 0
            item.y = 0
            item.width = Qt.binding(() => horizontal ? _firstSize : width)
            item.height = Qt.binding(() => horizontal ? height : _firstSize)
        } else {
            item.x = Qt.binding(() => horizontal ? _firstSize + handleSize : 0)
            item.y = Qt.binding(() => horizontal ? 0 : _firstSize + handleSize)
            item.width = Qt.binding(() => horizontal ? width - _firstSize - handleSize : width)
            item.height = Qt.binding(() => horizontal ? height : height - _firstSize - handleSize)
        }
    }

    Rectangle {
        id: handle

        x: horizontal ? _firstSize : 0
        y: horizontal ? 0 : _firstSize
        width: horizontal ? handleSize : split.width
        height: horizontal ? split.height : handleSize
        z: 1
        // Black like the gap between two monitors; slightly lighter while hovered or dragged.
        color: handleArea.pressed || handleArea.containsMouse ? "#404040" : "black"

        MouseArea {
            id: handleArea

            // Slightly larger than the visible handle so it is easy to grab.
            anchors.fill: parent
            anchors.margins: -2
            hoverEnabled: true
            cursorShape: horizontal ? Qt.SplitHCursor : Qt.SplitVCursor

            onPositionChanged: function(mouse) {
                if (!pressed || _available <= 0)
                    return

                var pos = mapToItem(split, mouse.x, mouse.y)
                var offset = (horizontal ? pos.x : pos.y) - handleSize / 2
                var minRatio = Math.min(0.5, minimumPaneSize / _available)
                split.ratio = Math.max(minRatio, Math.min(1 - minRatio, offset / _available))
            }
        }
    }
}
