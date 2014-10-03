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

    // Manage command line arguments from the cpp side
    QStringList args = app.arguments();
    if (args.contains("-h") || args.contains("--help")) {
        qDebug() << "Usage: " + args.at(0) + " [--default-settings] [-h|--help]";
        qDebug() << "    --default-settings  Run cool-old-term with the default settings";
        qDebug() << "    -p|--profile        Run cool-old-term with the given profile.";
        qDebug() << "    -h|--help           Print this help.";
        return 0;
    }

    // Manage import paths
    QStringList importPathList = engine.importPathList();
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/imports/");
    engine.setImportPathList(importPathList);

    engine.load(QUrl("qrc:/main.qml"));

    return app.exec();
}

