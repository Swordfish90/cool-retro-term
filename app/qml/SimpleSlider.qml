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

import "Components"

RowLayout {
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property alias minimumValue: slider.from
    property alias maximumValue: slider.to
    property real maxMultiplier: 100

    id: setting_component
    spacing: 10
    Slider {
        id: slider
        stepSize: parent.stepSize
        Layout.fillWidth: true
    }
    SizedLabel {
        text: Math.round(value * maxMultiplier) + "%"
    }
}
