/*******************************************************************************
* Copyright (c) 2013 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*******************************************************************************/

import QtQuick 2.0

import org.yat 1.0

TerminalScreen {
    id: screenItem

    property font font
    property real fontWidth: fontMetricText.paintedWidth
    property real fontHeight: fontMetricText.paintedHeight

    property var lineComponent : Qt.createComponent("TerminalLine.qml")
    property var textComponent : Qt.createComponent("TerminalText.qml")
    property var cursorComponent : Qt.createComponent("TerminalCursor.qml")

    font.family: "menlo"
    focus: true

    onActiveFocusChanged: {
        if (activeFocus) {
            Qt.inputMethod.show();
        }
    }

    Keys.onPressed: {
        if (event.text === "?") {
            terminal.screen.printScreen()
        }
    }

    Text {
        id: fontMetricText
        text: "B"
        font: parent.font
        visible: false
        textFormat: Text.PlainText
    }

    Flickable {
        id: flickable
        anchors.top: parent.top
        anchors.left: parent.left
        contentWidth: width
        contentHeight: textContainer.height
        interactive: true
        flickableDirection: Flickable.VerticalFlick
        contentY: ((screen.contentHeight - screen.height) * screenItem.fontHeight)

        Item {
            id: textContainer
            width: parent.width
            height: screen.contentHeight * screenItem.fontHeight
            Rectangle {
                id: background
                anchors.fill: parent
                color: terminal.screen.defaultBackgroundColor
            }
        }
        onContentYChanged: {
            if (!atYEnd) {
                var top_line = Math.floor(Math.max(contentY,0) / screenItem.fontHeight);
                screen.ensureVisiblePages(top_line);
            }
        }
    }

    Connections {
        id: connections

        target: terminal.screen

        onFlash: {
            flashAnimation.start()
        }

        onReset: {
            resetScreenItems();
        }

        onTextCreated: {
            var textSegment = textComponent.createObject(screenItem,
                {
                    "parent" : background,
                    "objectHandle" : text,
                    "font" : screenItem.font,
                    "fontWidth" : screenItem.fontWidth,
                    "fontHeight" : screenItem.fontHeight,
                })
        }

        onCursorCreated: {
            if (cursorComponent.status != Component.Ready) {
                console.log(cursorComponent.errorString());
                return;
            }
            var cursorVariable = cursorComponent.createObject(screenItem,
                {
                    "parent" : textContainer,
                    "objectHandle" : cursor,
                    "fontWidth" : screenItem.fontWidth,
                    "fontHeight" : screenItem.fontHeight,
                })
        }

        onRequestHeightChange: {
            terminalWindow.height = newHeight * screenItem.fontHeight;
            terminalWindow.contentItem.height = newHeight * screenItem.fontHeight;
        }

        onRequestWidthChange: {
            terminalWindow.width = newWidth * screenItem.fontWidth;
            terminalWindow.contentItem.width = newWidth * screenItem.fontWidth;
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
            flickable.width = pty_width * fontWidth;
            screen.width = pty_width;
        }
    }

    function setTerminalHeight() {
        if (fontHeight > 0) {
            var pty_height = Math.floor(height / fontHeight);
            flickable.height = pty_height * fontHeight;
            screen.height = pty_height;
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
        id: flash
        z: 1.2
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
