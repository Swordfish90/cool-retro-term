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
    property ShaderEffectSource source
    property ShaderEffectSource blurredSource
    property ShaderEffectSource bloomSource

    property color fontColor: appSettings.fontColor
    property color backgroundColor: appSettings.backgroundColor
    property real bloom: appSettings.bloom * 2.5

    property real burnIn: appSettings.burnIn

    property real jitter: appSettings.jitter * 0.007
    property real staticNoise: appSettings.staticNoise
    property size scaleNoiseSize: Qt.size((width) / (noiseTexture.width * appSettings.windowScaling * appSettings.fontScaling),
                                          (height) / (noiseTexture.height * appSettings.windowScaling * appSettings.fontScaling))

    property real screen_distorsion: appSettings.screenCurvature
    property real glowingLine: appSettings.glowingLine

    property real chromaColor: appSettings.chromaColor;

    property real rbgShift: appSettings.rbgShift * 0.2

    property real flickering: appSettings.flickering
    property real horizontalSync: appSettings.horizontalSync

    property bool frameReflections: appSettings.frameReflections

    property real disp_top: (frame.displacementTop * appSettings.windowScaling) / height
    property real disp_bottom: (frame.displacementBottom * appSettings.windowScaling) / height
    property real disp_left: (frame.displacementLeft * appSettings.windowScaling) / width
    property real disp_right: (frame.displacementRight * appSettings.windowScaling) / width

    property real screen_brightness: appSettings.brightness * 1.5 + 0.5

    property real dispX
    property real dispY
    property size virtual_resolution

    TimeManager{
        id: timeManager
        enableTimer: terminalWindow.visible
    }

    property alias time: timeManager.time
    property variant noiseSource: noiseShaderSource

    // If something goes wrong activate the fallback version of the shader.
    property bool fallBack: false

    blending: false

    //Smooth random texture used for flickering effect.
    Image{
        id: noiseTexture
        source: "images/allNoise512.png"
        width: 512
        height: 512
        fillMode: Image.Tile
        visible: false
    }
    ShaderEffectSource{
        id: noiseShaderSource
        sourceItem: noiseTexture
        wrapMode: ShaderEffectSource.Repeat
        visible: false
        smooth: true
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
            uniform sampler2D noiseSource;" : "") +

        (!fallBack && flickering !== 0.0 ?"
            varying lowp float brightness;
            uniform lowp float flickering;" : "") +
        (!fallBack && horizontalSync !== 0.0 ?"
            uniform lowp float horizontalSync;
            varying lowp float distortionScale;
            varying lowp float distortionFreq;" : "") +

        "
        void main() {
            qt_TexCoord0.x = (qt_MultiTexCoord0.x - disp_left) / (1.0 - disp_left - disp_right);
            qt_TexCoord0.y = (qt_MultiTexCoord0.y - disp_top) / (1.0 - disp_top - disp_bottom);
            vec2 coords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0)));" +

            (!fallBack && (flickering !== 0.0 || horizontalSync !== 0.0) ?
                "vec4 initialNoiseTexel = texture2D(noiseSource, coords);"
            : "") +
            (!fallBack && flickering !== 0.0 ? "
                brightness = 1.0 + (initialNoiseTexel.g - 0.5) * flickering;"
            : "") +

            (!fallBack && horizontalSync !== 0.0 ? "
                float randval = horizontalSync - initialNoiseTexel.r;
                distortionScale = step(0.0, randval) * randval * horizontalSync;
                distortionFreq = mix(4.0, 40.0, initialNoiseTexel.g);"
            : "") +

            "gl_Position = qt_Matrix * qt_Vertex;
        }"

    fragmentShader: "
        uniform sampler2D source;
        uniform highp float qt_Opacity;
        uniform highp float time;
        varying highp vec2 qt_TexCoord0;

        uniform highp vec4 fontColor;
        uniform highp vec4 backgroundColor;
        uniform lowp float screen_brightness;

        uniform highp vec2 virtual_resolution;
        uniform highp float dispX;
        uniform highp float dispY;" +

        (bloom !== 0 ? "
            uniform highp sampler2D bloomSource;
            uniform lowp float bloom;" : "") +
        (burnIn !== 0 ? "
            uniform sampler2D blurredSource;" : "") +
        (staticNoise !== 0 ? "
            uniform highp float staticNoise;" : "") +
        (((staticNoise !== 0 || jitter !== 0 || rbgShift)
          ||(fallBack && (flickering || horizontalSync))) ? "
            uniform lowp sampler2D noiseSource;
            uniform highp vec2 scaleNoiseSize;" : "") +
        (screen_distorsion !== 0 ? "
            uniform highp float screen_distorsion;" : "") +
        (glowingLine !== 0 ? "
            uniform highp float glowingLine;" : "") +
        (chromaColor !== 0 ? "
            uniform lowp float chromaColor;" : "") +
        (jitter !== 0 ? "
            uniform lowp float jitter;" : "") +
        (rbgShift !== 0 ? "
            uniform lowp float rbgShift;" : "") +

        (fallBack && horizontalSync !== 0 ? "
            uniform lowp float horizontalSync;" : "") +
        (fallBack && flickering !== 0.0 ?"
            uniform lowp float flickering;" : "") +
        (!fallBack && flickering !== 0 ? "
            varying lowp float brightness;"
        : "") +
        (!fallBack && horizontalSync !== 0 ? "
            varying lowp float distortionScale;
            varying lowp float distortionFreq;" : "") +

        (glowingLine !== 0 ? "
            float randomPass(vec2 coords){
                return fract(smoothstep(-0.2, 0.0, coords.y - 3.0 * fract(time * 0.0001))) * glowingLine;
            }" : "") +

        "highp float getScanlineIntensity(vec2 coords) {
            highp float result = 1.0;" +

           (appSettings.rasterization != appSettings.no_rasterization ?
               "result *= abs(sin(coords.y * virtual_resolution.y * "+Math.PI+"));" : "") +
           (appSettings.rasterization == appSettings.pixel_rasterization ?
               "result *= abs(sin(coords.x * virtual_resolution.x * "+Math.PI+"));" : "") + "

           return result;
        }

        float rgb2grey(vec3 v){
            return dot(v, vec3(0.21, 0.72, 0.04));
        }" +

        "void main() {" +
            "vec2 cc = vec2(0.5) - qt_TexCoord0;" +
            "float distance = length(cc);" +

            //FallBack if there are problems
            (fallBack && (flickering !== 0.0 || horizontalSync !== 0.0) ?
                "vec2 initialCoords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0)));
                 vec4 initialNoiseTexel = texture2D(noiseSource, initialCoords);"
            : "") +
            (fallBack && flickering !== 0.0 ? "
                float brightness = 1.0 + (initialNoiseTexel.g - 0.5) * flickering;"
            : "") +
            (fallBack && horizontalSync !== 0.0 ? "
                float randval = horizontalSync - initialNoiseTexel.r;
                float distortionScale = step(0.0, randval) * randval * horizontalSync;
                float distortionFreq = mix(4.0, 40.0, initialNoiseTexel.g);"
            : "") +

            (staticNoise ? "
                float noise = staticNoise;" : "") +

            (screen_distorsion !== 0 ? "
                float distortion = dot(cc, cc) * screen_distorsion;
                vec2 staticCoords = (qt_TexCoord0 - cc * (1.0 + distortion) * distortion);"
            :"
                vec2 staticCoords = qt_TexCoord0;") +

            "vec2 coords = staticCoords;" +

            (horizontalSync !== 0 ? "
                float dst = sin((coords.y + time * 0.001) * distortionFreq);
                coords.x += dst * distortionScale;" +
                (staticNoise ? "
                    noise += distortionScale * 3.0;" : "")
            : "") +

            (jitter !== 0 || staticNoise !== 0 ?
                "vec4 noiseTexel = texture2D(noiseSource, scaleNoiseSize * coords + vec2(fract(time / 51.0), fract(time / 237.0)));"
            : "") +

            (jitter !== 0 ? "
                vec2 offset = vec2(noiseTexel.b, noiseTexel.a) - vec2(0.5);
                vec2 txt_coords = coords + offset * jitter;"
            :  "vec2 txt_coords = coords;") +

            "float color = 0.0;" +

            (staticNoise !== 0 ? "
                float noiseVal = noiseTexel.a;
                color += noiseVal * noise * (1.0 - distance * 1.3);" : "") +

            (glowingLine !== 0 ? "
                color += randomPass(coords) * glowingLine;" : "") +

            "vec3 txt_color = texture2D(source, txt_coords).rgb;" +

            (burnIn !== 0 ? "
                vec4 txt_blur = texture2D(blurredSource, txt_coords);
                txt_color = txt_color + txt_blur.rgb * txt_blur.a;"
            : "") +

             "float greyscale_color = rgb2grey(txt_color) + color;" +

            (chromaColor !== 0 ?
                (rbgShift !== 0 ? "
                    float rgb_noise = abs(texture2D(noiseSource, vec2(fract(time/(1024.0 * 256.0)), fract(time/(1024.0*1024.0)))).a - 0.5);
                    float rcolor = texture2D(source, txt_coords + vec2(0.1, 0.0) * rbgShift * rgb_noise).r;
                    float bcolor = texture2D(source, txt_coords - vec2(0.1, 0.0) * rbgShift * rgb_noise).b;
                    txt_color.r = rcolor;
                    txt_color.b = bcolor;
                    greyscale_color = 0.33 * (rcolor + bcolor);" : "") +

                "vec3 mixedColor = mix(fontColor.rgb, txt_color * fontColor.rgb, chromaColor);
                 vec3 finalBackColor = mix(backgroundColor.rgb, mixedColor, greyscale_color);
                 vec3 finalColor = mix(finalBackColor, fontColor.rgb, color).rgb;"
            :
                "vec3 finalColor = mix(backgroundColor.rgb, fontColor.rgb, greyscale_color);") +

            "finalColor *= getScanlineIntensity(coords);" +

            (bloom !== 0 ?
                "vec4 bloomFullColor = texture2D(bloomSource, coords);
                 vec3 bloomColor = bloomFullColor.rgb;
                 float bloomAlpha = bloomFullColor.a;" +
                (chromaColor !== 0 ?
                    "bloomColor = fontColor.rgb * mix(vec3(rgb2grey(bloomColor)), bloomColor, chromaColor);"
                :
                    "bloomColor = fontColor.rgb * rgb2grey(bloomColor);") +
                "finalColor += bloomColor * bloom * bloomAlpha;"
            : "") +

            "finalColor *= smoothstep(-dispX, 0.0, staticCoords.x) - smoothstep(1.0, 1.0 + dispX, staticCoords.x);
             finalColor *= smoothstep(-dispY, 0.0, staticCoords.y) - smoothstep(1.0, 1.0 + dispY, staticCoords.y);" +

            (flickering !== 0 ? "
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
