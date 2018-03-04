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
    property var source: fontlist.get(selectedFontIndex).source
    property var _font: fontlist.get(selectedFontIndex)
    property bool lowResolutionFont: _font.lowResolutionFont

    property int pixelSize: lowResolutionFont
                                 ? _font.pixelSize
                                 : _font.pixelSize * scaling

    property int lineSpacing: lowResolutionFont
                                  ? _font.lineSpacing
                                  : pixelSize * _font.lineSpacing

    property real screenScaling: lowResolutionFont
                                     ? _font.baseScaling * scaling
                                     : 1.0

    property real defaultFontWidth: fontlist.get(selectedFontIndex).fontWidth

    // There are two kind of fonts: low resolution and high resolution.
    // Low resolution font sets the lowResolutionFont property to true.
    // They are rendered at a fixed pixel size and the texture is upscaled
    // to fill the screen (they are much faster to render).
    // High resolution fonts are instead drawn on a texture which has the
    // size of the screen, and the scaling directly controls their pixels size.
    // Those are slower to render but are not pixelated.

    property ListModel fontlist: ListModel{
        ListElement{
            name: "TERMINUS_SCALED"
            text: "Terminus (Modern)"
            source: "fonts/modern-terminus/TerminusTTF-4.38.2.ttf"
            lineSpacing: 1
            pixelSize: 12
            baseScaling: 3.0
            fontWidth: 1.0
            lowResolutionFont: true
        }
        ListElement{
            name: "PRO_FONT_SCALED"
            text: "Pro Font (Modern)"
            source: "fonts/modern-pro-font-win-tweaked/ProFontWindows.ttf"
            lineSpacing: 1
            pixelSize: 12
            baseScaling: 3.0
            fontWidth: 1.0
            lowResolutionFont: true
        }
        ListElement{
            name: "EXCELSIOR_SCALED"
            text: "Fixedsys Excelsior (Modern)"
            source: "fonts/modern-fixedsys-excelsior/FSEX301-L2.ttf"
            lineSpacing: 0
            pixelSize: 16
            baseScaling: 2.4
            fontWidth: 1.0
            lowResolutionFont: true
        }
        ListElement{
            name: "COMMODORE_PET_SCALED"
            text: "Commodore PET (1977)"
            source: "fonts/1977-commodore-pet/COMMODORE_PET.ttf"
            lineSpacing: 2
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.7
            lowResolutionFont: true
        }
        ListElement{
            name: "PROGGY_TINY_SCALED"
            text: "Proggy Tiny (Modern)"
            source: "fonts/modern-proggy-tiny/ProggyTiny.ttf"
            lineSpacing: 1
            pixelSize: 16
            baseScaling: 3.0
            fontWidth: 0.9
            lowResolutionFont: true
        }
        ListElement{
            name: "APPLE_II_SCALED"
            text: "Apple ][ (1977)"
            source: "fonts/1977-apple2/PrintChar21.ttf"
            lineSpacing: 2
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.8
            lowResolutionFont: true
        }
        ListElement{
            name: "ATARI_400_SCALED"
            text: "Atari 400-800 (1979)"
            source: "fonts/1979-atari-400-800/ATARI400800_original.TTF"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.7
            lowResolutionFont: true
        }
        ListElement{
            name: "COMMODORE_64_SCALED"
            text: "Commodore 64 (1982)"
            source: "fonts/1982-commodore64/C64_Pro_Mono_v1.0-STYLE.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            fontWidth: 0.7
            lowResolutionFont: true
        }
        ListElement{
            name: "ATARI_ST_SCALED"
            text: "Atari ST (1985)"
            source: "fonts/1985-atari-st/AtariST8x16SystemFont.ttf"
            lineSpacing: 3
            pixelSize: 16
            baseScaling: 2.0
            fontWidth: 1.0
            lowResolutionFont: true
        }
        ListElement{
            name: "IBM_DOS"
            text: "IBM DOS (1985)"
            source: "fonts/1985-ibm-pc-vga/Perfect DOS VGA 437 Win.ttf"
            lineSpacing: 3
            pixelSize: 16
            baseScaling: 2.0
            fontWidth: 1.0
            lowResolutionFont: true
        }
        ListElement{
            name: "HERMIT"
            text: "HD: Hermit (Modern)"
            source: "fonts/modern-hermit/Hermit-medium.otf"
            lineSpacing: 0.05
            pixelSize: 28
            fontWidth: 1.0
            lowResolutionFont: false
        }
        ListElement{
            name: "TERMINUS"
            text: "HD: Terminus (Modern)"
            source: "fonts/modern-terminus/TerminusTTF-4.38.2.ttf"
            lineSpacing: 0.1
            pixelSize: 35
            fontWidth: 1.0
            lowResolutionFont: false
        }
        ListElement{
            name: "PRO_FONT"
            text: "HD: Pro Font (Modern)"
            source: "fonts/modern-pro-font-win-tweaked/ProFontWindows.ttf"
            lineSpacing: 0.1
            pixelSize: 35
            fontWidth: 1.0
            lowResolutionFont: false
        }
        ListElement{
            name: "MONACO"
            text: "HD: Monaco (Modern)"
            source: "fonts/modern-monaco/monaco.ttf"
            lineSpacing: 0.1
            pixelSize: 30
            fontWidth: 1.0
            lowResolutionFont: false
        }
        ListElement{
            name: "INCONSOLATA"
            text: "HD: Inconsolata (Modern)"
            source: "fonts/modern-inconsolata/Inconsolata.otf"
            lineSpacing: 0.1
            pixelSize: 35
            fontWidth: 1.0
            lowResolutionFont: false
        }
        ListElement{
            name: "IBM_3278"
            text: "HD: IBM 3278 (1971)"
            source: "fonts/1971-ibm-3278/3270Medium.ttf"
            lineSpacing: 0.2
            pixelSize: 32
            fontWidth: 1.0
            lowResolutionFont: false
        }
        ListElement{
            name: "Knight_TV"
            text: "Knight TV (1975)"
            source: "fonts/1975-knight-tv/KnightTVMedium.ttf"
            lineSpacing: 0.2
            pixelSize: 10
            fontWidth: 1.0
            baseScaling: 3.0
            lowResolutionFont: true
        }
    }
}
