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

    readonly property string title: stack.currentItem ? stack.currentItem.title : ""
    readonly property size terminalSize: stack.currentItem ? stack.currentItem.terminalSize : Qt.size(0, 0)
    property alias currentIndex: tabBar.currentIndex
    readonly property int count: tabsModel.count

    function addTab() {
        tabsModel.append({ title: qsTr("Tab %1").arg(tabsModel.count + 1) })
        tabBar.currentIndex = tabsModel.count - 1
    }

    function closeTab(index) {
        if (tabsModel.count <= 1)
            return

        tabsModel.remove(index)
        if (tabBar.currentIndex >= tabsModel.count) {
            tabBar.currentIndex = tabsModel.count - 1
        }
    }

    ListModel {
        id: tabsModel
    }

    Component.onCompleted: addTab()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            focusPolicy: Qt.NoFocus
            visible: tabsModel.count > 1

            background: Rectangle {
                color: palette.window
            }

            Repeater {
                model: tabsModel
                TabButton {
                    id: tabButton
                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors { leftMargin: 6; rightMargin: 6 }
                        spacing: 6

                        Label {
                            text: model.title
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ToolButton {
                            text: "\u00d7"
                            focusPolicy: Qt.NoFocus
                            visible: tabsModel.count > 1
                            enabled: visible
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: tabsRoot.closeTab(index)
                        }
                    }
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
                onItemAdded: function(index, item) {
                    if (index === tabBar.currentIndex)
                        item.activate()
                }
                TerminalContainer {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onTitleChanged: tabsModel.setProperty(index, "title", title)
                }
            }
        }
    }

    Connections {
        target: tabBar
        onCurrentIndexChanged: {
            if (stack.currentItem)
                stack.currentItem.activate()
        }
    }
}
