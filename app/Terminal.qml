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
    property variant scanlineSource: scanlineSourceLoader.item

    property alias kterminal: kterminal

    //The blur effect has to take into account the framerate
    property real fpsAttenuation: 60 / shadersettings.fps
    property real mBlur: shadersettings.motion_blur
    property real motionBlurCoefficient: (_maxBlurCoefficient * mBlur + _minBlurCoefficient * (1 - mBlur))
    property real _minBlurCoefficient: 0.75
    property real _maxBlurCoefficient: 0.95

    property real scanlineWidth: 1
    property real scanlineHeight: 1
    property size virtual_resolution: Qt.size(width / scanlineWidth, height / scanlineHeight)
    property real deltay: 0.5 / virtual_resolution.height
    property real deltax: 0.5 / virtual_resolution.width

    property real mBloom: shadersettings.bloom_strength
    property int mScanlines: shadersettings.rasterization
    onMScanlinesChanged: restartBlurredSource()

    property size terminalSize: kterminal.terminalSize
    property size paintedTextSize

    onPaintedTextSizeChanged: console.log(paintedTextSize)

    //Force reload of the blursource when settings change
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
        font.pixelSize: shadersettings.font.pixelSize
        font.family: shadersettings.font.name

        colorScheme: "MyWhiteOnBlack"

        session: KSession {
            id: ksession
            kbScheme: "linux"

            onFinished: {
                Qt.quit()
            }
        }

        Text{id: fontMetrics; text: "B"; visible: false}

        function handleFontChange(){
            var scaling_factor = shadersettings.window_scaling;
            var font_size = shadersettings.font.pixelSize * scaling_factor;
            font.pixelSize = font_size;
            font.family = shadersettings.font.name;

            fontMetrics.font = font;

            var vertical_density = shadersettings.font.virtualResolution.height;
            var horizontal_density = shadersettings.font.virtualResolution.width;

            var scanline_height = fontMetrics.paintedHeight / vertical_density;
            var scanline_width = fontMetrics.paintedWidth / horizontal_density;

            var scanline_spacing = shadersettings.font.lineSpacing;
            var line_spacing = Math.round(scanline_spacing * scanline_height);

//            console.log("Font height: " + fontMetrics.paintedHeight)
//            console.log("Scanline Height: " + scanline_height)
//            console.log("Line Spacing: " + line_spacing)

            terminalContainer.scanlineHeight = scanline_height;
            terminalContainer.scanlineWidth = scanline_width;

            setLineSpacing(line_spacing);
            restartBlurredSource();
        }
        Component.onCompleted: {
            shadersettings.terminalFontChanged.connect(handleFontChange);
            handleFontChange();
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
        onWheel:
            wheel.angleDelta.y > 0 ? kterminal.scrollUp() : kterminal.scrollDown()
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
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.mouseMove(coord.width, coord.height);
        }
        onPressed: {
            if (mouse.button == Qt.LeftButton){
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.mousePress(coord.width, coord.height);
            }
        }
        onReleased: {
            if (mouse.button == Qt.LeftButton){
                kterminal.mouseRelease(mouse.x, mouse.y);
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
    }
    ShaderEffect {
        id: blurredterminal
        anchors.fill: parent
        property variant source: source
        property variant blurredSource: (mBlur !== 0) ? blurredSource : undefined
        property size virtual_resolution: parent.virtual_resolution
        property size delta: Qt.size((mScanlines == shadersettings.pixel_rasterization ? deltax : 0),
                                     mScanlines != shadersettings.no_rasterization ? deltay : 0)
        z: 2

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

        "float color = texture2D(source, coords + delta).r * 256.0;" +
        (mBlur !== 0 ?
        "float blurredSourceColor = texture2D(blurredSource, qt_TexCoord0).r * 256.0;" +
        "blurredSourceColor = blurredSourceColor - blurredSourceColor * " + (1.0 - motionBlurCoefficient) * fpsAttenuation+ ";" +
        "color = step(1.0, color) * color + step(color, 1.0) * blurredSourceColor;"
        : "") +


        "gl_FragColor = vec4(vec3(floor(color) / 256.0), 1.0);" +
        "}"
    }
    //////////////////////////////////////////////////////////////////////
    //EFFECTS
    //////////////////////////////////////////////////////////////////////
    //Bloom
    Loader{
        id: bloomEffectLoader
        active: mBloom != 0
        anchors.fill: parent
        sourceComponent: FastBlur{
            radius: 32
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
    //Scanlines
    Loader{
        id: scanlineEffectLoader
        active: mScanlines != shadersettings.no_rasterization
        anchors.fill: parent
        sourceComponent: ShaderEffect {
            property size virtual_resolution: terminalContainer.virtual_resolution

            fragmentShader:
                "uniform lowp float qt_Opacity;" +

                "varying highp vec2 qt_TexCoord0;
                 uniform highp vec2 virtual_resolution;

                 float getScanlineIntensity(vec2 coords) {
                    float result = abs(sin(coords.y * virtual_resolution.y * "+Math.PI+"));" +
            (mScanlines == shadersettings.pixel_rasterization ?
            "result *= abs(sin(coords.x * virtual_resolution.x * "+Math.PI+"));" : "") + "
                    return result;
                 }" +

            "void main() {" +
                "gl_FragColor = vec4(getScanlineIntensity(qt_TexCoord0));" +
            "}"
        }
    }
    Loader{
        id: scanlineSourceLoader
        active: mScanlines != shadersettings.no_rasterization
        sourceComponent: ShaderEffectSource{
            sourceItem: scanlineEffectLoader.item
            sourceRect: frame.sourceRect
            hideSource: true
            smooth: true
        }
    }
}
