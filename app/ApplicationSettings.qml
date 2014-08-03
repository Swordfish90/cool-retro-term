/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordifish90/cool-old-term
*
* This file is part of cool-old-term.
*
* cool-old-term is free software: you can redistribute it and/or modify
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
    onWindow_scalingChanged: handleFontChanged();

    property real fps: 0

    function mix(c1, c2, alpha){
        return Qt.rgba(c1.r * alpha + c2.r * (1-alpha),
                       c1.g * alpha + c2.g * (1-alpha),
                       c1.b * alpha + c2.b * (1-alpha),
                       c1.a * alpha + c2.a * (1-alpha))
    }
    function strToColor(s){
        var r = parseInt(s.substring(1,3), 16) / 256;
        var g = parseInt(s.substring(3,5), 16) / 256;
        var b = parseInt(s.substring(5,7), 16) / 256;
        return Qt.rgba(r, g, b, 1.0);
    }

    // PROFILE SETTINGS ///////////////////////////////////////////////////////

    property string _background_color: "#000000"
    property string _font_color: "#ff8100"
    property color font_color: mix(strToColor(_font_color), strToColor(_background_color), 0.7 + (contrast * 0.3))
    property color background_color: mix(strToColor(_background_color), strToColor(_font_color), 0.7 + (contrast * 0.3))

    property real noise_strength: 0.1
    property real screen_distortion: 0.1
    property real glowing_line_strength: 0.2
    property real motion_blur: 0.40
    property real bloom_strength: 0.65

    property real chroma_color: 0.0
    property real saturation_color: 0.0

    property real jitter: 0.18

    property real horizontal_sincronization: 0.08
    property real brightness_flickering: 0.1

    readonly property int no_rasterization: 0
    readonly property int scanline_rasterization: 1
    readonly property int pixel_rasterization: 2

    property int rasterization: no_rasterization

    ListModel{
        id: framelist
        ListElement{text: "No frame"; source: "./frames/NoFrame.qml"; reflections: false}
        ListElement{text: "Simple white frame"; source: "./frames/WhiteSimpleFrame.qml"; reflections: true}
        ListElement{text: "Rough black frame"; source: "./frames/BlackRoughFrame.qml"; reflections: true}
    }

    property string frame_source: frames_list.get(frames_index).source
    property int frames_index: 1
    property var frames_list: framelist


    // FONTS //////////////////////////////////////////////////////////////////

    signal terminalFontChanged(string fontSource, int pixelSize, int lineSpacing, size virtualCharSize)

    Loader{
        id: fontManager

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

    signal fontScalingChanged
    property var fontScalingList: fontManager.item.fontScalingList
    property var fontScalingIndexes: [5,1,1]

    function setScalingIndex(newScaling){
        fontScalingIndexes[rasterization] = newScaling;
        fontScalingChanged();
        handleFontChanged();
    }

    function getScalingIndex(){
        return fontScalingIndexes[rasterization];
    }

    property var fontIndexes: [0,0,0]
    property var fontlist: fontManager.item.fontlist

    function handleFontChanged(){
        if(!fontManager.item) return;
        fontManager.item.selectedFontIndex = fontIndexes[rasterization];
        fontManager.item.selectedScalingIndex = fontScalingIndexes[rasterization];

        var fontSource = fontManager.item.source;
        var pixelSize = fontManager.item.pixelSize;
        var lineSpacing = fontManager.item.lineSpacing;
        var virtualCharSize = fontManager.item.virtualCharSize;

        terminalFontChanged(fontSource, pixelSize, lineSpacing, virtualCharSize);
    }

    // FRAMES /////////////////////////////////////////////////////////////////

    property bool _frameReflections: true
    property bool reflectionsAllowed: framelist.get(frames_index).reflections
    property bool frameReflections: _frameReflections && reflectionsAllowed

    property alias profiles_list: profileslist
    property int profiles_index: 0

    // DB STORAGE /////////////////////////////////////////////////////////////

    Storage{id: storage}

    function composeSettingsString(){
        var settings = {
            fps: fps,
            window_scaling: window_scaling,
            show_terminal_size: show_terminal_size,
            fontScalingIndexes: fontScalingIndexes,
            fontIndexes: fontIndexes,
            frameReflections: _frameReflections,
            showMenubar: showMenubar
        }
        return JSON.stringify(settings);
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
            brightness: brightness,
            contrast: contrast,
            ambient_light: ambient_light,
            windowOpacity: windowOpacity,
            fontIndex: fontIndexes[rasterization]
        }
        return JSON.stringify(settings);
    }

    function loadSettings(){
        var settingsString = storage.getSetting("_CURRENT_SETTINGS");
        var profileString = storage.getSetting("_CURRENT_PROFILE");

        if(!settingsString) return;
        if(!profileString) return;

        loadSettingsString(settingsString);
        loadProfileString(profileString);

        console.log("Loading settings: " + settingsString + profileString);
    }

    function storeSettings(){
        var settingsString = composeSettingsString();
        var profileString = composeProfileString();

        storage.setSetting("_CURRENT_SETTINGS", settingsString);
        storage.setSetting("_CURRENT_PROFILE", profileString);

        console.log("Storing settings: " + settingsString);
        console.log("Storing profile: " + profileString);
    }

    function loadSettingsString(settingsString){
        var settings = JSON.parse(settingsString);

        show_terminal_size = settings.show_terminal_size !== undefined ? settings.show_terminal_size : show_terminal_size

        fps = settings.fps !== undefined ? settings.fps: fps
        window_scaling = settings.window_scaling !== undefined ? settings.window_scaling : window_scaling

        fontIndexes = settings.fontIndexes !== undefined ? settings.fontIndexes : fontIndexes
        fontScalingIndexes = settings.fontScalingIndexes !== undefined ? settings.fontScalingIndexes : fontScalingIndexes

        _frameReflections = settings.frameReflections !== undefined ? settings.frameReflections : _frameReflections;

        showMenubar = settings.showMenubar !== undefined ? settings.showMenubar : showMenubar;
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

        ambient_light = settings.ambient_light !== undefined ? settings.ambient_light : ambient_light;
        contrast = settings.contrast !== undefined ? settings.contrast : contrast;
        brightness = settings.brightness !== undefined ? settings.brightness : brightness;
        windowOpacity = settings.windowOpacity !== undefined ? settings.windowOpacity : windowOpacity;

        fontIndexes[rasterization] = settings.fontIndex !== undefined ? settings.fontIndex : fontIndexes[rasterization];
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
            console.log("Loading custom profile: " + JSON.stringify(profile));
            profiles_list.append(profile);
        }
    }

    function composeCustomProfilesString(){
        var customProfiles = []
        for(var i=0; i<profileslist.count; i++){
            var profile = profileslist.get(i);
            if(profile.builtin) continue;
            customProfiles.push({text: profile.text, obj_string: profile.obj_string, builtin: false})
        }
        return JSON.stringify(customProfiles);
    }

    function loadCurrentProfile(){
        loadProfile(profiles_index);
    }

    function loadProfile(index){
        var profile = profileslist.get(index);
        loadProfileString(profile.obj_string);
    }

    function addNewCustomProfile(name){
        var profileString = composeProfileString();
        profileslist.append({text: name, obj_string: profileString, builtin: false});
    }

    // PROFILES ///////////////////////////////////////////////////////////////

    ListModel{
        id: profileslist
        ListElement{
            text: "Default Amber"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.65,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontIndex":0,"font_color":"#ff8100","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.08,"jitter":0.18,"motion_blur":0.4,"noise_strength":0.1,"rasterization":0,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0}'
            builtin: true
        }
        ListElement{
            text: "Default Green"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontIndex":0,"font_color":"#0ccc68","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.08,"jitter":0.18,"motion_blur":0.45,"noise_strength":0.1,"rasterization":0,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0}'
            builtin: true
        }
        ListElement{
            text: "Default Scanlines"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontIndex":0,"font_color":"#00ff5b","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.07,"jitter":0.11,"motion_blur":0.4,"noise_strength":0.05,"rasterization":1,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0}'
            builtin: true
        }
        ListElement{
            text: "Default Pixelated"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.1,"contrast":0.85,"fontIndex":0,"font_color":"#ff8100","frames_index":1,"glowing_line_strength":0.2,"horizontal_sincronization":0.1,"jitter":0,"motion_blur":0.45,"noise_strength":0.14,"rasterization":2,"screen_distortion":0.05,"windowOpacity":1,"chroma_color":0,"saturation_color":0}'
            builtin: true
        }
        ListElement{
            text: "Apple ]["
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.5,"brightness":0.5,"brightness_flickering":0.2,"contrast":0.85,"fontIndex":2,"font_color":"#2fff91","frames_index":1,"glowing_line_strength":0.22,"horizontal_sincronization":0.08,"jitter":0.1,"motion_blur":0.65,"noise_strength":0.08,"rasterization":1,"screen_distortion":0.18,"windowOpacity":1,"chroma_color":0,"saturation_color":0}'
            builtin: true
        }
        ListElement{
            text: "Vintage"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.54,"contrast":0.85,"fontIndex":0,"font_color":"#00ff3e","frames_index":2,"glowing_line_strength":0.3,"horizontal_sincronization":0.2,"jitter":0.4,"motion_blur":0.75,"noise_strength":0.2,"rasterization":1,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":0,"saturation_color":0}'
            builtin: true
        }
        ListElement{
            text: "IBM Dos"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4,"brightness":0.5,"brightness_flickering":0.07,"contrast":0.85,"fontIndex":7,"font_color":"#ffffff","frames_index":1,"glowing_line_strength":0.13,"horizontal_sincronization":0,"jitter":0.08,"motion_blur":0.3,"noise_strength":0.03,"rasterization":0,"screen_distortion":0.1,"windowOpacity":1,"chroma_color":1,"saturation_color":0}'
            builtin: true
        }
        ListElement{
            text: "Transparent Green"
            obj_string: '{"ambient_light":0.2,"background_color":"#000000","bloom_strength":0.4549689440993788,"brightness":0.5,"brightness_flickering":0.20341614906832298,"contrast":0.85,"fontIndex":0,"font_color":"#0ccc68","frames_index":0,"glowing_line_strength":0.15993788819875776,"horizontal_sincronization":0.05045871559633028,"jitter":0.20341614906832298,"motion_blur":0.24999999999999997,"noise_strength":0.20031055900621117,"rasterization":0,"screen_distortion":0.05045871559633028,"windowOpacity":0.5956221198156681,"chroma_color":0,"saturation_color":0}'
            builtin: true
        }
    }

    Component.onCompleted: {
        loadSettings();
        loadCustomProfiles();
    }
    Component.onDestruction: {
        storeSettings();
        storeCustomProfiles();
        //storage.dropSettings(); //DROPS THE SETTINGS!.. REMEMBER TO DISABLE ONCE ENABLED!!
    }
}
