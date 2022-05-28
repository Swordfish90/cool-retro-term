/*******************************************************************************
* Copyright (c) 2013-2021 "Filippo Scognamiglio"
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
import QtQuick.Controls 2.1
import QtQuick.Window 2.1
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.1

Window {
    id: settings_window
    title: qsTr("Settings")
    width: 640
    height: 640

    color: palette.window
    property int tabmargins: 15

    Item {
        anchors { fill: parent;  margins: tabmargins }

        TabBar {
            id: bar
            anchors { left: parent.left; right: parent.right; top: parent.top; }
            TabButton {
                text: qsTr("General")
            }
            TabButton {
                text: qsTr("Terminal")
            }
            TabButton {
                text: qsTr("Effects")
            }
            TabButton {
                text: qsTr("Advanced")
            }
        }

        Frame {
            anchors {
                top: bar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            StackLayout {
                anchors.fill: parent

                currentIndex: bar.currentIndex

                SettingsGeneralTab { }
                SettingsTerminalTab { }
                SettingsEffectsTab { }
                SettingsAdvancedTab { }
            }
        }
    }
}
