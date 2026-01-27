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
import QtQuick
import QtQuick.Window
import QtQuick.Controls

import "menus"

ApplicationWindow {
    id: terminalWindow

    width: 1024
    height: 768

    // Show the window once it is ready.
    Component.onCompleted: {
        visible = true
    }

    minimumWidth: 320
    minimumHeight: 240

    visible: false

    property bool fullscreen: false
    onFullscreenChanged: visibility = (fullscreen ? Window.FullScreen : Window.Windowed)

    menuBar: WindowMenu { }

    property real normalizedWindowScale: 1024 / ((0.5 * width + 0.5 * height))

    color: "#00000000"

    title: terminalTabs.currentTitle

    Action {
        id: fullscreenAction
        text: qsTr("Fullscreen")
        enabled: !appSettings.isMacOS
        shortcut: StandardKey.FullScreen
        onTriggered: fullscreen = !fullscreen
        checkable: true
        checked: fullscreen
    }
    Action {
        id: newWindowAction
        text: qsTr("New Window")
        shortcut: appSettings.isMacOS ? "Meta+N" : "Ctrl+Shift+N"
        onTriggered: appRoot.createWindow()
    }
    Action {
        id: quitAction
        text: qsTr("Quit")
        shortcut: appSettings.isMacOS ? StandardKey.Close : "Ctrl+Shift+Q"
        onTriggered: terminalWindow.close()
    }
    Action {
        id: showsettingsAction
        text: qsTr("Settings")
        onTriggered: {
            settingsWindow.show()
            settingsWindow.requestActivate()
            settingsWindow.raise()
        }
    }
    Action {
        id: copyAction
        text: qsTr("Copy")
        shortcut: appSettings.isMacOS ? StandardKey.Copy : "Ctrl+Shift+C"
    }
    Action {
        id: pasteAction
        text: qsTr("Paste")
        shortcut: appSettings.isMacOS ? StandardKey.Paste : "Ctrl+Shift+V"
    }
    Action {
        id: zoomIn
        text: qsTr("Zoom In")
        shortcut: StandardKey.ZoomIn
        onTriggered: appSettings.incrementScaling()
    }
    Action {
        id: zoomOut
        text: qsTr("Zoom Out")
        shortcut: StandardKey.ZoomOut
        onTriggered: appSettings.decrementScaling()
    }
    Action {
        id: showAboutAction
        text: qsTr("About")
        onTriggered: {
            aboutDialog.show()
            aboutDialog.requestActivate()
            aboutDialog.raise()
        }
    }
    Action {
        id: newTabAction
        text: qsTr("New Tab")
        shortcut: "Meta+T"
        onTriggered: terminalTabs.addTab()
    }
    Action {
        id: closeTabAction
        text: qsTr("Close Tab")
        shortcut: "Meta+W"
        onTriggered: terminalTabs.closeTab(terminalTabs.currentIndex)
    }
    Shortcut {
        sequence: "Meta+T"
        context: Qt.WindowShortcut
        onActivated: terminalTabs.addTab()
    }
    Shortcut {
        sequence: "Meta+W"
        context: Qt.WindowShortcut
        onActivated: terminalTabs.closeTab(terminalTabs.currentIndex)
    }
    Shortcut {
        sequence: "Meta+1"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 0) terminalTabs.currentIndex = 0
    }
    Shortcut {
        sequence: "Meta+2"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 1) terminalTabs.currentIndex = 1
    }
    Shortcut {
        sequence: "Meta+3"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 2) terminalTabs.currentIndex = 2
    }
    Shortcut {
        sequence: "Meta+4"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 3) terminalTabs.currentIndex = 3
    }
    Shortcut {
        sequence: "Meta+5"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 4) terminalTabs.currentIndex = 4
    }
    Shortcut {
        sequence: "Meta+6"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 5) terminalTabs.currentIndex = 5
    }
    Shortcut {
        sequence: "Meta+7"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 6) terminalTabs.currentIndex = 6
    }
    Shortcut {
        sequence: "Meta+8"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 7) terminalTabs.currentIndex = 7
    }
    Shortcut {
        sequence: "Meta+9"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 8) terminalTabs.currentIndex = 8
    }
    TerminalTabs {
        id: terminalTabs
        width: parent.width
        height: (parent.height + Math.abs(y))
    }
    Loader {
        anchors.centerIn: parent
        active: appSettings.showTerminalSize
        sourceComponent: SizeOverlay {
            z: 3
            terminalSize: terminalTabs.terminalSize
        }
    }
    onClosing: {
        appRoot.closeWindow(terminalWindow)
    }
}
