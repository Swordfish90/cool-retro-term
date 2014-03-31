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

import QtQuick 2.1

Item{
    property bool fullscreen: false

    property real ambient_light: 0.2
    property real contrast: 0.8

    property real brightness: 0.5

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
    property string _font_color: "#00ff00"
    property color font_color: mix(strToColor(_font_color), strToColor(_background_color), 0.7 + (contrast * 0.3))
    property color background_color: mix(strToColor(_background_color), strToColor(_font_color), 0.7 + (contrast * 0.3))

    property real noise_strength: 0.1
    property real screen_distortion: 0.15
    property real glowing_line_strength: 0.4
    property real motion_blur: 0.65
    property real bloom_strength: 0.6

    property real horizontal_sincronization: 0.1
    property real brightness_flickering: 0.12

    property real scanlines: 0.0

    property string frame_source: frames_list.get(frames_index).source
    property int frames_index: 1
    property var frames_list: framelist

    property real font_scaling: 1.0
    property var font: currentfont
    property real fontSize: currentfont.pixelSize * font_scaling
    property int font_index: 0
    property var fonts_list: fontlist

    property var profiles_list: profileslist
    property int profiles_index: 0
    onProfiles_indexChanged: loadProfile(profiles_list.get(profiles_index).obj_name);

    onFont_indexChanged: handleFontChanged();
    onFont_scalingChanged: handleFontChanged();

    function handleFontChanged(){
        terminal.unloadKTerminal();
        currentfont.source = fontlist.get(font_index).source;
        currentfont.pixelSize = fontlist.get(font_index).pixelSize;
        currentfont.lineSpacing = fontlist.get(font_index).lineSpacing;
        terminal.loadKTerminal();
    }

    FontLoader{
        property int pixelSize: fontlist.get(font_index).pixelSize
        property int lineSpacing: fontlist.get(font_index).lineSpacing
        id: currentfont
        source: fontlist.get(font_index).source
    }

    ListModel{
        id: framelist
        ListElement{text: "No frame"; source: "./frames/NoFrame.qml"}
        ListElement{text: "Simple white frame"; source: "./frames/WhiteSimpleFrame.qml"}
        ListElement{text: "Rough black frame"; source: "./frames/BlackRoughFrame.qml"}
    }

    ListModel{
        id: fontlist
        ListElement{
            text: "Terminus (Modern)"
            source: "fonts/modern-terminus/TerminusTTF-4.38.2.ttf"
            pixelSize: 22
            lineSpacing: 0
        }
        ListElement{
            text: "Commodore PET (1977)"
            source: "fonts/1977-commodore-pet/COMMODORE_PET.ttf"
            pixelSize: 15
            lineSpacing: 0
        }
        ListElement{
            text: "Apple ][ (1977)"
            source: "fonts/1977-apple2/PrintChar21.ttf"
            pixelSize: 18
            lineSpacing: 0
        }
        ListElement{
            text: "Atari 400-800 (1979)"
            source: "fonts/1979-atari-400-800/ATARI400800_original.TTF"
            pixelSize: 16
            lineSpacing: 0
        }
        ListElement{
            text: "Commodore 64 (1982)"
            source: "fonts/1982-commodore64/C64_User_Mono_v1.0-STYLE.ttf"
            pixelSize: 16
            lineSpacing: 0
        }
        ListElement{
            text: "Atari ST (1985)"
            source: "fonts/1985-atari-st/AtariST8x16SystemFont.ttf"
            pixelSize: 18
            lineSpacing: 0
        }
        ListElement{
            text: "IBM DOS (1985)"
            source: "fonts/1985-ibm-pc-vga/Perfect DOS VGA 437.ttf"
            pixelSize: 20
            lineSpacing: 0
        }
    }

    Storage{id: storage}

    function loadProfile(profilename){
        var settings = storage.getSetting(profilename);
        if(!settings) return;
        console.log(profilename + settings);
        settings = JSON.parse(settings);

        contrast = settings.contrast ? settings.contrast : contrast;
        brightness = settings.brightness ? settings.brightness : brightness

        ambient_light = settings.ambient_light ? settings.ambient_light : ambient_light;
        _background_color = settings.background_color ? settings.background_color : _background_color;
        _font_color = settings.font_color ? settings.font_color : _font_color;

        brightness_flickering = settings.brightness_flickering ? settings.brightness_flickering : brightness_flickering;
        noise_strength = settings.noise_strength ? settings.noise_strength : noise_strength;
        screen_distortion = settings.screen_distortion ? settings.screen_distortion : screen_distortion;
        glowing_line_strength = settings.glowing_line_strength ? settings.glowing_line_strength : glowing_line_strength;
        scanlines = settings.scanlines ? settings.scanlines : scanlines;

        motion_blur = settings.motion_blur ? settings.motion_blur : motion_blur
        bloom_strength = settings.bloom_strength ? settings.bloom_strength : bloom_strength

        frames_index = settings.frames_index ? settings.frames_index : frames_index;

        font_index = settings.font_index ? settings.font_index : font_index;
        font_scaling = settings.font_scaling ? settings.font_scaling: font_scaling;
    }

    function storeCurrentSettings(){
        var settings = {
            ambient_light : ambient_light,
            brightness : brightness,
            contrast : contrast,
            background_color: _background_color,
            font_color: _font_color,
            brightness_flickering: brightness_flickering,
            noise_strength: noise_strength,
            screen_distortion: screen_distortion,
            glowing_line_strength: glowing_line_strength,
            scanlines: scanlines,
            frames_index: frames_index,
            font_index: font_index,
            font_scaling: font_scaling,
            motion_blur: motion_blur,
            bloom_strength: bloom_strength
        }

        console.log(JSON.stringify(settings));
        storage.setSetting("CURRENT_SETTINGS", JSON.stringify(settings));
    }

    Component.onCompleted: {
        //Save all the profiles into local storage
        for(var i=0; i<profileslist.count; i++){
            var temp = profileslist.get(i);
            storage.setSetting(temp.obj_name, temp.obj_string);
        }

        loadProfile("CURRENT_SETTINGS");
    }
    Component.onDestruction: {
        storeCurrentSettings();
        //storage.dropSettings(); //DROPS THE SETTINGS!.. REMEMBER TO DISABLE ONCE ENABLED!!
    }


    ListModel{
        id: profileslist
        ListElement{
            text: "Default"
            obj_name: "DEFAULT"
            obj_string: '{"ambient_light":0.3,"background_color":"#000000","font_color":"#00ff3b","font_index":0,"font_scaling":1,"frames_index":2,"glowing_line_strength":0.4,"noise_strength":0.1,"scanlines":0.0,"screen_distortion":0.15,"brightness_flickering":0.07}'
        }
        ListElement{
            text: "Commodore 64"
            obj_name: "COMMODORE64"
            obj_string: '{"ambient_light":0.2,"background_color":"#5048b2","font_color":"#8bcad1","font_index":2,"font_scaling":1,"frames_index":1,"glowing_line_strength":0.2,"noise_strength":0.05,"scanlines":0.0,"screen_distortion":0.1,"brightness_flickering":0.03}'
        }
        ListElement{
            text: "IBM Dos"
            obj_name: "IBMDOS"
            obj_string: '{"ambient_light":0.4,"background_color":"#000000","font_color":"#ffffff","font_index":3,"font_scaling":1,"frames_index":1,"glowing_line_strength":0,"noise_strength":0,"scanlines":0.0,"screen_distortion":0.05,"brightness_flickering":0.00}'
        }
    }
}
