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
        id: maincontainer
        anchors.fill: parent
        anchors.top: menuBar.bottom
        clip: true
        ShaderSettings{
            id: shadersettings
        }

        ShaderEffectSource{
            id: theSource
            sourceItem: terminal
            sourceRect: frame.sourceRect
        }

        ShaderEffect {
            id: shadercontainer
            anchors.fill: terminal
            blending: true
            z: 1.9
            property color font_color: shadersettings.font_color
            property color background_color: shadersettings.background_color
            property variant source: theSource
            property size txt_Size: Qt.size(terminal.width, terminal.height)
            property real time: 0

            property real noise_strength: shadersettings.noise_strength
            property real screen_distorsion: shadersettings.screen_distortion
            property real glowing_line_strength: shadersettings.glowing_line_strength
            property real brightness: 1.0

            property real scanlines: shadersettings.scanlines ? 1.0 : 0.0

            Behavior on brightness {
                NumberAnimation{
                    duration: 250
                    onRunningChanged:
                        if(!running) shadercontainer.brightness = 1.0;
                }
            }

            Behavior on horizontal_distortion {
                NumberAnimation{
                    duration: 150
                    onRunningChanged:
                        if(!running) shadercontainer.horizontal_distortion = 0.0;
                }
            }

            Loader{
                active: shadersettings.screen_flickering != 0
                sourceComponent: Timer{
                    property real randval
                    id: flickertimer
                    interval: 500
                    onTriggered: {
                        randval = Math.random();
                        if(randval < shadersettings.screen_flickering){
                            shadercontainer.horizontal_distortion = Math.random() * shadersettings.screen_flickering;
                        }
                        randval = Math.random();
                        if(randval < shadersettings.screen_flickering)
                        shadercontainer.brightness = Math.random() * 0.5 + 0.5;
                    }

                    repeat: true
                    running: true
                }
            }

            property real deltay: 3 / terminal.height
            property real deltax: 3 / terminal.width
            property real horizontal_distortion: 0.0
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

                        uniform highp float scanlines;

                        uniform highp float horizontal_distortion;

                        float rand(vec2 co, float time){
                            return fract(sin(dot(co.xy ,vec2(0.37898 * time ,0.78233))) * 437.5875453);
                        }

                        float stepNoise(vec2 p){
                            vec2 newP = p * txt_Size*0.25;
                            return rand(floor(newP), time);
                        }

                        float getScanlineIntensity(vec2 pos){
                            return abs(sin(pos.y * txt_Size.y)) * 0.5;
                        }

                        vec2 distortCoordinates(vec2 coords){
                            vec2 cc = coords - vec2(0.5);
                            float dist = dot(cc, cc) * screen_distorsion ;
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

                            //TODO This formula could be improved
                            float distortion = (sin(coords.y * 20.0 * fract(time * 0.1) + sin(fract(time * 0.2))) + sin(time * 0.05));
                            coords.x = coords.x + distortion * 0.3 * horizontal_distortion;

                            float color = (blurredColor(source, coords).r + texture2D(source, coords).r) * 0.5;
                            float scanline_alpha = getScanlineIntensity(coords) * scanlines;
                            float noise = stepNoise(coords) * noise_strength;
                            float randomPass = randomPass(coords) * glowing_line_strength;
                            color += noise + randomPass;
                            vec3 finalColor = mix(background_color, font_color, color).rgb;
                            finalColor = mix(finalColor, vec3(0.0), scanline_alpha);
                            gl_FragColor = vec4(finalColor * brightness, 1.0);
                        }"
        }

        Loader{
            property rect sourceRect: item.sourceRect

            id: frame
            anchors.fill: parent
            z: 2.1
            source: shadersettings.frame_source
        }

        TerminalScreen {
            id: terminal
            anchors.fill: parent

            //FIXME: Ugly forced clear terminal at the beginning
            Component.onCompleted: {
                terminal.screen.sendKey("l", 76, 67108864);
            }
        }

        RadialGradient{
            id: ambientreflection
            z: 2.0
            anchors.fill: parent
            cached: true
            opacity: shadersettings.ambient_light * 0.66
            gradient: Gradient{
                GradientStop{position: 0.0; color: "white"}
                GradientStop{position: 0.7; color: "#00000000"}
            }
        }
    }
}
