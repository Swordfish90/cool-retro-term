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
    }

    // This is used to render the texture to a lower resolution then scale it up.
    Loader{
        id: scalableContentSource
        active: shadersettings.window_scaling < 1
        sourceComponent: ShaderEffectSource{
            sourceItem: scalableContent
            hideSource: true
            smooth: true
        }
    }
    Loader{
        active: shadersettings.window_scaling < 1
        anchors.fill: parent
        sourceComponent: ShaderEffect{
            property var source: scalableContentSource.item
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
