#include <QtTest>
#include <QFile>
#include <QTextStream>
#include <QUrl>
#include "tst_fileio.h"
#include "fileio.h"

void FileIOTest::initTestCase()
{
    m_tempDir = new QTemporaryDir();
    QVERIFY(m_tempDir->isValid());
}

void FileIOTest::cleanupTestCase()
{
    delete m_tempDir;
}

QString FileIOTest::tempFilePath(const QString &name)
{
    // FileIO expects file:// URLs
    return QUrl::fromLocalFile(m_tempDir->path() + "/" + name).toString();
}

QString FileIOTest::localPath(const QString &name)
{
    // For direct file operations (verification)
    return m_tempDir->path() + "/" + name;
}

// Write tests
void FileIOTest::testWriteSimple()
{
    FileIO fileio;
    QString url = tempFilePath("simple.txt");
    QString local = localPath("simple.txt");

    bool result = fileio.write(url, "Hello, World!");
    QVERIFY(result);

    // Verify file exists and has correct content
    QFile file(local);
    QVERIFY(file.open(QIODevice::ReadOnly));
    QCOMPARE(file.readAll(), QByteArray("Hello, World!"));
}

void FileIOTest::testWriteEmpty()
{
    FileIO fileio;
    QString url = tempFilePath("empty.txt");
    QString local = localPath("empty.txt");

    bool result = fileio.write(url, "");
    QVERIFY(result);

    QFile file(local);
    QVERIFY(file.open(QIODevice::ReadOnly));
    QCOMPARE(file.size(), 0);
}

void FileIOTest::testWriteUnicode()
{
    FileIO fileio;
    QString url = tempFilePath("unicode.txt");
    QString local = localPath("unicode.txt");
    QString content = QString::fromUtf8("Hello 世界");

    bool result = fileio.write(url, content);
    QVERIFY(result);

    QFile file(local);
    QVERIFY(file.open(QIODevice::ReadOnly | QIODevice::Text));
    QTextStream stream(&file);
    stream.setCodec("UTF-8");
    QCOMPARE(stream.readAll(), content);
}

void FileIOTest::testWriteOverwrite()
{
    FileIO fileio;
    QString url = tempFilePath("overwrite.txt");
    QString local = localPath("overwrite.txt");

    fileio.write(url, "First content");
    bool result = fileio.write(url, "Second content");
    QVERIFY(result);

    QFile file(local);
    QVERIFY(file.open(QIODevice::ReadOnly));
    QCOMPARE(file.readAll(), QByteArray("Second content"));
}

// Read tests
void FileIOTest::testReadSimple()
{
    FileIO fileio;
    QString url = tempFilePath("read_simple.txt");
    QString local = localPath("read_simple.txt");

    // Create file first
    QFile file(local);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("Test content");
    file.close();

    QString result = fileio.read(url);
    QCOMPARE(result, QString("Test content"));
}

void FileIOTest::testReadNonexistent()
{
    FileIO fileio;
    QString url = tempFilePath("nonexistent.txt");

    QString result = fileio.read(url);
    QVERIFY(result.isEmpty());
}

void FileIOTest::testReadEmpty()
{
    FileIO fileio;
    QString url = tempFilePath("read_empty.txt");
    QString local = localPath("read_empty.txt");

    // Create empty file
    QFile file(local);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.close();

    QString result = fileio.read(url);
    QVERIFY(result.isEmpty());
}

void FileIOTest::testReadUnicode()
{
    FileIO fileio;
    QString url = tempFilePath("read_unicode.txt");
    QString local = localPath("read_unicode.txt");
    QString content = QString::fromUtf8("こんにちは世界");

    // Create file with unicode content
    QFile file(local);
    QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
    QTextStream stream(&file);
    stream.setCodec("UTF-8");
    stream << content;
    file.close();

    QString result = fileio.read(url);
    QCOMPARE(result, content);
}

// Round-trip tests
void FileIOTest::testWriteReadRoundtrip()
{
    FileIO fileio;
    QString url = tempFilePath("roundtrip.txt");
    QString content = "Line 1\nLine 2\nLine 3\n";

    QVERIFY(fileio.write(url, content));
    QString result = fileio.read(url);
    QCOMPARE(result, content);
}

void FileIOTest::testWriteReadLargeFile()
{
    FileIO fileio;
    QString url = tempFilePath("large.txt");

    // Create a ~100KB string
    QString content;
    for (int i = 0; i < 1000; i++) {
        content += QString("Line %1: This is some test content for the large file test.\n").arg(i);
    }

    QVERIFY(fileio.write(url, content));
    QString result = fileio.read(url);
    QCOMPARE(result, content);
}
