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
import QtQml.Models

Item {
    id: tabsRoot

    readonly property int innerPadding: 6
    readonly property string currentTitle: tabsModel.get(currentIndex).title ?? "cool-retro-term"
    property alias currentIndex: tabBar.currentIndex
    readonly property int count: tabsModel.count
    property size terminalSize: Qt.size(0, 0)

    // Each tab gets a stable number, shown while the shell has not set a title.
    property int nextTabNumber: 1

    function normalizeTitle(rawTitle) {
        if (rawTitle === undefined || rawTitle === null) {
            return ""
        }
        return String(rawTitle).trim()
    }

    function addTab() {
        tabsModel.append({ title: "", number: nextTabNumber++ })
        tabBar.currentIndex = tabsModel.count - 1
    }

    function closeTab(index) {
        if (tabsModel.count <= 1) {
            terminalWindow.close()
            return
        }

        tabsModel.remove(index)
        tabBar.currentIndex = Math.min(tabBar.currentIndex, tabsModel.count - 1)
    }

    function moveTab(from, to) {
        if (from === to || from < 0 || to < 0 || from >= tabsModel.count || to >= tabsModel.count)
            return
        tabsModel.move(from, to, 1)
        tabBar.currentIndex = to
    }

    // Index of the tab button under x (in tabBar coordinates), or -1.
    function tabIndexAt(x) {
        for (var i = 0; i < tabBar.count; i++) {
            var item = tabBar.itemAt(i)
            var left = item.mapToItem(tabBar, 0, 0).x
            if (x >= left && x < left + item.width)
                return i
        }
        return -1
    }

    ListModel {
        id: tabsModel
    }

    Component.onCompleted: addTab()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: tabRow
            Layout.fillWidth: true
            height: rowLayout.implicitHeight
            color: palette.window
            visible: tabsModel.count > 1

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                spacing: 0

                TabBar {
                    id: tabBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    focusPolicy: Qt.NoFocus

                    Repeater {
                        model: tabsModel
                        TabButton {
                            id: tabButton

                            // Drag a tab sideways to reorder it. The terminal moves with it.
                            DragHandler {
                                id: tabDrag
                                target: null
                                cursorShape: Qt.ClosedHandCursor
                                yAxis.enabled: false
                                onActiveChanged: if (active) tabBar.currentIndex = index
                                onCentroidChanged: {
                                    if (!active)
                                        return
                                    var p = tabButton.mapToItem(tabBar, centroid.position.x, centroid.position.y)
                                    var to = tabsRoot.tabIndexAt(p.x)
                                    if (to !== -1 && to !== index)
                                        tabsRoot.moveTab(index, to)
                                }
                            }

                            // Fade the tab while it is being dragged.
                            opacity: tabDrag.active ? 0.5 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors { leftMargin: innerPadding; rightMargin: innerPadding }
                                spacing: innerPadding

                                Label {
                                    text: model.title !== "" ? model.title : qsTr("Terminal %1").arg(model.number)
                                    font.italic: model.title === ""
                                    opacity: model.title === "" ? 0.7 : 1.0
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ToolButton {
                                    text: "\u00d7"
                                    focusPolicy: Qt.NoFocus
                                    padding: innerPadding
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: tabsRoot.closeTab(index)
                                }
                            }
                        }
                    }
                }

                ToolButton {
                    id: addTabButton
                    text: "+"
                    focusPolicy: Qt.NoFocus
                    Layout.fillHeight: true
                    padding: innerPadding
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: tabsRoot.addTab()
                }
            }
        }

        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            Repeater {
                model: tabsModel
                TerminalContainer {
                    property bool shouldHaveFocus: terminalWindow.active && StackLayout.isCurrentItem
                    isActive: StackLayout.isCurrentItem
                    onShouldHaveFocusChanged: {
                        if (shouldHaveFocus) {
                            activate()
                        }
                    }
                    onTitleChanged: tabsModel.setProperty(index, "title", normalizeTitle(title))
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onSessionFinished: tabsRoot.closeTab(index)
                    onTerminalSizeChanged: updateTerminalSize()

                    function updateTerminalSize() {
                        // Every tab will have the same size so we can simply take the first one.
                        if (index == 0) {
                            tabsRoot.terminalSize = terminalSize
                        }
                    }
                }
            }
        }
    }
}
