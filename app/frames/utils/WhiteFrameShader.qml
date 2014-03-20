import QtQuick 2.1

ShaderEffect{
    property variant source: framesource
    property variant normals: framesourcenormals
    property real screen_distorsion: shadersettings.screen_distortion
    property real ambient_light: shadersettings.ambient_light
    property color font_color: shadersettings.font_color
    property color background_color: shadersettings.background_color
    property real brightness: shadercontainer.brightness

    fragmentShader: "
                            uniform sampler2D source;
                            uniform sampler2D normals;
                            uniform highp float screen_distorsion;
                            uniform highp float ambient_light;

                            uniform highp vec4 font_color;
                            uniform highp vec4 background_color;
                            uniform highp float brightness;

                            varying highp vec2 qt_TexCoord0;

                            vec2 distortCoordinates(vec2 coords){
                                vec2 cc = coords - vec2(0.5);
                                float dist = dot(cc, cc) * screen_distorsion;
                                return (coords + cc * (1.0 + dist) * dist);
                            }

                            void main(){
                                vec2 coords = distortCoordinates(qt_TexCoord0);
                                vec4 txt_color = texture2D(source, coords);
                                vec4 normala = texture2D(normals, coords);
                                vec3 normal = normalize(normala.rgb) * txt_color.a;
                                float reflection = dot(normal, vec3(1.0, 1.0, 0.0)) * 0.4 * brightness;
                                vec3 reflection_color = mix(font_color, background_color, 0.7).rgb * reflection;
                                vec3 final_color = mix(txt_color.rgb, reflection_color, 1.0 - ambient_light);
                                gl_FragColor = vec4(final_color, txt_color.a);
                            }"
}
