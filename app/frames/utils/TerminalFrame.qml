import QtQuick 2.2

Item{
    id: framecontainer
    property int textureWidth: terminalWindow.width
    property int textureHeight: terminalWindow.height

    property int addedWidth
    property int addedHeight
    property int borderLeft
    property int borderRight
    property int borderTop
    property int borderBottom
    property string imageSource
    property string normalsSource
    property string shaderString

    //Value used to create the rect used to add the border to the texture
    property real rectX
    property real rectY

    //Values used to displace the texture in the screen. Used to make reflections correct.
    property real displacementLeft
    property real displacementTop
    property real displacementRight
    property real displacementBottom

    property real distortionCoefficient

    property rect sourceRect: Qt.rect(-rectX * shadersettings.window_scaling,
                                      -rectY * shadersettings.window_scaling,
                                      terminal.width + 2*rectX * shadersettings.window_scaling,
                                      terminal.height + 2*rectY * shadersettings.window_scaling)

    BorderImage{
        id: frameimage
        anchors.centerIn: parent
        width: textureWidth + addedWidth
        height: textureHeight + addedHeight

        border.bottom: borderBottom
        border.top: borderTop
        border.left: borderLeft
        border.right: borderRight

        source: imageSource
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }
    BorderImage{
        id: framenormals
        anchors.fill: frameimage

        border.bottom: borderBottom
        border.top: borderTop
        border.left: borderLeft
        border.right: borderRight

        source: normalsSource
        horizontalTileMode: BorderImage.Stretch
        verticalTileMode: BorderImage.Stretch
    }
    ShaderEffectSource{
        id: framesource
        sourceItem: frameimage
        hideSource: true
        textureSize: Qt.size(parent.width, parent.height)
    }
    ShaderEffectSource{
        id: framesourcenormals
        sourceItem: framenormals
        hideSource: true
        textureSize: Qt.size(parent.width, parent.height)
    }
    Loader{
        anchors.centerIn: parent
        width: parent.width + (addedWidth / textureWidth) * parent.width
        height: parent.height + (addedHeight / textureHeight) * parent.height
        source: shaderString
    }
}
