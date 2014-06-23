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
import QtQuick.Layouts 1.1

RowLayout {
    property string name
    property double value: (check.checked) ? _value : 0.0
    property double _value: 0.0
    property double min_value: 0.0
    property double max_value: 1.0
    property double stepSize: 0.01

    id: setting_component
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 25

    CheckBox{
        id: check
        implicitWidth: 150

        text: name
        Component.onCompleted: checked = (_value !== 0);
    }
    Slider{
        id: slider
        stepSize: parent.stepSize
        minimumValue: min_value
        maximumValue: max_value
        onValueChanged: setting_component._value = slider.value;
        Layout.fillWidth: true
        enabled: check.checked
        value: setting_component._value

        Component.onCompleted: slider.value = setting_component._value
    }
    Text{
        id: textfield
        property string unformattedText: Math.round(((value - min_value) / (max_value - min_value)) * 100)
        text: formatNumber(unformattedText)
    }
    function formatNumber(num) {
        var n = "" + num;
        while (n.length < 3) {
            n = " " + n;
        }
        return n + "%";
    }
}
