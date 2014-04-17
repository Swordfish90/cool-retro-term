import QtQuick 2.0

Rectangle{
    property size terminalSize
    property real topOpacity: 0.6
    width: textSize.width * 2
    height: textSize.height * 2
    radius: 5
    border.width: 2
    border.color: "white"
    color: "black"
    opacity: sizetimer.running ? 0.6 : 0.0

    Behavior on opacity{NumberAnimation{duration: 200}}

    onTerminalSizeChanged: sizetimer.restart()

    Text{
        id: textSize
        anchors.centerIn: parent
        color: "white"
        text: terminalSize.width + "x" + terminalSize.height
    }
    Timer{
        id: sizetimer
        interval: 1000
        running: false
    }
}
