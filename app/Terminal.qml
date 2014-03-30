import QtQuick 2.0
import QtGraphicalEffects 1.0

import org.kde.konsole 0.1

Item{
    id: terminalContainer
    property real mBloom: shadersettings.bloom_strength
    property real mBlur: shadersettings.motion_blur
    property real motionBlurCoefficient: (_minBlurCoefficient)*mBlur + (_maxBlurCoefficient)*(1.0-mBlur)
    property real _minBlurCoefficient: 0.015
    property real _maxBlurCoefficient: 0.10

    function loadKTerminal(){
        kterminal.active = true;
    }
    function unloadKTerminal(){
        kterminal.active = false;
    }

    Loader{
        id: kterminal
        active: false
        anchors.fill: parent
        sourceComponent: KTerminal {
            font.pointSize: shadersettings.fontSize
            font.family: shadersettings.font.name

            colorScheme: "MyWhiteOnBlack"

            session: KSession {
                id: ksession
                kbScheme: "linux"

                onFinished: {
                    Qt.quit()
                }
            }

            onUpdatedImage: {blurredSource.live = true;livetimer.restart();}

            Component.onCompleted: {
                font.pointSize = shadersettings.fontSize;
                font.family = shadersettings.font.name;
                forceActiveFocus();
            }
        }
    }
    MouseArea{
        acceptedButtons: Qt.NoButton
        anchors.fill: parent
        onWheel:
            wheel.angleDelta.y > 0 ? kterminal.item.scrollUp() : kterminal.item.scrollDown()
    }
    ShaderEffectSource{
        id: source
        sourceItem: kterminal
        hideSource: true
    }
    Loader{
        anchors.fill: parent
        active: mBlur !== 0
        ShaderEffectSource{
            id: blurredSource
            sourceItem: blurredterminal
            recursive: true
            live: true

            Timer{
                id: livetimer
                running: true
                onTriggered: parent.live = false;
            }
        }
    }
    ShaderEffect {
        id: blurredterminal
        anchors.fill: parent
        property variant source: source
        property variant blurredSource: (mBlur !== 0) ? blurredSource : undefined
        z: 2

        fragmentShader:
            "uniform lowp float qt_Opacity;" +
            "uniform lowp sampler2D source;" +

            "varying highp vec2 qt_TexCoord0;" +

            (mBlur !== 0 ?
                 "uniform lowp sampler2D blurredSource;" : "") +

            "void main() {" +
            "float color = texture2D(source, qt_TexCoord0).r * 0.8 * 512.0;" +
            (mBlur !== 0 ?
                 "float blurredSourceColor = texture2D(blurredSource, qt_TexCoord0).r * 512.0;" +
                 "color = mix(blurredSourceColor, color, " + motionBlurCoefficient + ");" : ""
             ) +
            "gl_FragColor = vec4(vec3(floor(color) / 512.0), 1.0);" +
            "}"
    }
}
