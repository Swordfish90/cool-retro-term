/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordifish90/cool-old-term
*
* This file is part of cool-old-term.
*
* cool-old-term is free software: you can redistribute it and/or modify
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

import QtQuick 2.1
import QtQuick.Dialogs 1.1

Item {
    property color button_color;

    ColorDialog {
        id: colorDialog
        title: qsTr("Choose a color")
        modality: Qt.ApplicationModal
        visible: false

        //This is a workaround to a Qt 5.2 bug.
        onCurrentColorChanged: colorDialog.color = colorDialog.currentColor;
        onAccepted: button_color = color;
    }
    Rectangle{
        radius: 10
        anchors.fill: parent
        color: button_color

        Text{
            id: text_color
            anchors.centerIn: parent
            z: 1.1
            text: button_color
        }

        Rectangle{
            anchors.centerIn: parent
            width: text_color.width * 1.4
            height: text_color.height * 1.4
            radius: 10
            border.color: "black"
            border.width: 2
            color: "white"
        }
    }
    MouseArea{
        anchors.fill: parent
        onClicked: colorDialog.visible = true;
    }
}
