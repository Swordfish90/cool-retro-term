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
            anchors {left: parent.left; right: parent.right}
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: qsTr("Profile")
            RowLayout {
                anchors.fill: parent
                TableView {
                    id: profilesView
                    Layout.fillWidth: true
                    anchors { top: parent.top; bottom: parent.bottom; }
                    model: appSettings.profilesList
                    headerVisible: false
                    TableViewColumn {
                        title: qsTr("Profile")
                        role: "text"
                        width: parent.width * 0.5
                    }
                    onActivated: {
                        appSettings.loadProfile(row);
                    }
                }
                ColumnLayout {
                    anchors { top: parent.top; bottom: parent.bottom }
                    Layout.fillWidth: false
                    Button{
                        Layout.fillWidth: true
                        property alias currentIndex: profilesView.currentRow
                        enabled: currentIndex >= 0
                        text: qsTr("Load")
                        onClicked: {
                            var index = profilesView.currentRow;
                            if (index >= 0)
                                appSettings.loadProfile(index);
                        }
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("New")
                        onClicked: insertname.show()
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Remove")
                        property alias currentIndex: profilesView.currentRow

                        enabled: currentIndex >= 0 && !appSettings.profilesList.get(currentIndex).builtin
                        onClicked: {
                            appSettings.profilesList.remove(profilesView.currentRow);
                            profilesView.activated(currentIndex);
                        }
                    }
                    InsertNameDialog{
                        id: insertname
                        onNameSelected: appSettings.addNewCustomProfile(name)
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
