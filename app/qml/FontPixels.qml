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

Item{
    property int selectedFontIndex
    property int selectedScalingIndex
    property alias fontlist: fontlist
    property var _font: fontlist.get(selectedFontIndex)
    property var _scaling: fontScalingList[selectedScalingIndex]
    property var source: _font.source
    property var fontScalingList: [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0, 2.1, 2.2, 2.3, 2.4, 2.5]
    property int pixelSize: _font.pixelSize
    property int lineSpacing: _font.lineSpacing
    property real screenScaling: _scaling * _font.baseScaling

    ListModel{
        id: fontlist
        ListElement{
            text: "Commodore PET 2Y (1977)"
            source: "fonts/1977-commodore-pet/COMMODORE_PET_2y.ttf"
            lineSpacing: 2
            pixelSize: 16
            baseScaling: 3.0
        }
        ListElement{
            text: "Commodore PET (1977)"
            source: "fonts/1977-commodore-pet/COMMODORE_PET.ttf"
            lineSpacing: 2
            pixelSize: 8
            baseScaling: 4.0
        }
        ListElement{
            text: "Apple ][ (1977)"
            source: "fonts/1977-apple2/PrintChar21.ttf"
            lineSpacing: 2
            pixelSize: 8
            baseScaling: 4.0
        }
        ListElement{
            text: "Atari 400-800 (1979)"
            source: "fonts/1979-atari-400-800/ATARI400800_original.TTF"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 4.0
        }
        ListElement{
            text: "Commodore 64 (1982)"
            source: "fonts/1982-commodore64/C64_User_Mono_v1.0-STYLE.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 4.0
        }
    }
}
