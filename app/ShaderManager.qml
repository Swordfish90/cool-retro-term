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

ShaderEffect {
    property color font_color: shadersettings.font_color
    property color background_color: shadersettings.background_color
    property variant source: terminal.theSource
    property variant bloomSource: terminal.bloomSource
    property variant rasterizationSource: terminal.rasterizationSource
    property variant noiseSource: terminal.staticNoiseSource
    property size txt_Size: Qt.size(frame.sourceRect.width, frame.sourceRect.height)
    property real bloom: shadersettings.bloom_strength

    property int rasterization: shadersettings.rasterization
    property real rasterization_strength: 0.5

    property real noise_strength: shadersettings.noise_strength
    property real screen_distorsion: shadersettings.screen_distortion
    property real glowing_line_strength: shadersettings.glowing_line_strength

    property real brightness_flickering: shadersettings.brightness_flickering
    property real horizontal_sincronization: shadersettings.horizontal_sincronization

    property bool frame_reflection_strength: shadersettings.frame_reflection_strength

    property real disp_top: frame.item.displacementTop * shadersettings.window_scaling
    property real disp_bottom: frame.item.displacementBottom * shadersettings.window_scaling
    property real disp_left: frame.item.displacementLeft * shadersettings.window_scaling
    property real disp_right: frame.item.displacementRight * shadersettings.window_scaling

    property real brightness: shadersettings.brightness * 1.5 + 0.5

    property real time: timetimer.time
    property variant randomFunctionSource: randfuncsource

    blending: false

    function str(num){
        return num.toFixed(8);
    }

    vertexShader: "
        uniform highp mat4 qt_Matrix;
        uniform highp float time;
        uniform sampler2D randomFunctionSource;
        uniform highp vec2 txt_Size;

        attribute highp vec4 qt_Vertex;
        attribute highp vec2 qt_MultiTexCoord0;

        varying highp vec2 qt_TexCoord0;" +

        (brightness_flickering !== 0.0 ?"
            varying lowp float brightness;" : "") +
        (horizontal_sincronization !== 0.0 ?"
            varying lowp float horizontal_distortion;" : "") +
        "
        void main() {
            qt_TexCoord0.x = -"+str(disp_left)+"/txt_Size.x + qt_MultiTexCoord0.x / ((txt_Size.x -("+str(disp_left+disp_right)+")) / txt_Size.x);" + "
            qt_TexCoord0.y = -"+str(disp_top)+"/txt_Size.y + qt_MultiTexCoord0.y / ((txt_Size.y -("+str(disp_top+disp_bottom)+")) / txt_Size.y);" + "
            vec2 coords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0)));" +
            (brightness_flickering !== 0.0 ? "
                brightness = 1.0 + (texture2D(randomFunctionSource, coords).g - 0.5) * "+str(brightness_flickering)+";"
            :   "") +

            (horizontal_sincronization !== 0.0 ? "
                float randval = 1.5 * texture2D(randomFunctionSource,(vec2(1.0) -coords) * 0.5).g;
                float negsinc = 1.0 - "+str(0.6*horizontal_sincronization)+";
                horizontal_distortion = step(negsinc, randval) * (randval - negsinc) * "+str(0.3*horizontal_sincronization)+";"
            : "") +

            "gl_Position = qt_Matrix * qt_Vertex;
        }"

    fragmentShader: "
        uniform sampler2D source;
        uniform highp float qt_Opacity;
        uniform highp float time;
        uniform highp vec2 txt_Size;
        varying highp vec2 qt_TexCoord0;

        uniform highp vec4 font_color;
        uniform highp vec4 background_color;
        uniform highp sampler2D rasterizationSource;" +

        (bloom !== 0 ? "
            uniform highp sampler2D bloomSource;" : "") +
        (noise_strength !== 0 ? "
            uniform highp float noise_strength;
            uniform lowp sampler2D noiseSource;" : "") +
        (screen_distorsion !== 0 ? "
            uniform highp float screen_distorsion;" : "")+
        (glowing_line_strength !== 0 ? "
            uniform highp float glowing_line_strength;" : "")+
        (brightness_flickering !== 0 ? "
            varying lowp float brightness;" : "") +
        (horizontal_sincronization !== 0 ? "
            varying lowp float horizontal_distortion;" : "") +

        (glowing_line_strength !== 0 ? "
            float randomPass(vec2 coords){
                return fract(smoothstep(-0.2, 0.0, coords.y - 3.0 * fract(time * 0.0001))) * glowing_line_strength;
            }" : "") +


        "void main() {" +
            "vec2 cc = vec2(0.5) - qt_TexCoord0;" +
            "float distance = length(cc);" +

            (noise_strength ? "
                float noise = noise_strength;" : "") +

            (screen_distorsion !== 0 ? "
                float distortion = dot(cc, cc) * screen_distorsion;
                vec2 coords = (qt_TexCoord0 - cc * (1.0 + distortion) * distortion);"
            :"
                vec2 coords = qt_TexCoord0;") +

            (frame_reflection_strength ? "
                vec2 inside = step(0.0, coords) - step(1.0, coords);
                coords = abs(mod(floor(coords), 2.0) - fract(coords)) * clamp(inside.x + inside.y, 0.0, 1.0);" : "") +

            (horizontal_sincronization !== 0 ? "
                float h_distortion = 0.5 * sin(time*0.001 + coords.y*10.0*fract(time/10.0));
                h_distortion += 0.5 * cos(time*0.04 + 0.03 + coords.y*50.0*fract(time/10.0 + 0.4));
                coords.x = coords.x + h_distortion * horizontal_distortion;" +
                (noise_strength ? "
                    noise += horizontal_distortion;" : "")
            : "") +

            "float color = texture2D(source, coords).a;" +

            (noise_strength !== 0 ? "
                color += texture2D(noiseSource, qt_TexCoord0 * 0.25 + fract(time / 100.0)).a * noise * (1.0 - distance * distance * 2.0);" : "") +

            (glowing_line_strength !== 0 ? "
                color += randomPass(coords) * glowing_line_strength;" : "") +

            (bloom !== 0 ? "
                color += texture2D(bloomSource, coords).r *" + str(2.5 * bloom) + ";" : "") +

            "vec3 finalColor = mix(background_color, font_color, color).rgb;" +
            "finalColor = mix(finalColor * 1.1, vec3(0.0), 1.2 * distance * distance);" +
            "finalColor *= (texture2D(rasterizationSource, coords).a) / "+rasterization_strength+";" +

            (brightness_flickering !== 0 ? "
                finalColor *= brightness;" : "") +

            "gl_FragColor = vec4(finalColor *"+str(brightness)+", qt_Opacity);
        }"

     onStatusChanged: if (log) console.log(log) //Print warning messages
}
