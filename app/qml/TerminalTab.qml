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

// The content of a tab: a binary tree of TerminalSplit nodes with TerminalContainer leaves.
// All nodes are created with the tab as QObject parent and only reparented visually, so
// collapsing a split never destroys the terminals it contained.
Item {
    id: tab

    property bool isCurrent: false
    // Profile JSON of the first terminal; splits copy the profile of the terminal they split.
    property string initialProfile: ""
    property Item rootNode: null
    property Item focusedTerminal: null

    readonly property string title: focusedTerminal ? focusedTerminal.title : ""
    readonly property size terminalSize: focusedTerminal ? focusedTerminal.terminalSize : Qt.size(0, 0)

    // Emitted when the last terminal of the tab is gone.
    signal finished()

    property bool shouldHaveFocus: terminalWindow.active && isCurrent
    onShouldHaveFocusChanged: activateFocusedTerminal()
    onFocusedTerminalChanged: activateFocusedTerminal()

    function activateFocusedTerminal() {
        if (shouldHaveFocus && focusedTerminal) {
            focusedTerminal.activate()
        }
    }

    Component {
        id: terminalComponent

        TerminalContainer {
            id: pane
            isActive: tab.isCurrent && tab.focusedTerminal === pane
            onSessionFinished: tab.closeTerminal(pane)
            onTerminalHasFocusChanged: {
                if (terminalHasFocus) {
                    tab.focusedTerminal = pane
                }
            }

            // When the tab is split, dim the terminals without focus so the active one stands out.
            Rectangle {
                anchors.fill: parent
                z: 10
                color: "black"
                opacity: 0.4
                visible: tab.rootNode !== pane && tab.focusedTerminal !== pane
            }
        }
    }

    Component {
        id: splitComponent
        TerminalSplit { }
    }

    Component.onCompleted: {
        var terminal = terminalComponent.createObject(tab, { initialProfile: initialProfile })
        setRoot(terminal)
        focusedTerminal = terminal
    }

    function setRoot(node) {
        rootNode = node
        node.parent = tab
        node.x = 0
        node.y = 0
        node.width = Qt.binding(() => tab.width)
        node.height = Qt.binding(() => tab.height)
    }

    // Puts newNode where oldNode is in the tree.
    function replaceNode(oldNode, newNode) {
        var container = oldNode.parent
        if (container === tab) {
            setRoot(newNode)
        } else if (container.first === oldNode) {
            container.first = newNode
        } else {
            container.second = newNode
        }
    }

    // Qt.Horizontal puts the new terminal to the right, Qt.Vertical below.
    function split(orientation) {
        var target = focusedTerminal
        if (!target)
            return

        var terminal = terminalComponent.createObject(tab, {
            initialWorkingDirectory: target.currentDir(),
            initialProfile: target.profile.composeProfileString()
        })
        var node = splitComponent.createObject(tab, { orientation: orientation })
        replaceNode(target, node)
        node.first = target
        node.second = terminal
        focusedTerminal = terminal
    }

    function closeTerminal(terminal) {
        var container = terminal.parent
        if (container === tab) {
            finished()
            return
        }

        var sibling = container.first === terminal ? container.second : container.first
        container.first = null
        container.second = null
        replaceNode(container, sibling)

        if (focusedTerminal === terminal) {
            focusedTerminal = terminalsIn(sibling)[0]
        }

        terminal.visible = false
        terminal.destroy()
        container.destroy()
    }

    function closeFocusedTerminal() {
        if (focusedTerminal) {
            closeTerminal(focusedTerminal)
        }
    }

    function terminalsIn(node) {
        if (!node)
            return []
        if (node.isSplit)
            return terminalsIn(node.first).concat(terminalsIn(node.second))
        return [node]
    }

    // Moves focus to the closest terminal in the given direction (Qt.LeftArrow, Qt.RightArrow,
    // Qt.UpArrow or Qt.DownArrow), preferring the one that overlaps the current terminal the most.
    function focusNeighbor(direction) {
        if (!focusedTerminal)
            return

        var from = focusedTerminal.mapToItem(tab, 0, 0, focusedTerminal.width, focusedTerminal.height)
        var best = null
        var bestDistance = Infinity
        var bestOverlap = -Infinity
        var candidates = terminalsIn(rootNode)

        for (var i = 0; i < candidates.length; i++) {
            var candidate = candidates[i]
            if (candidate === focusedTerminal)
                continue

            var r = candidate.mapToItem(tab, 0, 0, candidate.width, candidate.height)
            var distance, overlap
            if (direction === Qt.LeftArrow || direction === Qt.RightArrow) {
                distance = direction === Qt.LeftArrow ? from.x - (r.x + r.width) : r.x - (from.x + from.width)
                overlap = Math.min(from.y + from.height, r.y + r.height) - Math.max(from.y, r.y)
            } else {
                distance = direction === Qt.UpArrow ? from.y - (r.y + r.height) : r.y - (from.y + from.height)
                overlap = Math.min(from.x + from.width, r.x + r.width) - Math.max(from.x, r.x)
            }

            // Only terminals beyond the current one's edge that share part of it.
            if (distance < -1 || overlap <= 0)
                continue

            if (distance < bestDistance - 1 || (Math.abs(distance - bestDistance) <= 1 && overlap > bestOverlap)) {
                best = candidate
                bestDistance = distance
                bestOverlap = overlap
            }
        }

        if (best) {
            focusedTerminal = best
        }
    }
}
