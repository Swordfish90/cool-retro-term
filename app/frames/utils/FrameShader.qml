import QtQuick 2.2

ShaderEffect{
    property variant source: framesource
    property variant normals: framesourcenormals
    property real screen_distorsion: shadersettings.screen_distortion * framecontainer.distortionCoefficient
    property real ambient_light: shadersettings.ambient_light
    property color font_color: shadersettings.font_color
    property color background_color: shadersettings.background_color
    property real time: timetimer.time
    property variant randomFunctionSource: randfuncsource
    property real brightness_flickering: shadersettings.brightness_flickering
    property real brightness: shadersettings.brightness * 1.5 + 0.5

    property real frame_reflection_strength: shadersettings.frame_reflection_strength

    property color reflection_color: Qt.rgba((font_color.r*0.3 + background_color.r*0.7),
                                             (font_color.g*0.3 + background_color.g*0.7),
                                             (font_color.b*0.3 + background_color.b*0.7),
                                             1.0)

    blending: true

    vertexShader: "
                    uniform highp mat4 qt_Matrix;
                    uniform highp float time;
                    uniform sampler2D randomFunctionSource;

                    attribute highp vec4 qt_Vertex;
                    attribute highp vec2 qt_MultiTexCoord0;

                    varying highp vec2 qt_TexCoord0;
                    varying lowp float brightness;

                    void main() {
                        qt_TexCoord0 = qt_MultiTexCoord0;
                        brightness = "+brightness.toFixed(1)+";" +
                        (brightness_flickering !== 0 ?
                            "brightness -= texture2D(randomFunctionSource, vec2(fract(time/(1024.0*2.0)), fract(time/(1024.0*1024.0*2.0)))).r * "+brightness_flickering.toFixed(1)+";"
                        : "") + "

                        gl_Position = qt_Matrix * qt_Vertex;
                    }"

    fragmentShader: "
                            uniform sampler2D source;
                            uniform sampler2D normals;
                            uniform highp float screen_distorsion;
                            uniform highp float ambient_light;
                            uniform highp float qt_Opacity;

                            uniform vec4 reflection_color;
                            varying lowp float brightness;

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
                                float diffuse = dot(normal, light_dir);
                                float reflection = (diffuse * 0.6 + 0.4) * txt_normal.a;
                                float reflection_alpha = (1.0 - diffuse*"+frame_reflection_strength.toFixed(1)+");
                                vec4 dark_color = vec4(reflection_color.rgb * reflection * 0.4, txt_normal.a * reflection_alpha);
                                gl_FragColor = mix(dark_color, txt_color, ambient_light);
                            }"

    onStatusChanged: if (log) console.log(log) //Print warning messages
}
