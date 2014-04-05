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
    property size txt_Size: Qt.size(width, height)

    property real bloom: shadersettings.bloom_strength

    property int rasterization: shadersettings.rasterization
    property real rasterization_strength: shadersettings.rasterization_strength

    property real noise_strength: shadersettings.noise_strength
    property real screen_distorsion: shadersettings.screen_distortion
    property real glowing_line_strength: shadersettings.glowing_line_strength

    property real brightness_flickering: shadersettings.brightness_flickering
    property real horizontal_sincronization: shadersettings.horizontal_sincronization

    property bool frame_reflection_strength: shadersettings.frame_reflection_strength
    property real disp_top: frame.item.displacementTop.toFixed(1)
    property real disp_bottom: frame.item.displacementBottom
    property real disp_left: frame.item.displacementLeft
    property real disp_right: frame.item.displacementRight

    property real brightness: shadersettings.brightness * 1.5 + 0.5

    property real deltay: 3 / parent.height
    property real deltax: 3 / parent.width

    property real time: timetimer.time
    property variant randomFunctionSource: randfuncsource

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

    vertexShader: "
                    uniform highp mat4 qt_Matrix;
                    uniform highp float time;
                    uniform sampler2D randomFunctionSource;
                    uniform highp vec2 txt_Size;

                    attribute highp vec4 qt_Vertex;
                    attribute highp vec2 qt_MultiTexCoord0;

                    varying highp vec2 originalCoord;
                    varying highp vec2 qt_TexCoord0;" +
                    (brightness_flickering !== 0.0 ?"
                        varying lowp float brightness;" : "") +
                    (horizontal_sincronization !== 0.0 ?"
                        varying lowp float horizontal_distortion;" : "") +
                    "
                    void main() {
                        originalCoord = qt_MultiTexCoord0;
                        qt_TexCoord0.x = -"+disp_left.toFixed(1)+"/txt_Size.x + qt_MultiTexCoord0.x / ((txt_Size.x -("+(disp_left+disp_right).toFixed(1)+")) / txt_Size.x);" +
                        "qt_TexCoord0.y = -"+disp_top.toFixed(1)+"/txt_Size.y + qt_MultiTexCoord0.y / ((txt_Size.y -("+(disp_top+disp_bottom).toFixed(1)+")) / txt_Size.y);" +
                        "vec2 coords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0*2.0)));" +
                        (brightness_flickering !== 0.0 ? "
                            brightness = texture2D(randomFunctionSource, coords).g * "+brightness_flickering+";"
                        :   "") +

                        (horizontal_sincronization !== 0.0 ? "
                            float randval = 1.5 * texture2D(randomFunctionSource,(vec2(1.0) -coords) * 0.5).g;
                            float negsinc = 1.0 - "+0.6*horizontal_sincronization+";
                            horizontal_distortion = step(negsinc, randval) * (randval - negsinc) * "+0.3*horizontal_sincronization+";"
                        : "") +
                        "gl_Position = qt_Matrix * qt_Vertex;
                    }"

    fragmentShader: "
            uniform sampler2D source;
            uniform highp float qt_Opacity;
            uniform highp float time;
            uniform highp vec2 txt_Size;
            varying highp vec2 qt_TexCoord0;
            varying highp vec2 originalCoord;

            uniform highp vec4 font_color;
            uniform highp vec4 background_color;
            uniform highp float deltax;
            uniform highp float deltay;" +

    (bloom !== 0 ? "
        uniform highp sampler2D bloomSource;" : "") +
    (noise_strength !== 0 ? "
        uniform highp float noise_strength;" : "") +
    (screen_distorsion !== 0 ? "
        uniform highp float screen_distorsion;" : "")+
    (glowing_line_strength !== 0 ? "
        uniform highp float glowing_line_strength;" : "")+
    (brightness_flickering !== 0 ? "
        varying lowp float brightness;" : "") +
    (horizontal_sincronization !== 0 ? "
        varying lowp float horizontal_distortion;" : "") +

    (rasterization !== shadersettings.no_rasterization ? "
    float getScanlineIntensity(vec2 coord){
        float result = step(0.4, fract(coord.y * txt_Size.y * 0.5));" +
        (rasterization === shadersettings.pixel_rasterization ? "
            result *= step(0.4, fract(coord.x * txt_Size.x * 0.5));" : "") +
        "return result;
    }" : "") +

    "
    highp float rand(vec2 co)
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
    }" +

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

        (horizontal_sincronization !== 0 ? "
            float h_distortion = 0.5 * sin(time*0.001 + coords.y*10.0*fract(time/10.0));
            h_distortion += 0.5 * cos(time*0.04 + 0.03 + coords.y*50.0*fract(time/10.0 + 0.4));
            coords.x = coords.x + h_distortion * horizontal_distortion;" +
            (noise_strength ? "
                noise += horizontal_distortion * 0.5;" : "")
        : "") +

        (frame_reflection_strength ? "
            coords = abs(mod(floor(coords), 2.0) - fract(coords));" : "") +

        "float color = texture2D(source, coords).r;" +

        (noise_strength !== 0 ? "
            color += stepNoise(coords) * noise * (1.0 - distance * distance * 2.0);" : "") +

        (glowing_line_strength !== 0 ? "
            color += randomPass(coords) * glowing_line_strength;" : "") +

        (rasterization !== shadersettings.no_rasterization ? "
            color = mix(color, color * getScanlineIntensity(originalCoord), "+ rasterization_strength +");"
        : "") +

        (bloom !== 0 ? "
            color += texture2D(bloomSource, coords).r *" + 2.5 * bloom + ";" : "") +

        "vec3 finalColor = mix(background_color, font_color, color).rgb;" +
        "finalColor = mix(finalColor * 1.1, vec3(0.0), 1.2 * distance * distance);" +

        (brightness_flickering !== 0 ? "
            finalColor = mix(finalColor, vec3(0.0), brightness);" : "") +

        "gl_FragColor = vec4(finalColor *"+brightness+", qt_Opacity);
    }"

     onStatusChanged: console.log(log) //Print warning messages
}
