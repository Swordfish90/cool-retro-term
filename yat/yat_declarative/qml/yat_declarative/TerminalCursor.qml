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
    id: cursor

    property real fontHeight
    property real fontWidth

    height: fontHeight
    width: fontWidth
    x: objectHandle.x * fontWidth
    y: objectHandle.y * fontHeight
    z: 1.1

    visible: objectHandle.visible

    ShaderEffect {
        anchors.fill: parent

        property variant source: fragmentSource

        fragmentShader:
            "uniform lowp float qt_Opacity;" +
            "uniform sampler2D source;" +
            "varying highp vec2 qt_TexCoord0;" +

            "void main() {" +
            "   lowp vec4 color = texture2D(source, qt_TexCoord0 ) * qt_Opacity;" +
            "   gl_FragColor = vec4(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a);" +
            "}"

        ShaderEffectSource {
            id: fragmentSource
            sourceItem: background
            live: true

            sourceRect: Qt.rect(cursor.x,cursor.y,cursor.width,cursor.height);
        }
    }
}

