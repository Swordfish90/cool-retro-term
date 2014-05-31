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
    property bool fullscreen: false

    property real ambient_light: 0.2
    property real contrast: 0.85
    property real brightness: 0.75

    //On resize shows an overlay with the current size
    property bool show_terminal_size: true

    property real window_scaling: 1.0
    onWindow_scalingChanged: handleFontChanged();

    property real fps: 60

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

    //Probably there is a better way to cast string to colors.
    property string _background_color: "#000000"
    property string _font_color: "#ff9400"
    property color font_color: mix(strToColor(_font_color), strToColor(_background_color), 0.7 + (contrast * 0.3))
    property color background_color: mix(strToColor(_background_color), strToColor(_font_color), 0.7 + (contrast * 0.3))

    property real noise_strength: 0.1
    property real screen_distortion: 0.15
    property real glowing_line_strength: 0.4
    property real motion_blur: 0.65
    property real bloom_strength: 0.6

    property real horizontal_sincronization: 0.1
    property real brightness_flickering: 0.12

    readonly property int no_rasterization: 0
    readonly property int scanline_rasterization: 1
    readonly property int pixel_rasterization: 2

    property int rasterization: no_rasterization

    property string frame_source: frames_list.get(frames_index).source
    property int frames_index: 1
    property var frames_list: framelist

    signal terminalFontChanged

    property var _font_scalings: [0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0]
    property var font: currentfont
    property int font_index: 0
    property var fonts_list: fontlist

    property bool frame_reflections: true
    property real frame_reflection_strength: ((frame_reflections && framelist.get(frames_index).reflections) ? 1.0 : 0.0) * 0.15

    property alias profiles_list: profileslist
    property int profiles_index: 0
    onProfiles_indexChanged: loadProfile(profiles_index);

    onFont_indexChanged: handleFontChanged();
    onFont_scaling_indexChanged: handleFontChanged();

    function handleFontChanged(){
        var f = fontlist.get(font_index);
        var metrics = f.metrics.get(font_scaling_index);
        currentfont.source = f.source;
        currentfont.pixelSize = metrics.px;
        currentfont.lineSpacing = f.lineSpacing;
        currentfont.virtualResolution = Qt.size(metrics.virtualWidth,
                                                metrics.virtualHeight);
        terminalFontChanged();
    }

    FontLoader{
        property int pixelSize
        property real lineSpacing
        property size virtualResolution
        id: currentfont
        source: fontlist.get(font_index).source
    }

    ListModel{
        id: framelist
        ListElement{text: "No frame"; source: "./frames/NoFrame.qml"; reflections: false}
        ListElement{text: "Simple white frame"; source: "./frames/WhiteSimpleFrame.qml"; reflections: true}
        ListElement{text: "Rough black frame"; source: "./frames/BlackRoughFrame.qml"; reflections: true}
    }

    property int font_scaling_index: 0
    ListModel{
        id: fontlist
        ListElement{
            text: "Terminus (Modern)"
            source: "fonts/modern-terminus/TerminusTTF-4.38.2.ttf"
            lineSpacing: 1
            metrics: [
                ListElement{px: 18; virtualWidth: 3; virtualHeight: 6},
                ListElement{px: 27; virtualWidth: 5; virtualHeight: 8},
                ListElement{px: 36; virtualWidth: 6; virtualHeight: 11},
                ListElement{px: 44; virtualWidth: 7; virtualHeight: 11},
                ListElement{px: 54; virtualWidth: 7; virtualHeight: 11},
                ListElement{px: 62; virtualWidth: 8; virtualHeight: 13},
                ListElement{px: 71; virtualWidth: 7; virtualHeight: 13}]
        }
        ListElement{
            text: "Commodore PET (1977)"
            source: "fonts/1977-commodore-pet/COMMODORE_PET.ttf"
            lineSpacing: 2
            metrics: [
                ListElement{px: 16; virtualWidth: 8; virtualHeight: 6},
                ListElement{px: 20; virtualWidth: 7; virtualHeight: 6},
                ListElement{px: 27; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 34; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 40; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 44; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 50; virtualWidth: 8; virtualHeight: 8}]
        }
        ListElement{
            text: "Apple ][ (1977)"
            source: "fonts/1977-apple2/PrintChar21.ttf"
            lineSpacing: 2
            metrics: [
                ListElement{px: 15; virtualWidth: 6; virtualHeight: 5},
                ListElement{px: 21; virtualWidth: 6; virtualHeight: 7},
                ListElement{px: 27; virtualWidth: 7; virtualHeight: 8},
                ListElement{px: 34; virtualWidth: 7; virtualHeight: 8},
                ListElement{px: 40; virtualWidth: 7; virtualHeight: 8},
                ListElement{px: 47; virtualWidth: 7; virtualHeight: 8},
                ListElement{px: 54; virtualWidth: 7; virtualHeight: 8}]
        }
        ListElement{
            text: "Atari 400-800 (1979)"
            source: "fonts/1979-atari-400-800/ATARI400800_original.TTF"
            lineSpacing: 3
            metrics: [
                ListElement{px: 16; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 20; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 25; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 31; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 38; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 47; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 54; virtualWidth: 8; virtualHeight: 8}]
        }
        ListElement{
            text: "Commodore 64 (1982)"
            source: "fonts/1982-commodore64/C64_User_Mono_v1.0-STYLE.ttf"
            lineSpacing: 3
            metrics: [
                ListElement{px: 16; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 20; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 25; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 31; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 38; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 47; virtualWidth: 8; virtualHeight: 8},
                ListElement{px: 54; virtualWidth: 8; virtualHeight: 8}]
        }
        ListElement{
            text: "Atari ST (1985)"
            source: "fonts/1985-atari-st/AtariST8x16SystemFont.ttf"
            lineSpacing: 4
            metrics: [
                ListElement{px: 16; virtualWidth: 3; virtualHeight: 5},
                ListElement{px: 23; virtualWidth: 4; virtualHeight: 7},
                ListElement{px: 30; virtualWidth: 4; virtualHeight: 10},
                ListElement{px: 38; virtualWidth: 6; virtualHeight: 10},
                ListElement{px: 44; virtualWidth: 7; virtualHeight: 14},
                ListElement{px: 53; virtualWidth: 7; virtualHeight: 14},
                ListElement{px: 58; virtualWidth: 7; virtualHeight: 14}]
        }
        ListElement{
            text: "IBM DOS (1985)"
            source: "fonts/1985-ibm-pc-vga/Perfect DOS VGA 437.ttf"
            lineSpacing: 2
            metrics: [
                ListElement{px: 18; virtualWidth: 5; virtualHeight: 7},
                ListElement{px: 25; virtualWidth: 5; virtualHeight: 9},
                ListElement{px: 36; virtualWidth: 6; virtualHeight: 12},
                ListElement{px: 45; virtualWidth: 7; virtualHeight: 15},
                ListElement{px: 54; virtualWidth: 8; virtualHeight: 15},
                ListElement{px: 62; virtualWidth: 8; virtualHeight: 15},
                ListElement{px: 74; virtualWidth: 9; virtualHeight: 16}]
        }
    }

    Storage{id: storage}

    function composeSettingsString(){
        var settings = {
            fps: fps,
            window_scaling: window_scaling,
            show_terminal_size: show_terminal_size,
            brightness: brightness,
            contrast: contrast,
            ambient_light: ambient_light,
            font_scaling_index: font_scaling_index,
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
            screen_distortion: screen_distortion,
            glowing_line_strength: glowing_line_strength,
            frames_index: frames_index,
            font_index: font_index,
            motion_blur: motion_blur,
            bloom_strength: bloom_strength,
            rasterization: rasterization
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

        console.log("Storing settings :" + settingsString + profileString);
    }

    function loadSettingsString(settingsString){
        var settings = JSON.parse(settingsString);

        ambient_light = settings.ambient_light !== undefined ? settings.ambient_light : ambient_light;

        contrast = settings.contrast !== undefined ? settings.contrast : contrast;
        brightness = settings.brightness !== undefined ? settings.brightness : brightness

        show_terminal_size = settings.show_terminal_size ? settings.show_terminal_size : show_terminal_size

        fps = settings.fps !== undefined ? settings.fps: fps
        window_scaling = settings.window_scaling ? settings.window_scaling : window_scaling

        font_scaling_index = settings.font_scaling_index !== undefined ? settings.font_scaling_index: font_scaling_index;
    }

    function loadProfileString(profileString){
        var settings = JSON.parse(profileString);

        _background_color = settings.background_color !== undefined ? settings.background_color : _background_color;
        _font_color = settings.font_color !== undefined ? settings.font_color : _font_color;

        horizontal_sincronization = settings.horizontal_sincronization !== undefined ? settings.horizontal_sincronization : horizontal_sincronization
        brightness_flickering = settings.brightness_flickering !== undefined ? settings.brightness_flickering : brightness_flickering;
        noise_strength = settings.noise_strength !== undefined ? settings.noise_strength : noise_strength;
        screen_distortion = settings.screen_distortion !== undefined ? settings.screen_distortion : screen_distortion;
        glowing_line_strength = settings.glowing_line_strength !== undefined ? settings.glowing_line_strength : glowing_line_strength;

        motion_blur = settings.motion_blur !== undefined ? settings.motion_blur : motion_blur
        bloom_strength = settings.bloom_strength !== undefined ? settings.bloom_strength : bloom_strength

        frames_index = settings.frames_index !== undefined ? settings.frames_index : frames_index;

        font_index = settings.font_index !== undefined ? settings.font_index : font_index;

        rasterization = settings.rasterization !== undefined ? settings.rasterization : rasterization;
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

    function loadProfile(index){
        var profile = profileslist.get(index);
        loadProfileString(profile.obj_string);
    }

    function addNewCustomProfile(name){
        var profileString = composeProfileString();
        profileslist.append({text: name, obj_string: profileString, builtin: false});
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

    ListModel{
        id: profileslist
        ListElement{
            text: "Default"
            obj_string: '{"background_color":"#000000","bloom_strength":0.6,"brightness_flickering":0.12,"font_color":"#ff9400","font_index":0,"frames_index":1,"glowing_line_strength":0.4,"horizontal_sincronization":0.1,"motion_blur":0.65,"noise_strength":0.1,"rasterization":1,"screen_distortion":0.15}'
            builtin: true
        }
        ListElement{
            text: "Commodore 64"
            obj_string: '{"ambient_light":0.2,"background_color":"#5048b2","font_color":"#8bcad1","font_index":2,"font_scaling":1,"frames_index":1,"glowing_line_strength":0.2,"noise_strength":0.05,"scanlines":0.0,"screen_distortion":0.1,"brightness_flickering":0.03}'
            builtin: true
        }
        ListElement{
            text: "IBM Dos"
            obj_string: '{"ambient_light":0.4,"background_color":"#000000","font_color":"#ffffff","font_index":3,"font_scaling":1,"frames_index":1,"glowing_line_strength":0,"noise_strength":0,"scanlines":0.0,"screen_distortion":0.05,"brightness_flickering":0.00}'
            builtin: true
        }
    }
}
