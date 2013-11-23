import QtQuick 2.0

import org.yat 1.0

TerminalScreen {
    id: screenItem

    property font font
    property real fontWidth: fontMetricText.paintedWidth
    property real fontHeight: fontMetricText.paintedHeight

    property var lineComponent : Qt.createComponent("TerminalLine.qml")

    font.family: "courier"

    Text {
        id: fontMetricText
        text: "B"
        font: parent.font
        visible: false
        textFormat: Text.PlainText
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "black"
    }

    Connections {
        id: connections

        target: terminal.screen

        onFlash: {
            flashAnimation.start()
        }

        onCursorPositionChanged: {
            cursor.x = x * fontWidth;
            cursor.y = y * fontHeight;
        }

        onReset: {
            resetScreenItems();
        }

        onLineCreated: {
            var lineVariable = lineComponent.createObject(screenItem,
                {
                    "objectHandle" : line,
                    "font": screenItem.font,
                    "fontWidth" : screenItem.fontWidth,
                    "fontHeight" : screenItem.fontHeight,
                })
        }
    }

    onFontChanged: {
        setTerminalHeight();
        setTerminalWidth();
    }

    onWidthChanged: {
        setTerminalWidth();
    }
    onHeightChanged: {
        setTerminalHeight();
    }
    Component.onCompleted: {
        setTerminalWidth();
        setTerminalHeight();
    }

    function setTerminalWidth() {
        if (fontWidth > 0) {
            var pty_width = Math.floor(width / fontWidth);
            screen.width = pty_width;
        }
    }

    function setTerminalHeight() {
        if (fontHeight > 0) {
            var pty_height = Math.floor(height / fontHeight);
            screen.height = pty_height;
        }
    }


    Item {
        id: keyHandler
        focus: true
        Keys.onPressed: {
            terminal.screen.sendKey(event.text, event.key, event.modifiers);
            if (event.text === "?") {
                terminal.screen.printScreen()
            }
        }
    }

    HighlightArea {
        characterHeight: fontHeight
        characterWidth: fontWidth

        start: screen.selectionAreaStart
        end: screen.selectionAreaEnd

        visible: screen.selectionEnabled
    }

    Rectangle {
        id: cursor
        width: fontWidth
        height: fontHeight
        x: 0
        y: 0
        color: "grey"
    }

    Rectangle {
        id: flash
        anchors.fill: parent
        color: "grey"
        opacity: 0
        SequentialAnimation {
            id: flashAnimation
            NumberAnimation {
                target: flash
                property: "opacity"
                to: 1
                duration: 75
            }
            NumberAnimation {
                target: flash
                property: "opacity"
                to: 0
                duration: 75
            }
        }
    }

    MouseArea {
        id:mousArea

        property point drag_start

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: {
            if (mouse.button == Qt.LeftButton) {
                hoverEnabled = true;
                var character = Math.floor((mouse.x / screen.charWidth));
                var line = Math.floor(mouse.y / screen.lineHeight);
                var start = Qt.point(character,line);
                drag_start = start;
                screen.selectionAreaStart = start;
                screen.selectionAreaEnd = start;
            }
        }

        onPositionChanged: {
            var character = Math.floor(mouse.x / screen.charWidth);
            var line = Math.floor(mouse.y / screen.lineHeight);
            var current_pos = Qt.point(character,line);
            if (line < drag_start.y || (line === drag_start.y && character < drag_start.x)) {
                screen.selectionAreaStart = current_pos;
                screen.selectionAreaEnd = drag_start;
            }else {
                screen.selectionAreaEnd = current_pos;
                screen.selectionAreaStart = drag_start;
            }
        }

        onReleased: {
            if (mouse.button == Qt.LeftButton) {
                hoverEnabled = false;
                screen.sendSelectionToSelection();
            }
        }

        onClicked: {
            if (mouse.button == Qt.MiddleButton) {
                screen.pasteFromSelection();
            }
        }
        onDoubleClicked: {
            if (mouse.button == Qt.LeftButton) {
                var character = Math.floor(mouse.x / screen.charWidth);
                var line = Math.floor(mouse.y / screen.lineHeight);
                screen.doubleClicked(Qt.point(character,line));
            }
        }
    }
}
