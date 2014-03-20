/*
    This file is part of Konsole QML plugin,
    which is a terminal emulator from KDE.

    Copyright 2013      by Dmitry Zagnoyko <hiroshidi@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301  USA.
*/

#include <QString>
#include <QDir>

#include "plugin.h"

#include <stdlib.h>

KonsoleKterminalPlugin::KonsoleKterminalPlugin() { }

KonsoleKterminalPlugin::~KonsoleKterminalPlugin() { }

void KonsoleKterminalPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.konsole"));

    QQmlExtensionPlugin::initializeEngine(engine, uri);

    QStringList pwds = engine->importPathList();

    if (!pwds.empty()){

        QString cs, kbl;

        foreach (QString pwd, pwds) {
            cs  = pwd + "/org/kde/konsole/color-schemes";
            kbl = pwd + "/org/kde/konsole/kb-layouts";
            if (QDir(cs).exists()) break;
        }

        setenv("KB_LAYOUT_DIR",kbl.toLatin1().constData(),1);
        setenv("COLORSCHEMES_DIR",cs.toLatin1().constData(),1);
    }
}

void KonsoleKterminalPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.konsole"));

    qmlRegisterType<KTerminalDisplay>(uri, 0, 1, "KTerminal");
    qmlRegisterType<KSession>(uri, 0, 1, "KSession");
}
