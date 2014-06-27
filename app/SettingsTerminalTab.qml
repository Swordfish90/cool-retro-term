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

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

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
                currentIndex: shadersettings.rasterization
                onCurrentIndexChanged: {
                    scalingChanger.enabled = false;
                    shadersettings.rasterization = currentIndex
                    fontChanger.updateIndex();
                    scalingChanger.updateIndex();
                    scalingChanger.enabled = true;
                }
            }
        }
        GroupBox{
            title: qsTr("Font") + " (" + rasterizationBox.selectedElement + ")"
            Layout.fillWidth: true
            GridLayout{
                anchors.fill: parent
                columns: 2
                Text{ text: qsTr("Name") }
                ComboBox{
                    id: fontChanger
                    Layout.fillWidth: true
                    model: shadersettings.fontlist
                    currentIndex: updateIndex()
                    onActivated: {
                        shadersettings.fontIndexes[shadersettings.rasterization] = index;
                        shadersettings.handleFontChanged();
                    }
                    function updateIndex(){
                        currentIndex = shadersettings.fontIndexes[shadersettings.rasterization];
                    }
                }
                Text{ text: qsTr("Scaling") }
                RowLayout{
                    Layout.fillWidth: true
                    Slider{
                        id: scalingChanger
                        Layout.fillWidth: true
                        minimumValue: 0
                        maximumValue: shadersettings.fontScalingList.length - 1
                        stepSize: 1
                        tickmarksEnabled: true
                        value: updateIndex()
                        onValueChanged: {
                            if(!enabled) return; //Ugly and hacky solution. Look for a better solution.
                            shadersettings.fontScalingIndexes[shadersettings.rasterization] = value;
                            shadersettings.handleFontChanged();
                        }
                        function updateIndex(){
                            value = shadersettings.fontScalingIndexes[shadersettings.rasterization];
                        }
                    }
                    Text{
                        text: shadersettings.fontScalingList[scalingChanger.value].toFixed(2)
                    }
                }
            }
        }
        GroupBox{
            title: qsTr("Colors")
            Layout.fillWidth: true
            RowLayout{
                anchors.fill: parent
                ColorButton{
                    name: qsTr("Font")
                    height: 50
                    Layout.fillWidth: true
                    onButton_colorChanged: shadersettings._font_color = button_color
                    button_color: shadersettings._font_color
                }
                ColorButton{
                    name: qsTr("Background")
                    height: 50
                    Layout.fillWidth: true
                    onButton_colorChanged: shadersettings._background_color = button_color
                    button_color: shadersettings._background_color
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
                    model: shadersettings.frames_list
                    currentIndex: shadersettings.frames_index
                    onCurrentIndexChanged: shadersettings.frames_index = currentIndex
                }
                CheckBox{
                    checked: shadersettings.frame_reflections
                    text: qsTr("Reflections")
                    onCheckedChanged: shadersettings.frame_reflections = checked
                    enabled: framescombobox.model.get(framescombobox.currentIndex).reflections
                }
            }
        }
    }
}
