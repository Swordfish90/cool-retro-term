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
    property real scaling
    property alias fontlist: fontlist
    property var source: fontlist.get(selectedFontIndex).source
    property var _font: fontlist.get(selectedFontIndex)
    property int pixelSize: _font.pixelSize * scaling
    property int lineSpacing: pixelSize * _font.lineSpacing
    property real screenScaling: 1.0

    //In this configuration lineSpacing is proportional to pixelSize.

    ListModel{
        id: fontlist
        ListElement{
            text: "Terminus (Modern)"
            source: "fonts/modern-terminus/TerminusTTF-Bold-4.38.2.ttf"
            lineSpacing: 0.2
            pixelSize: 35
        }
        ListElement{
            text: "Commodore PET (1977)"
            source: "fonts/1977-commodore-pet/COMMODORE_PET.ttf"
            lineSpacing: 0.2
            pixelSize: 24
        }
        ListElement{
            text: "Apple ][ (1977)"
            source: "fonts/1977-apple2/PrintChar21.ttf"
            lineSpacing: 0.2
            pixelSize: 24
        }
        ListElement{
            text: "Atari 400-800 (1979)"
            source: "fonts/1979-atari-400-800/ATARI400800_original.TTF"
            lineSpacing: 0.3
            pixelSize: 24
        }
        ListElement{
            text: "Commodore 64 (1982)"
            source: "fonts/1982-commodore64/C64_User_Mono_v1.0-STYLE.ttf"
            lineSpacing: 0.3
            pixelSize: 24
        }
        ListElement{
            text: "Atari ST (1985)"
            source: "fonts/1985-atari-st/AtariST8x16SystemFont.ttf"
            lineSpacing: 0.2
            pixelSize: 32
        }
        ListElement{
            text: "IBM DOS (1985)"
            source: "fonts/1985-ibm-pc-vga/Perfect DOS VGA 437.ttf"
            lineSpacing: 0.2
            pixelSize: 32
        }
        ListElement{
            text: "IBM 3278 (1971)"
            source: "fonts/1971-ibm-3278/3270Medium.ttf"
            lineSpacing: 0.2
            pixelSize: 32
        }
    }
}
