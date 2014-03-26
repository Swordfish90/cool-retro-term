/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordifish90/cool-old-term
*
* This file is part of cool-old-term.
*
* cool-old-term is free software: you can redistribute it and/or modify
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

import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Window 2.1
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1

ApplicationWindow {
    id: settings_window
    title: qsTr("Settings")
    width: 640
    height: 400

    //modality: Qt.ApplicationModal

    TabView{
        anchors.fill: parent

        Tab{
            title: qsTr("Appearance")
            anchors.margins: 20
            anchors.top: parent.top

            GridLayout{
                anchors.fill: parent
                columns: 2
                GroupBox{
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    title: qsTr("Profile")
                    ComboBox{
                        anchors.fill: parent
                        model: shadersettings.profiles_list
                        onCurrentIndexChanged: {
                            shadersettings.loadProfile(shadersettings.profiles_list.get(currentIndex).obj_name);
                        }
                    }
                }

                GroupBox{
                    id: fontbox
                    title: qsTr("Font")
                    Layout.fillWidth: true
                    Layout.fillHeight:true
                    GridLayout{
                        anchors.fill: parent
                        columns: 2
                        Text{text: qsTr("Font style:")}
                        ComboBox{
                            Layout.fillWidth: true
                            model: shadersettings.fonts_list
                            currentIndex: shadersettings.font_index
                            onCurrentIndexChanged: shadersettings.font_index = currentIndex
                        }
                        Text{text: qsTr("Font scaling:")}
                        SpinBox{
                            Layout.fillWidth: true
                            decimals: 1
                            stepSize: 0.1
                            value: shadersettings.font_scaling
                            minimumValue: 0.5
                            maximumValue: 1.5
                            onValueChanged: shadersettings.font_scaling = value;
                        }
                        Item{Layout.fillHeight: true}
                        ColorButton{
                            height: 50
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            onButton_colorChanged: shadersettings.font_color = button_color;
                            Component.onCompleted: button_color = shadersettings.font_color;
                        }
                    }
                }
                GroupBox{
                    title: qsTr("Background")
                    Layout.fillWidth: true
                    Layout.fillHeight:true
                    GridLayout{
                        anchors.fill: parent
                        columns: 2
                        Text{text: "Frame texture"}
                        ComboBox{
                            Layout.fillWidth: true
                            model: shadersettings.frames_list
                            currentIndex: shadersettings.frames_index
                            onCurrentIndexChanged: shadersettings.frames_index = currentIndex
                        }
                        Item{Layout.fillHeight: true}

                        ColorButton{
                            height: 50
                            Layout.fillWidth: true
                            Layout.columnSpan: 2

                            onButton_colorChanged: shadersettings.background_color= button_color
                            Component.onCompleted: button_color = shadersettings.background_color;
                        }
                    }
                }
            }
        }

        Tab{
            title: qsTr("Eye-candy")
            anchors.fill: parent
            anchors.margins: 20

            GroupBox{
                title: qsTr("Effects")
                anchors.fill: parent

                ColumnLayout{
                    anchors.fill: parent

                    CheckBox{
                        text: "Scanlines"
                        checked: shadersettings.scanlines
                        onCheckedChanged: shadersettings.scanlines = checked;
                    }
                    SettingComponent{
                        name: "Bloom"
                        onValueChanged: shadersettings.bloom_strength = value
                        _value: shadersettings.bloom_strength
                    }
                    SettingComponent{
                        name: "Motion Blur"
                        onValueChanged: shadersettings.motion_blur = value
                        _value: shadersettings.motion_blur
                    }
                    SettingComponent{
                        name: "Noise"
                        onValueChanged: shadersettings.noise_strength = value
                        _value: shadersettings.noise_strength
                    }
                    SettingComponent{
                        name: "Glow"
                        onValueChanged: shadersettings.glowing_line_strength = value;
                        _value: shadersettings.glowing_line_strength
                    }
                    SettingComponent{
                        name: "Ambient light"
                        onValueChanged: shadersettings.ambient_light = value;
                        _value: shadersettings.ambient_light
                    }
                    SettingComponent{
                        name: "Screen distortion"
                        onValueChanged: shadersettings.screen_distortion = value;
                        _value: shadersettings.screen_distortion;
                    }
                    SettingComponent{
                        name: "Screen flickering"
                        onValueChanged: shadersettings.screen_flickering = value;
                        _value: shadersettings.screen_flickering;
                    }
                    SettingComponent{
                        name: "Horizontal flickering"
                        onValueChanged: shadersettings.horizontal_sincronization = value;
                        _value: shadersettings.horizontal_sincronization;
                    }
                }
            }
        }
    }
}
