import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

Tab{
    ColumnLayout{
        anchors.fill: parent
        GroupBox{
            title: qsTr("Rasterization Mode")
            Layout.fillWidth: true
            ComboBox {
                id: rasterizationBox
                anchors.fill: parent
                model: [qsTr("Default"), qsTr("Scanlines"), qsTr("Pixels")]
                currentIndex: shadersettings.rasterization
                onCurrentIndexChanged: shadersettings.rasterization = currentIndex
            }
        }
        GroupBox{
            title: qsTr("Font")
            Layout.fillWidth: true
            GridLayout{
                anchors.fill: parent
                columns: 2
                Text{ text: qsTr("Name") }
                ComboBox{
                    id: fontChanged
                    Layout.fillWidth: true
                    model: shadersettings.fontlist
                    currentIndex: shadersettings.fontIndexes[shadersettings.rasterization]
                    onCurrentIndexChanged: {
                        shadersettings.fontIndexes[shadersettings.rasterization] = currentIndex;
                        shadersettings.handleFontChanged();
                    }
                }
                Text{ text: qsTr("Scaling") }
                RowLayout{
                    Layout.fillWidth: true
                    Slider{
                        id: scalingChanger
                        Layout.fillWidth: true
                        minimumValue: 0
                        maximumValue: shadersettings.fontScalingList.length - 1
                        stepSize: 1
                        value: shadersettings.fontScalingIndexes[shadersettings.rasterization]
                        onValueChanged: {
                            shadersettings.fontScalingIndexes[shadersettings.rasterization] = value;
                            console.log(shadersettings.fontScalingIndexes);
                            shadersettings.handleFontChanged();
                        }
                    }
                    Text{
                        text: shadersettings.fontScalingList[scalingChanger.value].toFixed(2)
                    }
                }
            }
        }
        GroupBox{
            title: qsTr("Colors")
            Layout.fillWidth: true
            RowLayout{
                anchors.fill: parent
                ColorButton{
                    name: qsTr("Font")
                    height: 50
                    Layout.fillWidth: true
                    onButton_colorChanged: shadersettings._font_color = button_color
                    button_color: shadersettings._font_color
                }
                ColorButton{
                    name: qsTr("Background")
                    height: 50
                    Layout.fillWidth: true
                    onButton_colorChanged: shadersettings._background_color = button_color
                    button_color: shadersettings._background_color
                }
            }
        }
        GroupBox{
            title: qsTr("Frame")
            Layout.fillWidth: true
            RowLayout{
                anchors.fill: parent
                ComboBox{
                    id: framescombobox
                    Layout.fillWidth: true
                    model: shadersettings.frames_list
                    currentIndex: shadersettings.frames_index
                    onCurrentIndexChanged: shadersettings.frames_index = currentIndex
                }
                CheckBox{
                    checked: shadersettings.frame_reflections
                    text: qsTr("Reflections")
                    onCheckedChanged: shadersettings.frame_reflections = checked
                    enabled: framescombobox.model.get(framescombobox.currentIndex).reflections
                }
            }
        }
    }
}
