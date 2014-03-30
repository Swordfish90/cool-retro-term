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

import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtGraphicalEffects 1.0

import org.kde.konsole 0.1

ApplicationWindow{
    id: terminalWindow
    width: 1024
    height: 768

    title: qsTr("Terminal")

    Action {
        id: fullscreenAction
        text: "&Fullscreen"
        shortcut: "Alt+F11"
        onTriggered: shadersettings.fullscreen = !shadersettings.fullscreen;
    }
    Action {
        id: quitAction
        text: "&Quit"
        shortcut: "Ctrl+Q"
        onTriggered: terminalWindow.close();
    }
    Action{
        id: showsettingsAction
        text: "&Settings"
        onTriggered: settingswindow.show();
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
            MenuItem {action: showsettingsAction}
            MenuItem {action: fullscreenAction}
        }
    }

    visible: true
    visibility: shadersettings.fullscreen ? Window.FullScreen : Window.Windowed

    Item{
        id: maincontainer
        anchors.fill: parent
        clip: true

        ShaderEffectSource{
            id: theSource
            sourceItem: terminal
            sourceRect: frame.sourceRect
        }

        ShaderManager{
            id: shadercontainer
            anchors.fill: terminal
            blending: true
            z: 1.9
        }

        Loader{
            property rect sourceRect: item.sourceRect

            id: frame
            anchors.fill: parent
            z: 2.1
            source: shadersettings.frame_source
        }

        Loader{
            id: terminal

            width: parent.width
            height: parent.height
        }

        MouseArea{
            acceptedButtons: Qt.NoButton
            anchors.fill: parent
            onWheel:
                wheel.angleDelta.y > 0 ? terminal.item.scrollUp() : terminal.item.scrollDown()
        }

        RadialGradient{
            id: ambientreflection
            z: 2.0
            anchors.fill: parent
            cached: true
            opacity: shadersettings.ambient_light * 0.4
            gradient: Gradient{
                GradientStop{position: 0.0; color: "white"}
                GradientStop{position: 0.7; color: "#00000000"}
            }
        }
    }

    ShaderSettings{
        id: shadersettings
        Component.onCompleted: terminal.source = "Terminal.qml"
    }

    SettingsWindow{
        id: settingswindow
        visible: false
    }
}
