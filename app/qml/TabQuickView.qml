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

// Tilix-like tab quick view: a strip on the left with a live preview of every tab.
// It covers the tab area; the previews are rendered from the tab items themselves, which
// must be visible (but are hidden from the scene by the previews) while it is open.
FocusScope {
    id: quickView

    property var model
    property Repeater tabs
    property int currentIndex: 0

    signal tabSelected(int index)
    signal closeRequested()

    readonly property int stripWidth: Math.min(500, width - 40)
    readonly property int spacing: 10

    Keys.onEscapePressed: closeRequested()

    // Clicking anywhere outside the strip closes it.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.3

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: quickView.closeRequested()
            onWheel: function(wheel) { }
        }
    }

    Rectangle {
        id: strip

        width: stripWidth
        height: parent.height
        color: "#101010"

        NumberAnimation on x {
            from: -strip.width
            to: 0
            duration: 120
            easing.type: Easing.OutCubic
        }

        // Keep clicks between previews from closing the strip.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ListView {
            id: list

            anchors.fill: parent
            anchors.margins: quickView.spacing
            spacing: quickView.spacing
            clip: true
            focus: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            model: quickView.model
            currentIndex: quickView.currentIndex

            ScrollBar.vertical: ScrollBar { }

            Keys.onReturnPressed: quickView.tabSelected(currentIndex)
            Keys.onEnterPressed: quickView.tabSelected(currentIndex)

            delegate: Item {
                id: entry

                readonly property Item tabItem: quickView.tabs ? quickView.tabs.itemAt(index) : null
                readonly property bool isActiveTab: index === quickView.currentIndex
                readonly property bool isSelected: ListView.isCurrentItem

                width: ListView.view.width
                height: frame.height + caption.height + 4

                Rectangle {
                    id: frame

                    width: parent.width
                    // Same aspect ratio as the tab area the quick view covers.
                    height: width * quickView.height / Math.max(1, quickView.width)
                    color: "black"
                    border.width: 2
                    border.color: entry.isSelected ? palette.highlight
                                                   : entryArea.containsMouse ? "#808080" : "#303030"

                    ShaderEffectSource {
                        anchors.fill: parent
                        anchors.margins: frame.border.width
                        sourceItem: entry.tabItem
                        // The active tab is still shown behind the strip; the others only here.
                        hideSource: !entry.isActiveTab
                        textureSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                        smooth: true
                    }
                }

                Label {
                    id: caption

                    anchors.top: frame.bottom
                    anchors.topMargin: 4
                    width: parent.width
                    text: (index + 1) + "   " + model.title
                    font.bold: entry.isActiveTab
                    color: entry.isSelected ? "white" : "#b0b0b0"
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: entryArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: quickView.tabSelected(index)
                }
            }
        }
    }

    Component.onCompleted: {
        list.positionViewAtIndex(currentIndex, ListView.Contain)
        forceActiveFocus()
    }
}
