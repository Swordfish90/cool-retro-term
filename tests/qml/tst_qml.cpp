#include <QtQuickTest>
#include <QQmlEngine>

class Setup : public QObject
{
    Q_OBJECT

public slots:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        // Add import path for utils.js
        engine->addImportPath(QStringLiteral("../../app/qml"));
    }
};

QUICK_TEST_MAIN_WITH_SETUP(qml, Setup)

#include "tst_qml.moc"
