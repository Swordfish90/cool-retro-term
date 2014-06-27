import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1

Tab{
    GroupBox{
        title: qsTr("Effects")
        anchors.fill: parent
        ColumnLayout{
            anchors.fill: parent
            CheckableSlider{
                name: qsTr("Bloom")
                onValueChanged: shadersettings.bloom_strength = value
                _value: shadersettings.bloom_strength
            }
            CheckableSlider{
                name: qsTr("Motion Blur")
                onValueChanged: shadersettings.motion_blur = value
                _value: shadersettings.motion_blur
            }
            CheckableSlider{
                name: qsTr("Noise")
                onValueChanged: shadersettings.noise_strength = value
                _value: shadersettings.noise_strength
            }
            CheckableSlider{
                name: qsTr("Jitter")
                onValueChanged: shadersettings.jitter = value
                _value: shadersettings.jitter
            }
            CheckableSlider{
                name: qsTr("Glow")
                onValueChanged: shadersettings.glowing_line_strength = value;
                _value: shadersettings.glowing_line_strength
            }
            CheckableSlider{
                name: qsTr("Screen distortion")
                onValueChanged: shadersettings.screen_distortion = value;
                _value: shadersettings.screen_distortion;
            }
            CheckableSlider{
                name: qsTr("Brightness flickering")
                onValueChanged: shadersettings.brightness_flickering= value;
                _value: shadersettings.brightness_flickering;
            }
            CheckableSlider{
                name: qsTr("Horizontal flickering")
                onValueChanged: shadersettings.horizontal_sincronization = value;
                _value: shadersettings.horizontal_sincronization;
            }
        }
    }
}
