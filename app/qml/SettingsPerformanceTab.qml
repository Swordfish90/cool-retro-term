/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
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
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

Tab{
    ColumnLayout{
        anchors.fill: parent
        GroupBox{
            title: qsTr("General")
            Layout.fillWidth: true
            Layout.columnSpan: 2
            anchors.left: parent.left
            anchors.right: parent.right
            GridLayout{
                anchors.fill: parent
                rows: 2
                columns: 3
                CheckBox{
                    property int fps: checked ? slider.value : 0
                    onFpsChanged: shadersettings.fps = fps
                    checked: shadersettings.fps !== 0
                    text: qsTr("Limit FPS")
                }
                Slider{
                    id: slider
                    Layout.fillWidth: true
                    stepSize: 1
                    maximumValue: 60
                    minimumValue: 1
                    enabled: shadersettings.fps !== 0
                    value: shadersettings.fps !== 0 ? shadersettings.fps : 60
                }
                Text{text: slider.value}
                Text{text: qsTr("Texture quality")}
                Slider{
                    Layout.fillWidth: true
                    id: txtslider
                    onValueChanged: shadersettings.window_scaling = value;
                    value: shadersettings.window_scaling
                    tickmarksEnabled: true
                    stepSize: 0.25
                    Component.onCompleted: minimumValue = 0.5 //Without this value gets set to 0.5
                }
                Text{text: Math.round(txtslider.value * 100) + "%"}
            }
        }
        GroupBox{
            title: qsTr("Frame")
            Layout.fillWidth: true
            Layout.columnSpan: 2
            anchors.left: parent.left
            anchors.right: parent.right
            CheckBox{
                Layout.columnSpan: 3
                checked: !shadersettings._frameReflections
                text: qsTr("Disable reflections")
                onCheckedChanged: shadersettings._frameReflections = !checked
                enabled: shadersettings.reflectionsAllowed
            }
        }
    }
}
