#include <QtQml/QQmlApplicationEngine>
#include <QtGui/QGuiApplication>

#include <QQmlContext>
#include <QStringList>

#include <QtWidgets/QApplication>
#include <QIcon>
#include <QQuickStyle>
#include <QtQml/qqml.h>

#include <kdsingleapplication.h>

#include <QDebug>
#include <stdlib.h>

#include <QLoggingCategory>

#include <fileio.h>
#include <fontlistmodel.h>
#include <fontmanager.h>

#if defined(Q_OS_MAC)
#include <CoreFoundation/CoreFoundation.h>
#include <QStyleFactory>
#include <QMenu>
#endif

QString getNamedArgument(QStringList args, QString name, QString defaultName)
{
    int index = args.indexOf(name);
    return (index != -1) ? args[index + 1] : QString(defaultName);
}

QString getNamedArgument(QStringList args, QString name)
{
    return getNamedArgument(args, name, "");
}

int main(int argc, char *argv[])
{
    // Some environmental variable are necessary on certain platforms.
    // Disable Connections slot warnings
    QLoggingCategory::setFilterRules("qt.qml.connections.warning=false");
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::Round);

// #if defined (Q_OS_LINUX)
//     setenv("QSG_RENDER_LOOP", "threaded", 0);
// #endif

#if defined(Q_OS_MAC)
    // This allows UTF-8 characters usage in OSX.
    setenv("LC_CTYPE", "UTF-8", 1);

    // Ensure key repeat works for letter keys (disable macOS press-and-hold for this app).
    CFPreferencesSetAppValue(CFSTR("ApplePressAndHoldEnabled"), kCFBooleanFalse, kCFPreferencesCurrentApplication);
    CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);

    // Qt6 macOS default look is still lacking, so let's force Fusion for now
    QQuickStyle::setStyle(QStringLiteral("Fusion"));
#endif

    if (argc>1 && (!strcmp(argv[1],"-h") || !strcmp(argv[1],"--help"))) {
        QTextStream cout(stdout, QIODevice::WriteOnly);
        cout << "Usage: " << argv[0] << " [--default-settings] [--workdir <dir>] [--program <prog>] [-p|--profile <prof>] [--fullscreen] [-h|--help]" << Qt::endl;
        cout << "  --default-settings  Run cool-retro-term with the default settings" << Qt::endl;
        cout << "  --workdir <dir>     Change working directory to 'dir'" << Qt::endl;
        cout << "  -e <cmd>            Command to execute. This option will catch all following arguments, so use it as the last option." << Qt::endl;
        cout << "  --fullscreen        Run cool-retro-term in fullscreen." << Qt::endl;
        cout << "  -p|--profile <prof> Run cool-retro-term with the given profile." << Qt::endl;
        cout << "  -h|--help           Print this help." << Qt::endl;
        cout << "  --verbose           Print additional information such as profiles and settings." << Qt::endl;
        return 0;
    }

    QString appVersion(QStringLiteral(APP_VERSION));

    if (argc>1 && (!strcmp(argv[1],"-v") || !strcmp(argv[1],"--version"))) {
        QTextStream cout(stdout, QIODevice::WriteOnly);
        cout << "cool-retro-term " << appVersion << Qt::endl;
        return 0;
    }

    QApplication app(argc, argv);
    app.setAttribute(Qt::AA_MacDontSwapCtrlAndMeta, true);
    app.setApplicationName(QStringLiteral("cool-retro-term"));
    app.setOrganizationName(QStringLiteral("cool-retro-term"));
    app.setOrganizationDomain(QStringLiteral("cool-retro-term"));
    app.setApplicationVersion(appVersion);

    KDSingleApplication singleApp(QStringLiteral("cool-retro-term"));

    if (!singleApp.isPrimaryInstance()) {
        if (singleApp.sendMessage("new-window"))
            return 0;
        qWarning() << "KDSingleApplication: primary not reachable, continuing as independent instance.";
    }

    QQmlApplicationEngine engine;
    FileIO fileIO;

    qmlRegisterType<FontManager>("CoolRetroTerm", 1, 0, "FontManager");
    qmlRegisterUncreatableType<FontListModel>("CoolRetroTerm", 1, 0, "FontListModel", "FontListModel is created by FontManager");

#if !defined(Q_OS_MAC)
    app.setWindowIcon(QIcon::fromTheme("cool-retro-term", QIcon(":../icons/32x32/cool-retro-term.png")));
#if defined(Q_OS_LINUX)
    QGuiApplication::setDesktopFileName(QStringLiteral("cool-retro-term"));
#endif
#else
    app.setWindowIcon(QIcon(":../icons/32x32/cool-retro-term.png"));
#endif

    // Manage command line arguments from the cpp side
    QStringList args = app.arguments();

    // Manage default command
    QStringList cmdList;
    if (args.contains("-e")) {
        cmdList << args.mid(args.indexOf("-e") + 1);
    }
    QVariant command(cmdList.empty() ? QVariant() : cmdList[0]);
    QVariant commandArgs(cmdList.size() <= 1 ? QVariant() : QVariant(cmdList.mid(1)));
    engine.rootContext()->setContextProperty("appVersion", appVersion);
    engine.rootContext()->setContextProperty("defaultCmd", command);
    engine.rootContext()->setContextProperty("defaultCmdArgs", commandArgs);

    engine.rootContext()->setContextProperty("workdir", getNamedArgument(args, "--workdir", "$HOME"));
    engine.rootContext()->setContextProperty("fileIO", &fileIO);

    // Manage import paths for Linux and OSX.
    QStringList importPathList = engine.importPathList();
    importPathList.append(QCoreApplication::applicationDirPath() + "/qmltermwidget");
    importPathList.append(QCoreApplication::applicationDirPath() + "/../PlugIns");
    importPathList.append(QCoreApplication::applicationDirPath() + "/../../../qmltermwidget");
    engine.setImportPathList(importPathList);

    engine.load(QUrl(QStringLiteral ("qrc:/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qDebug() << "Cannot load QML interface";
        return EXIT_FAILURE;
    }

    // Quit the application when the engine closes.
    QObject::connect((QObject*) &engine, SIGNAL(quit()), (QObject*) &app, SLOT(quit()));

    auto requestNewWindow = [&engine]() {
        if (engine.rootObjects().isEmpty())
            return;

        QObject *rootObject = engine.rootObjects().constFirst();
        QMetaObject::invokeMethod(rootObject, "createWindow", Qt::QueuedConnection);
    };

    QObject::connect(&singleApp, &KDSingleApplication::messageReceived, &app,
                     [&requestNewWindow](const QByteArray &message) {
        if (message.isEmpty() || message == QByteArray("new-window"))
            requestNewWindow();
    });

#if defined(Q_OS_MAC)
    QMenu *dockMenu = new QMenu(nullptr);
    dockMenu->addAction(QObject::tr("New Window"), [&requestNewWindow]() { requestNewWindow(); });
    dockMenu->setAsDockMenu();
#endif

    return app.exec();
}
