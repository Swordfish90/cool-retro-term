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
                RowLayout{
                    Layout.fillWidth: true
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Import From File")
                        onClicked: {
                            fileDialog.selectExisting = true;
                            fileDialog.callBack = function (url) {loadFile(url);};
                            fileDialog.open();
                        }

                        function loadFile(url) {
                            console.log("Loading file: " + url);
                            var profileStirng = fileio.read(url);
                            shadersettings.loadProfileString(profileStirng);
                        }
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Export To File")
                        onClicked: {
                            fileDialog.selectExisting = false;
                            fileDialog.callBack = function (url) {storeFile(url);};
                            fileDialog.open();
                        }

                        function storeFile(url) {
                            console.log("Storing file: " + url);
                            var profileObject = shadersettings.composeProfileObject();
                            fileio.write(url, JSON.stringify(profileObject, undefined, 2));
                        }
                    }
                }
                InsertNameDialog{
                    id: insertname
                    onNameSelected: shadersettings.addNewCustomProfile(name)
                }
                Loader {
                    property var callBack
                    property bool selectExisting: false
                    id: fileDialog

                    sourceComponent: FileDialog{
                        nameFilters: ["Json files (*.json)"]
                        selectMultiple: false
                        selectFolder: false
                        selectExisting: fileDialog.selectExisting
                        onAccepted: callBack(fileUrl);
                    }

                    onSelectExistingChanged: reload()

                    function open() {
                        item.open();
                    }

                    function reload() {
                        active = false;
                        active = true;
                    }
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
            }
        }
    }
}
