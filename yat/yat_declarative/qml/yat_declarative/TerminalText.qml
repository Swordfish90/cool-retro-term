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

    y: 0
    x: 0

    width: textElement.paintedWidth
    height: textElement.paintedHeight

    visible: objectHandle.visible

    Rectangle {
        anchors.fill: parent
        color: textItem.objectHandle.backgroundColor
    }


    Text {
        id: textElement
        anchors.fill: parent
        text: objectHandle.text
        color: objectHandle.foregroundColor
        font: textItem.font
        textFormat: Text.PlainText
    }

    Connections {
        target: objectHandle

        onIndexChanged: {
            textItem.x = objectHandle.index *  textItem.fontWidth;
        }
    }

    //Component.onCompleted: {
    //    //color = randomBg();
    //}
    //function randomBg()
    //{
    //    var hex1=new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
    //        var hex2=new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
    //        var hex3=new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
    //        var hex4=new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
    //        var hex5=new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
    //        var hex6=new Array("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
    //        var bg="#"+hex1[Math.floor(Math.random()*hex1.length)]+hex2[Math.floor(Math.random()*hex2.length)]+hex3[Math.floor(Math.random()*hex3.length)]+hex4[Math.floor(Math.random()*hex4.length)]+hex5[Math.floor(Math.random()*hex5.length)]+hex6[Math.floor(Math.random()*hex6.length)]
    //        return bg
    //}
}
