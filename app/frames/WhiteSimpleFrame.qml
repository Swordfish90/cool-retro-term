import QtQuick 2.2
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
    normalsSource: "../images/screen-frame-normals.png"
    sourceRect: Qt.rect(-15 * shadersettings.total_scaling,
                        -15 * shadersettings.total_scaling,
                        terminal.width + 30 * shadersettings.total_scaling,
                        terminal.height+ 30 * shadersettings.total_scaling)

    distortionCoefficient: 1.5

    displacementLeft: 45
    displacementTop: 40
    displacementRight: 38.0
    displacementBottom: 28.0

    shaderString: "FrameShader.qml"
}
