import QtQuick 2.0

import "utils.js" as Utils

Loader {
    id: burnInEffect

    property ShaderEffectSource source: item ? item.source : null

    property real lastUpdate: 0
    property real prevLastUpdate: 0

    property real delay: (1.0 / appSettings.fps) * 1000
    property real burnIn: appSettings.burnIn
    property real burnInFadeTime: 1 / Utils.lint(_minBurnInFadeTime, _maxBurnInFadeTime, burnIn)
    property real _minBurnInFadeTime: 160
    property real _maxBurnInFadeTime: 1600

    active: appSettings.burnIn !== 0

    function completelyUpdate() {
        prevLastUpdate = lastUpdate;
        lastUpdate = timeManager.time;
        item.source.scheduleUpdate();
    }

    function restartBlurSource(){
        prevLastUpdate = 0;
        lastUpdate = 0;
        completelyUpdate()
    }

    sourceComponent: Item {
        property alias source: burnInEffectSource

        property int burnInScaling: scaleTexture * appSettings.burnInQuality

        width: appSettings.lowResolutionFont
               ? kterminal.width * Math.max(1, burnInScaling)
               : kterminal.width * scaleTexture * appSettings.burnInQuality

        height: appSettings.lowResolutionFont
                ? kterminal.height * Math.max(1, burnInScaling)
                : kterminal.height * scaleTexture * appSettings.burnInQuality

        ShaderEffectSource {
            id: burnInEffectSource

            anchors.fill: parent

            sourceItem: burnInShaderEffect
            live: false
            recursive: true
            hideSource: true
            wrapMode: kterminalSource.wrapMode

            format: ShaderEffectSource.RGBA

            visible: false

            Connections {
                target: kterminal
                onImagePainted: completelyUpdate()
            }
            // Restart blurred source settings change.
            Connections{
                target: appSettings
                onBurnInChanged: burnInEffect.restartBlurSource();
                onTerminalFontChanged: burnInEffect.restartBlurSource();
                onRasterizationChanged: burnInEffect.restartBlurSource();
                onBurnInQualityChanged: burnInEffect.restartBlurSource();
            }

            Connections {
                target: kterminalScrollbar
                onOpacityChanged: burnInEffect.restartBlurSource()
            }
        }

        ShaderEffect {
            id: burnInShaderEffect

            property variant txt_source: kterminalSource
            property variant burnInSource: burnInEffectSource
            property real burnInTime: burnInFadeTime
            property real lastUpdate: burnInEffect.lastUpdate
            property real prevLastUpdate: burnInEffect.prevLastUpdate

            anchors.fill: parent

            blending: false

            fragmentShader:
                "#ifdef GL_ES
                        precision mediump float;
                    #endif\n" +

                "uniform lowp float qt_Opacity;" +
                "uniform lowp sampler2D txt_source;" +

                "varying highp vec2 qt_TexCoord0;

                 uniform lowp sampler2D burnInSource;
                 uniform highp float burnInTime;

                 uniform highp float lastUpdate;

                 uniform highp float prevLastUpdate;" +

                "float max3(vec3 v) {
                     return max (max (v.x, v.y), v.z);
                }" +

                "void main() {
                    vec2 coords = qt_TexCoord0;

                    vec3 txtColor = texture2D(txt_source, coords).rgb;
                    vec4 accColor = texture2D(burnInSource, coords);

                    float prevMask = accColor.a;
                    float currMask = 1.0 - max3(txtColor);

                    highp float blurDecay = prevMask * clamp((lastUpdate - prevLastUpdate) * burnInTime, 0.0, 1.0);
                    vec3 blurColor = accColor.rgb - vec3(blurDecay);

                    blurColor = clamp(blurColor, vec3(0.0), vec3(1.0));
                    vec3 color = max(blurColor, txtColor * 0.5);

                    gl_FragColor = vec4(color, currMask);
                }
            "

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }
}
