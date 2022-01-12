/*******************************************************************************
* Copyright (c) 2013-2021 "Filippo Scognamiglio"
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
import QtQuick 2.0

import "utils.js" as Utils

Loader {
    id: burnInEffect

    property ShaderEffectSource source: item ? item.source : null

    property real lastUpdate: 0
    property real prevLastUpdate: 0

    property real burnIn: appSettings.burnIn
    property real burnInFadeTime: 1 / Utils.lint(_minBurnInFadeTime, _maxBurnInFadeTime, burnIn)
    property real _minBurnInFadeTime: appSettings.minBurnInFadeTime
    property real _maxBurnInFadeTime: appSettings.maxBurnInFadeTime

    active: appSettings.burnIn !== 0

    anchors.fill: parent

    function completelyUpdate() {
        let newTime = timeManager.time
        if (newTime > lastUpdate) {
            prevLastUpdate = lastUpdate
            lastUpdate = newTime
        }

        item.source.scheduleUpdate()
    }

    function restartBlurSource() {
        prevLastUpdate = timeManager.time
        lastUpdate = prevLastUpdate
        completelyUpdate()
    }

    sourceComponent: Item {
        property alias source: burnInEffectSource

        ShaderEffectSource {
            id: burnInEffectSource

            anchors.fill: parent

            sourceItem: burnInShaderEffect
            live: false
            recursive: true
            hideSource: true
            wrapMode: ShaderEffectSource.ClampToEdge

            format: ShaderEffectSource.RGBA
            smooth: true

            visible: false

            Connections {
                target: kterminal

                onImagePainted: {
                    completelyUpdate()
                }
            }
            // Restart blurred source settings change.
            Connections {
                target: appSettings

                onBurnInChanged: {
                    burnInEffect.restartBlurSource()
                }

                onTerminalFontChanged: {
                    burnInEffect.restartBlurSource()
                }

                onRasterizationChanged: {
                    burnInEffect.restartBlurSource()
                }

                onBurnInQualityChanged: {
                    burnInEffect.restartBlurSource()
                }
            }
        }

        ShaderLibrary {
            id: shaderLibrary
        }

        ShaderEffect {
            id: burnInShaderEffect

            property variant txt_source: kterminalSource
            property variant burnInSource: burnInEffectSource
            property real burnInTime: burnInFadeTime
            property real lastUpdate: burnInEffect.lastUpdate
            property real prevLastUpdate: burnInEffect.prevLastUpdate

            anchors.fill: parent
            blending: false

            fragmentShader:
                "#ifdef GL_ES
                        precision mediump float;
                    #endif\n" +

                "uniform lowp float qt_Opacity;" +
                "uniform lowp sampler2D txt_source;" +

                "varying highp vec2 qt_TexCoord0;

                 uniform lowp sampler2D burnInSource;
                 uniform highp float burnInTime;

                 uniform highp float lastUpdate;

                 uniform highp float prevLastUpdate;" +

                shaderLibrary.rgb2grey +

                "void main() {
                    vec2 coords = qt_TexCoord0;

                    vec3 txtColor = texture2D(txt_source, coords).rgb;
                    vec4 accColor = texture2D(burnInSource, coords);

                    float prevMask = accColor.a;
                    float currMask = rgb2grey(txtColor);

                    highp float blurDecay = clamp((lastUpdate - prevLastUpdate) * burnInTime, 0.0, 1.0);
                    blurDecay = max(0.0, blurDecay - prevMask);
                    vec3 blurColor = accColor.rgb - vec3(blurDecay);
                    vec3 color = max(blurColor, txtColor);

                    gl_FragColor = vec4(color, currMask);
                }
            "

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }
}
