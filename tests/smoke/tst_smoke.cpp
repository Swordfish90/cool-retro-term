#include <QtTest>
#include <QProcess>
#include <QCoreApplication>

class SmokeTest : public QObject
{
    Q_OBJECT

private slots:
    void testAppExists();
    void testAppLaunches();
};

void SmokeTest::testAppExists()
{
    QString appPath = APP_PATH;
    QFileInfo info(appPath);

    // On Linux, the binary is just "cool-retro-term" in the build dir
    if (!info.exists()) {
        appPath = QCoreApplication::applicationDirPath() + "/../../cool-retro-term";
        info.setFile(appPath);
    }

    QVERIFY2(info.exists(), qPrintable("App binary not found at: " + appPath));
    QVERIFY2(info.isExecutable(), "App binary is not executable");
}

void SmokeTest::testAppLaunches()
{
    QString appPath = APP_PATH;
    QFileInfo info(appPath);

    // Fallback for Linux
    if (!info.exists()) {
        appPath = QCoreApplication::applicationDirPath() + "/../../cool-retro-term";
    }

    QProcess app;
    app.setProgram(appPath);

    // Start the app
    app.start();

    bool started = app.waitForStarted(10000);
    if (!started) {
        QFAIL(qPrintable("App failed to start: " + app.errorString()));
    }

    // Give it time to initialize (create window, load QML, etc.)
    QTest::qWait(3000);

    // Check it's still running (didn't crash during init)
    QVERIFY2(app.state() == QProcess::Running,
             qPrintable("App crashed during initialization. Exit code: " +
                       QString::number(app.exitCode()) +
                       " stderr: " + app.readAllStandardError()));

    // Gracefully terminate
    app.terminate();

    bool finished = app.waitForFinished(5000);
    if (!finished) {
        app.kill();
        app.waitForFinished(2000);
    }

    // We don't check exit code here since terminate() may result in non-zero
    QVERIFY(true);
}

QTEST_MAIN(SmokeTest)
#include "tst_smoke.moc"
