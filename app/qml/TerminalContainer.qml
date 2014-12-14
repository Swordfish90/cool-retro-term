import QtQuick 2.2
import QtGraphicalEffects 1.0

ShaderTerminal{
    property alias title: terminal.title
    property alias terminalSize: terminal.terminalSize

    id: mainShader
    opacity: appSettings.windowOpacity * 0.3 + 0.7

    blending: false

    source: terminal.mainSource
    dispX: (12 / width) * appSettings.window_scaling
    dispY: (12 / height) * appSettings.window_scaling
    virtual_resolution: terminal.virtualResolution

    Loader{
        id: frame
        anchors.fill: parent
        z: 2.1
        source: appSettings.frame_source
    }

    PreprocessedTerminal{
        id: terminal
        anchors.fill: parent
    }

    //  EFFECTS  ////////////////////////////////////////////////////////////////

    Loader{
        property real scaling: appSettings.bloom_quality * appSettings.window_scaling
        id: bloomEffectLoader
        active: appSettings.bloom_strength
        asynchronous: true
        width: parent.width * scaling
        height: parent.height * scaling
        sourceComponent: FastBlur{
            radius: 48 * scaling
            source: terminal.mainTerminal
            transparentBorder: true
        }
    }
    Loader{
        id: bloomSourceLoader
        active: appSettings.bloom_strength !== 0
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

    // This shader might be useful in the future. Since we used it only for a couple
    // of calculations is probably best to move those in the main shader. If in
    // we will need to store another fullScreen channel this might be handy.

//    ShaderEffect {
//        id: rasterizationEffect
//        width: parent.width
//        height: parent.height
//        property real outColor: 0.0
//        property real dispX: (5 / width) * appSettings.window_scaling
//        property real dispY: (5 / height) * appSettings.window_scaling
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
