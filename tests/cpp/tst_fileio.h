#ifndef TST_FILEIO_H
#define TST_FILEIO_H

#include <QObject>
#include <QTemporaryDir>

class FileIOTest : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    // Write tests
    void testWriteSimple();
    void testWriteEmpty();
    void testWriteUnicode();
    void testWriteOverwrite();

    // Read tests
    void testReadSimple();
    void testReadNonexistent();
    void testReadEmpty();
    void testReadUnicode();

    // Round-trip tests
    void testWriteReadRoundtrip();
    void testWriteReadLargeFile();

private:
    QTemporaryDir *m_tempDir;
    QString tempFilePath(const QString &name);  // Returns file:// URL
    QString localPath(const QString &name);     // Returns local filesystem path
};

#endif // TST_FILEIO_H
