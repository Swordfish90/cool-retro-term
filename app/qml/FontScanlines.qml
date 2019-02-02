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

QtObject{
    property int selectedFontIndex
    property real scaling
    property var _font: fontlist.get(selectedFontIndex)
    property var source: _font.source
    property int pixelSize: _font.pixelSize
    property int lineSpacing: _font.lineSpacing
    property real screenScaling: scaling * _font.baseScaling
    property real defaultFontWidth: fontlist.get(selectedFontIndex).fontWidth
    property bool lowResolutionFont: true

    property ListModel fontlist: ListModel{
        ListElement{
            name: "COMMODORE_PET"
            text: "Commodore PET (1977)"
            source: "fonts/1977-commodore-pet/PetMe.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.7
        }
        ListElement{
            name: "IBM_PC"
            text: "IBM PC (1981)"
            source: "fonts/1981-ibm-pc/PxPlus_IBM_BIOS.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.8
        }
        ListElement{
            name: "PROGGY_TINY"
            text: "Proggy Tiny (Modern)"
            source: "fonts/modern-proggy-tiny/ProggyTiny.ttf"
            lineSpacing: 1
            pixelSize: 16
            baseScaling: 3.3
            fontWidth: 0.9
        }
        ListElement{
            name: "TERMINUS_SCALED"
            text: "Terminus (Modern)"
            source: "fonts/modern-terminus/TerminusTTF-4.46.0.ttf"
            lineSpacing: 1
            pixelSize: 12
            baseScaling: 3.0
            fontWidth: 1.0
        }
        ListElement{
            name: "PRO_FONT_SCALED"
            text: "Pro Font (Modern)"
            source: "fonts/modern-pro-font-win-tweaked/ProFontWindows.ttf"
            lineSpacing: 1
            pixelSize: 12
            baseScaling: 3.0
            fontWidth: 1.0
        }
        ListElement{
            name: "APPLE_II"
            text: "Apple ][ (1977)"
            source: "fonts/1977-apple2/PrintChar21.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.8
        }
        ListElement{
            name: "ATARI_400"
            text: "Atari 400-800 (1979)"
            source: "fonts/1979-atari-400-800/AtariClassic-Regular.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.7
        }
        ListElement{
            name: "COMMODORE_64"
            text: "Commodore 64 (1982)"
            source: "fonts/1982-commodore64/C64_Pro_Mono-STYLE.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.7
        }
    }
}
