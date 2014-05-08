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
    //The blur effect has to take into account the framerate
    property real fpsAttenuation: shadersettings.fps / 60
    property real mBlur: shadersettings.motion_blur
    property real motionBlurCoefficient: ((_minBlurCoefficient)*mBlur + (_maxBlurCoefficient)*(1.0-mBlur)) / fpsAttenuation
    property real _minBlurCoefficient: 0.015
    property real _maxBlurCoefficient: 0.10

    property real mBloom: shadersettings.bloom_strength

    property size terminalSize

    //Force reload of the blursource when settings change
    onMBloomChanged: restartBlurredSource()

    function restartBlurredSource(){
        if(!blurredSource) return;

        blurredSource.live = true;
        livetimer.restart()
    }
    function loadKTerminal(){
        kterminal.active = true;
    }
    function unloadKTerminal(){
        kterminal.active = false;
    }
    function pasteClipboard(){
        kterminal.item.pasteClipboard();
    }
    function copyClipboard(){
        kterminal.item.copyClipboard();
    }

    Loader{
        id: kterminal
        active: false
        anchors.fill: parent

        sourceComponent: KTerminal {
            id: ktermitem
            font.pointSize: shadersettings.fontSize
            font.family: shadersettings.font.name

            colorScheme: "MyWhiteOnBlack"

            onTerminalSizeChanged: terminalContainer.terminalSize = ktermitem.terminalSize

            session: KSession {
                id: ksession
                kbScheme: "linux"

                onFinished: {
                    Qt.quit()
                }
            }

            onUpdatedImage: {blurredSource.live = true;livetimer.restart();}

            Component.onCompleted: {
                var scaling_factor = shadersettings.font_scaling * shadersettings.window_scaling;
                var font_size = shadersettings.font.pixelSize * scaling_factor;
                var line_spacing = Math.round(shadersettings.font.lineSpacing * font_size);
                font.pointSize = font_size;
                font.family = shadersettings.font.name;
                setLineSpacing(line_spacing);
                forceActiveFocus();
            }
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
            wheel.angleDelta.y > 0 ? kterminal.item.scrollUp() : kterminal.item.scrollDown()
        onClicked: {
            if (mouse.button == Qt.RightButton){
                contextmenu.popup();
            } else if (mouse.button == Qt.MiddleButton){
                kterminal.item.pasteSelection();
            }
        }
        onDoubleClicked: {
            if (mouse.button == Qt.LeftButton){
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.item.mouseDoubleClick(coord.width, coord.height);
            }
        }
        onPositionChanged: {
            var coord = correctDistortion(mouse.x, mouse.y);
            kterminal.item.mouseMove(coord.width, coord.height);
        }
        onPressed: {
            if (mouse.button == Qt.LeftButton){
                var coord = correctDistortion(mouse.x, mouse.y);
                kterminal.item.mousePress(coord.width, coord.height);
            }
        }
        onReleased: {
            if (mouse.button == Qt.LeftButton){
                kterminal.item.mouseRelease(mouse.x, mouse.y);
            }
        }

        function correctDistortion(x, y){
            x = x / width;
            y = y / height;

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
    }
    Loader{
        anchors.fill: parent
        active: mBlur !== 0
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
            }
        }
    }
    ShaderEffect {
        id: blurredterminal
        anchors.fill: parent
        property variant source: source
        property variant blurredSource: (mBlur !== 0) ? blurredSource : undefined
        property size txt_size: Qt.size(width, height)

        z: 2

        fragmentShader:
            "uniform lowp float qt_Opacity;" +
            "uniform lowp sampler2D source;" +
            "uniform lowp vec2 txt_size;" +

            "varying highp vec2 qt_TexCoord0;" +

            (mBlur !== 0 ?
                 "uniform lowp sampler2D blurredSource;"
            : "") +

            "void main() {" +
                "float color = texture2D(source, qt_TexCoord0).r * 0.8 * 512.0;" +

                (mBlur !== 0 ?
                     "float blurredSourceColor = texture2D(blurredSource, qt_TexCoord0).r * 512.0;" +
                     "color = mix(blurredSourceColor, color, " + motionBlurCoefficient + ");"
                : "") +


                "gl_FragColor = vec4(vec3(floor(color) / 512.0), 1.0);" +
            "}"
    }
}
