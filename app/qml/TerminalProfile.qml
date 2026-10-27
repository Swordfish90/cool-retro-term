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
import CoolRetroTerm 1.0

import "utils.js" as Utils

// The look of a single terminal: colors, effects, frame and font. Every terminal (each pane
// of each tab) owns one, so profiles can differ between them.
QtObject {
    id: profile

    property real windowOpacity: 1.0
    property real ambientLight: 0.2
    property real contrast: 0.80
    property real brightness: 0.5

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

    property real rgbShift: 0.0

    property real _frameShininess: 0.2
    property real frameShininess: _frameShininess * 0.5

    property real _frameSize: 0.2
    property real frameSize: _frameSize * 0.05

    property real _screenRadius: 0.2
    property real screenRadius: Utils.lint(4.0, 120.0, _screenRadius)

    property real _margin: 0.5
    property real margin: Utils.lint(1.0, 40.0, _margin) + (1.0 - Math.SQRT1_2) * screenRadius

    readonly property bool frameEnabled: ambientLight > 0 || _frameSize > 0 || screenCurvature > 0

    property bool blinkingCursor: false

    // FONTS //////////////////////////////////////////////////////////////////
    property alias rasterization: fontManager.rasterization
    property alias fontSource: fontManager.fontSource
    property alias fontWidth: fontManager.fontWidth
    property alias lineSpacing: fontManager.lineSpacing
    property alias lowResolutionFont: fontManager.lowResolutionFont
    property alias fontName: fontManager.fontName
    property alias filteredFontList: fontManager.filteredFontList

    // Zoom is shared by all terminals. appSettings is not set yet while it creates its defaultProfile.
    property FontManager fontManager: FontManager {
        id: fontManager
        baseFontScaling: appSettings ? appSettings.baseFontScaling : 0.75
        fontScaling: appSettings ? appSettings.fontScaling : 1.0
    }

    function composeProfileObject() {
        var settings = {
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
            "rgbShift": rgbShift,
            "brightness": brightness,
            "contrast": contrast,
            "ambientLight": ambientLight,
            "windowOpacity": windowOpacity,
            "fontName": fontName,
            "fontSource": fontSource,
            "fontWidth": fontWidth,
            "lineSpacing": lineSpacing,
            "margin": _margin,
            "blinkingCursor": blinkingCursor,
            "frameSize": _frameSize,
            "screenRadius": _screenRadius,
            "frameColor": _frameColor,
            "frameShininess": _frameShininess
        }
        return settings
    }

    function composeProfileString() {
        return appSettings.stringify(composeProfileObject())
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

        rgbShift = settings.rgbShift !== undefined ? settings.rgbShift : rgbShift

        ambientLight = settings.ambientLight !== undefined ? settings.ambientLight : ambientLight
        contrast = settings.contrast !== undefined ? settings.contrast : contrast
        brightness = settings.brightness !== undefined ? settings.brightness : brightness
        windowOpacity = settings.windowOpacity
                !== undefined ? settings.windowOpacity : windowOpacity

        fontSource = settings.fontSource !== undefined ? settings.fontSource : fontSource
        fontName = settings.fontName !== undefined ? settings.fontName : fontName
        fontWidth = settings.fontWidth !== undefined ? settings.fontWidth : fontWidth
        lineSpacing = settings.lineSpacing !== undefined ? settings.lineSpacing : lineSpacing

        _margin = settings.margin !== undefined ? settings.margin : _margin
        _frameSize = settings.frameSize !== undefined ? settings.frameSize : _frameSize
        _screenRadius = settings.screenRadius !== undefined ? settings.screenRadius : _screenRadius
        _frameColor = settings.frameColor !== undefined ? settings.frameColor : _frameColor
        _frameShininess = settings.frameShininess !== undefined ? settings.frameShininess : _frameShininess

        blinkingCursor = settings.blinkingCursor !== undefined ? settings.blinkingCursor : blinkingCursor
    }

    function loadProfile(index) {
        loadProfileString(appSettings.profilesList.get(index).obj_string)
    }
}
