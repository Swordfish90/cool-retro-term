import QtQuick 2.2

ShaderTerminal{
    property alias title: terminal.title
    property alias terminalSize: terminal.terminalSize

    id: shadercontainer
    opacity: shadersettings.windowOpacity * 0.3 + 0.7

    Loader{
        id: frame
        anchors.fill: parent
        z: 2.1
        source: shadersettings.frame_source
    }
    PreprocessedTerminal{
        id: terminal
        anchors.fill: parent
    }
}
