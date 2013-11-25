import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Window 2.1
import QtQuick.Layouts 1.0

ApplicationWindow {
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
            ColumnLayout{
                anchors.fill: parent
                GridLayout{
                    width: parent.width
                    columns: 2
                    Text{text: "Font color"}
                    Text{text: "         ";
                        Rectangle{anchors.fill: parent; color: shadersettings.font_color}
                        MouseArea{anchors.fill: parent}
                    }
                    Text{text: "Backgroud color"}
                    Text{text: "         "; Rectangle{anchors.fill: parent; color: shadersettings.background_color}}
                }

                GridLayout{
                    columns: 4
                    CheckBox{
                        id: noisecheck
                        onCheckedChanged:
                            if(checked) shadersettings.noise_strength = noiseslider.value;
                            else shadersettings.noise_strength = 0;
                        Component.onCompleted: checked = shadersettings.noise_strength !== 0;
                    }
                    Text{
                        text: qsTr("Noise")
                    }
                    Slider{
                        id: noiseslider
                        stepSize: 0.01
                        minimumValue: 0.0
                        maximumValue: 1.0
                        onValueChanged: shadersettings.noise_strength = value;
                        Component.onCompleted: value = shadersettings.noise_strength;
                    }
                    TextArea{
                        text: noiseslider.value.toFixed(2);
                        enabled: false
                    }


                    CheckBox{
                        id: glowcheck
                        onCheckedChanged:
                            if(checked) shadersettings.glowing_line_strength = glowslider.value;
                            else shadersettings.glowing_line_strength = 0;
                        Component.onCompleted: checked = shadersettings.glowing_line_strength !== 0;
                    }
                    Text{
                        text: qsTr("Glow")
                    }
                    Slider{
                        id: glowslider
                        stepSize: 0.01
                        minimumValue: 0.0
                        maximumValue: 1.0
                        onValueChanged: shadersettings.glowing_line_strength = value;
                        Component.onCompleted: value = shadersettings.glowing_line_strength;
                    }
                    TextArea{
                        text: glowslider.value.toFixed(2);
                        enabled: false
                    }


                    CheckBox{
                        id: ambientcheck
                        onCheckedChanged:
                            if(checked) shadersettings.ambient_light = ambientslider.value;
                            else shadersettings.ambient_light = 0;
                        Component.onCompleted: checked = shadersettings.ambient_light !== 0;
                    }
                    Text{
                        text: qsTr("Ambient light")
                    }
                    Slider{
                        id: ambientslider
                        stepSize: 0.01
                        minimumValue: 0.1
                        maximumValue: 0.5
                        onValueChanged: shadersettings.ambient_light = value;
                        Component.onCompleted: value = shadersettings.ambient_light;
                    }
                    TextArea{
                        text: ambientslider.value.toFixed(2);
                        enabled: false
                    }

                    //                CheckBox{
                    //                    id: distortioncheck
                    //                    onCheckedChanged:
                    //                        if(checked) shadersettings.screen_distortion = distortionslider.value;
                    //                        else shadersettings.screen_distortion = 0;
                    //                    Component.onCompleted: checked = shadersettings.screen_distortion !== 0;
                    //                }
                    //                Text{
                    //                    text: qsTr("Distortion")
                    //                }
                    //                Slider{
                    //                    id: distortionslider
                    //                    stepSize: 0.01
                    //                    minimumValue: 0.0
                    //                    maximumValue: 1.0
                    //                    onValueChanged: shadersettings.screen_distortion = value;
                    //                    Component.onCompleted: value = shadersettings.screen_distortion;
                    //                }
                    //                TextArea{
                    //                    text: distortionslider.value.toFixed(2);
                    //                    enabled: false
                    //                }
                }

            }
        }
    }
}
