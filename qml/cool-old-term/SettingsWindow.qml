import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Window 2.1
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1

ApplicationWindow {
    id: settings_window
    title: qsTr("Settings")
    width: 640
    height: 480

    visible: true
    modality: Qt.ApplicationModal

    TabView{
        anchors.fill: parent

        Tab{
            title: qsTr("Settings")
            anchors.fill: parent
            anchors.margins: 20

            ColumnLayout{
                anchors.fill: parent
                RowLayout{
                    ColumnLayout{
                        Text{text: qsTr("Font color")}
                        ColorButton{
                            height: 200
                            width: 200

                            onButton_colorChanged: shadersettings.font_color = button_color
                            Component.onCompleted: button_color = shadersettings.font_color;
                        }
                    }
                    Item{
                        Layout.fillWidth: true
                    }
                    ColumnLayout{
                        Text{text: qsTr("Backgroud color")}
                        ColorButton{
                            height: 200
                            width: 200

                            onButton_colorChanged: shadersettings.background_color= button_color
                            Component.onCompleted: button_color = shadersettings.background_color;
                        }
                    }
                }
                ColumnLayout{
                    anchors.left: parent.left
                    anchors.right: parent.right

                    SettingComponent{
                        name: "Noise"
                        onValueChanged: shadersettings.noise_strength = value
                        Component.onCompleted: value = shadersettings.noise_strength
                    }
                    SettingComponent{
                        name: "Glow"
                        onValueChanged: shadersettings.glowing_line_strength = value;
                        Component.onCompleted: value = shadersettings.glowing_line_strength
                    }
                    SettingComponent{
                        name: "Ambient light"
                        onValueChanged: shadersettings.ambient_light = value;
                        Component.onCompleted: value = shadersettings.ambient_light
                    }
                }
            }
        }
    }
}
