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
    property color _staticFrameColor: "#fff"
    property color _backgroundColor: appSettings.backgroundColor
    property color _fontColor: appSettings.fontColor
    property color _lightColor: Utils.mix(_fontColor, _backgroundColor, 0.2)
    property real _ambientLight: Utils.lint(0.2, 0.8, appSettings.ambientLight)

    property color frameColor: Utils.mix(_staticFrameColor, _lightColor, _ambientLight)
    property real screenCurvature: appSettings.screenCurvature * appSettings.screenCurvatureSize

    // Coefficient of the log curve used to approximate shadowing
    property real screenShadowCoeff: Utils.lint(20.0, 10.0, _ambientLight)
    property real frameShadowCoeff: Utils.lint(20.0, 10.0, _ambientLight)

    property size margin: Qt.size(
        appSettings.frameMargin / width * appSettings.windowScaling,
        appSettings.frameMargin / height * appSettings.windowScaling
    )

    ShaderLibrary {
        id: shaderLibrary
    }

    fragmentShader: "
        #ifdef GL_ES
            precision mediump float;
        #endif

        uniform lowp float screenCurvature;
        uniform lowp float screenShadowCoeff;
        uniform lowp float frameShadowCoeff;
        uniform highp float qt_Opacity;
        uniform lowp vec4 frameColor;
        uniform mediump vec2 margin;

        varying highp vec2 qt_TexCoord0;

        vec2 distortCoordinates(vec2 coords){
            vec2 cc = (coords - vec2(0.5));
            float dist = dot(cc, cc) * screenCurvature;
            return (coords + cc * (1.0 + dist) * dist);
        }
        " +

        shaderLibrary.max2 +
        shaderLibrary.min2 +
        shaderLibrary.prod2 +
        shaderLibrary.sum2 +

        "

        vec2 positiveLog(vec2 x) {
            return clamp(log(x), vec2(0.0), vec2(100.0));
        }

        void main() {
            vec2 staticCoords = qt_TexCoord0;
            vec2 coords = distortCoordinates(staticCoords) * (vec2(1.0) + margin * 2.0) - margin;

            vec2 vignetteCoords = staticCoords * (1.0 - staticCoords.yx);
            float vignette = pow(prod2(vignetteCoords) * 15.0, 0.25);

            vec3 color = frameColor.rgb * vec3(1.0 - vignette);
            float alpha = 0.0;

            float frameShadow = max2(positiveLog(-coords * frameShadowCoeff + vec2(1.0)) + positiveLog(coords * frameShadowCoeff - (vec2(frameShadowCoeff) - vec2(1.0))));
            frameShadow = max(sqrt(frameShadow), 0.0);
            color *= frameShadow;
            alpha = sum2(1.0 - step(vec2(0.0), coords) + step(vec2(1.0), coords));
            alpha = clamp(alpha, 0.0, 1.0);
            alpha *= mix(1.0, 0.9, frameShadow);

            float screenShadow = 1.0 - prod2(positiveLog(coords * screenShadowCoeff + vec2(1.0)) * positiveLog(-coords * screenShadowCoeff + vec2(screenShadowCoeff + 1.0)));
            alpha = max(0.8 * screenShadow, alpha);

            gl_FragColor = vec4(color * alpha, alpha);
        }
    "

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
