import QtQuick 2.0

import org.yat 1.0

ObjectDestructItem {
    id: textLine

    property var textComponent : Qt.createComponent("TerminalText.qml")
    property font font
    property real fontHeight
    property real fontWidth

    height: fontHeight
    width: parent.width
    visible: objectHandle.visible

    Connections {
        target: objectHandle

        onIndexChanged: {
            y = objectHandle.index * fontHeight;
        }

        onTextCreated: {
            var textSegment = textComponent.createObject(textLine,
                {
                    "objectHandle" : text,
                    "font" : textLine.font,
                    "fontWidth" : textLine.fontWidth,
                })
        }
    }
}

