/*******************************************************************************
* Copyright (c) 2013 "Filippo Scognamiglio"
* https://github.com/Swordifish90/cool-old-term
*
* This file is part of cool-old-term.
*
* cool-old-term is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>

#include "register_qml_types.h"
#include "terminal_screen.h"
#include "yat_pty.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName("cool-old-term");

    register_qml_types();

    QQmlApplicationEngine engine;
    engine.load(QUrl("qml/cool-old-term/main.qml"));

    return app.exec();
}
