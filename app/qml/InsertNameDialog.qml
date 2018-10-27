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
import QtQuick.Window 2.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

Window{
    id: insertnamedialog
    width: 400
    height: 100
    modality: Qt.ApplicationModal
    title: qsTr("Save new profile")

    property alias profileName: namefield.text
    signal nameSelected(string name)

    MessageDialog {
        id: errorDialog
        title: qsTr("Error")
        visible: false

        function showError(message){
            text = message;
            open();
        }
    }

    function validateName(name){
        var profile_list = appSettings.profilesList;
        if (name === "")
            return 1;
        return 0;
    }

    ColumnLayout{
        anchors.margins: 10
        anchors.fill: parent
        RowLayout{
            Label{text: qsTr("Name")}
            TextField{
                id: namefield
                Layout.fillWidth: true
                Component.onCompleted: forceActiveFocus()
                onAccepted: okbutton.clickAction()
            }
        }
        RowLayout{
            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
            Button{
                id: okbutton
                text: qsTr("OK")
                onClicked: clickAction()
                function clickAction(){
                    var name = namefield.text;
                    switch(validateName(name)){
                    case 1:
                        errorDialog.showError(qsTr("The name you inserted is empty. Please choose a different one."));
                        break;
                    default:
                        nameSelected(name);
                        close();
                    }
                }
            }
            Button{
                text: qsTr("Cancel")
                onClicked: close()
            }
        }
    }
}
