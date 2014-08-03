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
            Layout.fillWidth: true
            title: qsTr("Profile")
            ColumnLayout{
                anchors.fill: parent
                ComboBox{
                    id: profilesbox
                    Layout.fillWidth: true
                    model: shadersettings.profiles_list
                    currentIndex: shadersettings.profiles_index
                }
                RowLayout{
                    Layout.fillWidth: true
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Load")
                        onClicked: {
                            shadersettings.profiles_index = profilesbox.currentIndex
                            shadersettings.loadCurrentProfile();
                            shadersettings.handleFontChanged();
                        }
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Save New Profile")
                        onClicked: insertname.show()
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Remove Selected")
                        enabled: !shadersettings.profiles_list.get(profilesbox.currentIndex).builtin
                        onClicked: {
                            shadersettings.profiles_list.remove(profilesbox.currentIndex)
                            profilesbox.currentIndex = profilesbox.currentIndex - 1
                        }
                    }
                }
                InsertNameDialog{
                    id: insertname
                    onNameSelected: shadersettings.addNewCustomProfile(name)
                }
            }
        }
        GroupBox{
            title: qsTr("Lights")
            Layout.fillWidth: true
            GridLayout{
                anchors.fill: parent
                columns: 2
                Text{ text: qsTr("Brightness") }
                SimpleSlider{
                    onValueChanged: shadersettings.brightness = value
                    value: shadersettings.brightness
                }
                Text{ text: qsTr("Contrast") }
                SimpleSlider{
                    onValueChanged: shadersettings.contrast = value
                    value: shadersettings.contrast
                }
                Text{ text: qsTr("Opacity") }
                SimpleSlider{
                    onValueChanged: shadersettings.windowOpacity = value
                    value: shadersettings.windowOpacity
                }
            }
        }
        GroupBox{
            title: qsTr("Performace")
            Layout.fillWidth: true
            Layout.columnSpan: 2
            anchors.left: parent.left
            anchors.right: parent.right
            GridLayout{
                anchors.fill: parent
                rows: 3
                columns: 3
                CheckBox{
                    Layout.columnSpan: 3
                    checked: !shadersettings._frameReflections
                    text: qsTr("Disable reflections")
                    onCheckedChanged: shadersettings._frameReflections = !checked
                    enabled: shadersettings.reflectionsAllowed
                }
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
    }
}
