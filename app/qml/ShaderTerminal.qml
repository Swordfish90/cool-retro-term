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

import "utils.js" as Utils

Item {
    property SlowBurnIn slowBurnInEffect
    property ShaderEffectSource source
    property BurnInEffect burnInEffect
    property ShaderEffectSource bloomSource

    property color fontColor: appSettings.fontColor
    property color backgroundColor: appSettings.backgroundColor

    property real screenCurvature: appSettings.screenCurvature * appSettings.screenCurvatureSize

    property real chromaColor: appSettings.chromaColor

    property real ambientLight: appSettings.ambientLight * 0.2

    property size virtual_resolution

     ShaderEffect {
         id: dynamicShader

         property ShaderEffectSource screenBuffer: frameBuffer
         property ShaderEffectSource burnInSource: burnInEffect.source
         property ShaderEffectSource frameSource: terminalFrameLoader.item

         property color fontColor: parent.fontColor
         property color backgroundColor: parent.backgroundColor
         property real screenCurvature: parent.screenCurvature
         property real chromaColor: parent.chromaColor
         property real ambientLight: parent.ambientLight

         property real flickering: appSettings.flickering
         property real horizontalSync: appSettings.horizontalSync
         property real horizontalSyncStrength: Utils.lint(0.05, 0.35, horizontalSync)
         property real glowingLine: appSettings.glowingLine * 0.2

         // Fast burnin properties
         property real burnIn: appSettings.useFastBurnIn ? appSettings.burnIn : 0
         property real burnInLastUpdate: burnInEffect.lastUpdate
         property real burnInTime: burnInEffect.burnInFadeTime

         // Slow burnin properties
         property real slowBurnIn: appSettings.useFastBurnIn ? 0 : appSettings.burnIn
         property ShaderEffectSource slowBurnInSource: slowBurnInEffect.source

         property real jitter: appSettings.jitter
         property size jitterDisplacement: Qt.size(0.007 * jitter, 0.002 * jitter)
         property real shadowLength: 0.25 * screenCurvature * Utils.lint(0.50, 1.5, ambientLight)
         property real staticNoise: appSettings.staticNoise
         property size scaleNoiseSize: Qt.size((width) / (noiseTexture.width * appSettings.windowScaling * appSettings.totalFontScaling),
                                               (height) / (noiseTexture.height * appSettings.windowScaling * appSettings.totalFontScaling))

         property size virtual_resolution: parent.virtual_resolution

         property real time: timeManager.time
         property ShaderEffectSource noiseSource: noiseShaderSource

         // If something goes wrong activate the fallback version of the shader.
         property bool fallBack: false

         anchors.fill: parent
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

             attribute highp vec4 qt_Vertex;
             attribute highp vec2 qt_MultiTexCoord0;

             varying highp vec2 qt_TexCoord0;" +

             (!fallBack ? "
                 uniform sampler2D noiseSource;" : "") +

             (!fallBack && flickering !== 0.0 ?"
                 varying lowp float brightness;
                 uniform lowp float flickering;" : "") +

             (!fallBack && horizontalSync !== 0.0 ?"
                 uniform lowp float horizontalSyncStrength;
                 varying lowp float distortionScale;
                 varying lowp float distortionFreq;" : "") +

             "
             void main() {
                 qt_TexCoord0 = qt_MultiTexCoord0;
                 vec2 coords = vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0)));" +

                 (!fallBack && (flickering !== 0.0 || horizontalSync !== 0.0) ?
                     "vec4 initialNoiseTexel = texture2D(noiseSource, coords);"
                 : "") +

                 (!fallBack && flickering !== 0.0 ? "
                     brightness = 1.0 + (initialNoiseTexel.g - 0.5) * flickering;"
                 : "") +

                 (!fallBack && horizontalSync !== 0.0 ? "
                     float randval = horizontalSyncStrength - initialNoiseTexel.r;
                     distortionScale = step(0.0, randval) * randval * horizontalSyncStrength;
                     distortionFreq = mix(4.0, 40.0, initialNoiseTexel.g);"
                 : "") +

                 "gl_Position = qt_Matrix * qt_Vertex;
             }"

         fragmentShader: "
             #ifdef GL_ES
                 precision mediump float;
             #endif

             uniform sampler2D screenBuffer;
             uniform highp float qt_Opacity;
             uniform highp float time;
             varying highp vec2 qt_TexCoord0;

             uniform highp vec4 fontColor;
             uniform highp vec4 backgroundColor;
             uniform lowp float shadowLength;

             uniform highp vec2 virtual_resolution;" +

             (burnIn !== 0 ? "
                 uniform sampler2D burnInSource;
                 uniform highp float burnInLastUpdate;
                 uniform highp float burnInTime;" : "") +
             (slowBurnIn !== 0 ? "
                 uniform sampler2D slowBurnInSource;" : "") +
             (staticNoise !== 0 ? "
                 uniform highp float staticNoise;" : "") +
             (((staticNoise !== 0 || jitter !== 0)
               ||(fallBack && (flickering || horizontalSync))) ? "
                 uniform lowp sampler2D noiseSource;
                 uniform highp vec2 scaleNoiseSize;" : "") +
             (screenCurvature !== 0 ? "
                 uniform highp float screenCurvature;
                 uniform lowp sampler2D frameSource;" : "") +
             (glowingLine !== 0 ? "
                 uniform highp float glowingLine;" : "") +
             (chromaColor !== 0 ? "
                 uniform lowp float chromaColor;" : "") +
             (jitter !== 0 ? "
                 uniform lowp vec2 jitterDisplacement;" : "") +
             (ambientLight !== 0 ? "
                 uniform lowp float ambientLight;" : "") +

             (fallBack && horizontalSync !== 0 ? "
                 uniform lowp float horizontalSyncStrength;" : "") +
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
                     return fract(smoothstep(-120.0, 0.0, coords.y - (virtual_resolution.y + 120.0) * fract(time * 0.00015)));
                 }" : "") +

             "float min2(vec2 v) {
                 return min(v.x, v.y);
             }

             float rgb2grey(vec3 v){
                 return dot(v, vec3(0.21, 0.72, 0.04));
             }

             float isInScreen(vec2 v) {
                 return min2(step(0.0, v) - step(1.0, v));
             }

             vec2 barrel(vec2 v, vec2 cc) {" +

                 (screenCurvature !== 0 ? "
                     float distortion = dot(cc, cc) * screenCurvature;
                     return (v - cc * (1.0 + distortion) * distortion);"
                 :
                     "return v;") +
             "}" +

             "vec3 convertWithChroma(vec3 inColor) {
                vec3 outColor = inColor;" +

                 (chromaColor !== 0 ?
                     "outColor = fontColor.rgb * mix(vec3(rgb2grey(inColor)), inColor, chromaColor);"
                 :
                     "outColor = fontColor.rgb * rgb2grey(inColor);") +

             "  return outColor;
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
                     float randval = horizontalSyncStrength - initialNoiseTexel.r;
                     float distortionScale = step(0.0, randval) * randval * horizontalSyncStrength;
                     float distortionFreq = mix(4.0, 40.0, initialNoiseTexel.g);"
                 : "") +

                 (staticNoise ? "
                     float noise = staticNoise;" : "") +

                 (screenCurvature !== 0 ? "
                     vec2 staticCoords = barrel(qt_TexCoord0, cc);"
                 :"
                     vec2 staticCoords = qt_TexCoord0;") +

                 "vec2 coords = qt_TexCoord0;" +

                 (horizontalSync !== 0 ? "
                     float dst = sin((coords.y + time * 0.001) * distortionFreq);
                     coords.x += dst * distortionScale;" +

                     (staticNoise ? "
                         noise += distortionScale * 7.0;" : "")

                 : "") +

                 (jitter !== 0 || staticNoise !== 0 ?
                     "vec4 noiseTexel = texture2D(noiseSource, scaleNoiseSize * coords + vec2(fract(time / 51.0), fract(time / 237.0)));"
                 : "") +

                 (jitter !== 0 ? "
                     vec2 offset = vec2(noiseTexel.b, noiseTexel.a) - vec2(0.5);
                     vec2 txt_coords = coords + offset * jitterDisplacement;"
                 :  "vec2 txt_coords = coords;") +

                 "float color = 0.0001;" +

                 (staticNoise !== 0 ? "
                     float noiseVal = noiseTexel.a;
                     color += noiseVal * noise * (1.0 - distance * 1.3);" : "") +

                 (glowingLine !== 0 ? "
                     color += randomPass(coords * virtual_resolution) * glowingLine;" : "") +

                 "vec3 txt_color = texture2D(screenBuffer, txt_coords).rgb;" +

                 (burnIn !== 0 ? "
                     vec4 txt_blur = texture2D(burnInSource, staticCoords);
                     float blurDecay = clamp((time - burnInLastUpdate) * burnInTime, 0.0, 1.0);
                     vec3 burnInColor = 0.65 * (txt_blur.rgb - vec3(blurDecay));
                     txt_color = max(txt_color, convertWithChroma(burnInColor));"
                 : "") +

                 (slowBurnIn !== 0 ? "
                     vec4 txt_blur = texture2D(slowBurnInSource, staticCoords);
                     txt_color = max(txt_color, convertWithChroma(txt_blur.rgb * txt_blur.a));
                 " : "") +

                  "txt_color += fontColor.rgb * vec3(color);" +

                 "vec3 finalColor = txt_color;" +

                 (flickering !== 0 ? "
                     finalColor *= brightness;" : "") +

                 (ambientLight !== 0 ? "
                     finalColor += vec3(ambientLight) * (1.0 - distance) * (1.0 - distance);" : "") +

                 (screenCurvature !== 0 ?
                    "vec4 frameColor = texture2D(frameSource, qt_TexCoord0);
                     finalColor = mix(finalColor, frameColor.rgb, frameColor.a);"
                 : "") +

                 "gl_FragColor = vec4(finalColor, qt_Opacity);" +
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

     Loader {
         id: terminalFrameLoader

         active: screenCurvature !== 0

         width: staticShader.width
         height: staticShader.height

         sourceComponent: ShaderEffectSource {

             sourceItem: terminalFrame
             hideSource: true
             visible: false
             format: ShaderEffectSource.RGBA

             NewTerminalFrame {
                 id: terminalFrame
                 blending: false
                 anchors.fill: parent
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
         property real bloom: appSettings.bloom * 2.5

         property real screenCurvature: parent.screenCurvature

         property real chromaColor: appSettings.chromaColor;

         property real rbgShift: (appSettings.rbgShift / width) * appSettings.totalFontScaling // TODO FILIPPO width here is wrong.

         property int rasterization: appSettings.rasterization

         property real screen_brightness: Utils.lint(0.5, 1.5, appSettings.brightness)

         property real ambientLight: parent.ambientLight

         property size virtual_resolution: parent.virtual_resolution

         blending: false
         visible: false

         //Print the number with a reasonable precision for the shader.
         function str(num){
             return num.toFixed(8);
         }

         fragmentShader: "
             #ifdef GL_ES
                 precision mediump float;
             #endif

             uniform sampler2D source;
             uniform highp float qt_Opacity;
             varying highp vec2 qt_TexCoord0;

             uniform highp vec4 fontColor;
             uniform highp vec4 backgroundColor;
             uniform lowp float screen_brightness;

             uniform highp vec2 virtual_resolution;" +

             (bloom !== 0 ? "
                 uniform highp sampler2D bloomSource;
                 uniform lowp float bloom;" : "") +

             (screenCurvature !== 0 ? "
                 uniform highp float screenCurvature;" : "") +

             (chromaColor !== 0 ? "
                 uniform lowp float chromaColor;" : "") +

             (rbgShift !== 0 ? "
                 uniform lowp float rbgShift;" : "") +

             (ambientLight !== 0 ? "
                 uniform lowp float ambientLight;" : "") +

             "highp float getScanlineIntensity(vec2 coords) {
                 float result = 1.0;" +

                (appSettings.rasterization != appSettings.no_rasterization ?
                    "float val = 0.0;
                     vec2 rasterizationCoords = fract(coords * virtual_resolution);
                     val += smoothstep(0.0, 0.5, rasterizationCoords.y);
                     val -= smoothstep(0.5, 1.0, rasterizationCoords.y);
                     result *= mix(0.5, 1.0, val);" : "") +

                (appSettings.rasterization == appSettings.pixel_rasterization ?
                    "val = 0.0;
                     val += smoothstep(0.0, 0.5, rasterizationCoords.x);
                     val -= smoothstep(0.5, 1.0, rasterizationCoords.x);
                     result *= mix(0.5, 1.0, val);" : "") + "

                return result;
             }

             float min2(vec2 v) {
                 return min(v.x, v.y);
             }

             float sum2(vec2 v) {
                 return v.x + v.y;
             }

             float rgb2grey(vec3 v){
                 return dot(v, vec3(0.21, 0.72, 0.04));
             }" +

             "vec3 convertWithChroma(vec3 inColor) {
                vec3 outColor = inColor;" +

                 (chromaColor !== 0 ?
                     "outColor = fontColor.rgb * mix(vec3(rgb2grey(inColor)), inColor, chromaColor);"
                 :
                     "outColor = fontColor.rgb * rgb2grey(inColor);") +

             "  return outColor;
             }" +


             "void main() {" +
                 "vec2 cc = vec2(0.5) - qt_TexCoord0;" +

                 (screenCurvature !== 0 ? "
                     float distortion = dot(cc, cc) * screenCurvature;
                     vec2 curvatureCoords = (qt_TexCoord0 - cc * (1.0 + distortion) * distortion);
                     vec2 txt_coords = - 2.0 * curvatureCoords + 3.0 * step(vec2(0.0), curvatureCoords) * curvatureCoords - 3.0 * step(vec2(1.0), curvatureCoords) * curvatureCoords;"
                 :"
                     vec2 txt_coords = qt_TexCoord0;") +

                 "vec3 txt_color = texture2D(source, txt_coords).rgb;" +

                 (rbgShift !== 0 ? "
                     vec2 displacement = vec2(12.0, 0.0) * rbgShift;
                     vec3 rightColor = texture2D(source, txt_coords + displacement).rgb;
                     vec3 leftColor = texture2D(source, txt_coords - displacement).rgb;
                     txt_color.r = leftColor.r * 0.10 + rightColor.r * 0.30 + txt_color.r * 0.60;
                     txt_color.g = leftColor.g * 0.20 + rightColor.g * 0.20 + txt_color.g * 0.60;
                     txt_color.b = leftColor.b * 0.30 + rightColor.b * 0.10 + txt_color.b * 0.60;
                 " : "") +

                  "txt_color *= getScanlineIntensity(txt_coords);" +

                  "txt_color += vec3(0.0001);" +
                  "float greyscale_color = rgb2grey(txt_color);" +

                 (screenCurvature !== 0 ? "
                     float reflectionMask = sum2(step(vec2(0.0), curvatureCoords) - step(vec2(1.0), curvatureCoords));
                     reflectionMask = clamp(reflectionMask, 0.0, 1.0);"
                 :
                     "float reflectionMask = 1.0;") +

                 (chromaColor !== 0 ?
                     "vec3 foregroundColor = mix(fontColor.rgb, txt_color * fontColor.rgb / greyscale_color, chromaColor);
                      vec3 finalColor = mix(backgroundColor.rgb, foregroundColor, greyscale_color * reflectionMask);"
                 :
                     "vec3 finalColor = mix(backgroundColor.rgb, fontColor.rgb, greyscale_color * reflectionMask);") +

                     (bloom !== 0 ?
                         "vec4 bloomFullColor = texture2D(bloomSource, txt_coords);
                          vec3 bloomColor = bloomFullColor.rgb;
                          float bloomAlpha = bloomFullColor.a;
                          bloomColor = convertWithChroma(bloomColor);
                          finalColor += clamp(bloomColor * bloom * bloomAlpha, 0.0, 0.5);"
                     : "") +

                 "finalColor *= screen_brightness;" +

                 "gl_FragColor = vec4(finalColor, qt_Opacity);" +
             "}"

         onStatusChanged: {
             // Print warning messages
             if (log) console.log(log);
         }
     }

     ShaderEffectSource {
         id: frameBuffer
         visible: false
         sourceItem: staticShader
         hideSource: true
     }
}
