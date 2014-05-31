import QtQuick 2.2
import "utils"

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

    rectX: 15
    rectY: 15

    distortionCoefficient: 1.9

    displacementLeft: 70.0
    displacementTop: 55.0
    displacementRight: 50.0
    displacementBottom: 38.0

    shaderString: "FrameShader.qml"
}
