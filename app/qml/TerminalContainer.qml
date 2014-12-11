import QtQuick 2.2

Item{
    property alias title: terminal.title

    Item{
        id: scalableContent
        width: parent.width * shadersettings.window_scaling
        height: parent.height * shadersettings.window_scaling

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
        ShaderTerminal{
            id: shadercontainer
            anchors.fill: parent
            opacity: shadersettings.windowOpacity * 0.3 + 0.7
            z: 1.9
        }

        transform: Scale {
            xScale: 1 / shadersettings.window_scaling
            yScale: 1 / shadersettings.window_scaling
        }
    }

    // Terminal size overlay. Shown when terminal size changes.
    Loader{
        id: sizeoverlayloader
        z: 3
        anchors.centerIn: parent
        active: shadersettings.show_terminal_size
        sourceComponent: SizeOverlay{
            terminalSize: terminal.terminalSize
        }
    }
}
