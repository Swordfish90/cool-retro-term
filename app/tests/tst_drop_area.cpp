#include <QtTest>
#include <memory>

#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMimeData>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickWindow>
#include <QUrl>

class RecordingTerminal final : public QObject
{
    Q_OBJECT

public:
    QList<QUrl> receivedUrls;

    Q_INVOKABLE void insertDroppedUrls(const QList<QUrl> &urls)
    {
        receivedUrls = urls;
    }
};

class DropAreaTest final : public QObject
{
    Q_OBJECT

private slots:
    void acceptsFileUrls();
    void ignoresTextOnlyDrops();
};

static std::unique_ptr<QQuickItem> createDropArea(QQmlEngine &engine,
                                                   RecordingTerminal &terminal)
{
    const QString path = QFINDTESTDATA("../qml/TerminalDropArea.qml");
    if (path.isEmpty())
        return nullptr;

    QQmlComponent component(&engine, QUrl::fromLocalFile(path));
    if (!component.isReady()) {
        qWarning() << component.errorString();
        return nullptr;
    }
    std::unique_ptr<QQuickItem> item(qobject_cast<QQuickItem *>(component.create()));
    if (item) {
        item->setProperty("targetTerminal", QVariant::fromValue(static_cast<QObject *>(&terminal)));
        item->setSize(QSizeF(200, 100));
    }
    return item;
}

void DropAreaTest::acceptsFileUrls()
{
    QQmlEngine engine;
    RecordingTerminal terminal;
    auto area = createDropArea(engine, terminal);
    QVERIFY(area != nullptr);

    QQuickWindow window;
    window.resize(200, 100);
    area->setParentItem(window.contentItem());
    window.show();
    QCoreApplication::processEvents();

    const QList<QUrl> urls = {
        QUrl::fromLocalFile(QStringLiteral("/tmp/image with spaces.png")),
        QUrl::fromLocalFile(QStringLiteral("/tmp/second image.png"))
    };
    QMimeData mimeData;
    mimeData.setUrls(urls);
    QDragEnterEvent enter(QPoint(40, 40), Qt::CopyAction, &mimeData,
                          Qt::LeftButton, Qt::NoModifier);
    QCoreApplication::sendEvent(&window, &enter);
    QVERIFY(enter.isAccepted());

    QDropEvent drop(QPointF(40, 40), Qt::CopyAction, &mimeData,
                    Qt::LeftButton, Qt::NoModifier);
    QCoreApplication::sendEvent(&window, &drop);
    QVERIFY(drop.isAccepted());
    QCOMPARE(terminal.receivedUrls, urls);
}

void DropAreaTest::ignoresTextOnlyDrops()
{
    QQmlEngine engine;
    RecordingTerminal terminal;
    auto area = createDropArea(engine, terminal);
    QVERIFY(area != nullptr);

    QQuickWindow window;
    window.resize(200, 100);
    area->setParentItem(window.contentItem());
    window.show();
    QCoreApplication::processEvents();

    QMimeData mimeData;
    mimeData.setText(QStringLiteral("plain text"));
    QDragEnterEvent enter(QPoint(40, 40), Qt::CopyAction, &mimeData,
                          Qt::LeftButton, Qt::NoModifier);
    QCoreApplication::sendEvent(&window, &enter);
    QVERIFY(!enter.isAccepted());
    QVERIFY(terminal.receivedUrls.isEmpty());
}

QTEST_MAIN(DropAreaTest)
#include "tst_drop_area.moc"
