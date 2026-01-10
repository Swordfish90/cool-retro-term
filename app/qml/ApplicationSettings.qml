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

import "utils.js" as Utils

QtObject {
    readonly property string version: appVersion
    readonly property int profileVersion: 2

    // STATIC CONSTANTS ////////////////////////////////////////////////////////
    readonly property real screenCurvatureSize: 0.4
    readonly property real minimumFontScaling: 0.25
    readonly property real maximumFontScaling: 2.50

    readonly property int defaultMargin: 16

    readonly property real minBurnInFadeTime: 0.16
    readonly property real maxBurnInFadeTime: 1.6

    property bool isMacOS: Qt.platform.os === "osx"

    // GENERAL SETTINGS ///////////////////////////////////////////////////////
    property int x: 100
    property int y: 100
    property int width: 1024
    property int height: 768

    property bool fullscreen: false
    property bool showMenubar: false

    property string wintitle: "cool-retro-term"

    property bool showTerminalSize: true
    property real windowScaling: 1.0

    property int effectsFrameSkip: 2
    property bool verbose: false

    property real bloomQuality: 0.5
    property real burnInQuality: 0.5

    property bool blinkingCursor: false

    onWindowScalingChanged: updateFont()

    // PROFILE SETTINGS ///////////////////////////////////////////////////////
    property real windowOpacity: 1.0
    property real ambientLight: 0.2
    property real contrast: 0.80
    property real brightness: 0.5

    property bool useCustomCommand: false
    property string customCommand: ""

    property string _backgroundColor: "#000000"
    property string _fontColor: "#ff8100"
    property string _frameColor: "#ffffff"
    property string saturatedColor: Utils.mix(Utils.strToColor(_fontColor), Utils.strToColor("#FFFFFF"), (saturationColor * 0.5))
    property color fontColor: Utils.mix(Utils.strToColor(_backgroundColor), Utils.strToColor(saturatedColor), (0.7 + (contrast * 0.3)))
    property color backgroundColor: Utils.mix(Utils.strToColor(saturatedColor), Utils.strToColor(_backgroundColor), (0.7 + (contrast * 0.3)))
    property color frameColor: Utils.strToColor(_frameColor)

    property real staticNoise: 0.12
    property real screenCurvature: 0.3
    property real glowingLine: 0.2
    property real burnIn: 0.25
    property real bloom: 0.55

    property real chromaColor: 0.25
    property real saturationColor: 0.25

    property real jitter: 0.2

    property real horizontalSync: 0.08
    property real flickering: 0.1

    property real rbgShift: 0.0

    property real _frameShininess: 0.2
    property real frameShininess: _frameShininess * 0.5

    property real _frameSize: 0.2
    property real frameSize: _frameSize * 0.05

    property real _screenRadius: 0.2
    property real screenRadius: Utils.lint(4.0, 40.0, _screenRadius)

    property real _margin: 0.5
    property real margin: Utils.lint(1.0, 40.0, _margin) + 0.25 * screenRadius

    readonly property int no_rasterization: 0
    readonly property int scanline_rasterization: 1
    readonly property int pixel_rasterization: 2
    readonly property int subpixel_rasterization: 3
    readonly property int modern_rasterization: 4

    property int rasterization: no_rasterization

    readonly property int bundled_fonts: 0
    readonly property int system_fonts: 1

    property int fontSource: bundled_fonts

    // FONTS //////////////////////////////////////////////////////////////////
    readonly property real baseFontScaling: 0.75
    property real fontScaling: 1.0
    property real totalFontScaling: baseFontScaling * fontScaling

    property real fontWidth: 1.0
    property real lineSpacing: 0.1

    property bool lowResolutionFont: false

    property string fontName: "TERMINUS_SCALED"
    property var fontlist: fontManager.item ? fontManager.item.fontlist : null

    property var filteredFontList: ListModel {}

    function updateFont() {
        if (!fontManager.item || !fontlist) return

        filteredFontList.clear()
        var currentFontInList = false

        for (var i = 0; i < fontlist.count; i++) {
            var font = fontlist.get(i)
            var isBundled = !font.isSystemFont
            var isSystem = font.isSystemFont

            var matchesSource = (fontSource === bundled_fonts && isBundled) || (fontSource === system_fonts && isSystem)

            if (!matchesSource) continue

            var modernMode = rasterization === modern_rasterization
            var matchesRasterization = font.isSystemFont || (modernMode == !font.lowResolutionFont)

            if (matchesRasterization) {
                filteredFontList.append(font)
                if (font.name === fontName) {
                    currentFontInList = true
                }
            }
        }

        if (!currentFontInList && filteredFontList.count > 0) {
            fontName = filteredFontList.get(0).name
        }

        var index = getIndexByName(fontName)
        if (index === undefined) return

        fontManager.item.selectedFontIndex = index
        fontManager.item.scaling = totalFontScaling

        var fontSourcePath = fontManager.item.source
        var pixelSize = fontManager.item.pixelSize
        var lineSpacing = fontManager.item.lineSpacing
        var screenScaling = fontManager.item.screenScaling
        var fontWidth = (fontManager.item.baseWidth ?? 1.0) * appSettings.fontWidth
        var fontFamily = fontManager.item.family
        var isSystemFont = fontManager.item.isSystemFont
        var lowResolutionFont = fontManager.item.lowResolutionFont;
        var fallbackFontFamily = ""

        appSettings.lowResolutionFont = fontManager.item.lowResolutionFont

        if (!isSystemFont) {
            fontLoader.source = fontSourcePath
            fontFamily = fontLoader.name
        }

        fallbackFontLoader.source = ""
        var fallbackName = fontManager.item.fallbackName
        if (fallbackName && fallbackName !== fontName) {
            var fallbackFont = getFontByName(fallbackName)
            if (fallbackFont) {
                fallbackFontLoader.source = fallbackFont.source
                fallbackFontFamily = fallbackFontLoader.name
            }
        }

        terminalFontChanged(fontFamily, pixelSize, lineSpacing, screenScaling, fontWidth, fallbackFontFamily, lowResolutionFont)
    }

    onFontSourceChanged: updateFont()
    onRasterizationChanged: updateFont()
    onFontNameChanged: updateFont()

    signal terminalFontChanged(string fontFamily, int pixelSize, int lineSpacing, real screenScaling, real fontWidth, string fallbackFontFamily, bool lowResolutionFont)

    signal initializedSettings

    property Loader fontManager: Loader {
        source: "Fonts.qml"
        onLoaded: updateFont()
    }

    property FontLoader fontLoader: FontLoader {}
    property FontLoader fallbackFontLoader: FontLoader {}

    onTotalFontScalingChanged: updateFont()
    onFontWidthChanged: updateFont()
    onLineSpacingChanged: updateFont()

    function getIndexByName(name) {
        for (var i = 0; i < fontlist.count; i++) {
            var requestedName = fontlist.get(i).name
            if (name === requestedName)
                return i
        }
        return 0 // If the font is not available default to 0.
    }

    function getFontByName(name) {
        for (var i = 0; i < fontlist.count; i++) {
            var font = fontlist.get(i)
            if (name === font.name) {
                return font
            }
        }
        return null
    }

    function incrementScaling() {
        fontScaling = Math.min(fontScaling + 0.05, maximumFontScaling)
    }

    function decrementScaling() {
        fontScaling = Math.max(fontScaling - 0.05, minimumFontScaling)
    }

    property Storage storage: Storage {}

    function stringify(obj) {
        var replacer = function (key, val) {
            return val.toFixed ? Number(val.toFixed(4)) : val
        }
        return JSON.stringify(obj, replacer, 2)
    }

    function composeSettingsString() {
        var settings = {
            "effectsFrameSkip": effectsFrameSkip,
            "x": x,
            "y": y,
            "width": width,
            "height": height,
            "windowScaling": windowScaling,
            "showTerminalSize": showTerminalSize,
            "fontScaling": fontScaling,
            "showMenubar": showMenubar,
            "bloomQuality": bloomQuality,
            "burnInQuality": burnInQuality,
            "useCustomCommand": useCustomCommand,
            "customCommand": customCommand
        }
        return stringify(settings)
    }

    function composeProfileObject() {
        var profile = {
            "backgroundColor": _backgroundColor,
            "fontColor": _fontColor,
            "flickering": flickering,
            "horizontalSync": horizontalSync,
            "staticNoise": staticNoise,
            "chromaColor": chromaColor,
            "saturationColor": saturationColor,
            "screenCurvature": screenCurvature,
            "glowingLine": glowingLine,
            "burnIn": burnIn,
            "bloom": bloom,
            "rasterization": rasterization,
            "jitter": jitter,
            "rbgShift": rbgShift,
            "brightness": brightness,
            "contrast": contrast,
            "ambientLight": ambientLight,
            "windowOpacity": windowOpacity,
            "fontName": fontName,
            "fontSource": fontSource,
            "fontWidth": fontWidth,
            "margin": _margin,
            "blinkingCursor": blinkingCursor,
            "frameSize": _frameSize,
            "screenRadius": _screenRadius,
            "frameColor": _frameColor,
            "frameShininess": _frameShininess
        }
        return profile
    }

    function composeProfileString() {
        return stringify(composeProfileObject())
    }

    function loadSettings() {
        var settingsString = storage.getSetting("_CURRENT_SETTINGS")
        var profileString = storage.getSetting("_CURRENT_PROFILE")

        if (!settingsString)
            return
        if (!profileString)
            return

        loadSettingsString(settingsString)
        loadProfileString(profileString)

        if (verbose)
            console.log("Loading settings: " + settingsString + profileString)
    }

    function storeSettings() {
        var settingsString = composeSettingsString()
        var profileString = composeProfileString()

        storage.setSetting("_CURRENT_SETTINGS", settingsString)
        storage.setSetting("_CURRENT_PROFILE", profileString)

        if (verbose) {
            console.log("Storing settings: " + settingsString)
            console.log("Storing profile: " + profileString)
        }
    }

    function loadSettingsString(settingsString) {
        var settings = JSON.parse(settingsString)

        showTerminalSize = settings.showTerminalSize
                !== undefined ? settings.showTerminalSize : showTerminalSize

        effectsFrameSkip = settings.effectsFrameSkip !== undefined ? settings.effectsFrameSkip : effectsFrameSkip
        windowScaling = settings.windowScaling
                !== undefined ? settings.windowScaling : windowScaling

        x = settings.x !== undefined ? settings.x : x
        y = settings.y !== undefined ? settings.y : y
        width = settings.width !== undefined ? settings.width : width
        height = settings.height !== undefined ? settings.height : height

        fontScaling = settings.fontScaling !== undefined ? settings.fontScaling : fontScaling

        showMenubar = settings.showMenubar !== undefined ? settings.showMenubar : showMenubar

        bloomQuality = settings.bloomQuality !== undefined ? settings.bloomQuality : bloomQuality
        burnInQuality = settings.burnInQuality
                !== undefined ? settings.burnInQuality : burnInQuality

        useCustomCommand = settings.useCustomCommand
                !== undefined ? settings.useCustomCommand : useCustomCommand
        customCommand = settings.customCommand
                !== undefined ? settings.customCommand : customCommand
    }

    function loadProfileString(profileString) {
        var settings = JSON.parse(profileString)

        _backgroundColor = settings.backgroundColor
                !== undefined ? settings.backgroundColor : _backgroundColor
        _fontColor = settings.fontColor !== undefined ? settings.fontColor : _fontColor

        horizontalSync = settings.horizontalSync
                !== undefined ? settings.horizontalSync : horizontalSync
        flickering = settings.flickering !== undefined ? settings.flickering : flickering
        staticNoise = settings.staticNoise !== undefined ? settings.staticNoise : staticNoise
        chromaColor = settings.chromaColor !== undefined ? settings.chromaColor : chromaColor
        saturationColor = settings.saturationColor
                !== undefined ? settings.saturationColor : saturationColor
        screenCurvature = settings.screenCurvature
                !== undefined ? settings.screenCurvature : screenCurvature
        glowingLine = settings.glowingLine !== undefined ? settings.glowingLine : glowingLine

        burnIn = settings.burnIn !== undefined ? settings.burnIn : burnIn
        bloom = settings.bloom !== undefined ? settings.bloom : bloom

        rasterization = settings.rasterization
                !== undefined ? settings.rasterization : rasterization

        jitter = settings.jitter !== undefined ? settings.jitter : jitter

        rbgShift = settings.rbgShift !== undefined ? settings.rbgShift : rbgShift

        ambientLight = settings.ambientLight !== undefined ? settings.ambientLight : ambientLight
        contrast = settings.contrast !== undefined ? settings.contrast : contrast
        brightness = settings.brightness !== undefined ? settings.brightness : brightness
        windowOpacity = settings.windowOpacity
                !== undefined ? settings.windowOpacity : windowOpacity

        fontName = settings.fontName !== undefined ? settings.fontName : fontName
        fontSource = settings.fontSource !== undefined ? settings.fontSource : fontSource
        fontWidth = settings.fontWidth !== undefined ? settings.fontWidth : fontWidth
        lineSpacing = settings.lineSpacing !== undefined ? settings.lineSpacing : lineSpacing

        _margin = settings.margin !== undefined ? settings.margin : _margin
        _frameSize = settings.frameSize !== undefined ? settings.frameSize : _frameSize
        _screenRadius = settings.screenRadius !== undefined ? settings.screenRadius : _screenRadius
        _frameColor = settings.frameColor !== undefined ? settings.frameColor : _frameColor
        _frameShininess = settings.frameShininess !== undefined ? settings.frameShininess : _frameShininess

        blinkingCursor = settings.blinkingCursor !== undefined ? settings.blinkingCursor : blinkingCursor
    }

    function storeCustomProfiles() {
        storage.setSetting("_CUSTOM_PROFILES", composeCustomProfilesString())
    }

    function loadCustomProfiles() {
        var customProfileString = storage.getSetting("_CUSTOM_PROFILES")
        if (customProfileString === undefined)
            customProfileString = "[]"
        loadCustomProfilesString(customProfileString)
    }

    function loadCustomProfilesString(customProfilesString) {
        var customProfiles = JSON.parse(customProfilesString)
        for (var i = 0; i < customProfiles.length; i++) {
            var profile = customProfiles[i]

            if (verbose)
                console.log("Loading custom profile: " + stringify(profile))

            profilesList.append(profile)
        }
    }

    function composeCustomProfilesString() {
        var customProfiles = []
        for (var i = 0; i < profilesList.count; i++) {
            var profile = profilesList.get(i)
            if (profile.builtin)
                continue
            customProfiles.push({
                                    "text": profile.text,
                                    "obj_string": profile.obj_string,
                                    "builtin": false
                                })
        }
        return stringify(customProfiles)
    }

    function loadProfile(index) {
        var profile = profilesList.get(index)
        loadProfileString(profile.obj_string)
    }

    function appendCustomProfile(name, profileString) {
        profilesList.append({
                                "text": name,
                                "obj_string": profileString,
                                "builtin": false
                            })
    }

    // PROFILES ///////////////////////////////////////////////////////////////
    property ListModel profilesList: ListModel {
        ListElement {
            text: "Default Amber"
            obj_string: '{
                "ambientLight": 0.3,
                "backgroundColor": "#000000",
                "bloom": 0.6,
                "brightness": 0.5,
                "burnIn": 0.3,
                "chromaColor": 0.2,
                "contrast": 0.8,
                "flickering": 0.1,
                "fontColor": "#ff8100",
                "fontName": "TERMINUS_SCALED",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.2,
                "horizontalSync": 0.1,
                "jitter": 0.2,
                "rasterization": 0,
                "rbgShift": 0,
                "saturationColor": 0.2,
                "screenCurvature": 0.4,
                "screenRadius": 0.3,
                "staticNoise": 0.1,
                "windowOpacity": 1,
                "margin": 0.3,
                "blinkingCursor": false,
                "frameSize": 0.1,
                "frameColor": "#f2d4a7",
                "frameShininess": 0.3
            }'
            builtin: true
        }
        ListElement {
            text: "Monochrome Green"
            obj_string: '{
                "ambientLight": 0.3,
                "backgroundColor": "#000000",
                "bloom": 0.5,
                "brightness": 0.5,
                "burnIn": 0.3,
                "chromaColor": 0.0,
                "contrast": 0.8,
                "flickering": 0.1,
                "fontColor": "#0ccc68",
                "fontName": "EXCELSIOR_SCALED",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.2,
                "horizontalSync": 0.1,
                "jitter": 0.2,
                "rasterization": 0,
                "rbgShift": 0,
                "saturationColor": 0.0,
                "screenCurvature": 0.7,
                "screenRadius": 0.6,
                "staticNoise": 0.1,
                "windowOpacity": 1,
                "margin": 0.3,
                "blinkingCursor": false,
                "frameSize": 0.1,
                "frameColor": "#bdeed2",
                "frameShininess": 0.1
            }'
            builtin: true
        }
        ListElement {
            text: "Deep Blue"
            obj_string: '{
                "ambientLight": 0.0,
                "backgroundColor": "#000000",
                "bloom": 0.6,
                "brightness": 0.5,
                "burnIn": 0.3,
                "chromaColor": 1.0,
                "contrast": 0.8,
                "flickering": 0.1,
                "fontColor": "#7fb4ff",
                "fontName": "COZETTE_SCALED",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.2,
                "horizontalSync": 0.1,
                "jitter": 0.2,
                "rasterization": 0,
                "rbgShift": 0,
                "saturationColor": 0.2,
                "screenCurvature": 1.0,
                "screenRadius": 0.3,
                "staticNoise": 0.1,
                "windowOpacity": 1,
                "margin": 0.3,
                "blinkingCursor": false,
                "frameSize": 0.1,
                "frameColor": "#ffffff",
                "frameShininess": 0.9
            }'
            builtin: true
        }
        ListElement {
            text: "Commodore 64"
            obj_string: '{
                "ambientLight": 0.4,
                "backgroundColor": "#3b3b8f",
                "bloom": 0.4,
                "brightness": 0.6,
                "burnIn": 0.1,
                "chromaColor": 0.0,
                "contrast": 0.7,
                "flickering": 0.1,
                "fontColor": "#a9a7ff",
                "fontName": "COMMODORE_64_SCALED",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.1,
                "horizontalSync": 0.0,
                "jitter": 0.0,
                "rasterization": 1,
                "rbgShift": 0,
                "saturationColor": 0,
                "screenCurvature": 0.5,
                "screenRadius": 0.4,
                "staticNoise": 0.1,
                "windowOpacity": 1,
                "margin": 0.3,
                "blinkingCursor": false,
                "frameSize": 0.5,
                "frameColor": "#444444",
                "frameShininess": 0.0
            }'
            builtin: true
        }
        ListElement {
            text: "Commodore PET"
            obj_string: '{
                "ambientLight": 0.0,
                "backgroundColor": "#000000",
                "bloom": 0.4,
                "brightness": 0.5,
                "burnIn": 0.4,
                "chromaColor": 0,
                "contrast": 0.8,
                "flickering": 0.2,
                "fontColor": "#ffffff",
                "fontName": "COMMODORE_PET_SCALED",
                "fontSource": 0,
                "fontWidth": 1.25,
                "lineSpacing": 0.1,
                "glowingLine": 0.3,
                "horizontalSync": 0.2,
                "jitter": 0.15,
                "rasterization": 1,
                "rbgShift": 0.1,
                "saturationColor": 0,
                "screenCurvature": 1.0,
                "screenRadius": 1.0,
                "staticNoise": 0.2,
                "windowOpacity": 1,
                "margin": 0.2,
                "blinkingCursor": false,
                "frameSize": 0.8,
                "frameColor": "#000000",
                "frameShininess": 0.6
            }'
            builtin: true
        }
        ListElement {
            text: "Apple ]["
            obj_string: '{
                "ambientLight": 1.0,
                "backgroundColor": "#001100",
                "bloom": 0.3,
                "brightness": 0.5,
                "burnIn": 0.3,
                "chromaColor": 0,
                "contrast": 0.8,
                "flickering": 0.2,
                "fontColor": "#4dff6b",
                "fontName": "APPLE_II_SCALED",
                "fontSource": 0,
                "fontWidth": 1.25,
                "lineSpacing": 0.1,
                "glowingLine": 0.3,
                "horizontalSync": 0.2,
                "jitter": 0.2,
                "rasterization": 1,
                "rbgShift": 0.1,
                "saturationColor": 0,
                "screenCurvature": 1.0,
                "screenRadius": 1.0,
                "staticNoise": 0.2,
                "windowOpacity": 1,
                "margin": 0.0,
                "blinkingCursor": false,
                "frameSize": 0.5,
                "frameColor": "#ffffff",
                "frameShininess": 0.8
            }'
            builtin: true
        }
        ListElement {
            text: "Atari 400"
            obj_string: '{
                "ambientLight": 0.1,
                "backgroundColor": "#0f1f5a",
                "bloom": 0.1,
                "brightness": 0.6,
                "burnIn": 0.2,
                "chromaColor": 0,
                "contrast": 0.9,
                "flickering": 0.1,
                "fontColor": "#8ed6ff",
                "fontName": "ATARI_400_SCALED",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.1,
                "horizontalSync": 0.0,
                "jitter": 0.0,
                "rasterization": 1,
                "rbgShift": 0.0,
                "saturationColor": 0,
                "screenCurvature": 0.3,
                "screenRadius": 0.5,
                "staticNoise": 0.1,
                "windowOpacity": 1,
                "margin": 0.2,
                "blinkingCursor": false,
                "frameSize": 0.4,
                "frameColor": "#8ed6ff",
                "frameShininess": 0.3
            }'
            builtin: true
        }
        ListElement {
            text: "IBM VGA 8x16"
            obj_string: '{
                "ambientLight": 0.2,
                "backgroundColor": "#000000",
                "bloom": 0.2,
                "brightness": 0.6,
                "burnIn": 0.1,
                "chromaColor": 0.5,
                "contrast": 1.0,
                "flickering": 0.1,
                "fontColor": "#c0c0c0",
                "fontName": "IBM_VGA_8x16",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.1,
                "horizontalSync": 0.0,
                "jitter": 0.0,
                "rasterization": 1,
                "rbgShift": 0.15,
                "saturationColor": 0,
                "screenCurvature": 0.3,
                "screenRadius": 0.2,
                "staticNoise": 0.0,
                "windowOpacity": 1,
                "margin": 0.2,
                "blinkingCursor": false,
                "frameSize": 0.1,
                "frameColor": "#ffffff",
                "frameShininess": 0.3
            }'
            builtin: true
        }
        ListElement {
            text: "IBM 3278"
            obj_string: '{
                "ambientLight": 0.2,
                "backgroundColor": "#000000",
                "bloom": 0.2,
                "brightness": 0.5,
                "burnIn": 0.7,
                "chromaColor": 0,
                "contrast": 0.8,
                "flickering": 0,
                "fontColor": "#3cff7a",
                "fontName": "IBM_3278",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.0,
                "horizontalSync": 0,
                "jitter": 0,
                "rasterization": 4,
                "rbgShift": 0,
                "saturationColor": 0,
                "screenCurvature": 0,
                "screenRadius": 0.0,
                "staticNoise": 0.0,
                "windowOpacity": 1,
                "margin": 0.1,
                "blinkingCursor": false,
                "frameSize": 0,
                "frameColor": "#ffffff",
                "frameShininess": 0.2
            }'
            builtin: true
        }
        ListElement {
            text: "Neon Cyan"
            obj_string: '{
                "ambientLight": 0.1,
                "backgroundColor": "#001018",
                "bloom": 0.6,
                "brightness": 0.6,
                "burnIn": 0.1,
                "chromaColor": 1,
                "contrast": 0.9,
                "flickering": 0.1,
                "fontColor": "#52f7ff",
                "fontName": "IOSEVKA",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.2,
                "horizontalSync": 0.0,
                "jitter": 0.1,
                "rasterization": 4,
                "rbgShift": 0.0,
                "saturationColor": 0.6,
                "screenCurvature": 0,
                "screenRadius": 0.0,
                "staticNoise": 0.1,
                "windowOpacity": 0.8,
                "margin": 0.1,
                "blinkingCursor": false,
                "frameSize": 0,
                "frameColor": "#52f7ff",
                "frameShininess": 0.2
            }'
            builtin: true
        }
        ListElement {
            text: "Ghost Terminal"
            obj_string: '{
                "ambientLight": 0.3,
                "backgroundColor": "#0b1014",
                "bloom": 0.3,
                "brightness": 0.6,
                "burnIn": 0.2,
                "chromaColor": 0,
                "contrast": 0.5,
                "flickering": 0.0,
                "fontColor": "#a6b3c0",
                "fontName": "JETBRAINS_MONO",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.1,
                "horizontalSync": 0.0,
                "jitter": 0.0,
                "rasterization": 4,
                "rbgShift": 0.1,
                "saturationColor": 0.0,
                "screenCurvature": 0,
                "screenRadius": 0.0,
                "staticNoise": 0.1,
                "windowOpacity": 0.7,
                "margin": 0.1,
                "blinkingCursor": false,
                "frameSize": 0,
                "frameColor": "#9aa7b3",
                "frameShininess": 0.2
            }'
            builtin: true
        }
        ListElement {
            text: "Plasma"
            obj_string: '{
                "ambientLight": 0.1,
                "backgroundColor": "#070014",
                "bloom": 0.7,
                "brightness": 0.6,
                "burnIn": 0.1,
                "chromaColor": 1,
                "contrast": 0.8,
                "flickering": 0.1,
                "fontColor": "#ff9bd6",
                "fontName": "FIRA_CODE",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.2,
                "horizontalSync": 0.0,
                "jitter": 0.1,
                "rasterization": 4,
                "rbgShift": 0.1,
                "saturationColor": 0.8,
                "screenCurvature": 0,
                "screenRadius": 0.0,
                "staticNoise": 0.1,
                "windowOpacity": 1.0,
                "margin": 0.1,
                "blinkingCursor": false,
                "frameSize": 0,
                "frameColor": "#ff9bd6",
                "frameShininess": 0.2
            }'
            builtin: true
        }
        ListElement {
            text: "Boring"
            obj_string: '{
                "ambientLight": 0.1,
                "backgroundColor": "#000000",
                "bloom": 0.5,
                "brightness": 0.5,
                "burnIn": 0.05,
                "chromaColor": 1,
                "contrast": 0.8,
                "flickering": 0.0,
                "fontColor": "#ffffff",
                "fontName": "JETBRAINS_MONO",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.1,
                "horizontalSync": 0,
                "jitter": 0.0,
                "rasterization": 4,
                "rbgShift": 0,
                "saturationColor": 0.0,
                "screenCurvature": 0,
                "screenRadius": 0.0,
                "staticNoise": 0.0,
                "windowOpacity": 1.0,
                "margin": 0.0,
                "blinkingCursor": false,
                "frameSize": 0,
                "frameColor": "#c0c0c0",
                "frameShininess": 0.2
            }'
            builtin: true
        }
        ListElement {
            text: "E-Ink"
            obj_string: '{
                "ambientLight": 0.6,
                "backgroundColor": "#f2f2ec",
                "bloom": 0.0,
                "brightness": 1.0,
                "burnIn": 0.6,
                "chromaColor": 0,
                "contrast": 0.5,
                "flickering": 0.0,
                "fontColor": "#101010",
                "fontName": "HACK",
                "fontSource": 0,
                "fontWidth": 1,
                "lineSpacing": 0.1,
                "glowingLine": 0.0,
                "horizontalSync": 0.0,
                "jitter": 0.0,
                "rasterization": 4,
                "rbgShift": 0,
                "saturationColor": 0,
                "screenCurvature": 0,
                "screenRadius": 0.0,
                "staticNoise": 0.0,
                "windowOpacity": 1,
                "margin": 0.1,
                "blinkingCursor": false,
                "frameSize": 0,
                "frameColor": "#d0d0c8",
                "frameShininess": 0.2
            }'
            builtin: true
        }
    }

    function getProfileIndexByName(name) {
        for (var i = 0; i < profilesList.count; i++) {
            if (profilesList.get(i).text === name)
                return i
        }
        return -1
    }

    Component.onCompleted: {
        // Manage the arguments from the QML side.
        var args = Qt.application.arguments
        if (args.indexOf("--verbose") !== -1) {
            verbose = true
        }
        if (args.indexOf("--default-settings") === -1) {
            loadSettings()
        }

        loadCustomProfiles()

        var profileArgPosition = args.indexOf("--profile")
        if (profileArgPosition !== -1) {
            var profileIndex = getProfileIndexByName(
                        args[profileArgPosition + 1])
            if (profileIndex !== -1)
                loadProfile(profileIndex)
            else
                console.log("Warning: selected profile is not valid; ignoring it")
        }

        if (args.indexOf("--fullscreen") !== -1) {
            fullscreen = true
            showMenubar = false
        }

        if (args.indexOf("-T") !== -1) {
            wintitle = args[args.indexOf("-T") + 1]
        }

        initializedSettings()
    }
    Component.onDestruction: {
        storeSettings()
        storeCustomProfiles()
        //        storage.dropSettings(); //DROPS THE SETTINGS!.. REMEMBER TO DISABLE ONCE ENABLED!!
    }

    // VARS ///////////////////////////////////////////////////////////////////
    property Label _sampleLabel: Label {
        text: "100%"
    }
    property real labelWidth: _sampleLabel.width
}
