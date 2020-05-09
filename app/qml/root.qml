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

QtObject {
    id: root
    property int terminalCount

    function newWindow() {
        var component = Qt.createComponent("main.qml")
        var window = component.createObject()			
        window.show()
        terminalCount = terminalCount + 1
    }
    function closeWindow() {
        terminalCount = terminalCount - 1
        if (terminalCount == 0) {
            Qt.quit()
        }
    }
    Component.onCompleted: {
        terminalCount = 0
        root.newWindow()
    }
}
