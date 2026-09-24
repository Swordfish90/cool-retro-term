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
import "logic/platform.js" as Platform
import "logic/pfkeys.js" as PfKeys

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

    /**
     * Optional IBM style audio for the whole window.  Kept here rather than
     * per terminal so that one window has exactly one sound, whichever tab is
     * showing and whether the press came from the terminal or a PF key.
     */
    property SoundManager soundManager: SoundManager {
        active: appSettings.audioEnabled
        clickEnabled: appSettings.keyClick
        bellEnabled: appSettings.bell
        clickVolume: appSettings.keyClickVolume
        bellVolume: appSettings.bellVolume
    }

    property real normalizedWindowScale: 1024 / ((0.5 * width + 0.5 * height))

    color: "#00000000"

    title: terminalTabs.currentTitle

    // Let the window manager aware of which window we are on, so that
    // "next window" starts from the right place.
    onActiveChanged: {
        if (active)
            appRoot.activeWindow = terminalWindow
    }

    /**
     * Resolve one entry of the platform key map.
     *
     * Everything is a plain sequence string ("Ctrl+Shift+N") except the few
     * functions where Qt already knows the platform's own convention: those
     * are spelled "StandardKey.X" here and handed to Qt as the real enum, so
     * the shortcut lands exactly where the OS puts it.
     */
    function keySequence(name) {
        switch (name) {
        case "StandardKey.FullScreen": return StandardKey.FullScreen
        case "StandardKey.Quit":       return StandardKey.Quit
        case "StandardKey.Copy":       return StandardKey.Copy
        case "StandardKey.Paste":      return StandardKey.Paste
        case "StandardKey.ZoomIn":     return StandardKey.ZoomIn
        case "StandardKey.ZoomOut":    return StandardKey.ZoomOut
        default:                       return name
        }
    }

    /** The sequence for a named function on the current platform. */
    function seq(name) {
        return keySequence(Platform.sequence(Qt.platform.os, name))
    }

    Action {
        id: fullscreenAction
        text: qsTr("Fullscreen")
        // F11 (Windows/Linux) or Cmd+Ctrl+F (macOS): the native binding on
        // every platform, so it works whether or not a menu bar is showing.
        shortcut: seq("fullscreen")
        onTriggered: fullscreen = !fullscreen
        checkable: true
        checked: fullscreen
    }
    Action {
        id: newWindowAction
        text: qsTr("New Window")
        shortcut: seq("newWindow")
        onTriggered: appRoot.createWindow()
    }
    Action {
        id: nextWindowAction
        text: qsTr("Next Window")
        shortcut: seq("nextWindow")
        onTriggered: appRoot.nextWindow()
    }
    Action {
        id: previousWindowAction
        text: qsTr("Previous Window")
        shortcut: seq("prevWindow")
        onTriggered: appRoot.previousWindow()
    }
    Action {
        id: closeWindowAction
        text: qsTr("Close Window")
        shortcut: seq("closeWindow")
        onTriggered: terminalWindow.close()
    }
    Action {
        id: quitAction
        text: qsTr("Quit")
        shortcut: seq("quit")
        onTriggered: appSettings.close()
    }
    Action {
        id: showsettingsAction
        text: qsTr("Settings")
        shortcut: seq("settings")
        onTriggered: {
            settingsWindow.show()
            settingsWindow.requestActivate()
            settingsWindow.raise()
        }
    }
    Action {
        id: copyAction
        text: qsTr("Copy")
        shortcut: seq("copy")
    }
    Action {
        id: pasteAction
        text: qsTr("Paste")
        shortcut: seq("paste")
    }
    Action {
        id: zoomIn
        text: qsTr("Zoom In")
        shortcut: seq("zoomIn")
        onTriggered: appSettings.incrementScaling()
    }
    Action {
        id: zoomOut
        text: qsTr("Zoom Out")
        shortcut: seq("zoomOut")
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
        shortcut: seq("newTab")
        onTriggered: terminalTabs.addTab()
    }
    Action {
        id: closeTabAction
        text: qsTr("Close Tab")
        shortcut: seq("closeTab")
        onTriggered: terminalTabs.closeTab(terminalTabs.currentIndex)
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+1" : "Alt+1"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 0) terminalTabs.currentIndex = 0
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+2" : "Alt+2"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 1) terminalTabs.currentIndex = 1
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+3" : "Alt+3"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 2) terminalTabs.currentIndex = 2
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+4" : "Alt+4"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 3) terminalTabs.currentIndex = 3
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+5" : "Alt+5"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 4) terminalTabs.currentIndex = 4
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+6" : "Alt+6"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 5) terminalTabs.currentIndex = 5
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+7" : "Alt+7"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 6) terminalTabs.currentIndex = 6
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+8" : "Alt+8"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 7) terminalTabs.currentIndex = 7
    }
    Shortcut {
        sequence: appSettings.isMacOS ? "Meta+9" : "Alt+9"
        context: Qt.WindowShortcut
        onActivated: if (terminalTabs.count > 8) terminalTabs.currentIndex = 8
    }

    /***************************************************************************
    * IBM 3270 style PF / PA keys.
    *
    * One Shortcut per slot, scoped to this window.  A slot whose function is
    * "Off" keeps its Shortcut *disabled*, which is precisely what lets the raw
    * F-key fall through to the shell untouched; anything else is claimed here
    * before the terminal widget ever sees it.
    *
    * The legend these keys belong to is drawn by PfKeyBar inside the CRT
    * shader input, and it deliberately has no mouse handling at all.
    ***************************************************************************/
    Instantiator {
        model: appSettings.pfAssignments.length
        delegate: Shortcut {
            sequence: index < appSettings.pfAssignments.length
                      ? appSettings.pfAssignments[index].key : ""
            context: Qt.WindowShortcut
            enabled: index < appSettings.pfAssignments.length
                     && PfKeys.intercepts(appSettings.pfAssignments[index])
            onActivated: terminalWindow.dispatchPfAction(index)
        }
    }

    /** Execute the function bound to PF/PA slot `index`. */
    function dispatchPfAction(index) {
        // The Shortcut consumed the keystroke, so the terminal never saw it:
        // click here to keep the tactile feedback consistent.
        if (soundManager)
            soundManager.keyClick()

        var assignments = appSettings.pfAssignments
        if (index < 0 || index >= assignments.length)
            return

        var assignment = assignments[index]
        var action = PfKeys.actionById(assignment.action)
        if (!action)
            return

        if (action.kind === "term") {
            // Attention (Ctrl+C), Erase Input (Ctrl+U) and user macros all
            // travel the same way: straight into the active terminal.
            var text = action.id === "sendText"
                    ? PfKeys.macroText(assignment.payload) : action.payload
            terminalTabs.sendTextToCurrent(text)
            return
        }

        dispatchAppAction(action.id)
    }

    /** Map an action id onto the QAction that implements it. */
    function dispatchAppAction(id) {
        switch (id) {
        case "newWindow":   newWindowAction.trigger(); break
        case "nextWindow":  appRoot.nextWindow(); break
        case "prevWindow":  appRoot.previousWindow(); break
        case "closeWindow": closeWindowAction.trigger(); break
        case "newTab":      newTabAction.trigger(); break
        case "closeTab":    closeTabAction.trigger(); break
        case "fullscreen":  fullscreenAction.trigger(); break
        case "settings":    showsettingsAction.trigger(); break
        case "copy":        copyAction.trigger(); break
        case "paste":       pasteAction.trigger(); break
        default: break
        }
    }

    TerminalTabs {
        id: terminalTabs
        width: parent.width
        height: (parent.height + Math.abs(y))
    }
    Loader {
        anchors.centerIn: parent
        active: appSettings.chrome.sizeOverlay
        sourceComponent: SizeOverlay {
            z: 3
            terminalSize: terminalTabs.terminalSize
        }
    }
    onClosing: {
        appRoot.closeWindow(terminalWindow)
    }
}
