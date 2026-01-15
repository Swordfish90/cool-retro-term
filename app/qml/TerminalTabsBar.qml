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
import QtQuick.Window

Item {
    id: barRoot

    readonly property int innerPadding: 6
    readonly property int leftInset: (isMacOS && !showWindowControls) ? 72 : 0
    property var tabsController
    property var hostWindow
    property bool isMacOS: false
    property bool showWindowControls: true
    property bool windowControlsOnLeft: false
    property bool enableSystemMove: true
    property bool enableDoubleClickMaximize: true

    implicitHeight: rowLayout.implicitHeight

    function toggleMaximize() {
        if (!hostWindow) {
            return
        }
        hostWindow.visibility = (hostWindow.visibility === Window.Maximized)
            ? Window.Windowed
            : Window.Maximized
    }

    onTabsControllerChanged: {
        if (tabsController) {
            tabBar.currentIndex = tabsController.currentIndex
        }
    }

    Component.onCompleted: {
        if (tabsController) {
            tabBar.currentIndex = tabsController.currentIndex
        }
    }

    Rectangle {
        anchors.fill: parent
        color: palette.window
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: leftInset
            visible: leftInset > 0
        }

        Loader {
            active: showWindowControls && windowControlsOnLeft
            sourceComponent: windowControlsComponent
        }

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.fillHeight: true
            focusPolicy: Qt.NoFocus

            onCurrentIndexChanged: {
                if (tabsController && tabsController.currentIndex !== currentIndex) {
                    tabsController.currentIndex = currentIndex
                }
            }

            Repeater {
                model: tabsController ? tabsController.tabsModel : null
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
                            onClicked: {
                                if (tabsController) {
                                    tabsController.closeTab(index)
                                }
                            }
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
            onClicked: {
                if (tabsController) {
                    tabsController.addTab()
                }
            }
        }

        Loader {
            active: showWindowControls && !windowControlsOnLeft
            sourceComponent: windowControlsComponent
        }
    }

    Component {
        id: windowControlsComponent
        RowLayout {
            id: windowControls
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            ToolButton {
                text: "\u2212"
                focusPolicy: Qt.NoFocus
                padding: innerPadding
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    if (hostWindow) {
                        hostWindow.visibility = Window.Minimized
                    }
                }
            }

            ToolButton {
                text: hostWindow && hostWindow.visibility === Window.Maximized ? "\u2752" : "\u25a1"
                focusPolicy: Qt.NoFocus
                padding: innerPadding
                Layout.alignment: Qt.AlignVCenter
                onClicked: toggleMaximize()
            }

            ToolButton {
                text: "\u00d7"
                focusPolicy: Qt.NoFocus
                padding: innerPadding
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    if (hostWindow) {
                        hostWindow.close()
                    }
                }
            }
        }
    }

    Connections {
        target: tabsController
        function onCurrentIndexChanged() {
            if (tabBar.currentIndex !== tabsController.currentIndex) {
                tabBar.currentIndex = tabsController.currentIndex
            }
        }
    }

    DragHandler {
        acceptedDevices: PointerDevice.Mouse
        acceptedButtons: Qt.LeftButton
        grabPermissions: PointerHandler.CanTakeOverFromItems
        target: null
        onActiveChanged: {
            if (active && hostWindow && enableSystemMove) {
                hostWindow.startSystemMove()
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            if (tapCount === 2 && enableDoubleClickMaximize) {
                toggleMaximize()
            }
        }
    }
}
