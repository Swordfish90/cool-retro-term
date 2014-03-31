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

import QtQuick 2.0
import QtGraphicalEffects 1.0

import org.kde.konsole 0.1

Item{
    id: terminalContainer
    property real mBloom: shadersettings.bloom_strength
    property real mBlur: shadersettings.motion_blur
    property real scanlines: shadersettings.scanlines
    property real motionBlurCoefficient: (_minBlurCoefficient)*mBlur + (_maxBlurCoefficient)*(1.0-mBlur)
    property real _minBlurCoefficient: 0.015
    property real _maxBlurCoefficient: 0.10
    anchors.fill: parent

    //Force reload of the blursource when settings change
    onScanlinesChanged: restartBlurredSource()
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

    Loader{
        id: kterminal
        active: false
        anchors.fill: parent

        sourceComponent: KTerminal {
            id: ktermitem
            font.pointSize: shadersettings.fontSize
            font.family: shadersettings.font.name

            colorScheme: "MyWhiteOnBlack"

            session: KSession {
                id: ksession
                kbScheme: "linux"

                onFinished: {
                    Qt.quit()
                }
            }

            onUpdatedImage: {blurredSource.live = true;livetimer.restart();}

            Component.onCompleted: {
                font.pointSize = shadersettings.fontSize;
                font.family = shadersettings.font.name;
                forceActiveFocus();
            }
        }
    }
    MouseArea{
        acceptedButtons: Qt.NoButton
        anchors.fill: parent
        onWheel:
            wheel.angleDelta.y > 0 ? kterminal.item.scrollUp() : kterminal.item.scrollDown()
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

            "float getScanlineIntensity(vec2 coord){
                float h = coord.y * txt_size.y * 0.5;
                return step(0.5, fract(h));
            }" +

            (mBlur !== 0 ?
                 "uniform lowp sampler2D blurredSource;"
            : "") +

            "void main() {" +
                "float color = texture2D(source, qt_TexCoord0).r * 0.8 * 512.0;" +

                (mBlur !== 0 ?
                     "float blurredSourceColor = texture2D(blurredSource, qt_TexCoord0).r * 512.0;" +
                     "color = mix(blurredSourceColor, color, " + motionBlurCoefficient + ");"
                : "") +

                (scanlines !== 0 ? "
                    color = mix(color, 1.0 * color*getScanlineIntensity(qt_TexCoord0), "+scanlines+");"
                : "") +

                "gl_FragColor = vec4(vec3(floor(color) / 512.0), 1.0);" +
            "}"
    }
}
