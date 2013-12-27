import QtQuick 2.1

Item{
    property real ambient_light: 0.2

    property color background_color: "#002200"
    property color font_color: "#00ff00"

    property real screen_flickering: 0.1
    property real noise_strength: 0.1
    property real screen_distortion: 0.15
    property real glowing_line_strength: 0.4

    property bool scanlines: true

    property string frame_source: frames_list.get(frames_index).source
    property int frames_index: 1
    property var frames_list: framelist

    property var font: currentfont
    property alias fontSize: currentfont.pixelSize
    property int font_index: 2
    property var fonts_list: fontlist

    onFont_indexChanged: {
        terminalwindowloader.source = "";
        terminalwindowloader.source = "TerminalWindow.qml";
    }

    FontLoader{
        property int pixelSize: fontlist.get(font_index).pixelSize
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
            text: "Commodore PET (1977)"
            source: "fonts/CommodorePET/COMMODORE_PET.ttf"
            pixelSize: 20
        }
        ListElement{
            text: "Atari 8bit (1979)"
            source: "./fonts/Atari8bit/ATARI400800_original.TTF"
            pixelSize: 18
        }
        ListElement{
            text: "Commodore 64 (1982)"
            source: "./fonts/Commodore64/C64_User_Mono_v1.0-STYLE.ttf"
            pixelSize: 20
        }
        ListElement{
            text: "IBM DOS (1985)"
            source: "./fonts/Dos/Perfect DOS VGA 437.ttf"
            pixelSize: 25
        }
    }
}
