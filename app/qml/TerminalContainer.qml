import QtQuick 2.2
import QtGraphicalEffects 1.0

import "utils.js" as Utils

ShaderTerminal {
    property alias title: terminal.title
    property alias terminalSize: terminal.terminalSize

    id: mainShader
    opacity: appSettings.windowOpacity * 0.3 + 0.7

    source: terminal.mainSource
    burnInEffect: terminal.burnInEffect
    slowBurnInEffect: terminal.slowBurnInEffect
    virtual_resolution: terminal.virtualResolution

    TimeManager{
        id: timeManager
        enableTimer: terminalWindow.visible
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
            radius: Utils.lint(16, 64, appSettings.bloomQuality);
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

//    NewTerminalFrame {
//        id: terminalFrame
//        anchors.fill: parent
//        blending: true
//    }

    // This shader might be useful in the future. Since we used it only for a couple
    // of calculations is probably best to move those in the main shader. If in the future
    // we need to store another fullScreen channel this might be handy.

//    ShaderEffect {
//        id: rasterizationEffect
//        width: parent.width
//        height: parent.height
//        property real outColor: 0.0
//        property real dispX: (5 / width) * appSettings.windowScaling
//        property real dispY: (5 / height) * appSettings.windowScaling
//        property size virtual_resolution: terminal.virtualResolution

//        blending: false

//        fragmentShader:
//            "uniform lowp float qt_Opacity;" +

//            "varying highp vec2 qt_TexCoord0;
//             uniform highp vec2 virtual_resolution;
//             uniform highp float dispX;
//             uniform highp float dispY;
//             uniform mediump float outColor;

//             highp float getScanlineIntensity(vec2 coords) {
//                 highp float result = 1.0;" +

//                (appSettings.rasterization != appSettings.no_rasterization ?
//                    "result *= abs(sin(coords.y * virtual_resolution.y * "+Math.PI+"));" : "") +
//                (appSettings.rasterization == appSettings.pixel_rasterization ?
//                    "result *= abs(sin(coords.x * virtual_resolution.x * "+Math.PI+"));" : "") + "

//                return result;
//             }" +

//            "void main() {" +
//                "highp float color = getScanlineIntensity(qt_TexCoord0);" +

//                "float distance = length(vec2(0.5) - qt_TexCoord0);" +
//                "color = mix(color, 0.0, 1.2 * distance * distance);" +

//                "color *= outColor + smoothstep(0.00, dispX, qt_TexCoord0.x) * (1.0 - outColor);" +
//                "color *= outColor + smoothstep(0.00, dispY, qt_TexCoord0.y) * (1.0 - outColor);" +
//                "color *= outColor + (1.0 - smoothstep(1.00 - dispX, 1.00, qt_TexCoord0.x)) * (1.0 - outColor);" +
//                "color *= outColor + (1.0 - smoothstep(1.00 - dispY, 1.00, qt_TexCoord0.y)) * (1.0 - outColor);" +

//                "gl_FragColor.a = color;" +
//            "}"

//        onStatusChanged: if (log) console.log(log) //Print warning messages
//    }

//    rasterizationSource: ShaderEffectSource{
//        id: rasterizationEffectSource
//        sourceItem: rasterizationEffect
//        hideSource: true
//        smooth: true
//        wrapMode: ShaderEffectSource.ClampToEdge
//        visible: false
//    }
}
