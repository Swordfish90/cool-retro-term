import QtQuick 2.0

import "utils.js" as Utils

ShaderEffect {
    property color _staticFrameColor: "#dedede"
    property color _backgroundColor: appSettings.backgroundColor
    property color _fontColor: appSettings.fontColor
    property color _lightColor: Utils.mix(_fontColor, _backgroundColor, 0.2)
    property real _ambientLight: Utils.lint(0.2, 0.8, appSettings.ambientLight)

    property color frameColor: Utils.mix(_staticFrameColor, _lightColor, _ambientLight)
    property real screenCurvature: appSettings.screenCurvature * appSettings.screenCurvatureSize
    property real shadowLength: 0.5 * screenCurvature * Utils.lint(0.50, 1.5, _ambientLight)

    fragmentShader: "
        #ifdef GL_ES
            precision mediump float;
        #endif

        uniform lowp float screenCurvature;
        uniform lowp float shadowLength;
        uniform highp float qt_Opacity;
        uniform lowp vec4 frameColor;

        varying highp vec2 qt_TexCoord0;

        vec2 distortCoordinates(vec2 coords){
            vec2 cc = (coords - vec2(0.5));
            float dist = dot(cc, cc) * screenCurvature;
            return (coords + cc * (1.0 + dist) * dist);
        }

        float max2(vec2 v) {
            return max(v.x, v.y);
        }

        float min2(vec2 v) {
            return min(v.x, v.y);
        }

        float sum2(vec2 v) {
            return v.x + v.y;
        }

        void main(){
            vec2 staticCoords = qt_TexCoord0;
            vec2 coords = distortCoordinates(staticCoords);

            vec3 color = vec3(0.0);
            float alpha = 0.0;

            float outShadowLength = shadowLength;

            float outShadow = max2(1.0 - smoothstep(vec2(-outShadowLength), vec2(0.0), coords) + smoothstep(vec2(1.0), vec2(1.0 + outShadowLength), coords));
            outShadow = clamp(0.0, 1.0, outShadow);
            color += frameColor.rgb * sqrt(outShadow);
            alpha = sum2(1.0 - step(0.0, coords) + step(1.0, coords));
            alpha = clamp(alpha, 0.0, 1.0) * mix(1.0, 0.9, sqrt(outShadow));

            gl_FragColor = vec4(color * alpha, alpha);
        }
    "

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
