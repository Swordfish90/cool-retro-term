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
            Layout.fillHeight: true
            title: qsTr("Profile")
            RowLayout {
                anchors.fill: parent
                TableView {
                    id: profilesView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                    Layout.fillHeight: true
                    Layout.fillWidth: false
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Save")
                        onClicked: {
                            insertname.profileName = "";
                            insertname.show()
                        }
                    }
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
                        text: qsTr("Remove")
                        property alias currentIndex: profilesView.currentRow

                        enabled: currentIndex >= 0 && !appSettings.profilesList.get(currentIndex).builtin
                        onClicked: {
                            appSettings.profilesList.remove(currentIndex);
                            profilesView.selection.clear();

                            // TODO This is a very ugly workaround. The view didn't update on Qt 5.3.2.
                            profilesView.model = 0;
                            profilesView.model = appSettings.profilesList;
                        }
                    }
                    Item {
                        // Spacing
                        Layout.fillHeight: true
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Import")
                        onClicked: {
                            fileDialog.selectExisting = true;
                            fileDialog.callBack = function (url) {loadFile(url);};
                            fileDialog.open();
                        }
                        function loadFile(url) {
                            try {
                                if (appSettings.verbose)
                                    console.log("Loading file: " + url);

                                var profileObject = JSON.parse(fileIO.read(url));
                                var name = profileObject.name;

                                if (!name)
                                    throw "Profile doesn't have a name";

                                var version = profileObject.version !== undefined ? profileObject.version : 1;
                                if (version !== appSettings.profileVersion)
                                    throw "This profile is not supported on this version of CRT.";

                                delete profileObject.name;

                                appSettings.appendCustomProfile(name, JSON.stringify(profileObject));
                            } catch (err) {
                                messageDialog.text = qsTr(err)
                                messageDialog.open();
                            }
                        }
                    }
                    Button{
                        property alias currentIndex: profilesView.currentRow

                        Layout.fillWidth: true

                        text: qsTr("Export")
                        enabled: currentIndex >= 0 && !appSettings.profilesList.get(currentIndex).builtin
                        onClicked: {
                            fileDialog.selectExisting = false;
                            fileDialog.callBack = function (url) {storeFile(url);};
                            fileDialog.open();
                        }
                        function storeFile(url) {
                            try {
                                var urlString = url.toString();

                                // Fix the extension if it's missing.
                                var extension = urlString.substring(urlString.length - 5, urlString.length);
                                var urlTail = (extension === ".json" ? "" : ".json");
                                url += urlTail;

                                if (true)
                                    console.log("Storing file: " + url);

                                var profileObject = appSettings.profilesList.get(currentIndex);
                                var profileSettings = JSON.parse(profileObject.obj_string);
                                profileSettings["name"] = profileObject.text;
                                profileSettings["version"] = appSettings.profileVersion;

                                var result = fileIO.write(url, JSON.stringify(profileSettings, undefined, 2));
                                if (!result)
                                    throw "The file could not be written.";
                            } catch (err) {
                                console.log(err);
                                messageDialog.text = qsTr("There has been an error storing the file.")
                                messageDialog.open();
                            }
                        }
                    }
                }
            }
        }

        GroupBox{
            title: qsTr("Screen")
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
                Label{ text: qsTr("Margin") }
                SimpleSlider{
                    onValueChanged: appSettings._margin = value
                    value: appSettings._margin
                }
                Label{ text: qsTr("Opacity") }
                SimpleSlider{
                    onValueChanged: appSettings.windowOpacity = value
                    value: appSettings.windowOpacity
                }
            }
        }

        // DIALOGS ////////////////////////////////////////////////////////////////
        InsertNameDialog{
            id: insertname
            onNameSelected: {
                appSettings.appendCustomProfile(name, appSettings.composeProfileString());
            }
        }
        MessageDialog {
            id: messageDialog
            title: qsTr("File Error")
            onAccepted: {
                messageDialog.close();
            }
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
