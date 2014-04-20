/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordifish90/cool-old-term
*
* This file is part of cool-old-term.
*
* cool-old-term is free software: you can redistribute it and/or modify
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

import org.kde.konsole 0.1

ApplicationWindow{
    id: terminalWindow
    width: 1024
    height: 768

    title: qsTr("cool-old-term")
    visible: true
    visibility: shadersettings.fullscreen ? Window.FullScreen : Window.Windowed

    Action {
        id: fullscreenAction
        text: qsTr("&Fullscreen")
        shortcut: "Alt+F11"
        onTriggered: shadersettings.fullscreen = !shadersettings.fullscreen;
        checkable: true
        checked: shadersettings.fullscreen
    }
    Action {
        id: quitAction
        text: qsTr("&Quit")
        shortcut: "Ctrl+Q"
        onTriggered: terminalWindow.close();
    }
    Action{
        id: showsettingsAction
        text: qsTr("&Settings")
        onTriggered: settingswindow.show();
    }
    Action{
        id: copyAction
        text: qsTr("&Copy")
        shortcut: "Ctrl+Shift+C"
        onTriggered: terminal.copyClipboard()
    }
    Action{
        id: pasteAction
        text: qsTr("&Paste")
        shortcut: "Ctrl+Shift+V"
        onTriggered: terminal.pasteClipboard()
    }

    menuBar: MenuBar {
        id: menubar
        Menu {
            title: qsTr("File")
            visible: shadersettings.fullscreen ? false : true
            MenuItem {action: quitAction}
        }
        Menu {
            title: qsTr("Edit")
            visible: shadersettings.fullscreen ? false : true
            MenuItem {action: copyAction}
            MenuItem {action: pasteAction}
            MenuSeparator{}
            MenuItem {action: showsettingsAction}
        }
        Menu{
            title: qsTr("View")
            visible: shadersettings.fullscreen ? false : true
            MenuItem {action: fullscreenAction}
        }
    }

    Loader{
        id: frame
        property rect sourceRect: Qt.rect(-item.rectX * shadersettings.window_scaling,
                                          -item.rectY * shadersettings.window_scaling,
                                          terminal.width + 2*item.rectX * shadersettings.window_scaling,
                                          terminal.height + 2*item.rectY * shadersettings.window_scaling)
        anchors.fill: parent
        z: 2.1
        source: shadersettings.frame_source
        opacity: 1.0
    }

    Item{
        id: maincontainer
        anchors.centerIn: parent
        width: parent.width * shadersettings.window_scaling
        height: parent.height * shadersettings.window_scaling
        scale: 1.0 / shadersettings.window_scaling

        Image{
            id: randtexture
            source: "frames/images/randfunction.png"
            width: 512
            height: 512
            sourceSize.width: 512
            sourceSize.height: 256
            fillMode: Image.TileVertically
        }
        ShaderEffectSource{
            id: randfuncsource
            sourceItem: randtexture
            live: false
            hideSource: true
            wrapMode: ShaderEffectSource.Repeat
        }
        Timer{
            id: timetimer
            property real time: 0
            onTriggered: time += interval
            interval: Math.round(1000 / shadersettings.fps)
            running: true
            repeat: true
        }
        Terminal{
            id: terminal
            anchors.centerIn: parent
            property int frameOffsetX: frame.item.addedWidth -  frame.item.borderLeft - frame.item.borderRight
            property int frameOffsetY: frame.item.addedHeight - frame.item.borderTop  - frame.item.borderBottom
            width: parent.width + frameOffsetX * shadersettings.window_scaling
            height: parent.height + frameOffsetY * shadersettings.window_scaling
        }
        ShaderEffectSource{
            id: theSource
            sourceItem: terminal
            sourceRect: frame.sourceRect
        }
        ShaderManager{
            id: shadercontainer
            anchors.fill: parent
            z: 1.9
        }
    }
    ShaderSettings{
        id: shadersettings
        Component.onCompleted: {
            terminal.loadKTerminal();
        }
    }
    SettingsWindow{
        id: settingswindow
        visible: false
    }
    Loader{
        id: sizeoverlayloader
        z: 3
        anchors.centerIn: parent
        active: shadersettings.show_terminal_size
        sourceComponent: SizeOverlay{
            terminalSize: terminal.terminalSize
        }
    }
}
