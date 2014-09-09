/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
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
import QtGraphicalEffects 1.0


ShaderEffect {
    property color font_color: shadersettings.font_color
    property color background_color: shadersettings.background_color
    property variant source: terminal.theSource
    property variant bloomSource: terminal.bloomSource
    property variant rasterizationSource: terminal.rasterizationSource
    property variant noiseSource: terminal.staticNoiseSource
    property size txt_Size: Qt.size(frame.sourceRect.width, frame.sourceRect.height)
    property real bloom_strength: shadersettings.bloom_strength * 2.5

    property int rasterization: shadersettings.rasterization

    property real jitter: shadersettings.jitter * 0.007

    property real noise_strength: shadersettings.noise_strength
    property real screen_distorsion: shadersettings.screen_distortion
    property real glowing_line_strength: shadersettings.glowing_line_strength

    property real chroma_color: shadersettings.chroma_color;
    property real saturation_color: shadersettings.saturation_color;

    property real rgb_shift: shadersettings.rgb_shift * 0.2

    property real brightness_flickering: shadersettings.brightness_flickering
    property real horizontal_sincronization: shadersettings.horizontal_sincronization

    property bool frameReflections: shadersettings.frameReflections

    property real disp_top: frame.item.displacementTop * shadersettings.window_scaling
    property real disp_bottom: frame.item.displacementBottom * shadersettings.window_scaling
    property real disp_left: frame.item.displacementLeft * shadersettings.window_scaling
    property real disp_right: frame.item.displacementRight * shadersettings.window_scaling

    property real screen_brightness: shadersettings.brightness * 1.5 + 0.5

    property real time: timeManager.time
    property variant randomFunctionSource: randfuncsource

    blending: false

    //Smooth random texture used for flickering effect.
    Image{
        id: randtexture
        source: "frames/images/randfunction.png"
        width: 512
        height: 512
        sourceSize.width: 512
        sourceSize.height: 256
        fillMode: Image.TileVertically
    }
    ShaderEffectSource{
        id: randfuncsource
        sourceItem: randtexture
        live: false
        hideSource: true
        wrapMode: ShaderEffectSource.Repeat
    }

    //Print the number with a reasonable precision for the shader.
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
            varying lowp float brightness;
            uniform lowp float brightness_flickering;" : "") +
        (horizontal_sincronization !== 0.0 ?"
            varying lowp float horizontal_distortion;
            uniform lowp float horizontal_sincronization;" : "") +
        "
        void main() {
            qt_TexCoord0 = qt_MultiTexCoord0;
            vec2 coords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0)));" +
            (brightness_flickering !== 0.0 ? "
                brightness = 1.0 + (texture2D(randomFunctionSource, coords).g - 0.5) * brightness_flickering;"
            :   "") +

            (horizontal_sincronization !== 0.0 ? "
                float randval = 1.5 * texture2D(randomFunctionSource,(vec2(1.0) -coords) * 0.5).g;
                float negsinc = 1.0 - 0.6 * horizontal_sincronization;" + "
                horizontal_distortion = step(negsinc, randval) * (randval - negsinc) * 0.3*horizontal_sincronization;"
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
        uniform highp sampler2D rasterizationSource;
        uniform lowp float screen_brightness;" +

        (bloom_strength !== 0 ? "
            uniform highp sampler2D bloomSource;
            uniform lowp float bloom_strength;" : "") +
        (noise_strength !== 0 ? "
            uniform highp float noise_strength;" : "") +
        (noise_strength !== 0 || jitter !== 0 ? "
            uniform lowp sampler2D noiseSource;" : "") +
        (screen_distorsion !== 0 ? "
            uniform highp float screen_distorsion;" : "") +
        (glowing_line_strength !== 0 ? "
            uniform highp float glowing_line_strength;" : "") +
        (chroma_color !== 0 ? "
            uniform lowp float chroma_color;" : "") +
        (jitter !== 0 ? "
            uniform lowp float jitter;" : "") +
        (rgb_shift !== 0 ? "
            uniform lowp float rgb_shift;" : "") +
        (brightness_flickering !== 0 ? "
            varying lowp float brightness;" : "") +
        (horizontal_sincronization !== 0 ? "
            varying lowp float horizontal_distortion;" : "") +

        (glowing_line_strength !== 0 ? "
            float randomPass(vec2 coords){
                return fract(smoothstep(-0.2, 0.0, coords.y - 3.0 * fract(time * 0.0001))) * glowing_line_strength;
            }" : "") +

        "float rgb2grey(vec3 v){
            return dot(v, vec3(0.21, 0.72, 0.04));
        }" +

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

            (frameReflections ? "
                vec2 inside = step(0.0, coords) - step(1.0, coords);
                coords = abs(mod(floor(coords), 2.0) - fract(coords)) * clamp(inside.x + inside.y, 0.0, 1.0);" : "") +

            (horizontal_sincronization !== 0 ? "
                float h_distortion = 0.5 * sin(time*0.001 + coords.y*10.0*fract(time/10.0));
                h_distortion += 0.5 * cos(time*0.04 + 0.03 + coords.y*50.0*fract(time/10.0 + 0.4));
                coords.x = coords.x + h_distortion * horizontal_distortion;" +
                (noise_strength ? "
                    noise += horizontal_distortion;" : "")
            : "") +

            (jitter !== 0 ? "
                vec2 offset = vec2(texture2D(noiseSource, coords + fract(time / 57.0)).a,
                                   texture2D(noiseSource, coords + fract(time / 251.0)).a) - 0.5;
                vec2 txt_coords = coords + offset * jitter;"
            :  "vec2 txt_coords = coords;") +

            "float color = 0.0;" +

            (noise_strength !== 0 ? "
                float noiseVal = texture2D(noiseSource, qt_TexCoord0 + vec2(fract(time / 51.0), fract(time / 237.0))).a;
                color += noiseVal * noise * (1.0 - distance * 1.3);" : "") +

            (glowing_line_strength !== 0 ? "
                color += randomPass(coords) * glowing_line_strength;" : "") +

            (chroma_color !== 0 ?
                (rgb_shift !== 0 ? "
                    float rgb_noise = abs(texture2D(noiseSource, vec2(fract(time/(1024.0 * 256.0)), fract(time/(1024.0*1024.0)))).a - 0.5);
                    vec4 realBackColor = texture2D(source, txt_coords);
                    vec2 rcolor = texture2D(source, txt_coords + vec2(0.1, 0.0) * rgb_shift * rgb_noise).ra;
                    vec2 bcolor = texture2D(source, txt_coords - vec2(0.1, 0.0) * rgb_shift * rgb_noise).ba;
                    realBackColor.r = rcolor.x;
                    realBackColor.b = bcolor.x;
                    realBackColor.a = 0.33 * (realBackColor.a + rcolor.y + bcolor.y);"
                :
                    "vec4 realBackColor = texture2D(source, txt_coords);") +

                "vec4 mixedColor = mix(font_color, realBackColor * font_color, chroma_color);" +

                "vec4 finalBackColor = mix(background_color, mixedColor, realBackColor.a);" +
                "vec3 finalColor = mix(finalBackColor, font_color, color).rgb;"
            :
                "color += texture2D(source, txt_coords).a;" +
                "vec3 finalColor = mix(background_color, font_color, color).rgb;"
            ) +

            "finalColor *= texture2D(rasterizationSource, coords).a;" +

            (bloom_strength !== 0 ?
                "vec3 bloomColor = texture2D(bloomSource, coords).rgb;" +
                (chroma_color !== 0 ?
                    "bloomColor = font_color.rgb * mix(vec3(rgb2grey(bloomColor)), bloomColor, chroma_color);"
                :
                    "bloomColor = font_color.rgb * rgb2grey(bloomColor);") +
                "finalColor += bloomColor * bloom_strength;"
            : "") +

            (brightness_flickering !== 0 ? "
                finalColor *= brightness;" : "") +

            "gl_FragColor = vec4(finalColor * screen_brightness, qt_Opacity);" +
        "}"

     onStatusChanged: if (log) console.log(log) //Print warning messages
}
