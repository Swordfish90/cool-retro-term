import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtGraphicalEffects 1.0


ApplicationWindow{
    id: terminalWindow
    width: 1024
    height: 768

    title: qsTr("Terminal")

    menuBar: MenuBar {
        id: menubar
        Menu {
            title: qsTr("File")
            MenuItem { text: "Close"; onTriggered: terminalWindow.close()}
        }
        Menu {
            title: qsTr("Edit")
            MenuItem {
                text: qsTr("Settings")
                onTriggered: {
                    settingswindow.show();
                }
            }
        }
    }

    visible: true

    Item{
        id: maincontainer
        anchors.fill: parent
        anchors.top: menuBar.bottom
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

        TerminalScreen {
            id: terminal
            anchors.fill: parent

            //FIXME: Ugly forced clear terminal at the beginning
            Component.onCompleted: {
                terminal.screen.sendKey("l", 76, 67108864);
                terminal.setTerminalHeight();
                terminal.setTerminalWidth();
            }
        }

        RadialGradient{
            id: ambientreflection
            z: 2.0
            anchors.fill: parent
            cached: true
            opacity: shadersettings.ambient_light * 0.66
            gradient: Gradient{
                GradientStop{position: 0.0; color: "white"}
                GradientStop{position: 0.7; color: "#00000000"}
            }
        }
    }
}
