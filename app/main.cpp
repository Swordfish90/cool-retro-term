#include <QtQml/QQmlApplicationEngine>
#include <QtGui/QGuiApplication>

#include <QtWidgets/QApplication>

#include <QDebug>
#include <stdlib.h>


int main(int argc, char *argv[])
{
    setenv("QT_QPA_PLATFORMTHEME", "", 1);
    QApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // Managing some env variables

    // Manage import paths
    QStringList importPathList = engine.importPathList();
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/imports/");
    engine.setImportPathList(importPathList);

    engine.load(QUrl("qrc:/main.qml"));

    return app.exec();
}

