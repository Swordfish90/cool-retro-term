import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

Tab{
    ColumnLayout{
        anchors.fill: parent
        GroupBox{
            Layout.fillWidth: true
            title: qsTr("Profile")
            ColumnLayout{
                anchors.fill: parent
                ComboBox{
                    id: profilesbox
                    Layout.fillWidth: true
                    model: shadersettings.profiles_list
                    currentIndex: shadersettings.profiles_index
                }
                RowLayout{
                    Layout.fillWidth: true
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Load")
                        onClicked: {
                            shadersettings.profiles_index = profilesbox.currentIndex
                            shadersettings.loadCurrentProfile();
                            shadersettings.handleFontChanged();
                        }
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Store current")
                        onClicked: insertname.show()
                    }
                    Button{
                        Layout.fillWidth: true
                        text: qsTr("Remove Selected")
                        enabled: !shadersettings.profiles_list.get(profilesbox.currentIndex).builtin
                        onClicked: {
                            shadersettings.profiles_list.remove(profilesbox.currentIndex)
                            profilesbox.currentIndex = profilesbox.currentIndex - 1
                        }
                    }
                }
                InsertNameDialog{
                    id: insertname
                    onNameSelected: shadersettings.addNewCustomProfile(name)
                }
            }
        }
        GroupBox{
            title: qsTr("Lights")
            Layout.fillWidth: true
            GridLayout{
                anchors.fill: parent
                columns: 2
                Text{ text: qsTr("Brightness") }
                SimpleSlider{
                    onValueChanged: shadersettings.brightness = value
                    value: shadersettings.brightness
                }
                Text{ text: qsTr("Contrast") }
                SimpleSlider{
                    onValueChanged: shadersettings.contrast = value
                    value: shadersettings.contrast
                }
                Text{ text: qsTr("Ambient") }
                SimpleSlider{
                    onValueChanged: shadersettings.ambient_light = value;
                    value: shadersettings.ambient_light
                }
            }
        }
        GroupBox{
            title: qsTr("Performace")
            Layout.fillWidth: true
            Layout.columnSpan: 2
            anchors.left: parent.left
            anchors.right: parent.right
            GridLayout{
                anchors.fill: parent
                rows: 2
                columns: 3
                CheckBox{
                    property int fps: checked ? slider.value : 0
                    onFpsChanged: shadersettings.fps = fps
                    checked: shadersettings.fps !== 0
                    text: qsTr("Limit FPS")
                }
                Slider{
                    id: slider
                    Layout.fillWidth: true
                    stepSize: 1
                    maximumValue: 60
                    minimumValue: 1
                    enabled: shadersettings.fps !== 0
                    value: shadersettings.fps !== 0 ? shadersettings.fps : 60
                }
                Text{text: slider.value}
                Text{text: qsTr("Texture quality")}
                Slider{
                    Layout.fillWidth: true
                    id: txtslider
                    stepSize: 0.01
                    maximumValue: 1
                    minimumValue: 0
                    onValueChanged: shadersettings.window_scaling = value;
                    value: shadersettings.window_scaling
                    updateValueWhileDragging: false
                }
                Text{text: Math.round(txtslider.__handlePos * 100) + "%"}
            }
        }
    }
}
