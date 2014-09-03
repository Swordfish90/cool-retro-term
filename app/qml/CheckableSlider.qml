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
    property alias name: check.text

    property double value
    property alias min_value: slider.minimumValue
    property alias max_value: slider.maximumValue
    property alias stepSize: slider.stepSize

    signal newValue(real newValue);

    id: setting_component
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: 25

    onValueChanged: {
        check.checked = !(value == 0);
        if(check.checked)
            slider.value = value;
    }

    CheckBox{
        id: check
        implicitWidth: 150
        onClicked: {
            if(!checked){
                checked = false;
                slider.enabled = false;
                newValue(0);
            } else {
                checked = true;
                newValue(slider.value);
                slider.enabled = true;
            }
        }
    }
    Slider{
        id: slider
        stepSize: parent.stepSize
        Layout.fillWidth: true
        onValueChanged: {
            newValue(value);
        }
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
