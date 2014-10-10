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
    property real bloom_strength: shadersettings.bloom_strength * 2.5

    property real jitter: shadersettings.jitter * 0.007

    property real noise_strength: shadersettings.noise_strength
    property real screen_distorsion: shadersettings.screen_distortion
    property real glowing_line_strength: shadersettings.glowing_line_strength

    property real chroma_color: shadersettings.chroma_color;

    property real rgb_shift: shadersettings.rgb_shift * 0.2

    property real brightness_flickering: shadersettings.brightness_flickering
    property real horizontal_sincronization: shadersettings.horizontal_sincronization

    property bool frameReflections: shadersettings.frameReflections

    property real disp_top: (frame.item.displacementTop * shadersettings.window_scaling) / height
    property real disp_bottom: (frame.item.displacementBottom * shadersettings.window_scaling) / height
    property real disp_left: (frame.item.displacementLeft * shadersettings.window_scaling) / width
    property real disp_right: (frame.item.displacementRight * shadersettings.window_scaling) / width

    property real screen_brightness: shadersettings.brightness * 1.5 + 0.5

    property real time: timeManager.time
    property variant randomFunctionSource: randfuncsource

    // If something goes wrong activate the fallback version of the shader.
    property bool fallBack: false

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

        uniform highp float disp_left;
        uniform highp float disp_right;
        uniform highp float disp_top;
        uniform highp float disp_bottom;

        attribute highp vec4 qt_Vertex;
        attribute highp vec2 qt_MultiTexCoord0;

        varying highp vec2 qt_TexCoord0;" +

        (!fallBack ? "
            uniform sampler2D randomFunctionSource;" : "") +

        (!fallBack && brightness_flickering !== 0.0 ?"
            varying lowp float brightness;
            uniform lowp float brightness_flickering;" : "") +
        (!fallBack && horizontal_sincronization !== 0.0 ?"
            varying lowp float horizontal_distortion;
            uniform lowp float horizontal_sincronization;" : "") +
        "
        void main() {
            qt_TexCoord0.x = (qt_MultiTexCoord0.x - disp_left) / (1.0 - disp_left - disp_right);
            qt_TexCoord0.y = (qt_MultiTexCoord0.y - disp_top) / (1.0 - disp_top - disp_bottom);
            vec2 coords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0)));" +
            (!fallBack && brightness_flickering !== 0.0 ? "
                brightness = 1.0 + (texture2D(randomFunctionSource, coords).g - 0.5) * brightness_flickering;"
            :   "") +

            (!fallBack && horizontal_sincronization !== 0.0 ? "
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
        (noise_strength !== 0 || jitter !== 0 || rgb_shift ? "
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

        (fallBack && (brightness_flickering || horizontal_sincronization) ? "
            uniform lowp sampler2D randomFunctionSource;" : "") +
        (fallBack && horizontal_sincronization !== 0 ? "
            uniform lowp float horizontal_sincronization;" : "") +
        (fallBack && brightness_flickering !== 0.0 ?"
            uniform lowp float brightness_flickering;" : "") +
        (!fallBack && brightness_flickering !== 0 ? "
            varying lowp float brightness;" : "") +
        (!fallBack && horizontal_sincronization !== 0 ? "
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

            //FallBack if there are problem
            (fallBack && (brightness_flickering || horizontal_sincronization) ? "
                vec2 randCoords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0)));" : "") +

            (fallBack && brightness_flickering !== 0.0 ? "
                float brightness = 1.0 + (texture2D(randomFunctionSource, randCoords).g - 0.5) * brightness_flickering;"
            :   "") +

            (fallBack && horizontal_sincronization !== 0.0 ? "
                float randval = 1.5 * texture2D(randomFunctionSource,(vec2(1.0) - randCoords) * 0.5).g;
                float negsinc = 1.0 - 0.6 * horizontal_sincronization;" + "
                float horizontal_distortion = step(negsinc, randval) * (randval - negsinc) * 0.3*horizontal_sincronization;"
            : "") +

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


            "vec3 txt_color = texture2D(source, txt_coords).rgb;
             float greyscale_color = rgb2grey(txt_color) + color;" +

            (chroma_color !== 0 ?
                (rgb_shift !== 0 ? "
                    float rgb_noise = abs(texture2D(noiseSource, vec2(fract(time/(1024.0 * 256.0)), fract(time/(1024.0*1024.0)))).a - 0.5);
                    float rcolor = texture2D(source, txt_coords + vec2(0.1, 0.0) * rgb_shift * rgb_noise).r;
                    float bcolor = texture2D(source, txt_coords - vec2(0.1, 0.0) * rgb_shift * rgb_noise).b;
                    txt_color.r = rcolor;
                    txt_color.b = bcolor;
                    greyscale_color = 0.33 * (rcolor + bcolor);" : "") +

                "vec3 mixedColor = mix(font_color.rgb, txt_color * font_color.rgb, chroma_color);
                 vec3 finalBackColor = mix(background_color.rgb, mixedColor, greyscale_color);
                 vec3 finalColor = mix(finalBackColor, font_color.rgb, color).rgb;"
            :
                "vec3 finalColor = mix(background_color.rgb, font_color.rgb, greyscale_color);") +

            "finalColor *= texture2D(rasterizationSource, coords).a;" +

            (bloom_strength !== 0 ?
                "vec4 bloomFullColor = texture2D(bloomSource, coords);
                 vec3 bloomColor = bloomFullColor.rgb;
                 vec2 minBound = step(vec2(0.0), coords);
                 vec2 maxBound = step(coords, vec2(1.0));
                 float bloomAlpha = bloomFullColor.a * minBound.x * minBound.y * maxBound.x * maxBound.y;" +
                (chroma_color !== 0 ?
                    "bloomColor = font_color.rgb * mix(vec3(rgb2grey(bloomColor)), bloomColor, chroma_color);"
                :
                    "bloomColor = font_color.rgb * rgb2grey(bloomColor);") +
                "finalColor += bloomColor * bloom_strength * bloomAlpha;"
            : "") +

            (brightness_flickering !== 0 ? "
                finalColor *= brightness;" : "") +

            "gl_FragColor = vec4(finalColor * screen_brightness, qt_Opacity);" +
        "}"

     onStatusChanged: {
         // Print warning messages
         if (log)
             console.log(log);

         // Activate fallback mode
         if (status == ShaderEffect.Error) {
            fallBack = true;
         }
     }
}
