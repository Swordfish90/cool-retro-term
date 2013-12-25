import QtQuick 2.1

ShaderEffect{
    property variant source: framesource
    property real screen_distorsion: shadersettings.screen_distortion

    fragmentShader: "
        uniform sampler2D source;
        uniform highp float screen_distorsion;
        varying highp vec2 qt_TexCoord0;

        vec2 distortCoordinates(vec2 coords){
            vec2 cc = coords - vec2(0.5);
            float dist = dot(cc, cc) * screen_distorsion;
            return (coords + cc * (1.0 + dist) * dist);
        }

        void main(){
            vec2 coords = distortCoordinates(qt_TexCoord0);
            float inside = texture2D(source, coords).a;
            gl_FragColor = vec4(vec3(0.0), inside);
        }"
}
