import QtQuick 2.2
import QtGraphicalEffects 1.0

ShaderTerminal{
    property alias title: terminal.title
    property alias terminalSize: terminal.terminalSize

    id: mainShader
    opacity: shadersettings.windowOpacity * 0.3 + 0.7

    blending: false

    Loader{
        id: frame
        anchors.fill: parent
        z: 2.1
        source: shadersettings.frame_source
    }

    PreprocessedTerminal{
        id: terminal
        anchors.fill: parent
    }

    source: terminal.mainSource

    //  EFFECTS  ////////////////////////////////////////////////////////////////

    Loader{
        property real scaling: shadersettings.bloom_quality * shadersettings.window_scaling
        id: bloomEffectLoader
        active: shadersettings.bloom_strength
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
        active: shadersettings.bloom_strength !== 0
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

    ShaderEffect {
        id: staticNoiseEffect
        anchors.fill: parent
        property real element_size: shadersettings.rasterization == shadersettings.no_rasterization ? 2 : 1
        property alias __terminalHeight: terminal.virtualResolution.height
        property alias __terminalWidth: terminal.virtualResolution.width
        property size virtual_resolution: Qt.size(__terminalWidth / element_size, __terminalHeight / element_size)

        blending: false

        fragmentShader:
            "uniform lowp float qt_Opacity;
             varying highp vec2 qt_TexCoord0;
             uniform highp vec2 virtual_resolution;" +

            "highp float noise(vec2 co)
            {
                highp float a = 12.9898;
                highp float b = 78.233;
                highp float c = 43758.5453;
                highp float dt= dot(co.xy ,vec2(a,b));
                highp float sn= mod(dt,3.14);
                return fract(sin(sn) * c);
            }

            vec2 sw(vec2 p) {return vec2( floor(p.x) , floor(p.y) );}
            vec2 se(vec2 p) {return vec2( ceil(p.x)  , floor(p.y) );}
            vec2 nw(vec2 p) {return vec2( floor(p.x) , ceil(p.y)  );}
            vec2 ne(vec2 p) {return vec2( ceil(p.x)  , ceil(p.y)  );}

            float smoothNoise(vec2 p) {
                vec2 inter = smoothstep(0., 1., fract(p));
                float s = mix(noise(sw(p)), noise(se(p)), inter.x);
                float n = mix(noise(nw(p)), noise(ne(p)), inter.x);
                return mix(s, n, inter.y);
            }" +

            "void main() {" +
                "gl_FragColor.a = smoothNoise(qt_TexCoord0 * virtual_resolution);" +
            "}"

        onStatusChanged: if (log) console.log(log) //Print warning messages
    }
    noiseSource: ShaderEffectSource{
        id: staticNoiseSource
        sourceItem: staticNoiseEffect
        textureSize: Qt.size(mainShader.width, mainShader.height)
        wrapMode: ShaderEffectSource.Repeat
        smooth: true
        hideSource: true
        visible: false
    }

    ShaderEffect {
        id: rasterizationEffect
        width: parent.width
        height: parent.height
        property real outColor: 0.0
        property real dispX: (5 / width) * shadersettings.window_scaling
        property real dispY: 5 / height * shadersettings.window_scaling
        property size virtual_resolution: terminal.virtualResolution

        blending: false

        fragmentShader:
            "uniform lowp float qt_Opacity;" +

            "varying highp vec2 qt_TexCoord0;
             uniform highp vec2 virtual_resolution;
             uniform highp float dispX;
             uniform highp float dispY;
             uniform mediump float outColor;

             highp float getScanlineIntensity(vec2 coords) {
                 highp float result = 1.0;" +

                (shadersettings.rasterization != shadersettings.no_rasterization ?
                    "result *= abs(sin(coords.y * virtual_resolution.y * "+Math.PI+"));" : "") +
                (shadersettings.rasterization == shadersettings.pixel_rasterization ?
                    "result *= abs(sin(coords.x * virtual_resolution.x * "+Math.PI+"));" : "") + "

                return result;
             }" +

            "void main() {" +
                "highp float color = getScanlineIntensity(qt_TexCoord0);" +

                "float distance = length(vec2(0.5) - qt_TexCoord0);" +
                "color = mix(color, 0.0, 1.2 * distance * distance);" +

                "color *= outColor + smoothstep(0.00, dispX, qt_TexCoord0.x) * (1.0 - outColor);" +
                "color *= outColor + smoothstep(0.00, dispY, qt_TexCoord0.y) * (1.0 - outColor);" +
                "color *= outColor + (1.0 - smoothstep(1.00 - dispX, 1.00, qt_TexCoord0.x)) * (1.0 - outColor);" +
                "color *= outColor + (1.0 - smoothstep(1.00 - dispY, 1.00, qt_TexCoord0.y)) * (1.0 - outColor);" +

                "gl_FragColor.a = color;" +
            "}"

        onStatusChanged: if (log) console.log(log) //Print warning messages
    }

    rasterizationSource: ShaderEffectSource{
        id: rasterizationEffectSource
        sourceItem: rasterizationEffect
        hideSource: true
        smooth: true
        wrapMode: ShaderEffectSource.ClampToEdge
        visible: false
    }
}
