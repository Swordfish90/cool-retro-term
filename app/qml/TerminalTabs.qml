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

Item {
    id: tabsRoot

    readonly property int innerPadding: 6
    readonly property string currentTitle: tabsModel.get(currentIndex).title ?? "cool-retro-term"
    readonly property size terminalSize: stack.currentItem ? stack.currentItem.terminalSize : Qt.size(0, 0)
    property alias currentIndex: tabBar.currentIndex
    readonly property int count: tabsModel.count
    property var hostWindow

    function normalizeTitle(rawTitle) {
        if (rawTitle === undefined || rawTitle === null) {
            return ""
        }
        return String(rawTitle).trim()
    }

    function addTab() {
        tabsModel.append({ title: "" })
        tabBar.currentIndex = tabsModel.count - 1
    }

    function closeTab(index) {
        if (tabsModel.count <= 1) {
            hostWindow.close()
            return
        }

        tabsModel.remove(index)
        tabBar.currentIndex = Math.min(tabBar.currentIndex, tabsModel.count - 1)
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
                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors { leftMargin: innerPadding; rightMargin: innerPadding }
                                spacing: innerPadding

                                Label {
                                    text: model.title
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
                    id: terminalContainer
                    hasFocus: terminalWindow.active && StackLayout.isCurrentItem
                    onTitleChanged: tabsModel.setProperty(index, "title", normalizeTitle(title))
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onSessionFinished: tabsRoot.closeTab(index)
                }
            }
        }
    }
}
