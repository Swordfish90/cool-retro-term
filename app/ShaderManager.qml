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

ShaderEffect {
    property color font_color: shadersettings.font_color
    property color background_color: shadersettings.background_color
    property variant source: theSource
    property size txt_Size: Qt.size(terminal.width, terminal.height)
    property real time: 0

    property real noise_strength: shadersettings.noise_strength
    property real screen_distorsion: shadersettings.screen_distortion
    property real glowing_line_strength: shadersettings.glowing_line_strength
    property real brightness: 1.0

    property real scanlines: shadersettings.scanlines ? 1.0 : 0.0

    Behavior on brightness {
        NumberAnimation{
            duration: 250
            onRunningChanged:
                if(!running) shadercontainer.brightness = 1.0;
        }
    }

    Behavior on horizontal_distortion {
        NumberAnimation{
            duration: 150
            onRunningChanged:
                if(!running) shadercontainer.horizontal_distortion = 0.0;
        }
    }

    Loader{
        active: shadersettings.screen_flickering !== 0
        sourceComponent: Timer{
            property real randval
            id: flickertimer
            interval: 500
            onTriggered: {
                randval = Math.random();
                if(randval < shadersettings.screen_flickering){
                    shadercontainer.horizontal_distortion = Math.random() * shadersettings.screen_flickering;
                }
                randval = Math.random();
                if(randval < shadersettings.screen_flickering)
                    shadercontainer.brightness = Math.random() * 0.5 + 0.5;
            }

            repeat: true
            running: true
        }
    }

    property real deltay: 3 / terminal.height
    property real deltax: 3 / terminal.width
    property real horizontal_distortion: 0.0
    //property real faulty_screen_prob: shadersettings.faulty_screen_prob

    NumberAnimation on time{
        from: -1
        to: 100
        duration: 5000

        loops: Animation.Infinite
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

            (noise_strength !== 0 ? "uniform highp float noise_strength;" : "") +
            (screen_distorsion !== 0 ? "uniform highp float screen_distorsion;" : "")+
            (glowing_line_strength !== 0 ? "uniform highp float glowing_line_strength;" : "")+
            "uniform highp float brightness;" +

            (scanlines != 0 ? "uniform highp float scanlines;" : "") +

            (shadersettings.screen_flickering !== 0 ? "uniform highp float horizontal_distortion;" : "") +

            "float rand(vec2 co, float time){
                return fract(sin(dot(co.xy ,vec2(0.37898 * time ,0.78233))) * 437.5875453);
            }

            float stepNoise(vec2 p){
                vec2 newP = p * txt_Size*0.25;
                return rand(floor(newP), time);
            }

            float getScanlineIntensity(vec2 pos){
                return abs(sin(pos.y * txt_Size.y)) * 0.5;
            }" +

            (screen_distorsion !== 0 ?
            "vec2 distortCoordinates(vec2 coords){
                vec2 cc = coords - vec2(0.5);
                float dist = dot(cc, cc) * screen_distorsion ;
                return (coords + cc * (1.0 + dist) * dist);
            }" : "") +

            (glowing_line_strength !== 0 ?
            "float randomPass(vec2 coords){
                return fract(smoothstep(-0.2, 0.0, coords.y - time * 0.03)) * glowing_line_strength;
            }" : "") +


            "void main() {" +
                (screen_distorsion !== 0 ? "vec2 coords = distortCoordinates(qt_TexCoord0);" : "vec2 coords = qt_TexCoord0;") +

                (horizontal_distortion !== 0 ?
                "float distortion = (sin(coords.y * 20.0 * fract(time * 0.1) + sin(fract(time * 0.2))) + sin(time * 0.05));
                coords.x = coords.x + distortion * 0.3 * horizontal_distortion; " : "") +

                "float color = texture2D(source, coords).r;" +

                (scanlines !== 0 ?
                "float scanline_alpha = getScanlineIntensity(coords);" : "float scanline_alpha = 0.0;") +

                (noise_strength !== 0 ?
                "color += stepNoise(coords) * noise_strength;" : "") +

                (glowing_line_strength !== 0 ?
                "color += randomPass(coords) * glowing_line_strength;" : "") +

                "vec3 finalColor = mix(background_color, font_color, color).rgb;
                finalColor = mix(finalColor, vec3(0.0), scanline_alpha);" +

                (brightness !== 1.0 ?
                "finalColor = finalColor * brightness;" : "") +

                "gl_FragColor = vec4(finalColor, 1.0);
            }"
}
