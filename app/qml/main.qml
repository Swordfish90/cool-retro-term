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
import QtQuick.Window 2.1
import QtQuick.Controls 1.1
import QtGraphicalEffects 1.0

ApplicationWindow{
    id: terminalWindow

    width: 1024
    height: 768
    minimumWidth: 320
    minimumHeight: 240

    visible: true

    property bool fullscreen: shadersettings.fullscreen
    onFullscreenChanged: visibility = (fullscreen ? Window.FullScreen : Window.Windowed)

    //Workaround: if menubar is assigned ugly margins are visible.
    menuBar: Qt.platform.os === "osx"
                ? defaultMenuBar
                : shadersettings.showMenubar ? defaultMenuBar : null

    color: "#00000000"
    title: qsTr("cool-retro-term")

    Action {
        id: showMenubarAction
        text: qsTr("Show Menubar")
        enabled: Qt.platform.os !== "osx"
        shortcut: "Ctrl+Shift+M"
        checkable: true
        checked: shadersettings.showMenubar
        onTriggered: shadersettings.showMenubar = !shadersettings.showMenubar
    }
    Action {
        id: fullscreenAction
        text: qsTr("Fullscreen")
        enabled: Qt.platform.os !== "osx"
        shortcut: "Alt+F11"
        onTriggered: shadersettings.fullscreen = !shadersettings.fullscreen;
        checkable: true
        checked: shadersettings.fullscreen
    }
    Action {
        id: quitAction
        text: qsTr("Quit")
        shortcut: "Ctrl+Shift+Q"
        onTriggered: terminalWindow.close();
    }
    Action{
        id: showsettingsAction
        text: qsTr("Settings")
        onTriggered: settingswindow.show();
    }
    Action{
        id: copyAction
        text: qsTr("Copy")
        shortcut: "Ctrl+Shift+C"
        onTriggered: terminal.copyClipboard()
    }
    Action{
        id: pasteAction
        text: qsTr("Paste")
        shortcut: "Ctrl+Shift+V"
        onTriggered: terminal.pasteClipboard()
    }
    Action{
        id: zoomIn
        text: qsTr("Zoom In")
        shortcut: "Ctrl++"
        onTriggered: shadersettings.incrementScaling();
    }
    Action{
        id: zoomOut
        text: qsTr("Zoom Out")
        shortcut: "Ctrl+-"
        onTriggered: shadersettings.decrementScaling();
    }
    Action{
        id: showAboutAction
        text: qsTr("About")
        onTriggered: {
            aboutDialog.show();
        }
    }
    CRTMainMenuBar{
        id: defaultMenuBar
    }
    ApplicationSettings{
        id: shadersettings
    }
    TimeManager{
        id: timeManager
        enableTimer: terminalWindow.visible
    }
    TerminalContainer{
        anchors.fill: parent
    }
    SettingsWindow{
        id: settingswindow
        visible: false
    }
    AboutDialog{
        id: aboutDialog
        visible: false
    }
    Component.onCompleted: shadersettings.handleFontChanged();
}
