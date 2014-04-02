import QtQuick 2.1
import "utils"
import QtGraphicalEffects 1.0

TerminalFrame{
    id: frame
    z: 2.1
    anchors.fill: parent
    addedWidth: 200
    addedHeight: 370
    borderLeft: 148
    borderRight: 148
    borderTop: 232
    borderBottom: 232
    imageSource: "../images/black-frame.png"
    normalsSource: "../images/black-frame-normals.png"
    sourceRect: Qt.rect(-80 * shadersettings.total_scaling,
                        -90 * shadersettings.total_scaling,
                        terminal.width + 160 * shadersettings.total_scaling,
                        terminal.height + 180 * shadersettings.total_scaling)

    shaderString: "FrameShader.qml"
}
