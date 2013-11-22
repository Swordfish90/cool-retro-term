#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>

#include "register_qml_types.h"
#include "terminal_screen.h"
#include "yat_pty.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("cool-old-term");

    register_qml_types();

    QQmlApplicationEngine engine;
    engine.load(QUrl("qml/cool-old-term/main.qml"));

    return app.exec();
}
