import QtQuick 2.1

Item{
    property real ambient_light: 0.2

    property color background_color: "#002200"
    property color font_color: "#00ff00"

    property real brightness_flickering: 0.2
    property real noise_strength: 0.1
    property real screen_distortion: 0.15
    property real glowing_line_strength: 0.4
    //property real faulty_screen_prob: 1.0

    property bool scanlines: true
}
