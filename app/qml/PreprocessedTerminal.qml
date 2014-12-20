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
import QtQuick.Controls 1.1

import QMLTermWidget 1.0

Item{
    id: terminalContainer

    property size virtualResolution: Qt.size(kterminal.width, kterminal.height)
    property alias mainTerminal: kterminal
    property ShaderEffectSource mainSource: kterminalSource
    property ShaderEffectSource blurredSource: blurredSourceLoader.item

    property real fontWidth: 1.0
    property real screenScaling: 1.0
    property real scaleTexture: 1.0
    property alias title: ksession.title
    property alias kterminal: kterminal

    anchors.leftMargin: frame.displacementLeft * appSettings.window_scaling
    anchors.rightMargin: frame.displacementRight * appSettings.window_scaling
    anchors.topMargin: frame.displacementTop * appSettings.window_scaling
    anchors.bottomMargin: frame.displacementBottom * appSettings.window_scaling

    //The blur effect has to take into account the framerate
    property real mBlur: appSettings.motion_blur
    property real motionBlurCoefficient: (_maxBlurCoefficient * Math.sqrt(mBlur) + _minBlurCoefficient * (1 - Math.sqrt(mBlur)))
    property real _minBlurCoefficient: 0.50
    property real _maxBlurCoefficient: 0.90

    property size terminalSize: kterminal.terminalSize
    property size fontMetrics: kterminal.fontMetrics

    // Manage copy and paste
    Connections{
        target: copyAction
        onTriggered: kterminal.copyClipboard();
    }
    Connections{
        target: pasteAction
        onTriggered: kterminal.pasteClipboard()
    }

    //When settings are updated sources need to be redrawn.
    Connections{
        target: appSettings
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
    }

    QMLTermWidget {
        id: kterminal
        width: Math.floor(parent.width / (screenScaling * fontWidth))
        height: Math.floor(parent.height / screenScaling)

        colorScheme: "cool-retro-term"

        smooth: false
        enableBold: false
        fullCursorHeight: true

        session: QMLTermSession {
            id: ksession

            onFinished: {
                Qt.quit()
            }
        }

        QMLTermScrollbar {
            id: kterminalScrollbar
            terminal: kterminal
            anchors.margins: width * 0.5
            width: terminal.fontMetrics.width * 0.75
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: 1
                color: "white"
                radius: width * 0.25
                opacity: 0.7
            }
        }

        FontLoader{ id: fontLoader }

        function handleFontChange(fontSource, pixelSize, lineSpacing, screenScaling, fontWidth){
            fontLoader.source = fontSource;
            font.pixelSize = pixelSize;
            font.family = fontLoader.name;

            terminalContainer.fontWidth = fontWidth;
            terminalContainer.screenScaling= screenScaling;
            scaleTexture = Math.max(1.0, Math.round(screenScaling / 2));

            kterminal.lineSpacing = lineSpacing;
        }
        Component.onCompleted: {
            appSettings.terminalFontChanged.connect(handleFontChange);

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
        MenuSeparator{visible: !appSettings.showMenubar}
        CRTMainMenuBar{visible: !appSettings.showMenubar}
    }
    MouseArea{
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        anchors.fill: parent
        onWheel:{
            if(wheel.modifiers & Qt.ControlModifier){
               wheel.angleDelta.y > 0 ? zoomIn.trigger() : zoomOut.trigger();
            } else {
                var coord = correctDistortion(wheel.x, wheel.y);
                kterminal.simulateWheel(coord.x, coord.y, wheel.buttons, wheel.modifiers, wheel.angleDelta);
            }
        }
        onDoubleClicked: {
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.simulateMouseDoubleClick(coord.x, coord.y, mouse.button, mouse.buttons, mouse.modifiers);
        }
        onPressed: {
            if((!kterminal.terminalUsesMouse || mouse.modifiers & Qt.ShiftModifier) && mouse.button == Qt.RightButton) {
                contextmenu.popup();
            } else {
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.simulateMousePress(coord.x, coord.y, mouse.button, mouse.buttons, mouse.modifiers)
            }
        }
        onReleased: {
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.simulateMouseRelease(coord.x, coord.y, mouse.button, mouse.buttons, mouse.modifiers);
        }
        onPositionChanged: {
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.simulateMouseMove(coord.x, coord.y, mouse.button, mouse.buttons, mouse.modifiers);
        }

        function correctDistortion(x, y){
            x = x / width;
            y = y / height;

            var cc = Qt.size(0.5 - x, 0.5 - y);
            var distortion = (cc.height * cc.height + cc.width * cc.width) * appSettings.screen_distortion;

            return Qt.point((x - cc.width  * (1+distortion) * distortion) * kterminal.width,
                           (y - cc.height * (1+distortion) * distortion) * kterminal.height)
        }
    }
    ShaderEffectSource{
        id: kterminalSource
        sourceItem: kterminal
        hideSource: true
        wrapMode: ShaderEffectSource.ClampToEdge
        visible: false
        textureSize: Qt.size(kterminal.width * scaleTexture, kterminal.height * scaleTexture);
    }
    Loader{
        id: blurredSourceLoader
        asynchronous: true
        active: mBlur !== 0

        sourceComponent: ShaderEffectSource{
            id: _blurredSourceEffect
            sourceItem: blurredTerminalLoader.item
            recursive: true
            live: true
            hideSource: true
            wrapMode: kterminalSource.wrapMode

            visible: false

            function restartBlurSource(){
                livetimer.restart();
            }

            Timer{
                id: livetimer
                running: true
                onTriggered: _blurredSourceEffect.live = false;
            }
            Connections{
                target: kterminal
                onImagePainted:{
                    _blurredSourceEffect.live = true;
                    livetimer.restart();
                }
            }
            // Restart blurred source settings change.
            Connections{
                target: appSettings
                onMotion_blurChanged: _blurredSourceEffect.restartBlurSource();
                onTerminalFontChanged: _blurredSourceEffect.restartBlurSource();
                onRasterizationChanged: _blurredSourceEffect.restartBlurSource();
            }
            Connections {
                target: kterminalScrollbar
                onOpacityChanged: _blurredSourceEffect.restartBlurSource();
            }
        }
    }

    Loader{
        id: blurredTerminalLoader

        width: kterminal.width * scaleTexture * appSettings.blur_quality
        height: kterminal.height * scaleTexture * appSettings.blur_quality
        active: mBlur !== 0
        asynchronous: true

        sourceComponent: ShaderEffect {
            property variant txt_source: kterminalSource
            property variant blurredSource: blurredSourceLoader.item
            property real blurCoefficient: (1.0 - motionBlurCoefficient)

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
                    "vec3 origColor = texture2D(txt_source, coords).rgb;" +
                    "vec3 blur_color = texture2D(blurredSource, coords).rgb * (1.0 - blurCoefficient);" +
                    "vec3 color = min(origColor + blur_color, max(origColor, blur_color));" +

                    "gl_FragColor = vec4(color, step(0.02, rgb2grey(color - origColor)));" +
                "}"

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }
}
