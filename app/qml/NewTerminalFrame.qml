import QtQuick 2.0

import "utils.js" as Utils

ShaderEffect {

    property real screenCurvature: appSettings.screenCurvature * appSettings.screenCurvatureSize
    property real ambientLight: Utils.lint(0.1, 0.9, appSettings.ambientLight)
    property color frameColor: "#dedede"
    property color fontColor: appSettings.fontColor
    property color backgroundColor: appSettings.backgroundColor
    property color reflectionColor: Utils.mix(fontColor, backgroundColor, 0.2)

    visible: screenCurvature != 0

    fragmentShader: "
        #ifdef GL_ES
            precision mediump float;
        #endif

        uniform lowp float screenCurvature;
        uniform lowp float ambientLight;
        uniform highp float qt_Opacity;
        uniform lowp vec4 frameColor;
        uniform lowp vec4 reflectionColor;

        varying highp vec2 qt_TexCoord0;

        vec2 distortCoordinates(vec2 coords){
            vec2 cc = (coords - vec2(0.5));
            float dist = dot(cc, cc) * screenCurvature;
            return (coords + cc * (1.0 + dist) * dist);
        }

        float max2(vec2 v) {
            return max(v.x, v.y);
        }

        float sum2(vec2 v) {
            return v.x + v.y;
        }

        void main(){
            vec2 staticCoords = qt_TexCoord0;
            vec2 coords = distortCoordinates(staticCoords);

            vec3 color = mix(reflectionColor.rgb, frameColor.rgb, ambientLight);
            float dist = 0.5 * screenCurvature;

            float shadowMask = 0.00 + max2(1.0 - smoothstep(vec2(-dist), vec2(0.0), coords) + smoothstep(vec2(1.0), vec2(1.0 + dist), coords));
            shadowMask = clamp(0.0, 1.0, shadowMask);
            color *= pow(shadowMask, 0.5);

            float alpha = sum2(1.0 - step(0.0, coords) + step(1.0, coords));
            alpha = clamp(alpha, 0.0, 1.0) * mix(1.0, 0.9, pow(shadowMask, 0.5));

            gl_FragColor = vec4(color * alpha, alpha);
        }
    "

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
