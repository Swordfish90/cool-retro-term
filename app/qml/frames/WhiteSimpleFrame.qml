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

    distortionCoefficient: 1.5

    displacementLeft: 55
    displacementTop: 50
    displacementRight: 55
    displacementBottom: 50

    staticDiffuseComponent: 1.0
    dinamycDiffuseComponent: 0.6
}
