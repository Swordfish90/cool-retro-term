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
import QtQuick 2.2
import QtQuick.Dialogs 1.1

Item {
    id: rootItem

    signal colorSelected(color color)
    property color color
    property string name

    ColorDialog {
        id: colorDialog
        title: qsTr("Choose a color")
        modality: Qt.ApplicationModal
        visible: false

        //This is a workaround to a Qt 5.2 bug.
        onColorChanged: if (!appSettings.isMacOS) colorSelected(color)
        onAccepted: if (appSettings.isMacOS) colorSelected(color)
    }
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: rootItem.color

        Rectangle {
            anchors.fill: parent
            anchors.margins: parent.height * 0.25
            radius: parent.radius
            color: "white"
            opacity: 0.5
        }
        Text {
            anchors.centerIn: parent
            z: parent.z + 1
            text: name + ":  " + rootItem.color
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: colorDialog.visible = true
    }
}
