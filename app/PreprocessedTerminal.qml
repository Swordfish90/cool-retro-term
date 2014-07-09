/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordifish90/cool-old-term
*
* This file is part of cool-old-term.
*
* cool-old-term is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/

import QtQuick 2.2
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.1

import org.kde.konsole 0.1

Item{
    id: terminalContainer
    property variant theSource: finalSource
    property variant bloomSource: bloomSourceLoader.item
    property variant rasterizationSource: rasterizationEffectSource
    property variant staticNoiseSource: staticNoiseSource

    property alias kterminal: kterminal

    signal sizeChanged
    onWidthChanged: sizeChanged()
    onHeightChanged: sizeChanged()

    //The blur effect has to take into account the framerate
    property int fps: shadersettings.fps !== 0 ? shadersettings.fps : 60
    property real fpsAttenuation: 60 / fps
    property real mBlur: shadersettings.motion_blur
    property real motionBlurCoefficient: (_maxBlurCoefficient * mBlur + _minBlurCoefficient * (1 - mBlur))
    property real _minBlurCoefficient: 0.75
    property real _maxBlurCoefficient: 0.95

    property size virtualPxSize: Qt.size(1,1)
    property size virtual_resolution: Qt.size(width / virtualPxSize.width, height / virtualPxSize.height)
    property real deltay: 0.5 / virtual_resolution.height
    property real deltax: 0.5 / virtual_resolution.width

    property real mBloom: shadersettings.bloom_strength
    property int mScanlines: shadersettings.rasterization
    onMScanlinesChanged: restartBlurredSource()

    property size terminalSize: kterminal.terminalSize
    property size paintedTextSize

    onMBlurChanged: restartBlurredSource()

    function restartBlurredSource(){
        if(!blurredSource) return;
        blurredSource.live = true;
        livetimer.restart()
    }
    function pasteClipboard(){
        kterminal.pasteClipboard();
    }
    function copyClipboard(){
        kterminal.copyClipboard();
    }

    KTerminal {
        id: kterminal
        anchors.fill: parent

        colorScheme: "cool-old-term"

        session: KSession {
            id: ksession
            kbScheme: "linux"

            onFinished: {
                Qt.quit()
            }
        }

        FontLoader{ id: fontLoader }
        Text{id: fontMetrics; text: "B"; visible: false}

        function getPaintedSize(pixelSize){
            fontMetrics.font.family = fontLoader.name;
            fontMetrics.font.pixelSize = pixelSize;
            return Qt.size(fontMetrics.paintedWidth, fontMetrics.paintedHeight);
        }
        function isValid(size){
            return size.width >= 0 && size.height >= 0;
        }
        function handleFontChange(fontSource, pixelSize, lineSpacing, virtualCharSize){
            fontLoader.source = fontSource;
            font.pixelSize = pixelSize * shadersettings.window_scaling;
            font.family = fontLoader.name;

            var paintedSize = getPaintedSize(pixelSize);
            var charSize = isValid(virtualCharSize)
                    ? virtualCharSize
                    : Qt.size(paintedSize.width / 2, paintedSize.height / 2);

            var virtualPxSize = Qt.size((paintedSize.width  / charSize.width) * shadersettings.window_scaling,
                                        (paintedSize.height / charSize.height) * shadersettings.window_scaling)

            terminalContainer.virtualPxSize = virtualPxSize;

            setLineSpacing(lineSpacing * shadersettings.window_scaling);
            restartBlurredSource();
        }
        Component.onCompleted: {
            shadersettings.terminalFontChanged.connect(handleFontChange);
            forceActiveFocus();
        }
    }
    Menu{
        id: contextmenu
        MenuItem{action: copyAction}
        MenuItem{action: pasteAction}
        MenuSeparator{}
        MenuItem{action: fullscreenAction}
    }
    MouseArea{
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        anchors.fill: parent
        onWheel:{
            var coord = correctDistortion(wheel.x, wheel.y);
            var lines = wheel.angleDelta.y > 0 ? -2 : 2;
            kterminal.scrollWheel(coord.width, coord.height, lines);
        }
        onClicked: {
            if (mouse.button == Qt.RightButton){
                contextmenu.popup();
            } else if (mouse.button == Qt.MiddleButton){
                kterminal.pasteSelection();
            }
        }
        onDoubleClicked: {
            if (mouse.button == Qt.LeftButton){
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.mouseDoubleClick(coord.width, coord.height);
            }
        }
        onPositionChanged: {
            if (pressedButtons & Qt.LeftButton){
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.mouseMove(coord.width, coord.height);
            }
        }
        onPressed: {
            if (mouse.button == Qt.LeftButton){
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.mousePress(coord.width, coord.height);
            }
        }
        onReleased: {
            if (mouse.button == Qt.LeftButton){
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.mouseRelease(coord.width, coord.height);
            }
        }

        //Frame displacement properties
        property real dtop: frame.item.displacementTop
        property real dleft:frame.item.displacementLeft
        property real dright: frame.item.displacementRight
        property real dbottom: frame.item.displacementBottom

        function correctDistortion(x, y){
            x = x / width;
            y = y / height;

            x = (-dleft + x * (width + dleft + dright)) / width
            y = (-dtop  + y * (height + dtop + dbottom)) / height

            var cc = Qt.size(0.5 - x, 0.5 - y);
            var distortion = (cc.height * cc.height + cc.width * cc.width) * shadersettings.screen_distortion;

            return Qt.size((x - cc.width  * (1+distortion) * distortion) * width,
                           (y - cc.height * (1+distortion) * distortion) * height)
        }
    }
    ShaderEffectSource{
        id: source
        sourceItem: kterminal
        hideSource: true
        smooth: false
    }
    ShaderEffectSource{
        id: blurredSource
        sourceItem: blurredterminal
        recursive: true
        live: true

        smooth: false
        antialiasing: false

        Timer{
            id: livetimer
            running: true
            onTriggered: parent.live = false;

            function updateImageHandler(){
                livetimer.restart();
                blurredSource.live = true;
            }
            Component.onCompleted: kterminal.updatedImage.connect(updateImageHandler);
        }
    }
    ShaderEffectSource{
        id: finalSource
        sourceItem: blurredterminal
        sourceRect: frame.sourceRect
        format: ShaderEffectSource.Alpha
    }
    ShaderEffect {
        id: blurredterminal
        anchors.fill: parent
        property variant source: source
        property variant blurredSource: (mBlur !== 0) ? blurredSource : undefined
        property size virtual_resolution: parent.virtual_resolution
        property size delta: Qt.size((mScanlines == shadersettings.pixel_rasterization ? deltax : 0),
                                     mScanlines != shadersettings.no_rasterization ? deltay : 0)
        blending: false

        fragmentShader:
            "uniform lowp float qt_Opacity;" +
            "uniform lowp sampler2D source;" +
            "uniform highp vec2 delta;" +

            "varying highp vec2 qt_TexCoord0;

             uniform highp vec2 virtual_resolution;" +

        (mBlur !== 0 ?
        "uniform lowp sampler2D blurredSource;"
        : "") +

        "void main() {" +
        "vec2 coords = qt_TexCoord0;" +
        (mScanlines != shadersettings.no_rasterization ? "
                    coords.y = floor(virtual_resolution.y * coords.y) / virtual_resolution.y;" +
        (mScanlines == shadersettings.pixel_rasterization ? "
                        coords.x = floor(virtual_resolution.x * coords.x) / virtual_resolution.x;" : "")
        : "") +
        "coords = coords + delta;" +
        "vec4 vcolor = texture2D(source, coords).r * 256.0;
         float color = vcolor.r * 0.21 + vcolor.g * 0.72 + vcolor.b + 0.04;" +
        (mBlur !== 0 ?
        "float blurredSourceColor = texture2D(blurredSource, coords).a * 256.0;" +
        "blurredSourceColor = blurredSourceColor - blurredSourceColor * " + (1.0 - motionBlurCoefficient) * fpsAttenuation+ ";" +
        "color = step(1.0, color) * color + step(color, 1.0) * blurredSourceColor;"
        : "") +


        "gl_FragColor.a = floor(color) / 256.0;" +
        "}"
    }
    ///////////////////////////////////////////////////////////////////////////
    //  EFFECTS  //////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    //  BLOOM  ////////////////////////////////////////////////////////////////

    Loader{
        id: bloomEffectLoader
        active: mBloom != 0
        anchors.fill: parent
        sourceComponent: FastBlur{
            radius: 48
            source: kterminal
            transparentBorder: true
            smooth: false
        }
    }
    Loader{
        id: bloomSourceLoader
        active: mBloom != 0
        sourceComponent: ShaderEffectSource{
            sourceItem: bloomEffectLoader.item
            hideSource: true
            sourceRect: frame.sourceRect
            smooth: false
        }
    }

    //  NOISE  ////////////////////////////////////////////////////////////////

    ShaderEffect {
        id: staticNoiseEffect
        anchors.fill: parent
        property size virtual_resolution: terminalContainer.virtual_resolution

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
    }
    ShaderEffectSource{
        id: staticNoiseSource
        sourceItem: staticNoiseEffect
        textureSize: Qt.size(parent.width, parent.height)
        wrapMode: ShaderEffectSource.Repeat
        smooth: true
        hideSource: true
        format: ShaderEffectSource.Alpha
    }

    // RASTERIZATION //////////////////////////////////////////////////////////
    ShaderEffect{
        id: rasterizationContainer
        width: frame.sourceRect.width
        height: frame.sourceRect.height
        property size offset: Qt.size(width - rasterizationEffect.width, height - rasterizationEffect.height)
        property size txtRes: Qt.size(width, height)

        blending: false

        fragmentShader:
            "uniform lowp float qt_Opacity;
             uniform highp vec2 offset;
             uniform highp vec2 txtRes;" +

            "varying highp vec2 qt_TexCoord0;" +

            "void main() {" +
                "float color = 1.0;
                 color *= smoothstep(0.0, offset.x / txtRes.x, qt_TexCoord0.x);
                 color *= smoothstep(0.0, offset.y / txtRes.y, qt_TexCoord0.y);
                 color *= smoothstep(0.0, offset.x / txtRes.x, 1.0 - qt_TexCoord0.x);
                 color *= smoothstep(0.0, offset.y / txtRes.y, 1.0 - qt_TexCoord0.y);" +

                "float distance = length(vec2(0.5) - qt_TexCoord0);" +
                "color = mix(color, 0.0, 1.2 * distance * distance);" +

                "gl_FragColor.a = color;" +
            "}"

        ShaderEffect {
            id: rasterizationEffect
            width: terminalContainer.width
            height: terminalContainer.height
            anchors.centerIn: parent
            property size virtual_resolution: terminalContainer.virtual_resolution

            blending: false

            fragmentShader:
                "uniform lowp float qt_Opacity;" +

                "varying highp vec2 qt_TexCoord0;
                     uniform highp vec2 virtual_resolution;

                     float getScanlineIntensity(vec2 coords) {
                        float result = 1.0;" +
                        (mScanlines != shadersettings.no_rasterization ?
                            "result *= abs(sin(coords.y * virtual_resolution.y * "+Math.PI+"));" : "") +
                        (mScanlines == shadersettings.pixel_rasterization ?
                            "result *= abs(sin(coords.x * virtual_resolution.x * "+Math.PI+"));" : "") + "
                        return result;
                     }" +

            "void main() {" +
                "float color = getScanlineIntensity(qt_TexCoord0);" +

                "float distance = length(vec2(0.5) - qt_TexCoord0);" +
                "color = mix(color, 0.0, 1.2 * distance * distance);" +

                "gl_FragColor.a = color;" +
            "}"
        }
    }
    ShaderEffectSource{
        id: rasterizationEffectSource
        sourceItem: rasterizationContainer
        hideSource: true
        smooth: true
        format: ShaderEffectSource.Alpha
    }
}
