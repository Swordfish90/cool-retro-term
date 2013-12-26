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

ObjectDestructItem {
    id: textItem
    property font font
    property real fontWidth
    property real fontHeight

    y: objectHandle.line * fontHeight;
    x: objectHandle.index * fontWidth;

    width: textElement.paintedWidth
    height: textElement.paintedHeight

    visible: objectHandle.visible

    Rectangle {
        anchors.fill: parent
        color: objectHandle.backgroundColor

        MonoText {
            id: textElement
            anchors.fill: parent
            text: objectHandle.text
            color: objectHandle.foregroundColor
            font.family: textItem.font.family
            font.pixelSize: textItem.font.pixelSize
            font.pointSize: textItem.font.pointSize
            font.bold: objectHandle.bold
            font.underline: objectHandle.underline
            latin: objectHandle.latin

            SequentialAnimation {
                running: objectHandle.blinking
                loops: Animation.Infinite
                onRunningChanged: {
                    if (running === false)
                        textElement.opacity = 1
                }
                NumberAnimation {
                    target: textElement
                    property: "opacity"
                    to: 0
                    duration: 250
                }
                NumberAnimation {
                    target: textElement
                    property: "opacity"
                    to: 1
                    duration: 250
                }
            }
        }
    }

}
