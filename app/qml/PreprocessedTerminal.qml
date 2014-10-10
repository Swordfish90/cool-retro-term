/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordfish90/cool-retro-term
*
* This file is part of cool-retro-term.
*
* cool-retro-term is free software: you can redistribute it and/or modify
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

import org.crt.konsole 0.1

Item{
    id: terminalContainer

    //Frame displacement properties. This makes the terminal the same size of the texture.
    property real dtop: frame.item.displacementTop
    property real dleft:frame.item.displacementLeft
    property real dright: frame.item.displacementRight
    property real dbottom: frame.item.displacementBottom

    anchors.leftMargin: dleft
    anchors.rightMargin: dright
    anchors.topMargin: dtop
    anchors.bottomMargin: dbottom

    property variant theSource: mBlur !== 0 ? blurredSourceLoader.item : kterminalSource
    property variant bloomSource: bloomSourceLoader.item
    property variant rasterizationSource: rasterizationEffectSource
    property variant staticNoiseSource: staticNoiseSource

    property alias kterminal: kterminal

    signal sizeChanged
    onWidthChanged: sizeChanged()
    onHeightChanged: sizeChanged()

    //The blur effect has to take into account the framerate
    property int fps: shadersettings.fps !== 0 ? shadersettings.fps : 60
    property real fpsAttenuation: Math.sqrt(60 / fps)
    property real mBlur: shadersettings.motion_blur
    property real motionBlurCoefficient: (_maxBlurCoefficient * mBlur + _minBlurCoefficient * (1 - mBlur))
    property real _minBlurCoefficient: 0.70
    property real _maxBlurCoefficient: 0.90

    property real mBloom: shadersettings.bloom_strength
    property int mScanlines: shadersettings.rasterization
    onMScanlinesChanged: restartBlurredSource()

    property size terminalSize: kterminal.terminalSize
    property size paintedTextSize

    onMBlurChanged: restartBlurredSource()

    function restartBlurredSource(){
        if(!blurredSourceLoader.item) return;
        blurredSourceLoader.item.restartBlurSource();
    }
    function pasteClipboard(){
        kterminal.pasteClipboard();
    }
    function copyClipboard(){
        kterminal.copyClipboard();
    }

    //When settings are updated sources need to be redrawn.
    Connections{
        target: shadersettings
        onFontScalingChanged: terminalContainer.updateSources();
        onFontWidthChanged: terminalContainer.updateSources();
    }
    Connections{
        target: terminalContainer
        onWidthChanged: terminalContainer.updateSources();
        onHeightChanged: terminalContainer.updateSources();
    }
    function updateSources() {
        kterminal.update();
        kterminal.updateImage();
    }


    KTerminal {
        id: kterminal
        width: parent.width
        height: parent.height

        colorScheme: "cool-retro-term"

        smooth: false

        session: KSession {
            id: ksession
            kbScheme: "xterm"

            onFinished: {
                Qt.quit()
            }
        }

        FontLoader{ id: fontLoader }
        Text{id: fontMetrics; text: "B"; visible: false}

        function handleFontChange(fontSource, pixelSize, lineSpacing, screenScaling){
            fontLoader.source = fontSource;
            font.pixelSize = pixelSize;
            font.family = fontLoader.name;

            var fontWidth = 1.0 / shadersettings.fontWidth;

            width = Qt.binding(function() {return Math.floor(fontWidth * terminalContainer.width / screenScaling);});
            height = Qt.binding(function() {return Math.floor(terminalContainer.height / screenScaling);});

            var scaleTexture = Math.max(Math.round(screenScaling / shadersettings.scanline_quality), 1.0);

            kterminalSource.textureSize = Qt.binding(function () {
                return Qt.size(kterminal.width * scaleTexture, kterminal.height * scaleTexture);
            });

            setLineSpacing(lineSpacing);
            update();
            restartBlurredSource();
        }
        Component.onCompleted: {
            shadersettings.terminalFontChanged.connect(handleFontChange);

            // Retrieve the variable set in main.cpp if arguments are passed.
            if (shellProgram)
                ksession.setShellProgram(shellProgram);
            if (workdir)
                ksession.initialWorkingDirectory = workdir;

            ksession.startShellProgram();
            forceActiveFocus();
        }
    }
    Menu{
        id: contextmenu
        MenuItem{action: copyAction}
        MenuItem{action: pasteAction}
        MenuSeparator{visible: Qt.platform.os !== "osx"}
        MenuItem{action: fullscreenAction; visible: Qt.platform.os !== "osx"}
        MenuItem{action: showMenubarAction; visible: Qt.platform.os !== "osx"}
        MenuSeparator{visible: !shadersettings.showMenubar}
        CRTMainMenuBar{visible: !shadersettings.showMenubar}
    }
    MouseArea{
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        // This is incredibly ugly. All this file should be reorganized.
        width: (parent.width + dleft + dright) / shadersettings.window_scaling - dleft -dright
        height: (parent.height + dtop + dbottom) / shadersettings.window_scaling - dtop - dbottom
        onWheel:{
            if(wheel.modifiers & Qt.ControlModifier){
               wheel.angleDelta.y > 0 ? zoomIn.trigger() : zoomOut.trigger();
            } else {
                var coord = correctDistortion(wheel.x, wheel.y);
                var lines = wheel.angleDelta.y > 0 ? -1 : 1;
                kterminal.scrollWheelEvent(coord, lines);
            }
        }
        onDoubleClicked: {
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.mouseDoubleClickEvent(coord, mouse.button, mouse.modifiers);
        }
        onPressed: {
	    if((!kterminal.usesMouse || mouse.modifiers & Qt.ShiftModifier) && mouse.button == Qt.RightButton) {
                contextmenu.popup();
            } else {
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.mousePressEvent(coord, mouse.button, mouse.modifiers)
            }
        }
        onReleased: {
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.mouseReleaseEvent(coord, mouse.button, mouse.modifiers);
        }
        onPositionChanged: {
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.mouseMoveEvent(coord, mouse.button, mouse.buttons, mouse.modifiers);
        }

        function correctDistortion(x, y){
            x = x / width;
            y = y / height;

            var cc = Qt.size(0.5 - x, 0.5 - y);
            var distortion = (cc.height * cc.height + cc.width * cc.width) * shadersettings.screen_distortion;

            return Qt.point((x - cc.width  * (1+distortion) * distortion) * kterminal.width,
                           (y - cc.height * (1+distortion) * distortion) * kterminal.height)
        }
    }
    ShaderEffectSource{
        id: kterminalSource
        sourceItem: kterminal
        hideSource: true
        wrapMode: ShaderEffectSource.ClampToEdge
        live: false

        signal sourceUpdate

        Connections{
            target: kterminal
            onUpdatedImage:{
                kterminalSource.scheduleUpdate();
                kterminalSource.sourceUpdate();
            }
        }
    }
    Loader{
        id: blurredSourceLoader
        asynchronous: true
        active: mBlur !== 0

        sourceComponent: ShaderEffectSource{
            id: _blurredSourceEffect
            sourceItem: blurredTerminalLoader.item
            recursive: true
            live: false
            hideSource: true
            wrapMode: kterminalSource.wrapMode

            function restartBlurSource(){
                livetimer.restart();
            }

            Timer{
                id: livetimer
                running: true
                onRunningChanged: {
                    running ?
                        timeBinding.target = timeManager :
                        timeBinding.target = null
                }
            }
            Connections{
                id: timeBinding
                target: timeManager
                onTimeChanged: {
                    _blurredSourceEffect.scheduleUpdate();
                }
            }
            Connections{
                target: kterminalSource
                onSourceUpdate:{
                    livetimer.restart();
                }
            }
            Connections{
                target: shadersettings
                onScanline_qualityChanged: restartBlurredSource();
            }
        }
    }

    Loader{
        id: blurredTerminalLoader
        width: kterminalSource.textureSize.width
        height: kterminalSource.textureSize.height
        active: mBlur !== 0
        asynchronous: true

        sourceComponent: ShaderEffect {
            property variant txt_source: kterminalSource
            property variant blurredSource: blurredSourceLoader.item
            property real blurCoefficient: (1.0 - motionBlurCoefficient) * fpsAttenuation

            blending: false

            fragmentShader:
                "uniform lowp float qt_Opacity;" +
                "uniform lowp sampler2D txt_source;" +

                "varying highp vec2 qt_TexCoord0;

                 uniform lowp sampler2D blurredSource;
                 uniform highp float blurCoefficient;" +

                "float rgb2grey(vec3 v){
                    return dot(v, vec3(0.21, 0.72, 0.04));
                }" +

                "void main() {" +
                    "vec2 coords = qt_TexCoord0;" +
                    "vec3 color = texture2D(txt_source, coords).rgb * 256.0;" +

                    "vec3 blur_color = texture2D(blurredSource, coords).rgb * 256.0;" +
                    "blur_color = blur_color - blur_color * blurCoefficient;" +
                    "color = step(vec3(1.0), color) * color + step(color, vec3(1.0)) * blur_color;" +

                    "gl_FragColor = vec4(floor(color) / 256.0, 1.0);" +
                "}"

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }
    ///////////////////////////////////////////////////////////////////////////
    //  EFFECTS  //////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    //  BLOOM  ////////////////////////////////////////////////////////////////

    Loader{
        property real scaling: shadersettings.bloom_quality * shadersettings.window_scaling
        id: bloomEffectLoader
        active: mBloom != 0
        asynchronous: true
        width: parent.width * scaling
        height: parent.height * scaling
        sourceComponent: FastBlur{
            radius: 48 * scaling
            source: kterminal
            transparentBorder: true
        }
    }
    Loader{
        id: bloomSourceLoader
        active: mBloom != 0
        asynchronous: true
        sourceComponent: ShaderEffectSource{
            id: _bloomEffectSource
            sourceItem: bloomEffectLoader.item
            hideSource: true
            live: false
            smooth: true
            Connections{
                target: kterminalSource
                onSourceUpdate: _bloomEffectSource.scheduleUpdate();
            }
        }
    }

    //  NOISE  ////////////////////////////////////////////////////////////////

    ShaderEffect {
        id: staticNoiseEffect
        anchors.fill: parent
        property real element_size: shadersettings.rasterization == shadersettings.no_rasterization ? 2 : 1
        property size virtual_resolution: Qt.size(kterminal.width / element_size, kterminal.height / element_size)

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
    ShaderEffectSource{
        id: staticNoiseSource
        sourceItem: staticNoiseEffect
        textureSize: Qt.size(parent.width, parent.height)
        wrapMode: ShaderEffectSource.Repeat
        smooth: true
        hideSource: true
    }

    // RASTERIZATION //////////////////////////////////////////////////////////

    ShaderEffect {
        id: rasterizationEffect
        width: parent.width
        height: parent.height
        property size virtual_resolution: Qt.size(kterminal.width, kterminal.height)

        blending: false

        fragmentShader:
            "uniform lowp float qt_Opacity;" +

            "varying highp vec2 qt_TexCoord0;
             uniform highp vec2 virtual_resolution;

             highp float getScanlineIntensity(vec2 coords) {
                 highp float result = 1.0;" +

                (mScanlines != shadersettings.no_rasterization ?
                    "result *= abs(sin(coords.y * virtual_resolution.y * "+Math.PI+"));" : "") +
                (mScanlines == shadersettings.pixel_rasterization ?
                    "result *= abs(sin(coords.x * virtual_resolution.x * "+Math.PI+"));" : "") + "

                return result;
             }" +

            "void main() {" +
                "highp float color = getScanlineIntensity(qt_TexCoord0);" +

                "float distance = length(vec2(0.5) - qt_TexCoord0);" +
                "color = mix(color, 0.0, 1.2 * distance * distance);" +

                "gl_FragColor.a = color;" +
            "}"

        onStatusChanged: if (log) console.log(log) //Print warning messages
    }
    ShaderEffectSource{
        id: rasterizationEffectSource
        sourceItem: rasterizationEffect
        hideSource: true
        smooth: true
        wrapMode: ShaderEffectSource.Repeat
    }
}
