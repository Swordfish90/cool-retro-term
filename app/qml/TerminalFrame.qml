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

ShaderEffect {
    property color _staticFrameColor: Utils.sum(appSettings.frameColor, Qt.rgba(0.1, 0.1, 0.1, 1.0))
    property color _backgroundColor: appSettings.backgroundColor
    property color _fontColor: appSettings.fontColor
    property color _lightColor: Utils.mix(_fontColor, _backgroundColor, 0.2)
    property real _ambientLight: appSettings.ambientLight

    property color frameColor: Utils.sum(
        Utils.scaleColor(_staticFrameColor, 0.8 * _ambientLight),
        Utils.scaleColor(_lightColor, 0.2)
    )

    property real screenCurvature: appSettings.screenCurvature * appSettings.screenCurvatureSize

    // TODO FILIPPO... Get rid of those...
    // Coefficient of the log curve used to approximate shadowing
    property real frameShadowCoeff: 0.0125//Utils.lint(0.05, 0.025, _ambientLight)
    property real frameShininess: appSettings.frameShininess

    property real frameSize: appSettings.frameSize

    // Uniforms required by the shared block
    property real qt_Opacity: 1.0
    property real time: timeManager.time
    property color fontColor: appSettings.fontColor
    property color backgroundColor: appSettings.backgroundColor
    property real shadowLength: 0
    property size virtualResolution: Qt.size(width, height)
    property real rasterizationIntensity: 0
    property int rasterizationMode: 0
    property real burnInLastUpdate: 0
    property real burnInTime: 0
    property real burnIn: 0
    property real staticNoise: 0
    property real glowingLine: 0
    property real chromaColor: 0
    property size jitterDisplacement: Qt.size(0, 0)
    property real ambientLight: _ambientLight
    property real jitter: 0
    property real horizontalSync: 0
    property real horizontalSyncStrength: 0
    property real flickering: 0
    property real displayTerminalFrame: 0
    property size scaleNoiseSize: Qt.size(0, 0)
    property real screen_brightness: 1.0
    property real bloom: 0
    property real rbgShift: 0
    property real prevLastUpdate: 0

    vertexShader: "qrc:/shaders/passthrough.vert.qsb"
    fragmentShader: "qrc:/shaders/terminal_frame.frag.qsb"

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
