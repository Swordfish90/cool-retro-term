/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordfish90/cool-retro-term
*
* This file is part of cool-retro-term.
*
* cool-retro-term is free software: you can redistribute it and/or modify
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
import QtQuick.Layouts 1.1

Tab{
    GroupBox{
        title: qsTr("Effects")
        anchors.fill: parent
        ColumnLayout{
            anchors.fill: parent
            CheckableSlider{
                name: qsTr("Bloom")
                onNewValue: shadersettings.bloom_strength = newValue
                value: shadersettings.bloom_strength
            }
            CheckableSlider{
                name: qsTr("Motion Blur")
                onNewValue: shadersettings.motion_blur = newValue
                value: shadersettings.motion_blur
            }
            CheckableSlider{
                name: qsTr("Noise")
                onNewValue: shadersettings.noise_strength = newValue
                value: shadersettings.noise_strength
            }
            CheckableSlider{
                name: qsTr("Jitter")
                onNewValue: shadersettings.jitter = newValue
                value: shadersettings.jitter
            }
            CheckableSlider{
                name: qsTr("Glow")
                onNewValue: shadersettings.glowing_line_strength = newValue;
                value: shadersettings.glowing_line_strength
            }
            CheckableSlider{
                name: qsTr("Screen distortion")
                onNewValue: shadersettings.screen_distortion = newValue;
                value: shadersettings.screen_distortion;
            }
            CheckableSlider{
                name: qsTr("Ambient light")
                onNewValue: shadersettings.ambient_light = newValue;
                value: shadersettings.ambient_light
                enabled: shadersettings.frames_index !== 0
            }
            CheckableSlider{
                name: qsTr("Brightness flickering")
                onNewValue: shadersettings.brightness_flickering = newValue;
                value: shadersettings.brightness_flickering;
            }
            CheckableSlider{
                name: qsTr("Horizontal flickering")
                onNewValue: shadersettings.horizontal_sincronization = newValue;
                value: shadersettings.horizontal_sincronization;
            }
            CheckableSlider{
                name: qsTr("RGB shift")
                onNewValue: shadersettings.rgb_shift = newValue;
                value: shadersettings.rgb_shift;
                enabled: shadersettings.chroma_color !== 0
            }
        }
    }
}
