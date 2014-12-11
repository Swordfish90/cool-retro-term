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
            Layout.fillWidth: true
            title: qsTr("Profile")
            ColumnLayout{
                anchors.fill: parent
                ComboBox{
                    id: profilesbox
                    Layout.fillWidth: true
                    model: appSettings.profiles_list
                    currentIndex: appSettings.profiles_index
                }
                RowLayout{
                    Layout.fillWidth: true
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Load")
                        onClicked: {
                            appSettings.profiles_index = profilesbox.currentIndex
                            appSettings.loadCurrentProfile();
                            appSettings.handleFontChanged();
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
                        enabled: !appSettings.profiles_list.get(profilesbox.currentIndex).builtin
                        onClicked: {
                            appSettings.profiles_list.remove(profilesbox.currentIndex)
                            profilesbox.currentIndex = profilesbox.currentIndex - 1
                        }
                    }
                }
                InsertNameDialog{
                    id: insertname
                    onNameSelected: appSettings.addNewCustomProfile(name)
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
                    onValueChanged: appSettings.brightness = value
                    value: appSettings.brightness
                }
                Text{ text: qsTr("Contrast") }
                SimpleSlider{
                    onValueChanged: appSettings.contrast = value
                    value: appSettings.contrast
                }
                Text{ text: qsTr("Opacity") }
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
                    model: appSettings.frames_list
                    currentIndex: appSettings.frames_index
                    onCurrentIndexChanged: appSettings.frames_index = currentIndex
                }
            }
        }
    }
}
