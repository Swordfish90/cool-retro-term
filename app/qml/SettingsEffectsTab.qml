/*******************************************************************************
* Copyright (c) 2013-2021 "Filippo Scognamiglio"
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
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

ColumnLayout {
    // The profile of the focused terminal: settings apply to it only.
    readonly property TerminalProfile profile: appRoot.activeProfile

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 2

    GroupBox {
        title: qsTr("Effects")
        Layout.fillWidth: true
        Layout.fillHeight: true
        padding: appSettings.defaultMargin

        ColumnLayout {
            anchors.fill: parent

            CheckableSlider {
                name: qsTr("Bloom")
                onNewValue: function(newValue) { profile.bloom = newValue }
                value: profile.bloom
            }
            CheckableSlider {
                name: qsTr("BurnIn")
                onNewValue: function(newValue) { profile.burnIn = newValue }
                value: profile.burnIn
            }
            CheckableSlider {
                name: qsTr("Static Noise")
                onNewValue: function(newValue) { profile.staticNoise = newValue }
                value: profile.staticNoise
            }
            CheckableSlider {
                name: qsTr("Jitter")
                onNewValue: function(newValue) { profile.jitter = newValue }
                value: profile.jitter
            }
            CheckableSlider {
                name: qsTr("Glow Line")
                onNewValue: function(newValue) { profile.glowingLine = newValue }
                value: profile.glowingLine
            }
            CheckableSlider {
                name: qsTr("Screen Curvature")
                onNewValue: function(newValue) { profile.screenCurvature = newValue }
                value: profile.screenCurvature
            }
            CheckableSlider {
                name: qsTr("Ambient Light")
                onNewValue: function(newValue) { profile.ambientLight = newValue }
                value: profile.ambientLight
                enabled: appSettings.framesIndex !== 0
            }
            CheckableSlider {
                name: qsTr("Flickering")
                onNewValue: function(newValue) { profile.flickering = newValue }
                value: profile.flickering
            }
            CheckableSlider {
                name: qsTr("Horizontal Sync")
                onNewValue: function(newValue) { profile.horizontalSync = newValue }
                value: profile.horizontalSync
            }
            CheckableSlider {
                name: qsTr("RGB Shift")
                onNewValue: function(newValue) { profile.rgbShift = newValue }
                value: profile.rgbShift
            }
            CheckableSlider {
                name: qsTr("Frame Shininess")
                onNewValue: function(newValue) { profile._frameShininess = newValue }
                value: profile._frameShininess
            }
        }
    }
}
