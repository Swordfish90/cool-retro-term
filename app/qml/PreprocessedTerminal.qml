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

import "utils.js" as Utils

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

    anchors.leftMargin: frame.displacementLeft * appSettings.windowScaling
    anchors.rightMargin: frame.displacementRight * appSettings.windowScaling
    anchors.topMargin: frame.displacementTop * appSettings.windowScaling
    anchors.bottomMargin: frame.displacementBottom * appSettings.windowScaling

    //Parameters for the burnIn effect.
    property real burnIn: appSettings.burnIn
    property real fps: appSettings.fps !== 0 ? appSettings.fps : 60
    property real burnInFadeTime: Utils.lint(_minBurnInFadeTime, _maxBurnInFadeTime, burnIn)
    property real motionBlurCoefficient: 1.0 / (fps * burnInFadeTime)
    property real _minBurnInFadeTime: 0.16
    property real _maxBurnInFadeTime: 1.6

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

        smooth: !appSettings.lowResolutionFont
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

        function handleFontChanged(fontFamily, pixelSize, lineSpacing, screenScaling, fontWidth) {
            kterminal.antialiasText = !appSettings.lowResolutionFont;
            font.pixelSize = pixelSize;
            font.family = fontFamily;

            terminalContainer.fontWidth = fontWidth;
            terminalContainer.screenScaling = screenScaling;
            scaleTexture = Math.max(1.0, Math.floor(screenScaling * appSettings.windowScaling));

            kterminal.lineSpacing = lineSpacing;
        }

        function startSession() {
            appSettings.initializedSettings.disconnect(startSession);

            // Retrieve the variable set in main.cpp if arguments are passed.
            if (defaultCmd) {
                ksession.setShellProgram(defaultCmd);
                ksession.setArgs(defaultCmdArgs);
            } else if (appSettings.useCustomCommand) {
                var args = Utils.tokenizeCommandLine(appSettings.customCommand);
                ksession.setShellProgram(args[0]);
                ksession.setArgs(args.slice(1));
            } else if (!defaultCmd && Qt.platform.os === "osx") {
                // OSX Requires the following default parameters for auto login.
                ksession.setArgs(["-i", "-l"]);
            }

            if (workdir)
                ksession.initialWorkingDirectory = workdir;

            ksession.startShellProgram();
            forceActiveFocus();
        }
        Component.onCompleted: {
            appSettings.terminalFontChanged.connect(handleFontChanged);
            appSettings.initializedSettings.connect(startSession);
        }
    }
    Component {
        id: linuxContextMenu
        Menu{
            id: contextmenu
            MenuItem{action: copyAction}
            MenuItem{action: pasteAction}
            MenuSeparator{}
            MenuItem{action: fullscreenAction}
            MenuItem{action: showMenubarAction}
            MenuSeparator{visible: !appSettings.showMenubar}
            CRTMainMenuBar{visible: !appSettings.showMenubar}
        }
    }
    Component {
        id: osxContextMenu
        Menu{
            id: contextmenu
            MenuItem{action: copyAction}
            MenuItem{action: pasteAction}
        }
    }
    Loader {
        id: menuLoader
        sourceComponent: (Qt.platform.os === "osx" ? osxContextMenu : linuxContextMenu)
    }
    property alias contextmenu: menuLoader.item

    MouseArea{
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        anchors.fill: parent
        cursorShape: kterminal.terminalUsesMouse ? Qt.ArrowCursor : Qt.IBeamCursor
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
            var distortion = (cc.height * cc.height + cc.width * cc.width) * appSettings.screenCurvature;

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
        active: burnIn !== 0

        sourceComponent: ShaderEffectSource{
            property bool updateBurnIn: false

            id: _blurredSourceEffect
            sourceItem: blurredTerminalLoader.item
            recursive: true
            live: false
            hideSource: true
            wrapMode: kterminalSource.wrapMode

            visible: false

            function restartBlurSource(){
                livetimer.restart();
            }

            // This updates the burnin synched with the timer.
            Connections {
                target: updateBurnIn ? mainShader : null
                ignoreUnknownSignals: false
                onTimeChanged: _blurredSourceEffect.scheduleUpdate();
            }

            Timer{
                id: livetimer

                // The interval assumes 60 fps. This is the time needed burnout a white pixel.
                // We multiply 1.1 to have a little bit of margin over the theoretical value.
                // This solution is not extremely clean, but it's probably the best to avoid measuring fps.

                interval: burnInFadeTime * 1000 * 1.1
                running: true
                onTriggered: _blurredSourceEffect.updateBurnIn = false;
            }
            Connections{
                target: kterminal
                onImagePainted:{
                    _blurredSourceEffect.scheduleUpdate();
                    _blurredSourceEffect.updateBurnIn = true;
                    livetimer.restart();
                }
            }
            // Restart blurred source settings change.
            Connections{
                target: appSettings
                onBurnInChanged: _blurredSourceEffect.restartBlurSource();
                onTerminalFontChanged: _blurredSourceEffect.restartBlurSource();
                onRasterizationChanged: _blurredSourceEffect.restartBlurSource();
                onBurnInQualityChanged: _blurredSourceEffect.restartBlurSource();
            }
            Connections {
                target: kterminalScrollbar
                onOpacityChanged: _blurredSourceEffect.restartBlurSource();
            }
        }
    }

    Loader{
        id: blurredTerminalLoader

        property int burnInScaling: scaleTexture * appSettings.burnInQuality

        width: appSettings.lowResolutionFont
                  ? kterminal.width * Math.max(1, burnInScaling)
                  : kterminal.width * scaleTexture * appSettings.burnInQuality
        height: appSettings.lowResolutionFont
                    ? kterminal.height * Math.max(1, burnInScaling)
                    : kterminal.height * scaleTexture * appSettings.burnInQuality

        active: burnIn !== 0
        asynchronous: true

        sourceComponent: ShaderEffect {
            property variant txt_source: kterminalSource
            property variant blurredSource: blurredSourceLoader.item
            property real blurCoefficient: motionBlurCoefficient

            blending: false

            fragmentShader:
                "#ifdef GL_ES
                    precision mediump float;
                #endif\n" +

                "uniform lowp float qt_Opacity;" +
                "uniform lowp sampler2D txt_source;" +

                "varying highp vec2 qt_TexCoord0;

                 uniform lowp sampler2D blurredSource;
                 uniform highp float blurCoefficient;" +

                "float max3(vec3 v) {
                     return max (max (v.x, v.y), v.z);
                }" +

                "void main() {" +
                    "vec2 coords = qt_TexCoord0;" +
                    "vec3 origColor = texture2D(txt_source, coords).rgb;" +
                    "vec3 blur_color = texture2D(blurredSource, coords).rgb - vec3(blurCoefficient);" +
                    "vec3 color = min(origColor + blur_color, max(origColor, blur_color));" +

                    "gl_FragColor = vec4(color, max3(color - origColor));" +
                "}"

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }
}
