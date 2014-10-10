#include <QtQml/QQmlApplicationEngine>
#include <QtGui/QGuiApplication>

#include <QQmlContext>
#include <QStringList>

#include <QtWidgets/QApplication>

#include <QDebug>
#include <stdlib.h>


QString getNamedArgument(QStringList args, QString name) {
    int index = args.indexOf(name);
    return (index != -1) ? args[index + 1] : QString("");
}

int main(int argc, char *argv[])
{
    setenv("QT_QPA_PLATFORMTHEME", "", 1);
    QApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // Manage command line arguments from the cpp side
    QStringList args = app.arguments();
    if (args.contains("-h") || args.contains("--help")) {
        qDebug() << "Usage: " + args.at(0) + " [--default-settings] [--workdir <dir>] [--program <prog>] [-p|--profile <prof>] [--fullscreen] [-h|--help]";
        qDebug() << "    --default-settings  Run cool-retro-term with the default settings";
        qDebug() << "    --workdir <dir>     Change working directory to 'dir'";
        qDebug() << "    --program <prog>    Run the 'prog' in the new terminal.";
        qDebug() << "    --fullscreen        Run cool-retro-term in fullscreen.";
        qDebug() << "    -p|--profile <prof> Run cool-retro-term with the given profile.";
        qDebug() << "    -h|--help           Print this help.";
        return 0;
    }

    engine.rootContext()->setContextProperty("workdir", getNamedArgument(args, "--workdir"));
    engine.rootContext()->setContextProperty("shellProgram", getNamedArgument(args, "--program"));

    // Manage import paths for Linux and OSX.
    QStringList importPathList = engine.importPathList();
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/imports/");
    importPathList.prepend(QCoreApplication::applicationDirPath() + "/../PlugIns");
    engine.setImportPathList(importPathList);

    engine.load(QUrl("qrc:/main.qml"));

    return app.exec();
}
