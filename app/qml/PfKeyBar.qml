/*******************************************************************************
* On screen IBM PF / PA key legend.
*
* Deliberately built from plain Item/Rectangle/Text only:
*   - it contains no MouseArea and no Controls, so it can never be clicked,
*     hovered or dragged: it is reachable by eye, never by cursor;
*   - it never takes keyboard focus, so it cannot steal a keystroke.
*
* It is rendered *inside* the item that is captured by the CRT shader, so the
* legend glows like everything else on the phosphor.
*
* Self contained on purpose: it reads no application globals, which lets the
* Qt Quick test suite instantiate it on its own.
*******************************************************************************/
import QtQuick

import "logic/pfkeys.js" as PfKeys

Item {
    id: root

    /** Normalized assignment array (see logic/pfkeys.js). */
    property var model: []

    /** Phosphor styling, bound by the caller so this file stays global free. */
    property color textColor: "#ff8100"
    property color borderColor: "#ff8100"
    property color background: "transparent"

    /** When false only the key identity (PF1..PF12) is shown. */
    property bool showLegends: true

    /** Key cap metrics. */
    property real capSpacing: 4
    property real capPadding: 6
    property real capRadius: 0
    property real minimumCapWidth: 0

    readonly property int count: (model && model.length !== undefined) ? model.length : 0
    readonly property bool empty: count === 0

    visible: !empty
    implicitHeight: empty ? 0 : capRow.implicitHeight + topBottomPadding
    implicitWidth: empty ? 0 : capRow.implicitWidth

    // Internal only: keeps a sliver of breathing room above and below.
    property real topBottomPadding: 2

    /** Legend text for one slot, or "" when the key passes to the shell. */
    function legendFor(assignment) {
        if (!showLegends)
            return ""
        return PfKeys.legend(assignment)
    }

    /** Identity shown on the cap: PF1..PF12 or PA1..PA3. */
    function nameFor(index, assignment) {
        if (assignment && assignment.label)
            return String(assignment.label)
        return PfKeys.slotName(index)
    }

    Row {
        id: capRow
        objectName: "pfCapRow"

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.capSpacing

        Repeater {
            model: root.count

            delegate: Rectangle {
                id: cap
                objectName: "pfCap_" + index

                required property int index

                // Visible width is driven by the text, never below the minimum.
                implicitWidth: Math.max(minimumContentWidth, root.minimumCapWidth)
                implicitHeight: contentColumn.implicitHeight + root.capPadding * 2
                width: implicitWidth
                height: implicitHeight

                color: root.background
                border.color: root.borderColor
                border.width: 1
                radius: root.capRadius
                opacity: root.showLegends && root.legendFor(root.model[index]) !== "" ? 1.0 : 0.65

                readonly property var assignment: root.model[index] || null
                readonly property real minimumContentWidth: Math.max(
                    nameText.implicitWidth,
                    legendText.visible ? legendText.implicitWidth : 0) + root.capPadding * 2

                Column {
                    id: contentColumn
                    objectName: "pfContent_" + cap.index

                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        id: nameText
                        objectName: "pfName_" + cap.index
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.nameFor(cap.index, cap.assignment)
                        color: root.textColor
                        font.family: "monospace"
                        font.bold: true
                        font.pixelSize: 11
                    }

                    Text {
                        id: legendText
                        objectName: "pfLegend_" + cap.index
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.legendFor(cap.assignment)
                        visible: text.length > 0
                        color: root.textColor
                        font.family: "monospace"
                        font.pixelSize: 9
                        opacity: 0.9
                    }
                }
            }
        }
    }
}
