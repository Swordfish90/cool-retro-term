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

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

Window {
    id: settings_window
    title: qsTr("Settings")
    width: 640
    height: 480

    modality: Qt.ApplicationModal

    TabView{
        anchors.fill: parent
        anchors.margins: 10
        Tab{
            title: qsTr("Appearance")
            anchors.fill: parent
            anchors.margins: 15
            GridLayout{
                anchors.fill: parent
                columns: 2
                GroupBox{
                    anchors.left: parent.left
                    anchors.right: parent.right
                    Layout.columnSpan: 2
                    title: qsTr("Profile")
                    RowLayout{
                        anchors.fill: parent
                        ComboBox{
                            id: profilesbox
                            Layout.fillWidth: true
                            model: shadersettings.profiles_list
                            currentIndex: shadersettings.profiles_index
                        }
                        Button{
                            text: "Load"
                            onClicked: shadersettings.profiles_index = profilesbox.currentIndex
                        }
                        Button{
                            text: "Add"
                            onClicked: insertname.show()
                        }
                        Button{
                            text: "Remove"
                            enabled: !shadersettings.profiles_list.get(profilesbox.currentIndex).builtin
                            onClicked: {
                                shadersettings.profiles_list.remove(profilesbox.currentIndex)
                                profilesbox.currentIndex = profilesbox.currentIndex - 1
                            }
                        }
                        InsertNameDialog{
                            id: insertname
                            onNameSelected: shadersettings.addNewCustomProfile(name)
                        }
                    }
                }

                GroupBox{
                    id: fontbox
                    title: qsTr("Font")
                    Layout.fillHeight: true
                    Layout.fillWidth: true
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
                            decimals: 2
                            stepSize: 0.25
                            value: shadersettings.font_scaling
                            minimumValue: 0.5
                            maximumValue: 2.0
                            onValueChanged: shadersettings.font_scaling = value;
                        }
                        Item{Layout.fillHeight: true}
                        ColorButton{
                            height: 50
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            onButton_colorChanged: shadersettings._font_color = button_color;
                            button_color: shadersettings._font_color;
                        }
                    }
                }
                GroupBox{
                    title: qsTr("Background")
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    GridLayout{
                        anchors.fill: parent
                        columns: 2
                        Text{text: "Frame texture"}
                        ComboBox{
                            id: framescombobox
                            Layout.fillWidth: true
                            model: shadersettings.frames_list
                            currentIndex: shadersettings.frames_index
                            onCurrentIndexChanged: shadersettings.frames_index = currentIndex
                        }
                        CheckBox{
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            checked: shadersettings.frame_reflections
                            text: qsTr("Frame reflections")
                            onCheckedChanged: shadersettings.frame_reflections = checked
                            enabled: framescombobox.model.get(framescombobox.currentIndex).reflections
                        }

                        Item{Layout.fillHeight: true}
                        ColorButton{
                            height: 50
                            Layout.fillWidth: true
                            Layout.columnSpan: 2

                            onButton_colorChanged: shadersettings._background_color= button_color
                            button_color: shadersettings._background_color;
                        }
                    }
                }
                GroupBox{
                    title: qsTr("Lights")
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    GridLayout{
                        Layout.columnSpan: 2
                        columns: 2
                        rows: 2
                        anchors.left: parent.left
                        anchors.right: parent.right
                        Text{text: qsTr("Contrast")}
                        SimpleSlider{
                            onValueChanged: shadersettings.contrast = value
                            value: shadersettings.contrast
                        }
                        Text{text: qsTr("Brightness")}
                        SimpleSlider{
                            onValueChanged: shadersettings.brightness = value
                            value: shadersettings.brightness
                        }
                    }
                }
                GroupBox{
                    title: qsTr("Performace")
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    GridLayout{
                        columns: 3
                        Layout.columnSpan: 2
                        anchors {left: parent.left; right: parent.right}
                        Text{text: "Animation FPS"}
                        Slider{
                            Layout.fillWidth: true
                            id: slider
                            stepSize: 1
                            maximumValue: 60
                            minimumValue: 0
                            onValueChanged: shadersettings.fps = value;
                            value: shadersettings.fps
                        }
                        Text{text: slider.value}
                        Text{text: "Texture quality"}
                        Slider{
                            Layout.fillWidth: true
                            id: txtslider
                            stepSize: 0.01
                            maximumValue: 1
                            minimumValue: 0
                            onValueChanged: shadersettings.window_scaling = value;
                            value: shadersettings.window_scaling
                            updateValueWhileDragging: false
                        }
                        Text{text: Math.round(txtslider.value * 100) + "%"}
                    }
                }
            }
        }

        Tab{
            title: qsTr("Eye-candy")
            anchors.fill: parent
            anchors.margins: 15

            ColumnLayout{
                anchors.fill: parent
                GroupBox{
                    title: qsTr("Rasterization")
                    anchors.left: parent.left
                    anchors.right: parent.right
                    ColumnLayout{
                        anchors.left: parent.left
                        anchors.right: parent.right
                        RowLayout{
                            anchors.left: parent.left
                            anchors.right: parent.right
                            ExclusiveGroup { id: rasterizationgroup }
                            RadioButton {
                                text: qsTr("No Rasterization")
                                exclusiveGroup: rasterizationgroup
                                checked: shadersettings.rasterization === shadersettings.no_rasterization
                                onCheckedChanged: if(checked)
                                                      shadersettings.rasterization = shadersettings.no_rasterization
                            }
                            RadioButton {
                                text: qsTr("Scanlines")
                                exclusiveGroup: rasterizationgroup
                                checked: shadersettings.rasterization === shadersettings.scanline_rasterization
                                onCheckedChanged: if(checked)
                                                      shadersettings.rasterization = shadersettings.scanline_rasterization
                            }
                            RadioButton {
                                text: qsTr("Pixels")
                                exclusiveGroup: rasterizationgroup
                                checked: shadersettings.rasterization === shadersettings.pixel_rasterization
                                onCheckedChanged: if(checked)
                                                      shadersettings.rasterization = shadersettings.pixel_rasterization
                            }
                        }
                        SimpleSlider{
                            Layout.fillWidth: true
                            value: shadersettings.rasterization_strength
                            onValueChanged: shadersettings.rasterization_strength = value
                        }
                    }
                }
                GroupBox{
                    title: qsTr("Effects")
                    anchors.left: parent.left
                    anchors.right: parent.right
                    ColumnLayout{
                        anchors.fill: parent
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
                            name: "Brightness flickering"
                            onValueChanged: shadersettings.brightness_flickering= value;
                            _value: shadersettings.brightness_flickering;
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
}
