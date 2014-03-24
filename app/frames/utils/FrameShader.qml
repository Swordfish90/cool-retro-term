import QtQuick 2.1

ShaderEffect{
    property variant source: framesource
    property variant normals: framesourcenormals
    property real screen_distorsion: shadersettings.screen_distortion
    property real ambient_light: shadersettings.ambient_light
    property color font_color: shadersettings.font_color
    property color background_color: shadersettings.background_color
    property real brightness: shadercontainer.brightness

    property color reflection_color: Qt.rgba((font_color.r*0.3 + background_color.r*0.7),
                                             (font_color.g*0.3 + background_color.g*0.7),
                                             (font_color.b*0.3 + background_color.b*0.7),
                                             1.0)


    fragmentShader: "
                            uniform sampler2D source;
                            uniform sampler2D normals;
                            uniform highp float screen_distorsion;
                            uniform highp float ambient_light;

                            uniform vec4 reflection_color;
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
                                vec4 txt_normal = texture2D(normals, coords);
                                vec3 normal = normalize(txt_normal.rgb * 2.0 - 1.0);
                                vec3 light_dir = normalize(vec3(0.5,0.5, 0.0) - vec3(qt_TexCoord0, 0.0));
                                float reflection = dot(normal, light_dir) * 0.4 * brightness + 0.2;
                                vec3 final_color = reflection_color * reflection * 0.5;
                                final_color += txt_color * ambient_light;
                                gl_FragColor = vec4(final_color * txt_normal.a, txt_color.a);
                            }"
}
