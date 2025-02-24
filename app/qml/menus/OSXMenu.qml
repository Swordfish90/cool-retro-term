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

import QtQuick 2.3
import Qt.labs.platform 1.1

MenuBar {
    id: defaultMenuBar

    Menu {
        title: qsTr("File")
        MenuItem {
            text: quitAction.text
            onTriggered: quitAction.trigger()
        }
    }
    Menu {
        title: qsTr("Edit")
        MenuItem {
            text: copyAction.text
            shortcut: "Meta+C"
            onTriggered: copyAction.trigger()
        }
        MenuItem {
            text: pasteAction.text
            shortcut: "Meta+V"
            onTriggered: pasteAction.trigger()
        }
        MenuSeparator {}
        MenuItem {
            text: showsettingsAction.text
            shortcut: showsettingsAction.shortcut
            onTriggered: showsettingsAction.trigger()
        }
    }
    Menu {
        title: qsTr("View")
        MenuItem {
            text: zoomIn.text
            shortcut: "Meta++"
            onTriggered: zoomIn.trigger()
        }
        MenuItem {
            text: zoomOut.text
            shortcut: "Meta+-"
            onTriggered: zoomOut.trigger()
        }
    }
    Menu {
        id: profilesMenu
        title: qsTr("Profiles")
        Instantiator {
            model: appSettings.profilesList
            delegate: MenuItem {
                text: model.text
                onTriggered: {
                    appSettings.loadProfileString(obj_string)
                    appSettings.handleFontChanged()
                }
            }
            onObjectAdded: profilesMenu.insertItem(index, object)
            onObjectRemoved: profilesMenu.removeItem(object)
        }
    }
    Menu {
        title: qsTr("Help")
        MenuItem {
            text: showAboutAction.text
            onTriggered: showAboutAction.trigger()
        }
    }
}
