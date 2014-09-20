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
        title: qsTr("Edit")
        visible: defaultMenuBar.visible
        MenuItem {action: copyAction}
        MenuItem {action: pasteAction}
        MenuSeparator{}
        MenuItem {action: showsettingsAction}
    }
    Menu{
        title: qsTr("View")
        visible: defaultMenuBar.visible
        MenuItem {action: fullscreenAction}
        MenuItem {action: showMenubarAction}
        MenuSeparator{}
        MenuItem {action: zoomIn}
        MenuItem {action: zoomOut}
    }
    Menu{
        id: profilesMenu
        title: qsTr("Profiles")
        visible: defaultMenuBar.visible
        Instantiator{
            model: shadersettings.profiles_list
            delegate: MenuItem {
                text: model.text
                onTriggered: {
                    shadersettings.loadProfileString(obj_string);
                    shadersettings.handleFontChanged();
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
