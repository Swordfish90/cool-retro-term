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
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

Window {
    id: settings_window
    title: qsTr("Settings")
    width: 580
    height: 400

    property int tabmargins: 15

    TabView{
        id: tabView
        anchors.fill: parent
        anchors.margins: 10
        SettingsGeneralTab {
            id: generalTab
            title: qsTr("General")
            anchors.fill: parent
            anchors.margins: tabmargins
        }
        SettingsTerminalTab {
            id: terminalTab
            title: qsTr("Terminal")
            anchors.fill: parent
            anchors.margins: tabmargins
        }
        SettingsEffectsTab {
            id: effectsTab
            title: qsTr("Effects")
            anchors.fill: parent
            anchors.margins: tabmargins
        }
        SettingsAdvancedTab {
            id: performanceTab
            title: qsTr("Advanced")
            anchors.fill: parent
            anchors.margins: tabmargins
        }
    }
}
