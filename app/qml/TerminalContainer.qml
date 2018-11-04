import QtQuick 2.2
import QtGraphicalEffects 1.0

import "utils.js" as Utils

ShaderTerminal{
    property alias title: terminal.title
    property alias terminalSize: terminal.terminalSize

    id: mainShader
    opacity: appSettings.windowOpacity * 0.3 + 0.7

    blending: false

    source: terminal.mainSource
    blurredSource: terminal.blurredSource
    dispX: (12 / width) * appSettings.windowScaling
    dispY: (12 / height) * appSettings.windowScaling
    virtual_resolution: terminal.virtualResolution

    Loader{
        id: frame
        anchors.fill: parent

        property real displacementLeft: item ? item.displacementLeft : 0
        property real displacementTop: item ? item.displacementTop : 0
        property real displacementRight: item ? item.displacementRight : 0
        property real displacementBottom: item ? item.displacementBottom : 0

        asynchronous: true
        visible: status === Loader.Ready

        z: 2.1
        source: appSettings.frameSource
    }

    PreprocessedTerminal{
        id: terminal
        anchors.fill: parent
    }

    //  EFFECTS  ////////////////////////////////////////////////////////////////

    Loader{
        id: bloomEffectLoader
        active: appSettings.bloom
        asynchronous: true
        width: parent.width * appSettings.bloomQuality
        height: parent.height * appSettings.bloomQuality

        sourceComponent: FastBlur{
            radius: Utils.lint(16, 64, appSettings.bloomQuality * appSettings.windowScaling);
            source: terminal.mainSource
            transparentBorder: true
        }
    }
    Loader{
        id: bloomSourceLoader
        active: appSettings.bloom !== 0
        asynchronous: true
        sourceComponent: ShaderEffectSource{
            id: _bloomEffectSource
            sourceItem: bloomEffectLoader.item
            hideSource: true
            smooth: true
            visible: false
        }
    }

    bloomSource: bloomSourceLoader.item

    Loader {
        id: rasterizationEffectLoader
        active: appSettings.rasterization != appSettings.no_rasterization
        asynchronous: true
        sourceComponent: ShaderEffect {
            id: rasterizationEffect
            width: 16
            height: 16

            blending: false

            fragmentShader:
                "uniform lowp float qt_Opacity;" +

                "varying highp vec2 qt_TexCoord0;

                 highp float getScanlineIntensity(vec2 coords) {
                     highp float result = 1.0;" +

                    (appSettings.rasterization == appSettings.scanline_rasterization ?
                        "result *= (smoothstep(0.0, 0.5, coords.y) - smoothstep(0.5, 1.0, coords.y));" : "") +

                    (appSettings.rasterization == appSettings.pixel_rasterization ?
                       "result *= (smoothstep(0.0, 0.25, coords.y) - smoothstep(0.75, 1.0, coords.y));
                        result *= (smoothstep(0.0, 0.25, coords.x) - smoothstep(0.75, 1.0, coords.x));" : "") +

                    (appSettings.rasterization == appSettings.subpixel_rasterization ?
                       "result *= (smoothstep(0.0, 0.25, coords.y) - smoothstep(0.75, 1.0, coords.y));" : "") + "

                    return result;
                 }" +

                "void main() {" +

                    (appSettings.rasterization == appSettings.subpixel_rasterization ?
                        "highp vec3 color = vec3(0.0);
                        color += vec3(1.0, 0.25, 0.25) * (step(0.0, qt_TexCoord0.x) - step(1.0/3.0, qt_TexCoord0.x));
                        color += vec3(0.25, 1.0, 0.25) * (step(1.0/3.0, qt_TexCoord0.x) - step(2.0/3.0, qt_TexCoord0.x));
                        color += vec3(0.25, 0.25, 1.0) * (step(2.0/3.0, qt_TexCoord0.x) - step(3.0/3.0, qt_TexCoord0.x));"
                    :
                        "highp vec3 color = vec3(1.0);" ) +

                    "color *= getScanlineIntensity(qt_TexCoord0);
                     gl_FragColor = vec4(color, 1.0);" +
                "}"

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }

    Loader {
        id: rasterizationSourceLoader
        active: appSettings.rasterization != appSettings.no_rasterization
        asynchronous: true

        sourceComponent: ShaderEffectSource {
            sourceItem: rasterizationEffectLoader.item
            hideSource: true
            smooth: true
            wrapMode: ShaderEffectSource.Repeat
            visible: false
            mipmap: true
        }
    }

    rasterizationSource: rasterizationSourceLoader.item
}
