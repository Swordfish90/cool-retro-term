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

#ifndef KDE_QML_PLUGIN_KTERMINAL
#define KDE_QML_PLUGIN_KTERMINAL

#include "TerminalDisplay.h"
#include "ksession.h"

#include <QtQml/QQmlEngine>
#include <QtQml/QQmlExtensionPlugin>

class KonsoleKterminalPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    KonsoleKterminalPlugin();
    ~KonsoleKterminalPlugin();

    void registerTypes(const char *uri);
    void initializeEngine(QQmlEngine *engine, const char *uri);

};

#endif // KDE_QML_PLUGIN_KTERMINAL
