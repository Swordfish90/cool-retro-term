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

import "utils.js" as Utils

QtObject{
    property string version: "0.9"

    // GENERAL SETTINGS ///////////////////////////////////////////////////

    property bool fullscreen: false
    property bool showMenubar: true

    property real windowOpacity: 1.0
    property real ambient_light: 0.2
    property real contrast: 0.85
    property real brightness: 0.5

    property bool show_terminal_size: true
    property real window_scaling: 1.0

    property real fps: 24
    property bool verbose: false

    onWindow_scalingChanged: handleFontChanged();

    // PROFILE SETTINGS ///////////////////////////////////////////////////////

    property string _background_color: "#000000"
    property string _font_color: "#ff8100"
    property string saturated_color: Utils.mix(Utils.strToColor("#FFFFFF"), Utils.strToColor(_font_color), saturation_color * 0.5)
    property color font_color: Utils.mix(Utils.strToColor(saturated_color), Utils.strToColor(_background_color), 0.7 + (contrast * 0.3))
    property color background_color: Utils.mix(Utils.strToColor(_background_color), Utils.strToColor(saturated_color), 0.7 + (contrast * 0.3))

    property real noise_strength: 0.1
    property real screen_distortion: 0.1
    property real glowing_line_strength: 0.2
    property real motion_blur: 0.40
    property real bloom_strength: 0.65

    property real bloom_quality: 0.5
    property real blur_quality: 0.5

    property real chroma_color: 0.0
    property real saturation_color: 0.0

    property real jitter: 0.18

    property real horizontal_sincronization: 0.08
    property real brightness_flickering: 0.1

    property real rgb_shift: 0.0

    readonly property int no_rasterization: 0
    readonly property int scanline_rasterization: 1
    readonly property int pixel_rasterization: 2

    property int rasterization: no_rasterization

    property int profiles_index: 0

    // FONTS //////////////////////////////////////////////////////////////////

    property real fontScaling: 1.0
    property real fontWidth: 1.0

    property var fontNames: ["TERMINUS", "COMMODORE_PET", "COMMODORE_PET"]
    property var fontlist: fontManager.item.fontlist

    signal terminalFontChanged(string fontSource, int pixelSize, int lineSpacing, real screenScaling, real fontWidth)

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

    onFontScalingChanged: handleFontChanged();
    onFontWidthChanged: handleFontChanged();

    function getIndexByName(name) {
        for (var i = 0; i < fontlist.count; i++) {
            if (name === fontlist.get(i).name)
                return i;
        }
        return 0; // If the font is not available returns the first one.
    }

    function incrementScaling(){
        fontScaling = Math.min(fontScaling + 0.05, 2.50);
        handleFontChanged();
    }

    function decrementScaling(){
        fontScaling = Math.max(fontScaling - 0.05, 0.50);
        handleFontChanged();
    }

    function handleFontChanged(){
        if (!fontManager.item) return;

        var index = getIndexByName(fontNames[rasterization]);
        if (index === undefined) return;

        fontManager.item.selectedFontIndex = index;
        fontManager.item.scaling = fontScaling * window_scaling;

        var fontSource = fontManager.item.source;
        var pixelSize = fontManager.item.pixelSize;
        var lineSpacing = fontManager.item.lineSpacing;
        var screenScaling = fontManager.item.screenScaling;
        var fontWidth = fontManager.item.defaultFontWidth * appSettings.fontWidth;

        terminalFontChanged(fontSource, pixelSize, lineSpacing, screenScaling, fontWidth);
    }

    // FRAMES /////////////////////////////////////////////////////////////////

    property bool _frameReflections: false
    property bool reflectionsAllowed: frames_list.get(frames_index).reflections
    property bool frameReflections: _frameReflections && reflectionsAllowed

    property ListModel frames_list: ListModel{
        ListElement{text: "No frame"; source: ""; reflections: false}
        ListElement{text: "Simple white frame"; source: "./frames/WhiteSimpleFrame.qml"; reflections: true}
        ListElement{text: "Rough black frame"; source: "./frames/BlackRoughFrame.qml"; reflections: true}
    }

    property string frame_source: frames_list.get(frames_index).source
    property int frames_index: 1

    // DB STORAGE /////////////////////////////////////////////////////////////

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
            window_scaling: window_scaling,
            show_terminal_size: show_terminal_size,
            fontScaling: fontScaling,
            fontNames: fontNames,
            frameReflections: _frameReflections,
            showMenubar: showMenubar,
            bloom_quality: bloom_quality,
            blur_quality: blur_quality
        }
        return stringify(settings);
    }

    function composeProfileString(){
        var settings = {
            background_color: _background_color,
            font_color: _font_color,
            brightness_flickering: brightness_flickering,
            horizontal_sincronization: horizontal_sincronization,
            noise_strength: noise_strength,
            chroma_color: chroma_color,
            saturation_color: saturation_color,
            screen_distortion: screen_distortion,
            glowing_line_strength: glowing_line_strength,
            frames_index: frames_index,
            motion_blur: motion_blur,
            bloom_strength: bloom_strength,
            rasterization: rasterization,
            jitter: jitter,
            rgb_shift: rgb_shift,
            brightness: brightness,
            contrast: contrast,
            ambient_light: ambient_light,
            windowOpacity: windowOpacity,
            fontName: fontNames[rasterization],
            fontWidth: fontWidth
        }
        return stringify(settings);
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

        show_terminal_size = settings.show_terminal_size !== undefined ? settings.show_terminal_size : show_terminal_size

        fps = settings.fps !== undefined ? settings.fps: fps
        window_scaling = settings.window_scaling !== undefined ? settings.window_scaling : window_scaling

        fontNames = settings.fontNames !== undefined ? settings.fontNames : fontNames
        fontScaling = settings.fontScaling !== undefined ? settings.fontScaling : fontScaling

        _frameReflections = settings.frameReflections !== undefined ? settings.frameReflections : _frameReflections;

        showMenubar = settings.showMenubar !== undefined ? settings.showMenubar : showMenubar;

        bloom_quality = settings.bloom_quality !== undefined ? settings.bloom_quality : bloom_quality;
        blur_quality = settings.blur_quality !== undefined ? settings.blur_quality : blur_quality;
    }

    function loadProfileString(profileString){
        var settings = JSON.parse(profileString);

        _background_color = settings.background_color !== undefined ? settings.background_color : _background_color;
        _font_color = settings.font_color !== undefined ? settings.font_color : _font_color;

        horizontal_sincronization = settings.horizontal_sincronization !== undefined ? settings.horizontal_sincronization : horizontal_sincronization
        brightness_flickering = settings.brightness_flickering !== undefined ? settings.brightness_flickering : brightness_flickering;
        noise_strength = settings.noise_strength !== undefined ? settings.noise_strength : noise_strength;
        chroma_color = settings.chroma_color !== undefined ? settings.chroma_color : chroma_color;
        saturation_color = settings.saturation_color !== undefined ? settings.saturation_color : saturation_color;
        screen_distortion = settings.screen_distortion !== undefined ? settings.screen_distortion : screen_distortion;
        glowing_line_strength = settings.glowing_line_strength !== undefined ? settings.glowing_line_strength : glowing_line_strength;

        motion_blur = settings.motion_blur !== undefined ? settings.motion_blur : motion_blur
        bloom_strength = settings.bloom_strength !== undefined ? settings.bloom_strength : bloom_strength

        frames_index = settings.frames_index !== undefined ? settings.frames_index : frames_index;

        rasterization = settings.rasterization !== undefined ? settings.rasterization : rasterization;

        jitter = settings.jitter !== undefined ? settings.jitter : jitter;

        rgb_shift = settings.rgb_shift !== undefined ? settings.rgb_shift : rgb_shift;

        ambient_light = settings.ambient_light !== undefined ? settings.ambient_light : ambient_light;
        contrast = settings.contrast !== undefined ? settings.contrast : contrast;
        brightness = settings.brightness !== undefined ? settings.brightness : brightness;
        windowOpacity = settings.windowOpacity !== undefined ? settings.windowOpacity : windowOpacity;

        fontNames[rasterization] = settings.fontName !== undefined ? settings.fontName : fontNames[rasterization];
        fontWidth = settings.fontWidth !== undefined ? settings.fontWidth : fontWidth;
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
            console.log("Loading custom profile: " + stringify(profile));
            profiles_list.append(profile);
        }
    }

    function composeCustomProfilesString(){
        var customProfiles = []
        for(var i=0; i<profiles_list.count; i++){
            var profile = profiles_list.get(i);
            if(profile.builtin) continue;
            customProfiles.push({text: profile.text, obj_string: profile.obj_string, builtin: false})
        }
        return stringify(customProfiles);
    }

    function loadCurrentProfile(){
        loadProfile(profiles_index);
    }

    function loadProfile(index){
        var profile = profiles_list.get(index);
        loadProfileString(profile.obj_string);
    }

    function addNewCustomProfile(name){
        var profileString = composeProfileString();
        profiles_list.append({text: name, obj_string: profileString, builtin: false});
    }

    // PROFILES ///////////////////////////////////////////////////////////////

    property ListModel profiles_list: ListModel{
        ListElement{
            text: "Default Amber"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.65,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontName":"TERMINUS","font_color":"#ff8100","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.08,"jitter":0.18,"motion_blur":0.4,"noise_strength":0.1,"rasterization":0,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "Default Green"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontName":"TERMINUS","font_color":"#0ccc68","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.08,"jitter":0.18,"motion_blur":0.45,"noise_strength":0.1,"rasterization":0,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "Default Scanlines"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontName":"TERMINUS","font_color":"#00ff5b","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.07,"jitter":0.11,"motion_blur":0.4,"noise_strength":0.05,"rasterization":1,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "Default Pixelated"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontName":"TERMINUS","font_color":"#ff8100","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.1,"jitter":0,"motion_blur":0.45,"noise_strength":0.14,"rasterization":2,"screen_distortion":0.05,"windowOpacity":1,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "Apple ]["
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.5,"brightness":0.5,"brightness_flickering":0.2,"contrast":0.85,"fontName":"APPLE_II","font_color":"#2fff91","frames_index":1,"glowing_line_strength":0.22,"horizontal_sincronization":0.08,"jitter":0.1,"motion_blur":0.65,"noise_strength":0.08,"rasterization":1,"screen_distortion":0.18,"windowOpacity":1,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "Vintage"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.54,"contrast":0.85,"fontName":"TERMINUS","font_color":"#00ff3e","frames_index":2,"glowing_line_strength":0.3,"horizontal_sincronization":0.2,"jitter":0.4,"motion_blur":0.75,"noise_strength":0.2,"rasterization":1,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "IBM Dos"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.07,"contrast":0.85,"fontName":"IBM_DOS","font_color":"#ffffff","frames_index":1,"glowing_line_strength":0.13,"horizontal_sincronization":0,"jitter":0.08,"motion_blur":0.3,"noise_strength":0.03,"rasterization":0,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":1,"saturation_color":0,"rgb_shift":0.5,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "IBM 3278"
            obj_string: '{"ambient_light":0.1,"background_color":"#000000","bloom_strength":0.15,"brightness":0.5,"brightness_flickering":0,"contrast":0.95,"fontName":"IBM_3278","font_color":"#0ccc68","frames_index":1,"glowing_line_strength":0,"horizontal_sincronization":0,"jitter":0,"motion_blur":0.6,"noise_strength":0,"rasterization":0,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
        ListElement{
            text: "Transparent Green"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.45,"brightness":0.5,"brightness_flickering":0.20,"contrast":0.85,"fontName":"TERMINUS","font_color":"#0ccc68","frames_index":0,"glowing_line_strength":0.16,"horizontal_sincronization":0.05,"jitter":0.20,"motion_blur":0.25,"noise_strength":0.20,"rasterization":0,"screen_distortion":0.05,"windowOpacity":0.60,"chroma_color":0,"saturation_color":0,"rgb_shift":0,"fontWidth":1.0}'
            builtin: true
        }
    }

    function getProfileIndexByName(name) {
        for (var i = 0; i < profiles_list.count; i++) {
            if(profiles_list.get(i).text === name)
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
    }
    Component.onDestruction: {
        storeSettings();
        storeCustomProfiles();
        //storage.dropSettings(); //DROPS THE SETTINGS!.. REMEMBER TO DISABLE ONCE ENABLED!!
    }
}
