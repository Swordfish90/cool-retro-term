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
import QtQuick.Controls 1.0

import "utils.js" as Utils

QtObject{
    readonly property string version: appVersion
    readonly property int profileVersion: 2

    // STATIC CONSTANTS ////////////////////////////////////////////////////////

    readonly property real screenCurvatureSize: 0.4
    readonly property real minimumFontScaling: 0.25
    readonly property real maximumFontScaling: 2.50

    readonly property real minBurnInFadeTime: 160
    readonly property real maxBurnInFadeTime: 1600

    // GENERAL SETTINGS ///////////////////////////////////////////////////////

    property int x: 100
    property int y: 100
    property int width: 1024
    property int height: 768

    property bool fullscreen: false
    property bool showMenubar: Qt.platform.os === "osx" ? true : false

    property string wintitle: "cool-retro-term"

    property bool showTerminalSize: true
    property real windowScaling: 1.0

    property real fps: 20
    property bool verbose: false

    property real bloomQuality: 0.5

    property real burnInQuality: 0.5
    property bool useFastBurnIn: Qt.platform.os === "osx" ? false : true

    onWindowScalingChanged: handleFontChanged();

    // PROFILE SETTINGS ///////////////////////////////////////////////////////

    property real windowOpacity: 1.0
    property real ambientLight: 0.2
    property real contrast: 0.80
    property real brightness: 0.5

    property bool useCustomCommand: false
    property string customCommand: ""

    property string _backgroundColor: "#000000"
    property string _fontColor: "#ff8100"
    property string saturatedColor: Utils.mix(Utils.strToColor("#FFFFFF"), Utils.strToColor(_fontColor), saturationColor * 0.5)
    property color fontColor: Utils.mix(Utils.strToColor(saturatedColor), Utils.strToColor(_backgroundColor), 0.7 + (contrast * 0.3))
    property color backgroundColor: Utils.mix(Utils.strToColor(_backgroundColor), Utils.strToColor(saturatedColor), 0.7 + (contrast * 0.3))

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

    property real _margin: 0.5
    property real margin: Utils.lint(1.0, 20.0, _margin)

    readonly property int no_rasterization: 0
    readonly property int scanline_rasterization: 1
    readonly property int pixel_rasterization: 2

    property int rasterization: no_rasterization

    // FONTS //////////////////////////////////////////////////////////////////

    readonly property real baseFontScaling: 0.75
    property real fontScaling: 1.0
    property real totalFontScaling: baseFontScaling * fontScaling

    property real fontWidth: 1.0

    property bool lowResolutionFont: false

    property var fontNames: ["TERMINUS_SCALED", "COMMODORE_PET", "COMMODORE_PET"]
    property var fontlist: fontManager.item.fontlist

    signal terminalFontChanged(string fontFamily, int pixelSize, int lineSpacing, real screenScaling, real fontWidth)

    signal initializedSettings()

    property Loader fontManager: Loader{
        states: [
            State { when: rasterization == no_rasterization
                PropertyChanges {target: fontManager; source: "Fonts.qml" } },
            State { when: rasterization == scanline_rasterization
                PropertyChanges {target: fontManager; source: "FontScanlines.qml" } },
            State { when: rasterization == pixel_rasterization;
                PropertyChanges {target: fontManager; source: "FontPixels.qml" } }
        ]

        onLoaded: handleFontChanged()
    }

    property FontLoader fontLoader: FontLoader { }

    onTotalFontScalingChanged: handleFontChanged();
    onFontWidthChanged: handleFontChanged();

    function getIndexByName(name) {
        for (var i = 0; i < fontlist.count; i++) {
            var requestedName = fontlist.get(i).name;
            if (name === requestedName)
                return i;
        }
        return 0; // If the font is not available default to 0.
    }

    function incrementScaling(){
        fontScaling = Math.min(fontScaling + 0.05, maximumFontScaling);
        handleFontChanged();
    }

    function decrementScaling(){
        fontScaling = Math.max(fontScaling - 0.05, minimumFontScaling);
        handleFontChanged();
    }

    function handleFontChanged(){
        if (!fontManager.item) return;

        var index = getIndexByName(fontNames[rasterization]);
        if (index === undefined) return;

        fontManager.item.selectedFontIndex = index;
        fontManager.item.scaling = totalFontScaling;

        var fontSource = fontManager.item.source;
        var pixelSize = fontManager.item.pixelSize;
        var lineSpacing = fontManager.item.lineSpacing;
        var screenScaling = fontManager.item.screenScaling;
        var fontWidth = fontManager.item.defaultFontWidth * appSettings.fontWidth;
        var fontFamily = fontManager.item.family;
        var isSystemFont = fontManager.item.isSystemFont;

        lowResolutionFont = fontManager.item.lowResolutionFont;

        if (!isSystemFont) {
            fontLoader.source = fontSource;
            fontFamily = fontLoader.name;
        }

        terminalFontChanged(fontFamily, pixelSize, lineSpacing, screenScaling, fontWidth);
    }

    property Storage storage: Storage{ }

    function stringify(obj) {
        var replacer = function(key, val) {
            return val.toFixed ? Number(val.toFixed(4)) : val;
        }
        return JSON.stringify(obj, replacer, 2);
    }

    function composeSettingsString(){
        var settings = {
            fps: fps,
            x: x,
            y: y,
            width: width,
            height: height,
            windowScaling: windowScaling,
            showTerminalSize: showTerminalSize,
            fontScaling: fontScaling,
            fontNames: fontNames,
            showMenubar: showMenubar,
            bloomQuality: bloomQuality,
            burnInQuality: burnInQuality,
            useCustomCommand: useCustomCommand,
            customCommand: customCommand,
            useFastBurnIn: useFastBurnIn
        }
        return stringify(settings);
    }

    function composeProfileObject(){
        var settings = {
            backgroundColor: _backgroundColor,
            fontColor: _fontColor,
            flickering: flickering,
            horizontalSync: horizontalSync,
            staticNoise: staticNoise,
            chromaColor: chromaColor,
            saturationColor: saturationColor,
            screenCurvature: screenCurvature,
            glowingLine: glowingLine,
            burnIn: burnIn,
            bloom: bloom,
            rasterization: rasterization,
            jitter: jitter,
            rbgShift: rbgShift,
            brightness: brightness,
            contrast: contrast,
            ambientLight: ambientLight,
            windowOpacity: windowOpacity,
            fontName: fontNames[rasterization],
            fontWidth: fontWidth,
            margin: _margin
        }
        return settings;
    }

    function composeProfileString() {
        return stringify(composeProfileObject());
    }

    function loadSettings(){
        var settingsString = storage.getSetting("_CURRENT_SETTINGS");
        var profileString = storage.getSetting("_CURRENT_PROFILE");

        if(!settingsString) return;
        if(!profileString) return;

        loadSettingsString(settingsString);
        loadProfileString(profileString);

        if (verbose)
            console.log("Loading settings: " + settingsString + profileString);
    }

    function storeSettings(){
        var settingsString = composeSettingsString();
        var profileString = composeProfileString();

        storage.setSetting("_CURRENT_SETTINGS", settingsString);
        storage.setSetting("_CURRENT_PROFILE", profileString);

        if (verbose) {
            console.log("Storing settings: " + settingsString);
            console.log("Storing profile: " + profileString);
        }
    }

    function loadSettingsString(settingsString){
        var settings = JSON.parse(settingsString);

        showTerminalSize = settings.showTerminalSize !== undefined ? settings.showTerminalSize : showTerminalSize

        fps = settings.fps !== undefined ? settings.fps: fps
        windowScaling = settings.windowScaling !== undefined ? settings.windowScaling : windowScaling

        x = settings.x !== undefined ? settings.x : x
        y = settings.y !== undefined ? settings.y : y
        width = settings.width !== undefined ? settings.width : width
        height = settings.height !== undefined ? settings.height : height

        fontNames = settings.fontNames !== undefined ? settings.fontNames : fontNames
        fontScaling = settings.fontScaling !== undefined ? settings.fontScaling : fontScaling

        showMenubar = settings.showMenubar !== undefined ? settings.showMenubar : showMenubar;

        bloomQuality = settings.bloomQuality !== undefined ? settings.bloomQuality : bloomQuality;
        burnInQuality = settings.burnInQuality !== undefined ? settings.burnInQuality : burnInQuality;

        useCustomCommand = settings.useCustomCommand !== undefined ? settings.useCustomCommand : useCustomCommand
        customCommand = settings.customCommand !== undefined ? settings.customCommand : customCommand

        useFastBurnIn = settings.useFastBurnIn !== undefined ? settings.useFastBurnIn : useFastBurnIn;
    }

    function loadProfileString(profileString){
        var settings = JSON.parse(profileString);

        _backgroundColor = settings.backgroundColor !== undefined ? settings.backgroundColor : _backgroundColor;
        _fontColor = settings.fontColor !== undefined ? settings.fontColor : _fontColor;

        horizontalSync = settings.horizontalSync !== undefined ? settings.horizontalSync : horizontalSync
        flickering = settings.flickering !== undefined ? settings.flickering : flickering;
        staticNoise = settings.staticNoise !== undefined ? settings.staticNoise : staticNoise;
        chromaColor = settings.chromaColor !== undefined ? settings.chromaColor : chromaColor;
        saturationColor = settings.saturationColor !== undefined ? settings.saturationColor : saturationColor;
        screenCurvature = settings.screenCurvature !== undefined ? settings.screenCurvature : screenCurvature;
        glowingLine = settings.glowingLine !== undefined ? settings.glowingLine : glowingLine;

        burnIn = settings.burnIn !== undefined ? settings.burnIn : burnIn
        bloom = settings.bloom !== undefined ? settings.bloom : bloom

        rasterization = settings.rasterization !== undefined ? settings.rasterization : rasterization;

        jitter = settings.jitter !== undefined ? settings.jitter : jitter;

        rbgShift = settings.rbgShift !== undefined ? settings.rbgShift : rbgShift;

        ambientLight = settings.ambientLight !== undefined ? settings.ambientLight : ambientLight;
        contrast = settings.contrast !== undefined ? settings.contrast : contrast;
        brightness = settings.brightness !== undefined ? settings.brightness : brightness;
        windowOpacity = settings.windowOpacity !== undefined ? settings.windowOpacity : windowOpacity;

        fontNames[rasterization] = settings.fontName !== undefined ? settings.fontName : fontNames[rasterization];
        fontWidth = settings.fontWidth !== undefined ? settings.fontWidth : fontWidth;

        _margin = settings.margin !== undefined ? settings.margin : _margin;

        handleFontChanged();
    }

    function storeCustomProfiles(){
        storage.setSetting("_CUSTOM_PROFILES", composeCustomProfilesString());
    }

    function loadCustomProfiles(){
        var customProfileString = storage.getSetting("_CUSTOM_PROFILES");
        if(customProfileString === undefined) customProfileString = "[]";
        loadCustomProfilesString(customProfileString);
    }

    function loadCustomProfilesString(customProfilesString){
        var customProfiles = JSON.parse(customProfilesString);
        for (var i=0; i<customProfiles.length; i++) {
            var profile = customProfiles[i];

            if (verbose)
                console.log("Loading custom profile: " + stringify(profile));

            profilesList.append(profile);
        }
    }

    function composeCustomProfilesString(){
        var customProfiles = []
        for(var i=0; i<profilesList.count; i++){
            var profile = profilesList.get(i);
            if(profile.builtin) continue;
            customProfiles.push({text: profile.text, obj_string: profile.obj_string, builtin: false})
        }
        return stringify(customProfiles);
    }

    function loadProfile(index){
        var profile = profilesList.get(index);
        loadProfileString(profile.obj_string);
    }

    function appendCustomProfile(name, profileString) {
        profilesList.append({text: name, obj_string: profileString, builtin: false});
    }

    // PROFILES ///////////////////////////////////////////////////////////////

    property ListModel profilesList: ListModel{
        ListElement{
            text: "Default Amber"
            obj_string: '{
                  "ambientLight": 0.2,
                  "backgroundColor": "#000000",
                  "bloom": 0.5538,
                  "brightness": 0.5,
                  "burnIn": 0.2517,
                  "chromaColor": 0.2483,
                  "contrast": 0.7959,
                  "flickering": 0.1,
                  "fontColor": "#ff8100",
                  "fontName": "TERMINUS_SCALED",
                  "fontWidth": 1,
                  "glowingLine": 0.2,
                  "horizontalSync": 0.08,
                  "jitter": 0.1997,
                  "rasterization": 0,
                  "rbgShift": 0,
                  "saturationColor": 0.2483,
                  "screenCurvature": 0.3,
                  "staticNoise": 0.1198,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "Monochrome Green"
            obj_string: '
                {
                  "ambientLight": 0.2,
                  "backgroundColor": "#000000",
                  "bloom": 0.5538,
                  "brightness": 0.5,
                  "burnIn": 0.2517,
                  "chromaColor": 0.0,
                  "contrast": 0.7959,
                  "flickering": 0.1,
                  "fontColor": "#0ccc68",
                  "fontName": "TERMINUS_SCALED",
                  "fontWidth": 1,
                  "glowingLine": 0.2,
                  "horizontalSync": 0.08,
                  "jitter": 0.1997,
                  "rasterization": 0,
                  "rbgShift": 0,
                  "saturationColor": 0.0,
                  "screenCurvature": 0.3,
                  "staticNoise": 0.1198,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "Green Scanlines"
            obj_string: '
                {
                  "ambientLight": 0,
                  "backgroundColor": "#000000",
                  "bloom": 0.6,
                  "brightness": 0.5,
                  "burnIn": 0.3,
                  "chromaColor": 0.5,
                  "contrast": 0.6,
                  "flickering": 0.1,
                  "fontColor": "#7cff4f",
                  "fontName": "PRO_FONT_SCALED",
                  "fontWidth": 1,
                  "glowingLine": 0.2,
                  "horizontalSync": 0.151,
                  "jitter": 0.11,
                  "rasterization": 1,
                  "rbgShift": 0,
                  "saturationColor": 0.5,
                  "screenCurvature": 0.3,
                  "staticNoise": 0.15,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "Default Pixelated"
            obj_string: '
                {
                  "ambientLight": 0,
                  "backgroundColor": "#000000",
                  "bloom": 0.4045,
                  "brightness": 0.6041,
                  "burnIn": 0.1024,
                  "chromaColor": 0.7517,
                  "contrast": 0.7473,
                  "flickering": 0.1962,
                  "fontColor": "#ffffff",
                  "fontName": "COMMODORE_PET",
                  "fontWidth": 1,
                  "glowingLine": 0.2,
                  "horizontalSync": 0.151,
                  "jitter": 0,
                  "rasterization": 2,
                  "rbgShift": 0,
                  "saturationColor": 0,
                  "screenCurvature": 0,
                  "staticNoise": 0.15,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "Apple ]["
            obj_string:
                '{
                  "ambientLight": 0.3038,
                  "backgroundColor": "#000000",
                  "bloom": 0.5,
                  "brightness": 0.5,
                  "burnIn": 0.5017,
                  "chromaColor": 0,
                  "contrast": 0.85,
                  "flickering": 0.2,
                  "fontColor": "#00d56d",
                  "fontName": "APPLE_II",
                  "fontWidth": 1,
                  "glowingLine": 0.22,
                  "horizontalSync": 0.16,
                  "jitter": 0.1,
                  "rasterization": 1,
                  "rbgShift": 0,
                  "saturationColor": 0,
                  "screenCurvature": 0.5,
                  "staticNoise": 0.099,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "Vintage"
            obj_string: '
                {
                  "ambientLight": 0.5,
                  "backgroundColor": "#000000",
                  "bloom": 0.4983,
                  "brightness": 0.5014,
                  "burnIn": 0.4983,
                  "chromaColor": 0,
                  "contrast": 0.7473,
                  "flickering": 0.9,
                  "fontColor": "#00ff3e",
                  "fontName": "COMMODORE_PET",
                  "fontWidth": 1,
                  "glowingLine": 0.3,
                  "horizontalSync": 0.42,
                  "jitter": 0.4,
                  "rasterization": 1,
                  "rbgShift": 0.2969,
                  "saturationColor": 0,
                  "screenCurvature": 0.5,
                  "staticNoise": 0.2969,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "IBM Dos"
            obj_string:
                '{
                  "ambientLight": 0.151,
                  "backgroundColor": "#000000",
                  "bloom": 0.2969,
                  "brightness": 0.5,
                  "burnIn": 0.0469,
                  "chromaColor": 1,
                  "contrast": 0.85,
                  "flickering": 0.0955,
                  "fontColor": "#ffffff",
                  "fontName": "IBM_DOS",
                  "fontWidth": 1,
                  "glowingLine": 0.1545,
                  "horizontalSync": 0,
                  "jitter": 0.1545,
                  "rasterization": 0,
                  "rbgShift": 0.3524,
                  "saturationColor": 0,
                  "screenCurvature": 0.4,
                  "staticNoise": 0.0503,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "IBM 3278"
            obj_string:
                '{
                  "ambientLight": 0.1,
                  "backgroundColor": "#000000",
                  "bloom": 0.2969,
                  "brightness": 0.5,
                  "burnIn": 0.6,
                  "chromaColor": 0,
                  "contrast": 0.85,
                  "flickering": 0,
                  "fontColor": "#0ccc68",
                  "fontName": "IBM_3278",
                  "fontWidth": 1,
                  "glowingLine": 0,
                  "horizontalSync": 0,
                  "jitter": 0,
                  "rasterization": 0,
                  "rbgShift": 0,
                  "saturationColor": 0,
                  "screenCurvature": 0.2,
                  "staticNoise": 0,
                  "windowOpacity": 1,
                  "margin": 0.5
                }'
            builtin: true
        }
        ListElement{
            text: "Futuristic"
            obj_string:
                '{
                  "ambientLight": 0,
                  "backgroundColor": "#000000",
                  "bloom": 0.5017,
                  "brightness": 0.5014,
                  "burnIn": 0.0955,
                  "chromaColor": 1,
                  "contrast": 0.85,
                  "flickering": 0.2,
                  "fontColor": "#729fcf",
                  "fontName": "TERMINUS",
                  "fontWidth": 1,
                  "glowingLine": 0.1476,
                  "horizontalSync": 0,
                  "jitter": 0.099,
                  "rasterization": 0,
                  "rbgShift": 0,
                  "saturationColor": 0.4983,
                  "screenCurvature": 0,
                  "staticNoise": 0.0955,
                  "windowOpacity": 0.7,
                  "margin": 0.1
                }'
            builtin: true
        }
    }

    function getProfileIndexByName(name) {
        for (var i = 0; i < profilesList.count; i++) {
            if(profilesList.get(i).text === name)
                return i;
        }
        return -1;
    }

    Component.onCompleted: {
        // Manage the arguments from the QML side.
        var args = Qt.application.arguments;
        if (args.indexOf("--verbose") !== -1) {
            verbose = true;
        }
        if (args.indexOf("--default-settings") === -1) {
            loadSettings();
        }

        loadCustomProfiles();

        var profileArgPosition = args.indexOf("--profile");
        if (profileArgPosition !== -1) {
            var profileIndex = getProfileIndexByName(args[profileArgPosition + 1]);
            if (profileIndex !== -1)
                loadProfile(profileIndex);
            else
                console.log("Warning: selected profile is not valid; ignoring it");
        }

        if (args.indexOf("--fullscreen") !== -1) {
            fullscreen = true;
            showMenubar = false;
        }

        if (args.indexOf("-T") !== -1) {
            wintitle = args[args.indexOf("-T") + 1]
        }

        initializedSettings();
    }
    Component.onDestruction: {
        storeSettings();
        storeCustomProfiles();
//        storage.dropSettings(); //DROPS THE SETTINGS!.. REMEMBER TO DISABLE ONCE ENABLED!!
    }

    // VARS ///////////////////////////////////////////////////////////////////

    property Label _sampleLabel: Label {
        text: "100%"
    }
    property real labelWidth: _sampleLabel.width
}
