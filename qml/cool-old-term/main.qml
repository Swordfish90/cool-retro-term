/****************************************************************************
 * This file is part of Terminal.
 *
 * Copyright (C) 2013 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * Author(s):
 *    Pier Luigi Fiorini
 *
 * $BEGIN_LICENSE:GPL2+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import QtGraphicalEffects 1.0

ApplicationWindow{
    id: mainwindow
    width: 1024
    height: 768

    title: qsTr("Terminal")

    menuBar: MenuBar {
        id: menubar
        Menu {
            title: qsTr("File")
            MenuItem { text: "Close"; onTriggered: mainwindow.close()}
        }
        Menu {
            title: qsTr("Edit")
            MenuItem {
                text: qsTr("Settings")
                onTriggered: {
                    var component = Qt.createComponent("SettingsWindow.qml");
                    component.createObject(mainwindow);
                }
            }
        }


    }

    visible: true

    Item{
        anchors.fill: parent
        anchors.topMargin: 30 //Fix the constant
        ShaderSettings{
            id: shadersettings
        }

        ShaderEffectSource{
            property double offset_top: 0.03
            property double offset_bottom: 0.04
            id: theSource
            sourceItem: terminal
            sourceRect: Qt.rect(-offset_top * terminal.width, -offset_top * terminal.height, terminal.width + offset_bottom * terminal.width, terminal.height + offset_bottom * terminal.height)
        }

        ShaderEffect {
            id: shadercontainer
            width: parent.width
            height: parent.height
            anchors.centerIn: parent
            blending: true
            z: 2
            property color font_color: shadersettings.font_color
            property color background_color: shadersettings.background_color
            property variant source: theSource
            property size txt_Size: Qt.size(terminal.width, terminal.height)
            property real time: 0

            property real noise_strength: shadersettings.noise_strength
            property real screen_distorsion: shadersettings.screen_distortion
            property real glowing_line_strength: shadersettings.glowing_line_strength
            property real brightness: 1.0

            NumberAnimation on brightness{
                to: 1.0
                duration: 300
                onStopped: {to = 1 - Math.random() * shadersettings.brightness_flickering; start();}
                running: true
            }

            property real deltay: 1.0 / terminal.height
            property real deltax: 1.0 / terminal.width
            //property real faulty_screen_prob: shadersettings.faulty_screen_prob

            NumberAnimation on time{
                from: -1
                to: 100
                duration: 5000

                loops: Animation.Infinite
            }

            fragmentShader: "
                        uniform sampler2D source;
                        uniform highp float qt_Opacity;
                        uniform highp float time;
                        uniform highp vec2 txt_Size;
                        varying highp vec2 qt_TexCoord0;

                        uniform highp vec4 font_color;
                        uniform highp vec4 background_color;

                        uniform highp float noise_strength;
                        uniform highp float screen_distorsion;
                        uniform highp float glowing_line_strength;
                        uniform highp float brightness;

                        uniform highp float deltax;
                        uniform highp float deltay;

                        float rand(vec2 co, float time){
                            return fract(sin(dot(co.xy ,vec2(0.37898 * time ,0.78233))) * 437.5875453);
                        }

                        float stepNoise(vec2 p){
                            vec2 newP = p * txt_Size*0.25;
                            return rand(floor(newP), time);
                        }

                        float getScanlineIntensity(vec2 pos){
                            return 0.5 + abs(sin(pos.y * txt_Size.y)) * 0.5;
                        }

                        vec2 distortCoordinates(vec2 coords){
                            vec2 cc = coords - vec2(0.5);
                            float dist = dot(cc, cc) * screen_distorsion;
                            return (coords + cc * (1.0 + dist) * dist);
                        }

                        float randomPass(vec2 coords){
                            return fract(smoothstep(-0.2, 0.0, coords.y - time * 0.03)) * glowing_line_strength;
                        }

                        vec4 blurredColor(sampler2D source, vec2 coords){
                            vec4 sum = vec4(0.0);
                            sum += texture2D(source, coords - vec2(-deltax, -deltay)) * 0.11;
                            sum += texture2D(source, coords - vec2(-deltax, 0.0)) * 0.11;
                            sum += texture2D(source, coords - vec2(-deltax, +deltay)) * 0.11;
                            sum += texture2D(source, coords - vec2(0.0, -deltay)) * 0.11;
                            sum += texture2D(source, coords - vec2(0.0, 0.0)) * 0.11;
                            sum += texture2D(source, coords - vec2(0.0, +deltay)) * 0.11;
                            sum += texture2D(source, coords - vec2(+deltax, -deltay)) * 0.11;
                            sum += texture2D(source, coords - vec2(+deltax, 0.0)) * 0.11;
                            sum += texture2D(source, coords - vec2(+deltax, +deltay)) * 0.11;
                            return sum;
                        }

                        void main() {
                            vec2 coords = distortCoordinates(qt_TexCoord0);

                            //Emulate faulty screen
                            //coords.x = coords.x + sin(coords.y * 5.0) * 0.05 * step(faulty_screen_prob, rand(txt_Size, floor(time)));

                            //vec4 color = texture2D(source, coords);
                            vec4 color = blurredColor(source, coords) * brightness;
                            float scanline_alpha = getScanlineIntensity(coords);
                            float inside = step(0.0, coords.x) * step(-1.0, -coords.x) * step(0.0, coords.y) * step(-1.0, -coords.y);
                            float noise = stepNoise(coords) * noise_strength;
                            float randomPass = randomPass(coords) * glowing_line_strength;
                            vec4 added_color = (noise + randomPass) * font_color;
                            vec4 finalColor = color + added_color;
                            finalColor = mix(finalColor, background_color, 1.0 - scanline_alpha);
                            gl_FragColor = vec4(finalColor.rgb, 1.0);
                        }"
        }

        ShaderEffect{
            z: 2.1
            width: parent.width * 1.05
            height: parent.height * 1.05
            anchors.centerIn: parent

            property variant source: framesource
            property real screen_distorsion: shadersettings.screen_distortion - 0.22
            property real ambient_light: shadersettings.ambient_light

            fragmentShader: "
            uniform sampler2D source;
            uniform highp float screen_distorsion;
            uniform highp float ambient_light;

            varying highp vec2 qt_TexCoord0;

            vec2 distortCoordinates(vec2 coords){
                vec2 cc = coords - vec2(0.5);
                float dist = dot(cc, cc) * screen_distorsion;
                return (coords + cc * (1.0 + dist) * dist);
            }

            void main(){
                vec2 coords = distortCoordinates(qt_TexCoord0);
                vec4 txt_color = texture2D(source, coords);
                vec4 final_color = mix(txt_color, vec4(vec3(0.0), 1.0), 1.0 - ambient_light);
                gl_FragColor = vec4(final_color.rgb, txt_color.a);
            }"
        }

        ShaderEffectSource{
            id: framesource
            sourceItem: frame
            hideSource: true
            live: false
        }

        Image{
            id: frame
            source: "../images/squared_frame.png"
            anchors.centerIn: parent
            visible: true
            opacity: shadersettings.ambient_light
        }

        TerminalScreen {
            id: terminal
            anchors.centerIn: parent
            width: mainwindow.width
            height: mainwindow.height
            visible: false

            //FIXME: Ugly forced clear terminal at the beginning
            Component.onCompleted: terminal.screen.sendKey("l", 76, 67108864);
        }

        RadialGradient{
            z: 4
            anchors.fill: parent
            cached: true
            opacity: 0.2
            gradient: Gradient{
                GradientStop{position: 0.0; color: shadersettings.font_color}
                GradientStop{position: 1.0; color: shadersettings.background_color}
            }
        }
    }
}
