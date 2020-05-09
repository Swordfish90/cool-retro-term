import QtQuick 2.2
import QtQuick.Controls 1.1

MenuBar {
    id: defaultMenuBar
    property bool visible: true
    Menu {
        title: qsTr("File")
        visible: defaultMenuBar.visible
        MenuItem {action: quitAction}
    }
    Menu {
        title: qsTr("Terminal")
        visible: defaultMenuBar.visible
        MenuItem {action: newAction}
        MenuItem {action: closeAction}
    }
    Menu {
        title: qsTr("Edit")
        visible: defaultMenuBar.visible && appSettings.showMenubar
        MenuItem {action: copyAction}
        MenuItem {action: pasteAction}
        MenuSeparator{visible: Qt.platform.os !== "osx"}
        MenuItem {action: showsettingsAction}
    }
    Menu{
        title: qsTr("View")
        visible: defaultMenuBar.visible
        MenuItem {action: fullscreenAction; visible: fullscreenAction.enabled}
        MenuItem {action: showMenubarAction; visible: showMenubarAction.enabled}
        MenuSeparator{visible: showMenubarAction.enabled}
        MenuItem {action: zoomIn}
        MenuItem {action: zoomOut}
    }
    Menu{
        id: profilesMenu
        title: qsTr("Profiles")
        visible: defaultMenuBar.visible
        Instantiator{
            model: appSettings.profilesList
            delegate: MenuItem {
                text: model.text
                onTriggered: {
                    appSettings.loadProfileString(obj_string);
                    appSettings.handleFontChanged();
                }
            }
            onObjectAdded: profilesMenu.insertItem(index, object)
            onObjectRemoved: profilesMenu.removeItem(object)
        }
    }
    Menu{
        title: qsTr("Help")
        visible: defaultMenuBar.visible
        MenuItem {action: showAboutAction}
    }
}
