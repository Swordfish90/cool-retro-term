import QtQuick 2.0

import org.kde.konsole 0.1

Item{
    id: terminalContainer
    property real blur: shadersettings.motion_blur
    property real motionBlurCoefficient: (_minBlurCoefficient)*blur + (_maxBlurCoefficient)*(1.0-blur)
    property real _minBlurCoefficient: 0.015
    property real _maxBlurCoefficient: 0.10
    KTerminal {
        id: kterminal
        font.pointSize: shadersettings.fontSize
        font.family: shadersettings.font.name
        width: parent.width
        height: parent.height

        colorScheme: "MyWhiteOnBlack"

        session: KSession {
            id: ksession
            kbScheme: "linux"

            onFinished: {
                Qt.quit()
            }
        }

        Component.onCompleted: {
            font.pointSize = shadersettings.fontSize;
            font.family = shadersettings.font.name;
            forceActiveFocus();
        }
    }

    Loader{
        anchors.fill: parent
        active: parent.blur !== 0

        sourceComponent: Item{
            ShaderEffectSource{
                id: source
                sourceItem: kterminal
                hideSource: true
            }
            ShaderEffectSource{
                id: blurredSource
                sourceItem: blurredterminal
                recursive: true
                live: true
            }
            ShaderEffect {
                id: blurredterminal
                anchors.fill: parent
                property variant source: source
                property variant blurredSource: blurredSource
                z: 2
                fragmentShader:
                    "uniform lowp float qt_Opacity;" +
                    "uniform lowp sampler2D source;" +
                    "uniform lowp sampler2D blurredSource;" +
                    "varying highp vec2 qt_TexCoord0;" +

                    "void main() {" +
                    "    float sourceColor = texture2D(source, qt_TexCoord0).r * 512.0;" +
                    "    float blurredSourceColor = texture2D(blurredSource, qt_TexCoord0).r * 512.0;" +
                    "    gl_FragColor = vec4(vec3(floor(mix(blurredSourceColor, sourceColor, " + motionBlurCoefficient + "))) / 512.0, 1.0);" +
                    "}"
            }
        }
    }
}
