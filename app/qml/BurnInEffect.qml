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

        ShaderEffect {
            id: burnInShaderEffect

            property real time: timeManager.time

            property variant txt_source: kterminalSource
            property variant burnInSource: burnInEffectSource
            property real burnInTime: burnInFadeTime
            property real burnInLastUpdate: burnInEffect.lastUpdate
            property real prevLastUpdate: burnInEffect.prevLastUpdate

            anchors.fill: parent
            blending: false

            fragmentShader: "qrc:/shaders/burn_in.frag.qsb"
            vertexShader: "qrc:/shaders/burn_in.vert.qsb"

            onStatusChanged: if (log) console.log(log) //Print warning messages
        }
    }
}
