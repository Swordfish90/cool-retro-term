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

import "Components"

Tab{
    ColumnLayout{
        anchors.fill: parent

        GroupBox{
            Layout.fillWidth: true
            title: qsTr("Command")
            ColumnLayout {
                anchors.fill: parent
                CheckBox{
                    id: useCustomCommand
                    text: qsTr("Use custom command instead of shell at startup")
                    checked: appSettings.useCustomCommand
                    onCheckedChanged: appSettings.useCustomCommand = checked
                }
                // Workaround for QTBUG-31627 for pre 5.3.0
                Binding{
                    target: useCustomCommand
                    property: "checked"
                    value: appSettings.useCustomCommand
                }
                TextField{
                    id: customCommand
                    Layout.fillWidth: true
                    text: appSettings.customCommand
                    enabled: useCustomCommand.checked
                    onEditingFinished: appSettings.customCommand = text

                    // Save text even if user forgets to press enter or unfocus
                    function saveSetting() {
                        appSettings.customCommand = text;
                    }
                    Component.onCompleted: settings_window.closing.connect(saveSetting)
                }
            }
        }

        GroupBox{
            title: qsTr("Performance")
            Layout.fillWidth: true
            GridLayout{
                anchors.fill: parent
                rows: 2
                columns: 3

                Label{text: qsTr("Effects FPS")}
                Slider{
                    Layout.fillWidth: true
                    id: fpsSlider
                    onValueChanged: {
                        if (enabled) {
                            appSettings.fps = value !== 60 ? value + 1 : 0;
                        }
                    }
                    stepSize: 1
                    enabled: false
                    Component.onCompleted: {
                        minimumValue = 0;
                        maximumValue = 60;
                        value = appSettings.fps !== 0 ? appSettings.fps - 1 : 60;
                        enabled = true;
                    }
                }

                SizedLabel{text: appSettings.fps !== 0 ? appSettings.fps : qsTr("Max")}
                Label{text: qsTr("Texture Quality")}
                Slider{
                    Layout.fillWidth: true
                    id: txtslider
                    onValueChanged: if (enabled) appSettings.windowScaling = value;
                    stepSize: 0.05
                    enabled: false
                    Component.onCompleted: {
                        minimumValue = 0.25 //Without this value gets set to 0.5
                        value = appSettings.windowScaling;
                        enabled = true;
                    }
                }
                SizedLabel{text: Math.round(txtslider.value * 100) + "%"}

                Label{text: qsTr("Bloom Quality")}
                Slider{
                    Layout.fillWidth: true
                    id: bloomSlider
                    onValueChanged: if (enabled) appSettings.bloomQuality = value;
                    stepSize: 0.05
                    enabled: false
                    Component.onCompleted: {
                        minimumValue = 0.25
                        value = appSettings.bloomQuality;
                        enabled = true;
                    }
                }
                SizedLabel{text: Math.round(bloomSlider.value * 100) + "%"}

                Label{text: qsTr("BurnIn Quality")}
                Slider{
                    Layout.fillWidth: true
                    id: burnInSlider
                    onValueChanged: if (enabled) appSettings.burnInQuality = value;
                    stepSize: 0.05
                    enabled: false
                    Component.onCompleted: {
                        minimumValue = 0.25
                        value = appSettings.burnInQuality;
                        enabled = true;
                    }
                }
                SizedLabel{text: Math.round(burnInSlider.value * 100) + "%"}
                CheckBox{
                    Layout.columnSpan: 2
                    text: qsTr("Burnin optimization (Might display timing artifacts)")
                    checked: appSettings.useFastBurnIn
                    onCheckedChanged: appSettings.useFastBurnIn = checked
                }
            }
        }
    }
}
