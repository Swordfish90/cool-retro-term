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
    property ListModel frames_list: ListModel{
        ListElement{text: "No frame"; source: "./frames/NoFrame.qml"}
        ListElement{text: "Simple white frame"; source: "./frames/WhiteSimpleFrame.qml"}
        ListElement{text: "Rough black frame"; source: "./frames/BlackRoughFrame.qml"}
    }
}
