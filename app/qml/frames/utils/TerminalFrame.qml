import QtQuick 2.2
import QtGraphicalEffects 1.0

import "../../utils.js" as Utils

Item{
    id: framecontainer
    property int textureWidth: terminalContainer.width / appSettings.windowScaling
    property int textureHeight: terminalContainer.height / appSettings.windowScaling

    property int addedWidth
    property int addedHeight
    property int borderLeft
    property int borderRight
    property int borderTop
    property int borderBottom
    property string imageSource
    property string normalsSource
    property string shaderString

    //Values used to displace the texture in the screen. Used to make reflections correct.
    property real displacementLeft
    property real displacementTop
    property real displacementRight
    property real displacementBottom

    // Material coefficients
    property real staticDiffuseComponent: 0.7
    property real dinamycDiffuseComponent: 1.0

    BorderImage{
        id: frameimage
        anchors.centerIn: parent
        width: textureWidth + addedWidth
        height: textureHeight + addedHeight

        border.bottom: borderBottom
        border.top: borderTop
        border.left: borderLeft
        border.right: borderRight

        source: imageSource
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }
    BorderImage{
        id: framenormals
        anchors.fill: frameimage

        border.bottom: borderBottom
        border.top: borderTop
        border.left: borderLeft
        border.right: borderRight

        source: normalsSource
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }
    ShaderEffectSource{
        id: framesource
        sourceItem: frameimage
        hideSource: true
        textureSize: Qt.size(parent.width, parent.height)
        sourceRect: Qt.rect(-1, -1, frameimage.width + 2, frameimage.height + 2)
        visible: false
    }
    ShaderEffectSource{
        id: framesourcenormals
        sourceItem: framenormals
        hideSource: true
        textureSize: Qt.size(parent.width, parent.height)
        sourceRect: Qt.rect(-1, -1, framenormals.width + 2, framenormals.height + 2)
        visible: false
    }

    // REFLECTIONS ////////////////////////////////////////////////////////////
    Loader{
        id: reflectionEffectLoader
        width: parent.width * 0.33
        height: parent.height * 0.33
        active: appSettings.frameReflections

        sourceComponent: FastBlur{
            id: frameReflectionEffect
            radius: 128
            source: terminal.mainSource
            smooth: false
        }
    }

    Loader{
        id: reflectionEffectSourceLoader
        active: appSettings.frameReflections
        sourceComponent: ShaderEffectSource{
            id: frameReflectionSource
            sourceItem: reflectionEffectLoader.item
            hideSource: true
            smooth: true
            visible: false
        }
    }

    // This texture represent the static light component.
    ShaderEffect {
        id: staticLight
        property alias source: framesource
        property alias normals: framesourcenormals
        property real screenCurvature: appSettings.screenCurvature
        property size curvature_coefficients: Qt.size(width / mainShader.width, height / mainShader.height)
        property real ambientLight: appSettings.ambientLight * 0.9 + 0.1
        property color fontColor: appSettings.fontColor
        property color backgroundColor: appSettings.backgroundColor
        property color reflectionColor: Utils.mix(fontColor, backgroundColor, 0.2)
        property real diffuseComponent: staticDiffuseComponent

        anchors.centerIn: parent
        width: parent.width + (addedWidth / textureWidth) * parent.width
        height: parent.height + (addedHeight / textureHeight) * parent.height

        blending: true

        fragmentShader: "
            uniform highp sampler2D normals;
            uniform highp sampler2D source;
            uniform lowp float screenCurvature;
            uniform highp vec2 curvature_coefficients;
            uniform lowp float ambientLight;
            uniform highp float qt_Opacity;
            uniform lowp vec4 reflectionColor;
            uniform lowp float diffuseComponent;

            varying highp vec2 qt_TexCoord0;

            vec2 distortCoordinates(vec2 coords){
                vec2 cc = (coords - vec2(0.5)) * curvature_coefficients;
                float dist = dot(cc, cc) * screenCurvature;
                return (coords + cc * (1.0 + dist) * dist);
            }

            float rgb2grey(vec3 v){
                return dot(v, vec3(0.21, 0.72, 0.04));
            }

            void main(){
                vec2 coords = distortCoordinates(qt_TexCoord0);
                vec4 txtColor = texture2D(source, coords);
                vec4 txtNormal = texture2D(normals, coords);

                vec3 normal = normalize(txtNormal.rgb * 2.0 - 1.0);
                vec2 lightDirection = normalize(vec2(0.5, 0.5) - coords);
                float dotProd = dot(normal, vec3(lightDirection, 0.0)) * diffuseComponent * txtNormal.a;

                vec3 darkColor = dotProd * reflectionColor.rgb;
                gl_FragColor = vec4(mix(darkColor, txtColor.rgb, ambientLight), dotProd);
            }
        "

        onStatusChanged: if (log) console.log(log) //Print warning messages
    }

    ShaderEffectSource {
        id: staticLightSource
        sourceItem: staticLight
        hideSource: true
        anchors.fill: staticLight
        live: true
    }

    Loader{
        id: dynamicLightLoader
        anchors.fill: staticLight
        active: appSettings.frameReflections
        sourceComponent: ShaderEffect {
            property ShaderEffectSource lightMask: staticLightSource
            property ShaderEffectSource reflectionSource: reflectionEffectSourceLoader.item
            property real diffuseComponent: dinamycDiffuseComponent
            property real chromaColor: appSettings.chromaColor
            property color fontColor: appSettings.fontColor

            visible: true
            blending: true

            fragmentShader: "
                uniform sampler2D lightMask;
                uniform sampler2D reflectionSource;
                uniform lowp float diffuseComponent;
                uniform lowp float chromaColor;
                uniform highp vec4 fontColor;
                uniform highp float qt_Opacity;

                varying highp vec2 qt_TexCoord0;

                float rgb2grey(vec3 v){
                    return dot(v, vec3(0.21, 0.72, 0.04));
                }

                void main() {
                    float alpha = texture2D(lightMask, qt_TexCoord0).a * diffuseComponent;
                    vec3 reflectionColor = texture2D(reflectionSource, qt_TexCoord0).rgb;
                    vec3 color = fontColor.rgb * rgb2grey(reflectionColor);" +
                    (chromaColor !== 0 ?
                        "color = mix(color, fontColor.rgb * reflectionColor, chromaColor);"
                    : "") +
                    "gl_FragColor = vec4(color, 1.0) * alpha;
                }
            "

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }
}
