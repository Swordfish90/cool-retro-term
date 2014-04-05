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
    normalsSource: "../images/screen-frame-normals.png"
    sourceRect: Qt.rect(-10 * shadersettings.total_scaling,
                        -5 * shadersettings.total_scaling,
                        terminal.width + 20 * shadersettings.total_scaling,
                        terminal.height+ 10 * shadersettings.total_scaling)

    distortionCoefficient: 1.3

    displacementLeft: 43.0
    displacementTop: 40.0
    displacementRight: 35.0
    displacementBottom: 32.0

    shaderString: "FrameShader.qml"
}
