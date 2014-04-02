import QtQuick 2.0
import "utils"

TerminalFrame{
    id: frame
    z: 2.1
    anchors.fill: parent
    addedWidth: 140
    addedHeight: 140
    borderLeft: 116
    borderRight: 116
    borderTop: 116
    borderBottom: 116
    imageSource: "../images/screen-frame.png"
    sourceRect: Qt.rect(-65 * shadersettings.total_scaling,
                        -75 * shadersettings.total_scaling,
                        terminal.width + 130 * shadersettings.total_scaling,
                        terminal.height + 150 * shadersettings.total_scaling)

    shaderString: "NoFrameShader.qml"
}
