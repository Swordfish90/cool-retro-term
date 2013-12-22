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
                GridLayout{
                    width: parent.width
                    columns: 2
                    Text{text: "Font color"}
                    Text{
                        text: "         ";
                        Rectangle{
                            anchors.fill: parent;
                            color: shadersettings.font_color
                        }
                        MouseArea{
                            anchors.fill: parent;
                            onClicked: {
                                var component = Qt.createComponent("MyColorDialog.qml");
                                component.createObject(settings_window, {"color_to_change": "font_color"});
                            }
                        }
                    }
                    Text{text: "Backgroud color"}
                    Text{text: "         ";
                        Rectangle{
                            anchors.fill: parent;
                            color: shadersettings.background_color
                        }
                        MouseArea{
                            anchors.fill: parent
                            onClicked: {
                                var component = Qt.createComponent("MyColorDialog.qml");
                                component.createObject(settings_window, {"color_to_change": "background_color"});
                            }
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
