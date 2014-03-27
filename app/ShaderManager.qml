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

ShaderEffect {
    property color font_color: shadersettings.font_color
    property color background_color: shadersettings.background_color
    property variant source: theSource
    property variant bloomSource: bloomSource
    property size txt_Size: Qt.size(terminal.width, terminal.height)
    property real time: 0

    property real bloom: shadersettings.bloom_strength

    property real noise_strength: shadersettings.noise_strength
    property real screen_distorsion: shadersettings.screen_distortion
    property real glowing_line_strength: shadersettings.glowing_line_strength

    property real scanlines: shadersettings.scanlines ? 1.0 : 0.0

    //Manage brightness (the function might be improved)
    property real screen_flickering: shadersettings.screen_flickering
    property real _A: 0.4 + Math.random() * 0.4
    property real _B: 0.2 + Math.random() * 0.4
    property real _C: 1.2 - _A - _B
    property real a: (0.0 + Math.random() * 0.4) * 0.05
    property real b: (0.1 + Math.random() * 0.4) * 0.05
    property real c: (0.4 + Math.random() * 0.4) * 0.05

    property real randval: (_A * Math.cos(a * time + _B) +
                            _B * Math.sin(b * time + _C) +
                            _C * Math.cos(c * time + _A))

    property real brightness: screen_flickering * randval
    property real horizontal_sincronization: shadersettings.horizontal_sincronization
    property real _neg_sinc: 1 - horizontal_sincronization
    property real horizontal_distortion: randval > (_neg_sinc) ? (randval - _neg_sinc) * horizontal_sincronization : 0

    property real deltay: 3 / terminal.height
    property real deltax: 3 / terminal.width

    //Blurred texture used for bloom
    Loader{
        anchors.fill: parent
        active: bloom !== 0
        FastBlur{
            radius: 32
            anchors.fill: parent
            source: theSource
            transparentBorder: true
            ShaderEffectSource{
                id: bloomSource
                sourceItem: parent
                hideSource: true
            }
        }
    }

    Timer{
        id: timetimer
        onTriggered: time += interval
        interval: 16
        running: true
        repeat: true
    }

    fragmentShader: "
            uniform sampler2D source;
            uniform highp float qt_Opacity;
            uniform highp float time;
            uniform highp vec2 txt_Size;
            varying highp vec2 qt_TexCoord0;

            uniform highp vec4 font_color;
            uniform highp vec4 background_color;
            uniform highp float deltax;
            uniform highp float deltay;" +

    (bloom !== 0 ? "uniform highp sampler2D bloomSource;" : "") +
    (noise_strength !== 0 ? "uniform highp float noise_strength;" : "") +
    (screen_distorsion !== 0 ? "uniform highp float screen_distorsion;" : "")+
    (glowing_line_strength !== 0 ? "uniform highp float glowing_line_strength;" : "")+
    "uniform lowp float brightness;" +

    (scanlines != 0 ? "uniform highp float scanlines;" : "") +

    (shadersettings.screen_flickering !== 0 ? "uniform highp float horizontal_distortion;" : "") +


            "highp float rand(vec2 co)
            {
                highp float a = 12.9898;
                highp float b = 78.233;
                highp float c = 43758.5453;
                highp float dt= dot(co.xy ,vec2(a,b));
                highp float sn= mod(dt,3.14);
                return fract(sin(sn) * c);
            }

            float stepNoise(vec2 p){
                vec2 newP = p * txt_Size*0.5;
                return rand(floor(newP) + fract(time / 100.0));
            }

            float getScanlineIntensity(vec2 pos){
                return abs(sin(pos.y * txt_Size.y)) * 0.5 + 0.5;
            }" +


    (glowing_line_strength !== 0 ?
    "float randomPass(vec2 coords){
                return fract(smoothstep(-0.2, 0.0, coords.y - 3.0 * fract(time * 0.0001))) * glowing_line_strength;
            }" : "") +


    "void main() {" +
    "vec2 cc = vec2(0.5) - qt_TexCoord0;" +
    "float distance = length(cc);" +

    (screen_distorsion !== 0 ?
    "float distortion = dot(cc, cc) * screen_distorsion;
                 vec2 coords = (qt_TexCoord0 - cc * (1.0 + distortion) * distortion);"
    :"vec2 coords = qt_TexCoord0;") +

    (shadersettings.horizontal_sincronization !== 0 ?
    "float h_distortion = 0.5 * sin(time*0.001 + coords.y*10.0*fract(time/10.0));
                h_distortion += 0.5 * cos(time*0.04 + 0.03 + coords.y*50.0*fract(time/10.0 + 0.4));
                coords.x = coords.x + h_distortion * 0.3 * horizontal_distortion;" +
    (noise_strength ? "noise_strength += horizontal_distortion * 0.5;" : "")
    : "") +

    "float color = texture2D(source, coords).r;" +

    (bloom !== 0 ? "color += texture2D(bloomSource, coords).r *" + 2.5 * bloom + ";" : "") +

    (scanlines !== 0 ?
    "float scanline_alpha = getScanlineIntensity(coords);" : "float scanline_alpha = 1.0;") +

    (noise_strength !== 0 ?
    "color += stepNoise(coords) * noise_strength * (1.0 - distance * distance * 2.0);" : "") +

    (glowing_line_strength !== 0 ?
    "color += randomPass(coords) * glowing_line_strength;" : "") +

    "vec3 finalColor = mix(background_color, font_color, color * scanline_alpha).rgb;" +
    "finalColor = mix(finalColor * 1.1, vec3(0.0), 1.2 * distance * distance);" +

    (screen_flickering !== 0 ?
    "finalColor = mix(finalColor, vec3(0.0), brightness);" : "") +
    "gl_FragColor = vec4(finalColor, 1.0);
            }"
}
