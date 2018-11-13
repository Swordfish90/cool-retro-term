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
import QtQuick.Dialogs 1.1

Tab{
    ColumnLayout{
        anchors.fill: parent
        GroupBox{
            title: qsTr("Rasterization Mode")
            Layout.fillWidth: true
            ComboBox {
                id: rasterizationBox
                property string selectedElement: model[currentIndex]
                anchors.fill: parent
                model: [qsTr("Default"), qsTr("Scanlines"), qsTr("Pixels")]
                currentIndex: appSettings.rasterization
                onCurrentIndexChanged: {
                    appSettings.rasterization = currentIndex
                }
            }
        }
        GroupBox{
            title: qsTr("Lights")
            Layout.fillWidth: true
            GridLayout{
                anchors.fill: parent
                columns: 2
                Label{ text: qsTr("Brightness") }
                SimpleSlider{
                    onValueChanged: appSettings.brightness = value
                    value: appSettings.brightness
                }
                Label{ text: qsTr("Contrast") }
                SimpleSlider{
                    onValueChanged: appSettings.contrast = value
                    value: appSettings.contrast
                }
                Label{ text: qsTr("Opacity") }
                SimpleSlider{
                    onValueChanged: appSettings.windowOpacity = value
                    value: appSettings.windowOpacity
                }
            }
        }
        GroupBox{
            title: qsTr("Frame")
            Layout.fillWidth: true
            RowLayout{
                anchors.fill: parent
                ComboBox{
                    id: framescombobox
                    Layout.fillWidth: true
                    model: appSettings.framesList
                    currentIndex: appSettings.framesIndex
                    onActivated: {
                        appSettings.frameName = appSettings.framesList.get(index).name;
                    }
                    function updateIndex(){
                        var name = appSettings.frameName;
                        var index = appSettings.getFrameIndexByName(name);
                        if (index !== undefined)
                            currentIndex = index;
                    }
                    Component.onCompleted: updateIndex();
                    Connections {
                        target: appSettings
                        onFrameNameChanged: framescombobox.updateIndex();
                    }
                }
            }
        }
    }
}
