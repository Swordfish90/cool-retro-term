import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0

Window{
    id: dialogwindow
    title: qsTr("About")
    width: 450
    height: 300

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "cool-retro-term"
            font {bold: true; pointSize: 18}
        }
        Loader{
            id: mainContent
            Layout.fillHeight: true
            Layout.fillWidth: true

            states: [
                State {
                    name: "Default"
                    PropertyChanges {
                        target: mainContent
                        sourceComponent: defaultComponent
                    }
                },
                State {
                    name: "License"
                    PropertyChanges {
                        target: mainContent
                        sourceComponent: licenseComponent
                    }
                }
            ]
            Component.onCompleted: mainContent.state = "Default";
        }
        Item{
            Layout.fillWidth: true
            height: childrenRect.height
            Button{
                anchors.left: parent.left
                text: qsTr("License")
                onClicked: {
                    mainContent.state == "Default" ? mainContent.state = "License" : mainContent.state = "Default"
                }
            }
            Button{
                anchors.right: parent.right
                text: qsTr("Close")
                onClicked: dialogwindow.close();
            }
        }
    }
    // MAIN COMPONENTS ////////////////////////////////////////////////////////
    Component{
        id: defaultComponent
        ColumnLayout{
            anchors.fill: parent
            spacing: 10
            Item{
                Layout.fillHeight: true
                Layout.fillWidth: true
                Image{
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "images/crt256.png"
                    smooth: true
                }
            }
            Text{
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: shadersettings.version + "\n" +
                      qsTr("Author: ") + "Filippo Scognamiglio\n" +
                      qsTr("Email: ")  + "flscogna@gmail.com\n" +
                      qsTr("Source: ") + "https://github.com/Swordfish90/cool-retro-term\n"
            }
        }
    }
    Component{
        id: licenseComponent
        TextArea{
            anchors.fill: parent
            readOnly: true
            text: "Copyright (c) 2013 Filippo Scognamiglio <flscogna@gmail.com>\n\n" +
                  "https://github.com/Swordfish90/cool-retro-term\n\n" +

                  "cool-retro-term is free software: you can redistribute it and/or modify " +
                  "it under the terms of the GNU General Public License as published by " +
                  "the Free Software Foundation, either version 3 of the License, or " +
                  "(at your option) any later version.\n\n" +

                  "This program is distributed in the hope that it will be useful, " +
                  "but WITHOUT ANY WARRANTY; without even the implied warranty of " +
                  "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the " +
                  "GNU General Public License for more details.\n\n" +

                  "You should have received a copy of the GNU General Public License " +
                  "along with this program.  If not, see <http://www.gnu.org/licenses/>."
        }
    }
}
