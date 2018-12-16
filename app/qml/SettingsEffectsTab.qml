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
    ColumnLayout{
        anchors.fill: parent
        spacing: 2

        GroupBox{
            title: qsTr("Effects")
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent

                CheckableSlider{
                    name: qsTr("Bloom")
                    onNewValue: appSettings.bloom = newValue
                    value: appSettings.bloom
                }
                CheckableSlider{
                    name: qsTr("BurnIn")
                    onNewValue: appSettings.burnIn = newValue
                    value: appSettings.burnIn
                }
                CheckableSlider{
                    name: qsTr("Static Noise")
                    onNewValue: appSettings.staticNoise = newValue
                    value: appSettings.staticNoise
                }
                CheckableSlider{
                    name: qsTr("Jitter")
                    onNewValue: appSettings.jitter = newValue
                    value: appSettings.jitter
                }
                CheckableSlider{
                    name: qsTr("Glow Line")
                    onNewValue: appSettings.glowingLine = newValue;
                    value: appSettings.glowingLine
                }
                CheckableSlider{
                    name: qsTr("Screen Curvature")
                    onNewValue: appSettings.screenCurvature = newValue;
                    value: appSettings.screenCurvature;
                }
                CheckableSlider{
                    name: qsTr("Ambient Light")
                    onNewValue: appSettings.ambientLight = newValue;
                    value: appSettings.ambientLight
                    enabled: appSettings.framesIndex !== 0
                }
                CheckableSlider{
                    name: qsTr("Flickering")
                    onNewValue: appSettings.flickering = newValue;
                    value: appSettings.flickering;
                }
                CheckableSlider{
                    name: qsTr("Horizontal Sync")
                    onNewValue: appSettings.horizontalSync = newValue;
                    value: appSettings.horizontalSync;
                }
                CheckableSlider{
                    name: qsTr("RGB Shift")
                    onNewValue: appSettings.rbgShift = newValue;
                    value: appSettings.rbgShift;
                }
            }
        }
    }
}
