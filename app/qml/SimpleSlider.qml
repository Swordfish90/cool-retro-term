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

RowLayout {
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property alias minimumValue: slider.minimumValue
    property alias maximumValue: slider.maximumValue
    property real maxMultiplier: 100

    id: setting_component
    spacing: 10
    Slider{
        id: slider
        stepSize: parent.stepSize
        Layout.fillWidth: true
    }
    Text{
        id: textfield
        text: formatNumber(Math.round(value * maxMultiplier))
    }
    function formatNumber(num) {
        var n = "" + num;
        while (n.length < 3) {
            n = " " + n;
        }
        return n + "%";
    }
}
