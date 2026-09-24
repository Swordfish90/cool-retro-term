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
import QtQuick.Controls
import QtQuick.Layouts

import "Components"
import "logic/pfkeys.js" as PfKeys
import "logic/platform.js" as Platform

ScrollView {
    id: retroTab
    clip: true

    readonly property int slotCount: appSettings.pfAssignments.length
    readonly property var keyMap: Platform.sequences(Qt.platform.os)
    readonly property int collisionCount: PfKeys.collisions(appSettings.pfAssignments).length

    function setSlot(index, patch) {
        appSettings.patchPfAssignment(index, patch)
    }

    /** Index into the action catalogue of the function bound to a slot. */
    function actionIndexOf(assignment) {
        if (!assignment)
            return 0
        for (var i = 0; i < PfKeys.ACTIONS.length; i++) {
            if (PfKeys.ACTIONS[i].id === assignment.action)
                return i
        }
        return 0
    }

    ColumnLayout {
        width: retroTab.availableWidth
        spacing: 12

        // INTERFACE //////////////////////////////////////////////////////////
        GroupBox {
            title: qsTr("Interface")
            Layout.fillWidth: true
            padding: appSettings.defaultMargin

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                CheckBox {
                    objectName: "nostalgicModeCheckBox"
                    text: qsTr("Nostalgic mode: no menu bar, no tab bar, no context menu")
                    checked: appSettings.nostalgicMode
                    onCheckedChanged: appSettings.nostalgicMode = checked
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.75
                    text: qsTr("Nothing on screen suggests a graphical interface. "
                               + "Everything is driven from the keyboard: "
                               + "settings %1, new window %2, next window %3, "
                               + "close window %4, fullscreen %5, quit %6.")
                        .arg(retroTab.keyMap.settings)
                        .arg(retroTab.keyMap.newWindow)
                        .arg(retroTab.keyMap.nextWindow)
                        .arg(retroTab.keyMap.closeWindow)
                        .arg("F11")
                        .arg(retroTab.keyMap.quit)
                }

                CheckBox {
                    objectName: "showPfKeysCheckBox"
                    text: qsTr("Show the IBM PF/PA key legend on the screen")
                    checked: appSettings.showPfKeys
                    onCheckedChanged: appSettings.showPfKeys = checked
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.75
                    text: qsTr("The legend is part of the display, not a widget: "
                               + "it cannot be clicked or focused, only read.")
                }
            }
        }

        // PF / PA KEYS ///////////////////////////////////////////////////////
        GroupBox {
            title: qsTr("PF / PA Keys")
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: appSettings.defaultMargin

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.75
                    text: qsTr("Twelve PF keys and three PA keys, as on an IBM "
                               + "3270. A function of \"Off\" hands the key back "
                               + "to the shell untouched. Use %1 and %2 for the "
                               + "window actions the desktop does not already own.")
                        .arg(retroTab.keyMap.nextWindow)
                        .arg(retroTab.keyMap.newWindow)
                }

                Label {
                    objectName: "pfCollisionWarning"
                    visible: retroTab.collisionCount > 0
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#e0a030"
                    text: qsTr("%1 key(s) claim the same sequence; only one of "
                               + "them can be recognised.").arg(retroTab.collisionCount)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label { text: qsTr("Key"); font.bold: true; Layout.preferredWidth: 44 }
                    Label { text: qsTr("Sequence"); font.bold: true; Layout.preferredWidth: 110 }
                    Label { text: qsTr("Function"); font.bold: true; Layout.fillWidth: true }
                    Label { text: qsTr("Text"); font.bold: true; Layout.preferredWidth: 150 }
                }

                Repeater {
                    model: retroTab.slotCount

                    delegate: RowLayout {
                        id: slotRow
                        objectName: "pfSlot_" + index

                        Layout.columnSpan: 4
                        Layout.fillWidth: true
                        spacing: 8

                        required property int index

                        readonly property var assignment: index < appSettings.pfAssignments.length
                                ? appSettings.pfAssignments[index] : null
                        readonly property int actionIndex: retroTab.actionIndexOf(assignment)

                        Label {
                            objectName: "pfName_" + slotRow.index
                            text: PfKeys.slotName(slotRow.index)
                            Layout.preferredWidth: 44
                            font.family: "monospace"
                        }

                        TextField {
                            objectName: "pfKey_" + slotRow.index
                            Layout.preferredWidth: 110
                            text: slotRow.assignment ? slotRow.assignment.key : ""
                            onEditingFinished: {
                                var value = text.trim()
                                if (value.length > 0)
                                    retroTab.setSlot(slotRow.index, { key: value })
                                else
                                    text = slotRow.assignment ? slotRow.assignment.key : ""
                            }
                        }

                        ComboBox {
                            objectName: "pfAction_" + slotRow.index
                            Layout.fillWidth: true
                            textRole: "label"
                            valueRole: "id"
                            model: PfKeys.ACTIONS
                            currentIndex: slotRow.actionIndex
                            onActivated: {
                                retroTab.setSlot(slotRow.index, { action: currentValue })
                                // Interacting with a ComboBox writes its index
                                // imperatively and would otherwise drop the
                                // binding, leaving the row stale after a reset.
                                currentIndex = Qt.binding(function() {
                                    return slotRow.actionIndex
                                })
                            }
                        }

                        TextField {
                            objectName: "pfPayload_" + slotRow.index
                            Layout.preferredWidth: 150
                            visible: slotRow.assignment && slotRow.assignment.action === "sendText"
                            placeholderText: qsTr("e.g. ls -la\\n")
                            text: slotRow.assignment ? slotRow.assignment.payload : ""
                            onEditingFinished: retroTab.setSlot(slotRow.index, { payload: text })
                        }
                    }
                }

                Button {
                    objectName: "resetPfKeysButton"
                    text: qsTr("Reset PF/PA keys to defaults")
                    onClicked: appSettings.resetPfAssignments()
                }
            }
        }

        // SOUND //////////////////////////////////////////////////////////////
        GroupBox {
            title: qsTr("Sound")
            Layout.fillWidth: true
            padding: appSettings.defaultMargin

            GridLayout {
                anchors.fill: parent
                columns: 3
                columnSpacing: 8
                rowSpacing: 6

                CheckBox {
                    objectName: "audioEnabledCheckBox"
                    Layout.columnSpan: 3
                    text: qsTr("Enable audible feedback")
                    checked: appSettings.audioEnabled
                    onCheckedChanged: appSettings.audioEnabled = checked
                }

                CheckBox {
                    objectName: "keyClickCheckBox"
                    text: qsTr("Key click")
                    enabled: appSettings.audioEnabled
                    checked: appSettings.keyClick
                    onCheckedChanged: appSettings.keyClick = checked
                }
                Slider {
                    id: keyClickVolume
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    enabled: appSettings.audioEnabled && appSettings.keyClick
                    from: 0.0
                    to: 1.0
                    stepSize: 0.05
                    value: appSettings.keyClickVolume
                    onValueChanged: appSettings.keyClickVolume = value
                }

                CheckBox {
                    objectName: "bellCheckBox"
                    text: qsTr("Terminal bell")
                    enabled: appSettings.audioEnabled
                    checked: appSettings.bell
                    onCheckedChanged: appSettings.bell = checked
                }
                Slider {
                    id: bellVolume
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    enabled: appSettings.audioEnabled && appSettings.bell
                    from: 0.0
                    to: 1.0
                    stepSize: 0.05
                    value: appSettings.bellVolume
                    onValueChanged: appSettings.bellVolume = value
                }
            }
        }

        // CURSOR AND ACTIVE LINE /////////////////////////////////////////////
        GroupBox {
            title: qsTr("Cursor and active line")
            Layout.fillWidth: true
            padding: appSettings.defaultMargin

            GridLayout {
                anchors.fill: parent
                columns: 3
                columnSpacing: 8
                rowSpacing: 6

                CheckBox {
                    objectName: "highlightActiveLineCheckBox"
                    Layout.columnSpan: 3
                    text: qsTr("Highlight the active line (the row the cursor is on)")
                    checked: appSettings.highlightActiveLine
                    onCheckedChanged: appSettings.highlightActiveLine = checked
                }

                Label { text: qsTr("Highlight strength") }
                Slider {
                    id: activeLineOpacity
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    enabled: appSettings.highlightActiveLine
                    from: 0.0
                    to: 1.0
                    stepSize: 0.01
                    value: appSettings.activeLineOpacity
                    onValueChanged: appSettings.activeLineOpacity = value
                }

                Label { text: qsTr("Cursor shape") }
                ComboBox {
                    objectName: "cursorStyleComboBox"
                    Layout.columnSpan: 2
                    Layout.preferredWidth: 180
                    textRole: "label"
                    valueRole: "value"
                    model: [
                        { label: qsTr("Block (3270 / PC BIOS)"), value: "block" },
                        { label: qsTr("Half block"), value: "half" }
                    ]
                    currentIndex: appSettings.cursorStyle === "half" ? 1 : 0
                    onActivated: appSettings.cursorStyle = currentValue
                }
            }
        }
    }
}
