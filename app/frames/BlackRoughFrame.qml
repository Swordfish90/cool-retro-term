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
    sourceRect: Qt.rect(-15 * shadersettings.total_scaling,
                        -15 * shadersettings.total_scaling,
                        terminal.width + 30 * shadersettings.total_scaling,
                        terminal.height + 30 * shadersettings.total_scaling)

    distortionCoefficient: 1.8

    displacementLeft: 70.0
    displacementTop: 55.0
    displacementRight: 50.0
    displacementBottom: 38.0

    shaderString: "FrameShader.qml"
}
