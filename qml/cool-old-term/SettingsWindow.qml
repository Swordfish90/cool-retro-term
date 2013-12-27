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
                    Label{
                        text: "Font"
                    }
                    ComboBox{
                        width: 300
                        model: shadersettings.fonts_list
                        currentIndex: shadersettings.font_index
                        onCurrentIndexChanged: shadersettings.font_index = currentIndex
                    }
                }
                RowLayout{
                    Label{
                        text: "Frame texture"
                    }
                    ComboBox{
                        width: 300
                        model: shadersettings.frames_list
                        currentIndex: shadersettings.frames_index
                        onCurrentIndexChanged: shadersettings.frames_index = currentIndex
                    }
                }

                RowLayout{
                    ColumnLayout{
                        Text{text: qsTr("Font color")}
                        ColorButton{
                            height: 200
                            width: 200

                            onButton_colorChanged: shadersettings.font_color = button_color;
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
                        Component.onCompleted: _value = shadersettings.noise_strength
                    }
                    SettingComponent{
                        name: "Glow"
                        onValueChanged: shadersettings.glowing_line_strength = value;
                        Component.onCompleted: _value = shadersettings.glowing_line_strength
                    }
                    SettingComponent{
                        name: "Ambient light"
                        onValueChanged: shadersettings.ambient_light = value;
                        Component.onCompleted: _value = shadersettings.ambient_light
                    }
                    SettingComponent{
                        name: "Screen distortion"
                        onValueChanged: shadersettings.screen_distortion = value;
                        Component.onCompleted:  _value = shadersettings.screen_distortion;
                    }
                    SettingComponent{
                        name: "Screen flickering"
                        onValueChanged: shadersettings.screen_flickering = value;
                        Component.onCompleted:  _value = shadersettings.screen_flickering;
                    }
                    CheckBox{
                        text: "Scanlines"
                        checked: shadersettings.scanlines
                        onCheckedChanged: shadersettings.scanlines = checked;
                    }
                }
            }
        }
    }
}
