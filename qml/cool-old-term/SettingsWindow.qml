import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Window 2.1
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1

ApplicationWindow {
    id: settings_window
    title: qsTr("Settings")
    width: 640
    height: 300

    visible: true
    modality: Qt.ApplicationModal

    TabView{
        anchors.fill: parent

        Tab{
            title: qsTr("Appearance")
            anchors.margins: 20
            anchors.top: parent.top

            GridLayout{
                anchors.fill: parent
                columns: 2
                GroupBox{
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    title: qsTr("Profile")
                    ComboBox{
                        anchors.fill: parent
                    }
                }

                GroupBox{
                    id: fontbox
                    title: qsTr("Font")
                    Layout.fillWidth: true
                    Layout.fillHeight:true
                    GridLayout{
                        anchors.fill: parent
                        columns: 2
                        Text{text: qsTr("Font style:")}
                        ComboBox{
                            Layout.fillWidth: true
                            model: shadersettings.fonts_list
                            currentIndex: shadersettings.font_index
                            onCurrentIndexChanged: shadersettings.font_index = currentIndex
                        }
                        Text{text: qsTr("Font scaling:")}
                        ComboBox{
                            Layout.fillWidth: true
                        }
                        Item{Layout.fillHeight: true}
                        ColorButton{
                            height: 50
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            onButton_colorChanged: shadersettings.font_color = button_color;
                            Component.onCompleted: button_color = shadersettings.font_color;
                        }
                    }
                }
                GroupBox{
                    title: qsTr("Background")
                    Layout.fillWidth: true
                    Layout.fillHeight:true
                    GridLayout{
                        anchors.fill: parent
                        columns: 2
                        Text{text: "Frame texture"}
                        ComboBox{
                            Layout.fillWidth: true
                            model: shadersettings.frames_list
                            currentIndex: shadersettings.frames_index
                            onCurrentIndexChanged: shadersettings.frames_index = currentIndex
                        }
                        Item{Layout.fillHeight: true}

                        ColorButton{
                            height: 50
                            Layout.fillWidth: true
                            Layout.columnSpan: 2

                            onButton_colorChanged: shadersettings.background_color= button_color
                            Component.onCompleted: button_color = shadersettings.background_color;
                        }
                    }
                }
            }
        }

        Tab{
            title: qsTr("Eye-candy")
            anchors.fill: parent
            anchors.margins: 20

            GroupBox{
                title: qsTr("Effects")
                anchors.fill: parent

                ColumnLayout{
                    anchors.fill: parent

                    CheckBox{
                        text: "Scanlines"
                        checked: shadersettings.scanlines
                        onCheckedChanged: shadersettings.scanlines = checked;
                    }
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
                }
            }
        }
    }
}
