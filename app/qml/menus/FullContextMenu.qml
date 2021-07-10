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
import QtQuick.Controls 2.3

Menu {
    id: contextmenu
    MenuItem {
        action: copyAction
    }
    MenuItem {
        action: pasteAction
    }
    MenuItem {
        action: showsettingsAction
    }

    MenuSeparator {}

    Menu {
        title: qsTr("File")
        MenuItem {
            action: quitAction
        }
    }
    Menu {
        title: qsTr("Edit")
        MenuItem {
            action: copyAction
        }
        MenuItem {
            action: pasteAction
        }
        MenuSeparator {}
        MenuItem {
            action: showsettingsAction
        }
    }
    Menu {
        title: qsTr("View")
        MenuItem {
            action: fullscreenAction
            visible: fullscreenAction.enabled
        }
        MenuItem {
            action: showMenubarAction
            visible: showMenubarAction.enabled
        }
        MenuItem {
            action: zoomIn
        }
        MenuItem {
            action: zoomOut
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
            action: showAboutAction
        }
    }
}
