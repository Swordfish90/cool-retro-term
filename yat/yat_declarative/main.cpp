/**************************************************************************************************
* Copyright (c) 2012 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
* associated documentation files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge, publish, distribute,
* sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or
* substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
* NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
* DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
* OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
***************************************************************************************************/

#include <QtGui/QGuiApplication>
#include <QtCore/QResource>
#include <QtCore/QThread>

#include <QQmlEngine>

#include "register_qml_types.h"
#include "terminal_screen.h"
#include "yat_pty.h"

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);

    register_qml_types();

    QQmlEngine engine;
    QQmlComponent component(&engine, QUrl("qrc:/qml/yat_declarative/main.qml"));
    auto errors = component.errors();
    for (int i = 0; i < errors.size(); i++) {
        qDebug() << errors.at(i).toString();
    }
    component.create();

    return app.exec();
}
