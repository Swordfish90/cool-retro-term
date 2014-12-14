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
            anchors.left: parent.left
            anchors.right: parent.right
            GridLayout{
                anchors.fill: parent
                rows: 2
                columns: 3
                CheckBox{
                    property int fps: checked ? slider.value : 0
                    onFpsChanged: appSettings.fps = fps
                    checked: appSettings.fps !== 0
                    text: qsTr("Limit FPS")
                }
                Slider{
                    id: slider
                    Layout.fillWidth: true
                    stepSize: 1
                    maximumValue: 60
                    minimumValue: 1
                    enabled: appSettings.fps !== 0
                    value: appSettings.fps !== 0 ? appSettings.fps : 60
                }
                Text{text: slider.value}
                Text{text: qsTr("Texture Quality")}
                Slider{
                    Layout.fillWidth: true
                    id: txtslider
                    onValueChanged: appSettings.window_scaling = value;
                    value: appSettings.window_scaling
                    stepSize: 0.10
                    Component.onCompleted: minimumValue = 0.3 //Without this value gets set to 0.5
                }
                Text{text: Math.round(txtslider.value * 100) + "%"}
            }
        }
        GroupBox{
            title: qsTr("Bloom")
            Layout.fillWidth: true
            anchors.left: parent.left
            anchors.right: parent.right
            GridLayout{
                id: bloomQualityContainer
                anchors.fill: parent

                Text{text: qsTr("Bloom Quality")}
                Slider{
                    Layout.fillWidth: true
                    id: bloomSlider
                    onValueChanged: appSettings.bloom_quality = value;
                    value: appSettings.bloom_quality
                    stepSize: 0.10
                    Component.onCompleted: minimumValue = 0.3 //Without this value gets set to 0.5
                }
                Text{text: Math.round(bloomSlider.value * 100) + "%"}
            }
        }
        GroupBox{
            title: qsTr("Frame")
            Layout.fillWidth: true
            anchors.left: parent.left
            anchors.right: parent.right
            CheckBox{
                checked: appSettings._frameReflections
                text: qsTr("Frame Reflections")
                onCheckedChanged: appSettings._frameReflections = checked
            }
        }
    }
}
