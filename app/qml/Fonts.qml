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

QtObject {
    property int selectedFontIndex
    property real scaling
    property var source: fontlist.get(selectedFontIndex).source
    property var _font: fontlist.get(selectedFontIndex)
    property bool lowResolutionFont: _font.lowResolutionFont

    // Reference height (in pixels) that represents the "normal" on-screen size at scaling=1.0.
    // Adjust this single value to tune how large fonts appear by default.
    property int baseFontPixelHeight: 32

    // Target pixel height we want on screen for the current zoom level. Low-res fonts will be scaled
    // up to this height, high-res fonts render directly at this size.
    property real targetPixelHeight: baseFontPixelHeight * scaling

    property int pixelSize: lowResolutionFont ? _font.pixelSize : targetPixelHeight

    // Line spacing stays absolute for low-res fonts; for high-res fonts it's a factor of target size.
    property int lineSpacing: lowResolutionFont ? _font.lineSpacing : Math.round(targetPixelHeight * _font.lineSpacing)

    // Use total line height (glyph + spacing) for scaling computations on low-res fonts.
    property real nativeLineHeight: _font.pixelSize + _font.lineSpacing
    property real targetLineHeight: targetPixelHeight + lineSpacing

    // Scale low-res font textures to hit the target line height; high-res fonts don't need scaling.
    property real screenScaling: lowResolutionFont ? targetLineHeight / nativeLineHeight : 1.0

    // Uniform default font width (user width scaling still applies).
    property real defaultFontWidth: 1.0

    property bool isSystemFont: fontlist.get(selectedFontIndex).isSystemFont

    property string family: fontlist.get(selectedFontIndex).family

    // There are two kind of fonts: low resolution and high resolution.
    // Low resolution font sets the lowResolutionFont property to true.
    // They are rendered at a fixed pixel size and the texture is upscaled
    // to fill the screen (they are much faster to render).
    // High resolution fonts are instead drawn on a texture which has the
    // size of the screen, and the scaling directly controls their pixels size.
    // Those are slower to render but are not pixelated.
    property ListModel fontlist: ListModel {
        ListElement {
            name: "TERMINUS_SCALED"
            text: "Terminus"
            source: "fonts/terminus/TerminusTTF-4.49.3.ttf"
            lineSpacing: 1
            pixelSize: 12
            baseScaling: 3.0
            lowResolutionFont: true
            isSystemFont: false
        }
        ListElement {
            name: "EXCELSIOR_SCALED"
            text: "Fixedsys Excelsior"
            source: "fonts/fixedsys-excelsior/FSEX301-L2.ttf"
            lineSpacing: 0
            pixelSize: 16
            baseScaling: 2.4
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_16_SCALED"
        }
        ListElement {
            name: "GREYBEARD_SCALED"
            text: "Greybeard"
            source: "fonts/greybeard/Greybeard-16px.ttf"
            lineSpacing: 1
            pixelSize: 16
            baseScaling: 3.0
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_16_SCALED"
        }
        ListElement {
            name: "COMMODORE_PET_SCALED"
            text: "Commodore PET"
            source: "fonts/pet-me/PetMe.ttf"
            lineSpacing: 0
            pixelSize: 8
            baseScaling: 3.5
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_8_SCALED"
        }
        ListElement {
            name: "COZETTE_SCALED"
            text: "Cozette"
            source: "fonts/cozette/CozetteVector.ttf"
            lineSpacing: 1
            pixelSize: 13
            baseScaling: 3.3
            lowResolutionFont: true
            isSystemFont: false
        }
        ListElement {
            name: "UNSCII_8_SCALED"
            text: "Unscii 8"
            source: "fonts/unscii/unscii-8.ttf"
            lineSpacing: 0
            pixelSize: 8
            baseScaling: 3.5
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_8_SCALED"
        }
        ListElement {
            name: "UNSCII_8_THIN_SCALED"
            text: "Unscii 8 Thin"
            source: "fonts/unscii/unscii-8-thin.ttf"
            lineSpacing: 0
            pixelSize: 8
            baseScaling: 3.5
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_8_SCALED"
        }
        ListElement {
            name: "UNSCII_16_SCALED"
            text: "Unscii 16"
            source: "fonts/unscii/unscii-16-full.ttf"
            lineSpacing: 0
            pixelSize: 16
            baseScaling: 2.4
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_16_SCALED"
        }
        ListElement {
            name: "APPLE_II_SCALED"
            text: "Apple ]["
            source: "fonts/apple2/PrintChar21.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_8_SCALED"
        }
        ListElement {
            name: "ATARI_400_SCALED"
            text: "Atari 400-800"
            source: "fonts/atari-400-800/AtariClassic-Regular.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_8_SCALED"
        }
        ListElement {
            name: "IBM_EGA_8x8"
            text: "IBM EGA 8x8"
            source: "fonts/oldschool-pc-fonts/PxPlus_IBM_EGA_8x8.ttf"
            lineSpacing: 3
            pixelSize: 8
            baseScaling: 3.5
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_8_SCALED"
        }
        ListElement {
            name: "COMMODORE_64_SCALED"
            text: "Commodore 64"
            source: "fonts/pet-me/PetMe64.ttf"
            lineSpacing: 0
            pixelSize: 8
            baseScaling: 3.5
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_8_SCALED"
        }
        ListElement {
            name: "IBM_VGA_8x16"
            text: "IBM VGA 8x16"
            source: "fonts/oldschool-pc-fonts/PxPlus_IBM_VGA_8x16.ttf"
            lineSpacing: 3
            pixelSize: 16
            baseScaling: 2.0
            lowResolutionFont: true
            isSystemFont: false
            fallbackName: "UNSCII_16_SCALED"
        }
        ListElement {
            name: "TERMINUS"
            text: "Terminus"
            source: "fonts/terminus/TerminusTTF-4.49.3.ttf"
            lineSpacing: 0.1
            pixelSize: 35
            lowResolutionFont: false
            isSystemFont: false
        }
        ListElement {
            name: "HACK"
            text: "Hack"
            source: "fonts/hack/Hack-Regular.ttf"
            lineSpacing: 0.1
            pixelSize: 35
            lowResolutionFont: false
            isSystemFont: false
        }
        ListElement {
            name: "FIRA_CODE"
            text: "Fira Code"
            source: "fonts/fira-code/FiraCode-Medium.ttf"
            lineSpacing: 0.1
            pixelSize: 35
            lowResolutionFont: false
            isSystemFont: false
        }
        ListElement {
            name: "IOSEVKA"
            text: "Iosevka"
            source: "fonts/iosevka/IosevkaTerm-ExtendedMedium.ttf"
            lineSpacing: 0.1
            pixelSize: 35
            lowResolutionFont: false
            isSystemFont: false
        }
        ListElement {
            name: "JETBRAINS_MONO"
            text: "JetBrains Mono"
            source: "fonts/jetbrains-mono/JetBrainsMono-Medium.ttf"
            lineSpacing: 0.1
            pixelSize: 35
            lowResolutionFont: false
            isSystemFont: false
        }
        ListElement {
            name: "IBM_3278"
            text: "IBM 3278"
            source: "fonts/ibm-3278/3270-Regular.ttf"
            lineSpacing: 0.2
            pixelSize: 32
            lowResolutionFont: false
            isSystemFont: false
        }
    }

    Component.onCompleted: addSystemFonts()

    function addSystemFonts() {
        var families = monospaceSystemFonts;
        for (var i = 0; i < families.length; i++) {
            if (verbose) {
                console.log("Adding system font: ", families[i])
            }
            fontlist.append(convertToListElement(families[i]))
        }
        appSettings.updateFont();
    }

    function convertToListElement(family) {
        return {
            "name": family,
            "text": family,
            "source": "",
            "lineSpacing": 0.1,
            "pixelSize": 30,
            "baseScaling": 1.0,
            "lowResolutionFont": false,
            "isSystemFont": true,
            "family": family
        }
    }
}
