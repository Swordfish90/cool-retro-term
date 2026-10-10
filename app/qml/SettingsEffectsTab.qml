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
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

ScrollView {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
        width: parent.width
        spacing: 10

        GroupBox {
            title: qsTr("CRT Effects")
            Layout.fillWidth: true
            padding: appSettings.defaultMargin

            ColumnLayout {
                anchors.fill: parent

                CheckableSlider {
                    name: qsTr("Bloom")
                    onNewValue: function(newValue) { appSettings.bloom = newValue }
                    value: appSettings.bloom
                }
                CheckableSlider {
                    name: qsTr("BurnIn")
                    onNewValue: function(newValue) { appSettings.burnIn = newValue }
                    value: appSettings.burnIn
                }
                CheckableSlider {
                    name: qsTr("Static Noise")
                    onNewValue: function(newValue) { appSettings.staticNoise = newValue }
                    value: appSettings.staticNoise
                }
                CheckableSlider {
                    name: qsTr("Jitter")
                    onNewValue: function(newValue) { appSettings.jitter = newValue }
                    value: appSettings.jitter
                }
                CheckableSlider {
                    name: qsTr("Glow Line")
                    onNewValue: function(newValue) { appSettings.glowingLine = newValue }
                    value: appSettings.glowingLine
                }
                CheckableSlider {
                    name: qsTr("Screen Curvature")
                    onNewValue: function(newValue) { appSettings.screenCurvature = newValue }
                    value: appSettings.screenCurvature
                }
                CheckableSlider {
                    name: qsTr("Ambient Light")
                    onNewValue: function(newValue) { appSettings.ambientLight = newValue }
                    value: appSettings.ambientLight
                    enabled: appSettings.framesIndex !== 0
                }
                CheckableSlider {
                    name: qsTr("Flickering")
                    onNewValue: function(newValue) { appSettings.flickering = newValue }
                    value: appSettings.flickering
                }
                CheckableSlider {
                    name: qsTr("Horizontal Sync")
                    onNewValue: function(newValue) { appSettings.horizontalSync = newValue }
                    value: appSettings.horizontalSync
                }
                CheckableSlider {
                    name: qsTr("RGB Shift")
                    onNewValue: function(newValue) { appSettings.rgbShift = newValue }
                    value: appSettings.rgbShift
                }
                CheckableSlider {
                    name: qsTr("Frame Shininess")
                    onNewValue: function(newValue) { appSettings._frameShininess = newValue }
                    value: appSettings._frameShininess
                }
            }
        }

        GroupBox {
            title: qsTr("VHS Tape Effects")
            Layout.fillWidth: true
            padding: appSettings.defaultMargin

            ColumnLayout {
                anchors.fill: parent

                CheckableSlider {
                    name: qsTr("Color Bleed")
                    onNewValue: function(newValue) { appSettings.vhsBleed = newValue }
                    value: appSettings.vhsBleed
                }
                CheckableSlider {
                    name: qsTr("Tape Jitter")
                    onNewValue: function(newValue) { appSettings.vhsJitter = newValue }
                    value: appSettings.vhsJitter
                }
                CheckableSlider {
                    name: qsTr("Head Switch")
                    onNewValue: function(newValue) { appSettings.vhsHeadSwitch = newValue }
                    value: appSettings.vhsHeadSwitch
                }
            }
        }
    }
}
