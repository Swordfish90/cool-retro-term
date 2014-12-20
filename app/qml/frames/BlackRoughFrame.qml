import QtQuick 2.2
import "utils"

TerminalFrame{
    id: frame
    z: 2.1
    anchors.fill: parent
    addedWidth: 200
    addedHeight: 370
    borderLeft: 170
    borderRight: 170
    borderTop: 250
    borderBottom: 250
    imageSource: "../images/black-frame.png"
    normalsSource: "../images/black-frame-normals.png"

    displacementLeft: 80.0
    displacementTop: 65.0
    displacementRight: 80.0
    displacementBottom: 65.0

    staticDiffuseComponent: 1.0
    dinamycDiffuseComponent: 0.6
}
