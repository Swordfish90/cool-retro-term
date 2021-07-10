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

Rectangle {
    property size terminalSize
    property real topOpacity: 0.6

    width: textSize.width * 2
    height: textSize.height * 2
    radius: 5
    border.width: 2
    border.color: "white"
    color: "black"
    opacity: sizetimer.running ? 0.6 : 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    onTerminalSizeChanged: sizetimer.restart()

    Text {
        id: textSize
        anchors.centerIn: parent
        color: "white"
        text: terminalSize.width + "x" + terminalSize.height
    }
    Timer {
        id: sizetimer
        interval: 1000
        running: false
    }
}
