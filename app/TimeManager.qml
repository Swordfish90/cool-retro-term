import QtQuick 2.0

Timer{
    property int time

    NumberAnimation on time {
        from: 0
        to: 100000
        running: shadersettings.fps === 0
        duration: 100000
        loops: Animation.Infinite
    }

    onTriggered: time += interval
    running: shadersettings.fps !== 0
    interval: Math.round(1000 / shadersettings.fps)
    repeat: true
}
