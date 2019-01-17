import QtQuick 2.0

import "utils.js" as Utils

Loader {
    property ShaderEffectSource source: item ? item.source : null

    active: !appSettings.useFastBurnIn && appSettings.burnIn !== 0

    anchors.fill: parent

    sourceComponent: Item {
        property alias source: burnInSourceEffect

        property int burnInScaling: scaleTexture * appSettings.burnInQuality

        ShaderEffectSource {
            property bool updateBurnIn: false
            property real burnIn: appSettings.burnIn
            property real fps: appSettings.fps !== 0 ? appSettings.fps : 60
            property real burnInFadeTime: Utils.lint(minBurnInFadeTime, maxBurnInFadeTime, burnIn)
            property real burnInCoefficient: 1000 / (fps * burnInFadeTime)
            property real minBurnInFadeTime: appSettings.minBurnInFadeTime
            property real maxBurnInFadeTime: appSettings.maxBurnInFadeTime

            id: burnInSourceEffect

            anchors.fill: parent

            sourceItem: burnInEffect
            recursive: true
            live: false
            hideSource: true
            wrapMode: kterminalSource.wrapMode

            visible: false

            function restartBlurSource(){
                livetimer.restart();
            }

            // This updates the burnin synched with the timer.
            Connections {
                target: burnInSourceEffect.updateBurnIn ? timeManager : null
                ignoreUnknownSignals: false
                onTimeChanged: {
                    burnInSourceEffect.scheduleUpdate();
                }
            }

            Timer{
                id: livetimer

                // The interval assumes 60 fps. This is the time needed burnout a white pixel.
                // We multiply 1.1 to have a little bit of margin over the theoretical value.
                // This solution is not extremely clean, but it's probably the best to avoid measuring fps.

                interval: burnInSourceEffect.burnInFadeTime * 1.1
                running: true
                onTriggered: burnInSourceEffect.updateBurnIn = false;
            }
            Connections{
                target: kterminal
                onImagePainted:{
                    burnInSourceEffect.scheduleUpdate();
                    burnInSourceEffect.updateBurnIn = true;
                    livetimer.restart();
                }
            }
            // Restart blurred source settings change.
            Connections{
                target: appSettings
                onBurnInChanged: burnInSourceEffect.restartBlurSource();
                onTerminalFontChanged: burnInSourceEffect.restartBlurSource();
                onRasterizationChanged: burnInSourceEffect.restartBlurSource();
                onBurnInQualityChanged: burnInSourceEffect.restartBlurSource();
            }
            Connections {
                target: kterminalScrollbar
                onOpacityChanged: burnInSourceEffect.restartBlurSource();
            }

            ShaderEffect {
                id: burnInEffect

                property variant txt_source: kterminalSource
                property variant blurredSource: burnInSourceEffect
                property real burnInCoefficient: burnInSourceEffect.burnInCoefficient

                anchors.fill: parent
                blending: false

                fragmentShader:
                    "#ifdef GL_ES
                    precision mediump float;
                #endif\n" +

                "uniform lowp float qt_Opacity;" +
                "uniform lowp sampler2D txt_source;" +

                "varying highp vec2 qt_TexCoord0;
             uniform lowp sampler2D blurredSource;
             uniform highp float burnInCoefficient;" +

                "float max3(vec3 v) {
                     return max (max (v.x, v.y), v.z);
                }" +

                "void main() {" +
                    "vec2 coords = qt_TexCoord0;" +
                    "vec3 origColor = texture2D(txt_source, coords).rgb;" +
                    "vec3 blur_color = texture2D(blurredSource, coords).rgb - vec3(burnInCoefficient);" +
                    "vec3 color = min(origColor + blur_color, max(origColor, blur_color));" +

                    "gl_FragColor = vec4(color, max3(color - origColor));" +
                "}"

                onStatusChanged: if (log) console.log(log) //Print warning messages
            }
        }
    }
}
