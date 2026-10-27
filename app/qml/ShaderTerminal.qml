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

import QtQuick 2.2

import "utils.js" as Utils

Item {
    id: shaderTerminal

    function dynamicFragmentPath() {
        var rasterMode = profile.rasterization;
        var burnInOn = profile.burnIn > 0 ? 1 : 0;
        var frameOn = profile.frameEnabled ? 1 : 0;
        var chromaOn = profile.chromaColor > 0 ? 1 : 0;
        return "qrc:/shaders/terminal_dynamic_raster" + rasterMode +
               "_burn" + burnInOn +
               "_frame" + frameOn +
               "_chroma" + chromaOn +
               ".frag.qsb";
    }

    function staticFragmentPath() {
        var rgbShiftOn = profile.rgbShift > 0 ? 1 : 0;
        var bloomOn = profile.bloom > 0 ? 1 : 0;
        var curvatureOn = (profile.screenCurvature > 0 || profile.frameSize > 0) ? 1 : 0;
        var shineOn = profile.frameShininess > 0 ? 1 : 0;
        return "qrc:/shaders/terminal_static_rgb" + rgbShiftOn +
               "_bloom" + bloomOn +
               "_curve" + curvatureOn +
               "_shine" + shineOn +
               ".frag.qsb";
    }

    property TerminalProfile profile
    property ShaderEffectSource source
    property BurnInEffect burnInEffect
    property ShaderEffectSource bloomSource

    property color fontColor: profile.fontColor
    property color backgroundColor: profile.backgroundColor

    // Effects are sized relative to this terminal, which can be a pane smaller than the window.
    property real normalizedScale: 1024 / Math.max(1, 0.5 * width + 0.5 * height)

    property real screenCurvature: profile.screenCurvature * appSettings.screenCurvatureSize * normalizedScale
    property real frameSize: profile.frameSize * normalizedScale

    property real chromaColor: profile.chromaColor

    property real ambientLight: profile.ambientLight * 0.2

    property size virtualResolution
    property size screenResolution

    property real _screenDensity: Math.min(
        screenResolution.width / virtualResolution.width,
        screenResolution.height / virtualResolution.height
    )

    ShaderEffect {
        id: dynamicShader

        property ShaderEffectSource screenBuffer: frameBuffer
        property ShaderEffectSource burnInSource: burnInEffect.effectSource
        property ShaderEffectSource frameSource: terminalFrameLoader.item

        property color fontColor: parent.fontColor
        property color backgroundColor: parent.backgroundColor
        property real screenCurvature: parent.screenCurvature
        property real chromaColor: parent.chromaColor
        property real ambientLight: parent.ambientLight

        property real flickering: profile.flickering
        property real horizontalSync: profile.horizontalSync
        property real horizontalSyncStrength: Utils.lint(0.05, 0.35, horizontalSync)
        property real glowingLine: profile.glowingLine * 0.2

        // Fast burnin properties
        property real burnIn: profile.burnIn
        property real burnInLastUpdate: burnInEffect.lastUpdate
        property real burnInTime: burnInEffect.burnInFadeTime

        property real jitter: profile.jitter
        property size jitterDisplacement: Qt.size(0.007 * jitter, 0.002 * jitter)
        property real staticNoise: profile.staticNoise
        property size scaleNoiseSize: Qt.size((width * 0.75) / (noiseTexture.width * appSettings.windowScaling * appSettings.totalFontScaling),
                                              (height * 0.75) / (noiseTexture.height * appSettings.windowScaling * appSettings.totalFontScaling))

        property size virtualResolution: parent.virtualResolution

        // Rasterization might display oversamping issues if virtual resolution is close to physical display resolution.
        // We progressively disable rasterization from 4x up to 2x resolution.
        property real rasterizationIntensity: Utils.smoothstep(2.0, 4.0, _screenDensity)

        property real time: timeManager ? timeManager.time : 0
        property ShaderEffectSource noiseSource: noiseShaderSource

        property real frameSize: parent.frameSize
        property real frameShininess: profile.frameShininess
        property real bloom: parent.bloomSource ? profile.bloom * 2.5 : 0

        anchors.fill: parent
        blending: false

        Image {
            id: noiseTexture
            source: "images/allNoise512.png"
            width: 512
            height: 512
            fillMode: Image.Tile
            visible: false
        }
        ShaderEffectSource {
            id: noiseShaderSource
            sourceItem: noiseTexture
            wrapMode: ShaderEffectSource.Repeat
            visible: false
            smooth: true
        }

        vertexShader: "qrc:/shaders/terminal_dynamic.vert.qsb"
        fragmentShader: dynamicFragmentPath()

        onStatusChanged: if (log) console.log(log)
    }

    Loader {
        id: terminalFrameLoader

        active: profile.frameEnabled

        width: staticShader.width
        height: staticShader.height

        sourceComponent: ShaderEffectSource {

            sourceItem: terminalFrame
            hideSource: true
            visible: false
            format: ShaderEffectSource.RGBA

            TerminalFrame {
                id: terminalFrame
                blending: false
                anchors.fill: parent
                normalizedScale: shaderTerminal.normalizedScale
                profile: shaderTerminal.profile
            }
        }
    }

    ShaderEffect {
        id: staticShader

        width: parent.width * appSettings.windowScaling
        height: parent.height * appSettings.windowScaling

        property ShaderEffectSource source: parent.source
        property ShaderEffectSource bloomSource: parent.bloomSource

        property color fontColor: parent.fontColor
        property color backgroundColor: parent.backgroundColor
        property real bloom: bloomSource ? profile.bloom * 2.5 : 0

        property real screenCurvature: parent.screenCurvature

        property real chromaColor: profile.chromaColor;

        property real rgbShift: profile.rgbShift * (4.0 / width) * appSettings.totalFontScaling

        property real screen_brightness: Utils.lint(0.5, 1.5, profile.brightness)
        property real frameShininess: profile.frameShininess
        property real frameSize: parent.frameSize

        blending: false
        visible: false

        vertexShader: "qrc:/shaders/terminal_static.vert.qsb"
        fragmentShader: staticFragmentPath()

        onStatusChanged: if (log) console.log(log)
    }

    ShaderEffectSource {
        id: frameBuffer
        visible: false
        sourceItem: staticShader
        hideSource: true
    }
}
