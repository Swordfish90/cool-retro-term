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
                onNewValue: appSettings.bloom_strength = newValue
                value: appSettings.bloom_strength
            }
            CheckableSlider{
                name: qsTr("Motion Blur")
                onNewValue: appSettings.motion_blur = newValue
                value: appSettings.motion_blur
            }
            CheckableSlider{
                name: qsTr("Noise")
                onNewValue: appSettings.noise_strength = newValue
                value: appSettings.noise_strength
            }
            CheckableSlider{
                name: qsTr("Jitter")
                onNewValue: appSettings.jitter = newValue
                value: appSettings.jitter
            }
            CheckableSlider{
                name: qsTr("Glow")
                onNewValue: appSettings.glowing_line_strength = newValue;
                value: appSettings.glowing_line_strength
            }
            CheckableSlider{
                name: qsTr("Screen distortion")
                onNewValue: appSettings.screen_distortion = newValue;
                value: appSettings.screen_distortion;
            }
            CheckableSlider{
                name: qsTr("Ambient light")
                onNewValue: appSettings.ambient_light = newValue;
                value: appSettings.ambient_light
                enabled: appSettings.frames_index !== 0
            }
            CheckableSlider{
                name: qsTr("Brightness flickering")
                onNewValue: appSettings.brightness_flickering = newValue;
                value: appSettings.brightness_flickering;
            }
            CheckableSlider{
                name: qsTr("Horizontal flickering")
                onNewValue: appSettings.horizontal_sincronization = newValue;
                value: appSettings.horizontal_sincronization;
            }
            CheckableSlider{
                name: qsTr("RGB shift")
                onNewValue: appSettings.rgb_shift = newValue;
                value: appSettings.rgb_shift;
                enabled: appSettings.chroma_color !== 0
            }
        }
    }
}
